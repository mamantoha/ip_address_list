require "socket"
require "lib_c"

{% if flag?(:linux) || flag?(:darwin) %}
  lib LibC
    struct Ifaddrs
      ifa_next : Pointer(Ifaddrs)
      ifa_name : UInt64
      ifa_flags : UInt32
      ifa_addr : Pointer(Void)
      ifa_netmask : Pointer(Void)
      ifa_broadaddr : Pointer(Void)
      ifa_data : Pointer(Void)
    end

    fun getifaddrs(addrs : Pointer(Pointer(Ifaddrs))) : Int32
    fun freeifaddrs(addrs : Pointer(Ifaddrs)) : Void
  end
{% end %}

{% if flag?(:win32) %}
  @[Link("iphlpapi")]
  lib LibC
    # https://learn.microsoft.com/en-us/windows/win32/api/iptypes/ns-iptypes-ip_adapter_addresses_lh
    struct IP_ADAPTER_ADDRESSES
      length : UInt32
      if_index : UInt32
      next : Pointer(IP_ADAPTER_ADDRESSES)
      adapter_name : Pointer(UInt8)
      first_unicast_address : Pointer(Void)
    end

    struct IP_ADAPTER_UNICAST_ADDRESS
      length : UInt32
      flags : UInt32
      next : Pointer(IP_ADAPTER_UNICAST_ADDRESS)
      address : Pointer(LibC::Sockaddr)
    end

    # https://learn.microsoft.com/en-us/windows/win32/api/iphlpapi/nf-iphlpapi-getadaptersaddresses
    fun GetAdaptersAddresses(family : UInt32, flags : UInt32, reserved : Pointer(Void), addresses : Pointer(IP_ADAPTER_ADDRESSES), size : Pointer(UInt32)) : Int32
  end
{% end %}

class Socket
  {% if flag?(:linux) || flag?(:darwin) %}
    def self.ip_address_list : Array(Socket::IPAddress)
      ptr = Pointer(Pointer(LibC::Ifaddrs)).malloc(1)
      ret = LibC.getifaddrs(ptr)

      if ret == -1
        raise raise Socket::Error.new("Failed to get network interfaces")
      end

      list = [] of Socket::IPAddress
      addr = ptr.value

      while addr
        if addr.value.ifa_addr.null?
          addr = addr.value.ifa_next
          next
        end

        sockaddr = addr.value.ifa_addr.as(Pointer(LibC::SockaddrIn))

        if sockaddr.value.sin_family == Socket::Family::INET.to_i
          sockaddr_in = sockaddr.as(Pointer(LibC::SockaddrIn))

          ip_address = Socket::IPAddress.from(sockaddr_in, sizeof(typeof(sockaddr_in)))

          list << ip_address
        elsif sockaddr.value.sin_family == Socket::Family::INET6.to_i
          sockaddr_in6 = sockaddr.as(Pointer(LibC::SockaddrIn6))

          ip_address = Socket::IPAddress.from(sockaddr_in6, sizeof(typeof(sockaddr_in6)))

          list << ip_address
        else
          addr = addr.value.ifa_next
          next
        end

        addr = addr.value.ifa_next
      end

      LibC.freeifaddrs(ptr.value)

      list
    end
  {% end %}

  {% if flag?(:win32) %}
    def self.ip_address_list : Array(Socket::IPAddress)
      buffer_size = Pointer(UInt32).malloc(1)
      buffer_size.value = 15000 # Start with a reasonable buffer size
      buffer = Pointer(LibC::IP_ADAPTER_ADDRESSES).malloc(buffer_size.value)

      ret = LibC.GetAdaptersAddresses(LibC::AF_UNSPEC, 0, nil, buffer, buffer_size)

      if ret != 0
        raise Socket::Error.new("Failed to get network interfaces")
      end

      list = [] of Socket::IPAddress
      adapter = buffer

      while adapter
        unicast_address = adapter.value.first_unicast_address.as(Pointer(LibC::IP_ADAPTER_UNICAST_ADDRESS))

        while unicast_address
          sockaddr = unicast_address.value.address.as(Pointer(LibC::Sockaddr))

          if sockaddr.value.sa_family == Socket::Family::INET.to_i
            sockaddr_in = sockaddr.as(Pointer(LibC::SockaddrIn))

            ip_address = Socket::IPAddress.from(sockaddr_in, sizeof(typeof(sockaddr_in)))

            list << ip_address
          elsif sockaddr.value.sa_family == Socket::Family::INET6.to_i
            sockaddr_in6 = sockaddr.as(Pointer(LibC::SockaddrIn6))

            ip_address = Socket::IPAddress.from(sockaddr_in6, sizeof(typeof(sockaddr_in6)))

            list << ip_address
          end

          unicast_address = unicast_address.value.next
        end

        adapter = adapter.value.next
      end
      list
    end
  {% end %}
end

class Socket
  struct IPAddress
    def self.from(sockaddr_in : LibC::SockaddrIn* | LibC::SockaddrIn6*, addrlen) : IPAddress
      new(sockaddr_in, addrlen.to_i)
    end
  end
end

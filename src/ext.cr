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
    struct IP_ADAPTER_ADDRESSES
      length : UInt32
      if_index : UInt32
      next : Pointer(IP_ADAPTER_ADDRESSES)
      adapter_name : Pointer(UInt8)
      first_unicast_address : Pointer(Void)
    end

    struct SOCKADDR
      sa_family : UInt16
      sa_data : StaticArray(UInt8, 28)
    end

    struct IP_ADAPTER_UNICAST_ADDRESS
      length : UInt32
      flags : UInt32
      next : Pointer(IP_ADAPTER_UNICAST_ADDRESS)
      address : Pointer(LibC::SOCKADDR)
    end

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

        sockaddr_in = addr.value.ifa_addr.as(Pointer(LibC::SockaddrIn))

        unless sockaddr_in.value.sin_family.in?([Socket::Family::INET.to_i, Socket::Family::INET6.to_i])
          addr = addr.value.ifa_next
          next
        end

        ip_address = Socket::IPAddress.from(sockaddr_in, sizeof(typeof(sockaddr_in)))

        list << ip_address

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
          sockaddr = unicast_address.value.address.as(Pointer(LibC::SOCKADDR))

          if sockaddr.value.sa_family == 2 # AF_INET = 2 (IPv4)
            address = "#{sockaddr.value.sa_data[2]}.#{sockaddr.value.sa_data[3]}.#{sockaddr.value.sa_data[4]}.#{sockaddr.value.sa_data[5]}"
            ip_address = Socket::IPAddress.new(address, 0)

            list << ip_address
          elsif sockaddr.value.sa_family == 23 # AF_INET6 = 23 (IPv6)
            ipv6_addr = sockaddr.value.sa_data.to_a[6, 16]

            address = ipv6_addr.each_slice(2).map { |slice| "%02x%02x" % slice }.join(':')

            ip_address = Socket::IPAddress.new(address, 0)

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
    def self.from(sockaddr : LibC::SockaddrIn*, addrlen) : IPAddress
      case family = Family.new(sockaddr.value.sin_family.to_u8)
      when Family::INET6
        new(sockaddr.as(LibC::SockaddrIn6*), addrlen.to_i)
      when Family::INET
        new(sockaddr.as(LibC::SockaddrIn*), addrlen.to_i)
      else
        raise "Unsupported family type: #{family} (#{family.value})"
      end
    end
  end
end

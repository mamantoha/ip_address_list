require "socket"

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

class Socket
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

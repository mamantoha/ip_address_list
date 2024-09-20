class Socket
  # Returns local IP addresses as an array of `Socket::IPAddress` objects.
  def self.ip_address_list : Array(Socket::IPAddress)
    {% if flag?(:linux) || flag?(:darwin) %}
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

        sockaddr = addr.value.ifa_addr

        if sockaddr.value.sa_family == Socket::Family::INET.to_i
          sockaddr_in = sockaddr.as(Pointer(LibC::SockaddrIn))

          ip_address = Socket::IPAddress.from(sockaddr_in, sizeof(typeof(sockaddr_in)))

          list << ip_address
        elsif sockaddr.value.sa_family == Socket::Family::INET6.to_i
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
    {% elsif flag?(:win32) %}
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
        unicast_address = adapter.value.first_unicast_address

        while unicast_address
          sockaddr = unicast_address.value.address

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
    {% else %}
      raise NotImplementedError.new("Socket.ip_address_list")
    {% end %}
  end
end
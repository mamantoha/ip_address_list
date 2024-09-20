class Socket
  # Returns local IP addresses as an array of `Socket::IPAddress` objects.
  def self.ip_address_list : Array(Socket::IPAddress)
    {% if flag?(:linux) || flag?(:darwin) %}
      ptr = Pointer(Pointer(LibC::Ifaddrs)).malloc(1)
      ret = LibC.getifaddrs(ptr)

      raise raise Socket::Error.new("Failed to get network interfaces") if ret == -1

      list = [] of Socket::IPAddress
      addr = ptr.value

      while addr
        if addr.value.ifa_addr.null?
          addr = addr.value.ifa_next
          next
        end

        sockaddr = addr.value.ifa_addr

        sockaddr_to_ip_address(sockaddr).try { |ip_address| list << ip_address }

        addr = addr.value.ifa_next
      end

      LibC.freeifaddrs(ptr.value)

      list
    {% elsif flag?(:win32) %}
      buffer_size = Pointer(UInt32).malloc(1)
      buffer_size.value = 15000 # Start with a reasonable buffer size
      buffer = Pointer(LibC::IP_ADAPTER_ADDRESSES).malloc(buffer_size.value)

      ret = LibC.GetAdaptersAddresses(LibC::AF_UNSPEC, 0, nil, buffer, buffer_size)

      raise Socket::Error.new("Failed to get network interfaces") if ret != 0

      list = [] of Socket::IPAddress
      adapter = buffer

      while adapter
        unicast_address = adapter.value.first_unicast_address

        while unicast_address
          sockaddr = unicast_address.value.address

          sockaddr_to_ip_address(sockaddr).try { |ip_address| list << ip_address }

          unicast_address = unicast_address.value.next
        end

        adapter = adapter.value.next
      end

      list
    {% else %}
      raise NotImplementedError.new("Socket.ip_address_list")
    {% end %}
  end

  private def self.sockaddr_to_ip_address(sockaddr : LibC::Sockaddr*) : Socket::IPAddress?
    case sockaddr.value.sa_family
    when Socket::Family::INET.to_i
      sockaddr_in = sockaddr.as(Pointer(LibC::SockaddrIn))

      Socket::IPAddress.from(sockaddr_in, sizeof(typeof(sockaddr_in)))
    when Socket::Family::INET6.to_i
      sockaddr_in6 = sockaddr.as(Pointer(LibC::SockaddrIn6))

      Socket::IPAddress.from(sockaddr_in6, sizeof(typeof(sockaddr_in6)))
    end
  end
end

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

        Socket::IPAddress.from?(sockaddr).try { |ip_address| list << ip_address }

        addr = addr.value.ifa_next
      end

      LibC.freeifaddrs(ptr.value)

      list
    {% elsif flag?(:win32) %}
      # Allocate a 15 KB buffer to start with.
      out_buf_len = 15_000_u32
      
      p_addresses = Pointer(LibC::IP_ADAPTER_ADDRESSES).malloc(out_buf_len)

      # Unicast, anycast, and multicast IP addresses will be returned
      flags = 0

      dw_ret_val = LibC.GetAdaptersAddresses(LibC::AF_UNSPEC, flags, nil, p_addresses, pointerof(out_buf_len))

      raise Socket::Error.new("Failed to get network interfaces") if dw_ret_val != 0

      list = [] of Socket::IPAddress
      
      p_curr_addresses = p_addresses

      while p_curr_addresses
        p_unicast = p_curr_addresses.value.first_unicast_address

        while p_unicast
          sockaddr = unicast_address.value.address

          Socket::IPAddress.from?(sockaddr).try { |ip_address| list << ip_address }

          p_unicast = p_unicast.value.next
        end

        p_curr_addresses = p_curr_addresses.value.next
      end

      list
    {% else %}
      raise NotImplementedError.new("Socket.ip_address_list")
    {% end %}
  end
end

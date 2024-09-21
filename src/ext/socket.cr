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
      out_buf_len = Pointer(UInt32).malloc(1)
      out_buf_len.value = 15_000 # Allocate a 15 KB buffer to start with.

      p_addresses = Pointer(LibC::IP_ADAPTER_ADDRESSES).malloc(out_buf_len.value)

      dw_ret_val = LibC.GetAdaptersAddresses(LibC::AF_UNSPEC, 0, nil, p_addresses, out_buf_len)

      raise Socket::Error.new("Failed to get network interfaces") if dw_ret_val != 0

      list = [] of Socket::IPAddress
      adapter = p_addresses

      while adapter
        unicast_address = adapter.value.first_unicast_address

        while unicast_address
          sockaddr = unicast_address.value.address

          Socket::IPAddress.from?(sockaddr).try { |ip_address| list << ip_address }

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

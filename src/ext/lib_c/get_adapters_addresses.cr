@[Link("iphlpapi")]
lib LibC
  # https://learn.microsoft.com/en-us/windows/win32/api/iptypes/ns-iptypes-ip_adapter_addresses_lh
  struct IP_ADAPTER_ADDRESSES
    length : UInt32
    if_index : UInt32
    next : Pointer(IP_ADAPTER_ADDRESSES)
    adapter_name : Pointer(UInt8)
    first_unicast_address : Pointer(LibC::IP_ADAPTER_UNICAST_ADDRESS)
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

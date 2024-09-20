# Crystal IP Address List Library

[![Crystal CI](https://github.com/mamantoha/ip_address_list/actions/workflows/crystal.yml/badge.svg)](https://github.com/mamantoha/ip_address_list/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/mamantoha/ip_address_list.svg)](https://github.com/mamantoha/ip_address_list/releases)
[![License](https://img.shields.io/github/license/mamantoha/ip_address_list.svg)](https://github.com/mamantoha/ip_address_list/blob/master/LICENSE)

This library provides functionality to retrieve the IP addresses (both IPv4 and IPv6) associated with the network interfaces on a system. It is a port of Ruby's `ip_address_list` method from the `Socket` class.

## Features

- Retrieve both IPv4 and IPv6 addresses from network interfaces.
- Supports Windows, Linux, and macOS.
- Easy-to-use interface, returning a list of `Socket::IPAddress` objects.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ip_address_list:
       github: mamantoha/ip_address_list
   ```

2. Run `shards install`

## Usage

```crystal
require "ip_address_list"

p! Socket.ip_address_list
# => [Socket::IPAddress(127.0.0.1:0),
#     Socket::IPAddress(192.168.31.229:0),
#     Socket::IPAddress(172.17.0.1:0),
#     Socket::IPAddress([::1]:0),
#     Socket::IPAddress([fdcc:60fc:349d:2fcf:7e6:1635:e1a7:1fb6]:0),
#     Socket::IPAddress([fe80::c8e3:857d:43c8:cec3]:0)
#     ...]
```

## Technical Notes

### Windows Implementation

On Windows, this library uses the `GetAdaptersAddresses` function to retrieve network interface information, including IP addresses. You can find more information about `GetAdaptersAddresses` in the Microsoft [documentation](https://docs.microsoft.com/en-us/windows/win32/api/iphlpapi/nf-iphlpapi-getadaptersaddresses).

### Linux and macOS Implementation

On Linux and macOS, the library uses the `getifaddrs` function to gather network interface information. This function is part of the standard C library and provides a linked list of structures describing the network interfaces of the local system. More details about `getifaddrs` can be found in the [Linux man page](https://man7.org/linux/man-pages/man3/getifaddrs.3.html) and the [macOS documentation](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/getifaddrs.3.html).

## Contributing

1. Fork it (<https://github.com/mamantoha/ip_address_list/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer

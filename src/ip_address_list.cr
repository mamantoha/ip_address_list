require "socket"
require "lib_c"

{% if flag?(:linux) || flag?(:darwin) %}
  require "./ext/lib_c/ifaddrs"
{% end %}

{% if flag?(:win32) %}
  require "./ext/lib_c/get_adapters_addresses"
{% end %}

require "./ext/socket"
require "./ext/socket/address"

module IpAddressList
  VERSION = "0.1.0"

  def self.local_ip_address : Socket::IPAddress?
    Socket.ip_address_list.find do |ip_address|
      ip_address.family == Socket::Family::INET && ip_address.private? && !ip_address.address.starts_with?("127")
    end
  end
end

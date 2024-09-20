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

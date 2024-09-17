require "./ext"

module IpAddressList
  VERSION = "0.1.0"

  def self.local_ip_address : Socket::IPAddress?
    Socket.ip_address_list.find do |ip_address|
      ip_address.family == Socket::Family::INET && ip_address.private? && !ip_address.address.starts_with?("127")
    end
  end
end

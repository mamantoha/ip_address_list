require "./spec_helper"

describe "ip_address_list" do
  ip_address_list = Socket.ip_address_list

  it "works" do
    local_ip_address = ip_address_list.find do |ip_address|
      ip_address.family == Socket::Family::INET && ip_address.private? && !ip_address.address.starts_with?("127")
    end

    puts local_ip_address

    local_ip_address.should be_a(Socket::IPAddress)
  end
end

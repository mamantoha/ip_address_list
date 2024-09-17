require "./spec_helper"

describe IpAddressList do
  it "works" do
    local_ip_address = IpAddressList.local_ip_address
    p! local_ip_address
    local_ip_address.should be_a(Socket::IPAddress)
  end
end

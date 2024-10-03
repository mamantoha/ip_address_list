class Socket
  struct IPAddress
    def self.from(sockaddr : LibC::Sockaddr*) : IPAddress
      case family = Family.new(sockaddr.value.sa_family)
      when Family::INET6
        sockaddr = sockaddr.as(LibC::SockaddrIn6*)

        new(sockaddr, sizeof(typeof(sockaddr)))
      when Family::INET
        sockaddr = sockaddr.as(LibC::SockaddrIn*)

        new(sockaddr, sizeof(typeof(sockaddr)))
      else
        raise "Unsupported family type: #{family} (#{family.value})"
      end
    end

    def self.from?(sockaddr : LibC::Sockaddr*) : IPAddress?
      case Family.new(sockaddr.value.sa_family)
      when Family::INET6
        sockaddr = sockaddr.as(LibC::SockaddrIn6*)

        new(sockaddr, sizeof(typeof(sockaddr)))
      when Family::INET
        sockaddr = sockaddr.as(LibC::SockaddrIn*)

        new(sockaddr, sizeof(typeof(sockaddr)))
      else
        nil
      end
    end
  end
end

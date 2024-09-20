class Socket
  struct IPAddress
    def self.from(sockaddr : LibC::Sockaddr*) : IPAddress
      case family = Family.new(sockaddr.value.sa_family)
      when Family::INET
        sockaddr_in = sockaddr.as(LibC::SockaddrIn*)

        new(sockaddr_in, sizeof(typeof(sockaddr_in)))
      when Family::INET6
        sockaddr_in = sockaddr.as(LibC::SockaddrIn6*)

        new(sockaddr_in, sizeof(typeof(sockaddr_in)))
      else
        raise "Unsupported family type: #{family} (#{family.value})"
      end
    end

    def self.from?(sockaddr : LibC::Sockaddr*) : IPAddress?
      case family = Family.new(sockaddr.value.sa_family)
      when Family::INET
        sockaddr_in = sockaddr.as(LibC::SockaddrIn*)

        new(sockaddr_in, sizeof(typeof(sockaddr_in)))
      when Family::INET6
        sockaddr_in = sockaddr.as(LibC::SockaddrIn6*)

        new(sockaddr_in, sizeof(typeof(sockaddr_in)))
      end
    end
  end
end

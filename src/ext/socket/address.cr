class Socket
  struct IPAddress
    def self.from(sockaddr_in : LibC::SockaddrIn* | LibC::SockaddrIn6*, addrlen) : IPAddress
      new(sockaddr_in, addrlen.to_i)
    end
  end
end

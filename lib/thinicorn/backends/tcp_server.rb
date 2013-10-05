class Thinicorn
  class TcpServer < Thin::Backends::TcpServer
    include Backend

    case RUBY_PLATFORM
    when /linux/
      # from /usr/include/linux/tcp.h
      TCP_DEFER_ACCEPT = 9 unless defined?(TCP_DEFER_ACCEPT)

      # do not send out partial frames (Linux)
      TCP_CORK = 3 unless defined?(TCP_CORK)
    when /freebsd/
      # do not send out partial frames (FreeBSD)
      TCP_NOPUSH = 4 unless defined?(TCP_NOPUSH)

      def accf_arg(af_name)
        [ af_name, nil ].pack('a16a240')
      end if defined?(SO_ACCEPTFILTER)
    end

    def connection_class
      Thin::Connection
    end

    def create_socket
      set_tcp_sockopts(TCPServer.open(@host, @port))
    end

    def set_tcp_sockopts(sock)
      sock = set_sockopts(sock)

      # highly portable, but off by default because we don't do keepalive
      if defined?(TCP_NODELAY)
        sock.setsockopt(Socket::IPPROTO_TCP, TCP_NODELAY, 1)
      end

      if defined?(TCP_CORK) # Linux
        sock.setsockopt(Socket::IPPROTO_TCP, TCP_CORK, 0)
      elsif defined?(TCP_NOPUSH) # TCP_NOPUSH is untested (FreeBSD)
        sock.setsockopt(Socket::IPPROTO_TCP, TCP_NOPUSH, 0)
      end

      # No good reason to ever have deferred accepts off
      # (except maybe benchmarking)
      if defined?(TCP_DEFER_ACCEPT)
        # this differs from nginx, since nginx doesn't allow us to
        # configure the the timeout...
        sock.setsockopt(Socket::SOL_TCP, TCP_DEFER_ACCEPT, 1)
      elsif respond_to?(:accf_arg)
        sock.setsockopt(Socket::SOL_SOCKET, SO_ACCEPTFILTER, accf_arg('httpready'))
      end

      sock
    end
  end
end

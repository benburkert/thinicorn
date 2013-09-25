class Thinicorn
  module Backend
    include Thin::Logging

    SERVER_FD = 'THINICORN_SERVER_FD'

    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}

      super(*args)

      @fd    = ENV[SERVER_FD].to_i unless ENV[SERVER_FD].nil?
      @klass = connection_class

      @pid = opts[:pid]
      @log = opts[:log]

      redirect_io if @log
      daemonize   if Thinicorn.daemonize?

      write_pidfile

      trap(:USR2) { reexec }
    end

    def connect
      @fd = create_socket.fileno if @fd.nil?

      ENV[SERVER_FD] = @fd.to_s

      EventMachine.attach_server @fd, @klass, &method(:initialize_connection)

      @signature = EventMachine.instance_eval{@acceptors.keys.first}
    end

    def reexec
      log ">> SIGUSR2 received - starting graceful restart"

      @reexec_at = Time.now.to_i

      swap_pidfile if @pid

      POSIX::Spawn::spawn(Thinicorn.command)

      stop
    end

    def set_sockopts(sock)
      sock.close_on_exec = false
      sock.fcntl Fcntl::F_SETFD, sock.fcntl(Fcntl::F_GETFD) & ~Fcntl::FD_CLOEXEC
      sock.listen(1024)

      sock
    end

    def redirect_io
      [STDOUT, STDERR].each {|io| io.reopen(@log, 'a') ; io.sync = true }
    end

    def daemonize
      POSIX::Spawn::spawn(Thinicorn.command)

      exit 0
    end

    def write_pidfile
      File.open(@pid, 'wb') {|f| f.write($$) }
    end

    def swap_pidfile
      File.unlink(@pid)

      basename = @pid.chomp('.pid')
      path     = "#{basename}.#{@reexec_at}.oldbin"

      File.open(path, 'wb') {|f| f.write($$) }

      at_exit { File.unlink(path) }
    end

  end
end

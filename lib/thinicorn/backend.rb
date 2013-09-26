class Thinicorn
  module Backend
    include Thin::Logging

    SERVER_FD = 'THINICORN_SERVER_FD'
    PIPE_FD   = 'THINICORN_PIPE_FD'

    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}

      super(*args)

      @fd    = ENV[SERVER_FD].to_i unless ENV[SERVER_FD].nil?
      @pipe  = ENV[PIPE_FD].to_i   unless ENV[PIPE_FD].nil?

      @klass = connection_class
      @state = :starting

      @pid = opts[:pid]
      @log = opts[:log]

      redirect_io if @log
      daemonize   if Thinicorn.daemonize?

      write_pidfile

      trap(:USR2) { reexec }

      $0 = procline
    end

    def connect
      if @fd.nil?
        sock = create_socket
        @fd  = sock.fileno
      else
        sock = Socket.for_fd(@fd)
      end

      ENV[SERVER_FD] = @fd.to_s

      @signature = EventMachine.attach_server sock, @klass, &method(:initialize_connection)

      if @pipe
        io = IO.for_fd(@pipe)
        io.write_nonblock('+')
      end

      @state          = :running
      @procline_timer = EventMachine::PeriodicTimer.new(5) { $0 = procline }
    end

    def reexec
      log ">> SIGUSR2 received - starting graceful restart"

      @state = :spawning

      @reexec_at = Time.now.to_i

      pipe_r, pipe_w = create_pipe

      ENV[PIPE_FD] = pipe_w.fileno.to_s

      swap_pidfile if @pid

      @child_pid = POSIX::Spawn::spawn(Thinicorn.command)

      EventMachine.attach(pipe_r, WaitForChild) do |conn|
        conn.on_timeout(&method(:restart_failed))
        conn.on_readable(&method(:restart_succeded))
      end
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

    def create_pipe
      r, w = IO.pipe

      w.close_on_exec = false
      w.fcntl Fcntl::F_SETFD, w.fcntl(Fcntl::F_GETFD) & ~Fcntl::FD_CLOEXEC

      r.close_on_exec = true
      r.fcntl Fcntl::F_SETFD, r.fcntl(Fcntl::F_GETFD) & Fcntl::FD_CLOEXEC

      return r, w
    end

    def restart_succeded
      log ">> Child is up - finishing graceful restart"

      @state = :stopping

      stop
    end

    def restart_failed
      log ">> Child start timed out - aborting graceful restart"

      Process.kill(:KILL, @child_pid)

      @child_pid = nil

      @state = :running
    end

    def procline
      "thinicorn [%s] (%s): %5d conns" % [self, @state.to_s.upcase, @connections.size]
    end
  end

  class WaitForChild < EventMachine::Connection
    attr_accessor :state

    def on_timeout(timeout = 5, &block)
      @timeout_block = block
      EventMachine::Timer.new(timeout, &method(:timeout))
    end

    def on_readable(&block)
      @readable_block = block
    end

    def timeout
      @state ||= :timeout

      @timeout_block.call if @state == :timeout
    end

    def receive_data(*)
      @state ||= :readable

      @readable_block.call if @state == :readable
    end
  end

end

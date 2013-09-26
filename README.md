# Thinicorn

Unicorn's graceful restarts for Thin.

## Overview

Unicorn's graceful restart feature allows a webserver to reload the entire process
(with new code) without any downtime in accepting & processing requests. This is
accomplished by sharing a file descriptor between the parent and child process.
When the parent process recieves a USR2 signal, it saves the FD of the server
socket in an environment variable. That socket has been setup without the CLOEXEC
flag (`sock.close_on_exec = false`). The parent will then call fork followed by
exec which will create a child process with the FD available. When the child is
starting up it will check for the environment variable then reuse that FD. This
same pattern is implemented in Thinicorn.

## Usage

The server should be started with `thinicorn` executable instead of `thin`. This
will load the necessary handler. The flags are the same as `thin`.

    $ bin/thinicorn start --port 8080 --rackup config.ru --daemonize
    $ ps -p $(cat tmp/pids/thin.pid)
        PID TTY           TIME CMD
      12345 ttys001    0:00.34 thinicorn [0.0.0.0:8080] (RUNNING):     0 conns
    $ kill -USR2 $(cat tmp/pids/thin.pid)
    $ ps -p $(cat tmp/pids/thin.pid)
      12346 ttys001    0:00.34 thinicorn [0.0.0.0:8080] (RUNNING):     0 conns
    $ cat log/thin.log
      >> Thin web server (v1.5.1 codename Straight Razor)
      >> Maximum connections set to 1024
      >> Listening on 0.0.0.0:8080, CTRL+C to stop
      >> SIGUSR2 received - starting graceful restart
      >> Thin web server (v1.5.1 codename Straight Razor)
      >> Maximum connections set to 1024
      >> Listening on 0.0.0.0:8080, CTRL+C to stop
      >> Child is up - finishing graceful restart


## Caveats

This requires a patched version of `EventMachine` with the `attach_server` method:
https://github.com/eventmachine/eventmachine/pull/465

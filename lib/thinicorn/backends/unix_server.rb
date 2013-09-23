class Thinicorn
  class UnixServer < Thin::Backends::UnixServer
    include Backend
  end
end

Gem::Specification.new do |s|
  s.name        = "thinicorn"
  s.version     = '0.0.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Burkert"]
  s.email       = ["ben@benburkert.com"]
  s.homepage    = "http://github.com/benburkert/thinicorn"
  s.summary     = %q{Thin + Unicorn}
  s.description = %q{The power of Unicorn + the crazyness of Thin.}

  s.rubyforge_project = "thinicorn"

  s.executables   = %w( thinicorn )
  s.files         = Dir['lib/**/*.rb']
  s.bindir        = 'bin'
  s.require_paths = ["lib"]

  s.add_dependency 'thin'
  s.add_dependency 'posix-spawn'
end

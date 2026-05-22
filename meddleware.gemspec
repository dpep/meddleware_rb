require_relative 'lib/meddleware/version'

Gem::Specification.new do |s|
  s.name        = 'meddleware'
  s.version     = Meddleware::VERSION
  s.authors     = [ 'Daniel Pepper' ]
  s.summary     = 'A middleware framework to make meddling easy.'
  s.description = <<~DESC
    Lightweight, Rack-style middleware for any Ruby class.
    Lets callers wrap execution with before/after hooks —
    modifying arguments, intercepting results, or logging —
    without monkey patching. Supports declarative ordering via TSort.
  DESC
  s.homepage    = 'https://github.com/dpep/meddleware_rb'
  s.license     = 'MIT'
  s.files       = `git ls-files * ':!:spec'`.split("\n")

  s.required_ruby_version = '>= 3'

  s.add_development_dependency 'debug', '>= 1'
  s.add_development_dependency 'rspec', '>= 3.13'
  s.add_development_dependency 'simplecov', '>= 0.22'
end

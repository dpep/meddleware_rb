require_relative "lib/meddleware/version"
package = Meddleware

Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__).split(".")[0]
  s.version     = package.const_get 'VERSION'
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = 'A middleware framework to make meddling easy.'
  s.homepage    = "https://github.com/dpep/meddleware_rb"
  s.license     = 'MIT'
  s.files       = `git ls-files * ':!:spec'`.split("\n")

  s.required_ruby_version = '>= 3'

  s.add_development_dependency 'byebug', '>= 11'
  s.add_development_dependency 'rspec', '>= 3.13'
  s.add_development_dependency 'simplecov', '>= 0.22'
end

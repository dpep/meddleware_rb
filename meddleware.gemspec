package_name = File.basename(__FILE__).split(".")[0]
load Dir.glob("lib/**/version.rb")[0]

package = Meddleware


Gem::Specification.new do |s|
  s.name        = package_name
  s.version     = package.const_get 'VERSION'
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = 'A middleware framework to make meddling easy.'
  s.homepage    = "https://github.com/dpep/#{package_name}_rb"
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.7'

  s.files       = Dir[
    __FILE__,
    'lib/**/*',
    'CHANGELOG*',
    'LICENSE*',
    'README*',
  ]

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'codecov'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
end

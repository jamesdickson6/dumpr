$:.push File.expand_path("../lib", __FILE__)
require "dumper/version"

Gem::Specification.new do |s|

  s.name        = "dumper"
  s.version     = Dumper::Version.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Dickson"]
  s.email       = ["jdickson@bcap.com"]
  s.homepage    = "http://github.com/sixjameses/dumper"
  s.summary     = "Dump and load databases."
  s.description = "Dumper provides an easy way to dump and import databases."
  s.files       = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  s.licenses    = ['MIT']
  s.required_ruby_version = '>= 1.8.7'
  #s.add_dependency('highline')
end

$:.push File.expand_path("../lib", __FILE__)
require "dumpr/version"

Gem::Specification.new do |s|

  s.name        = "dumpr"
  s.version     = Dumpr::Version.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Dickson"]
  s.email       = ["jdickson@bcap.com"]
  s.homepage    = "http://github.com/jamesdickson6/dumpr"
  s.summary     = "Dump and import databases."
  s.description = "Dumpr provides an easy way to dump and import databases. Supported databases include MySQL and Postgres."
  s.files       = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  s.licenses    = ['MIT']
  s.required_ruby_version = '>= 2.2.1'
  #s.add_dependency('highline')
end

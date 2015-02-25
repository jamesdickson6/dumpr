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
  s.description = "Provides an easy way to dump, transfer and import databases."
  s.files         = `git ls-files`.split("\n").reject {|fn| fn =~ /\.gem$/ }
  #s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  s.licenses = ['MIT']

  #s.add_dependency('highline')
end

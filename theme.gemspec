# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'theme/version'

Gem::Specification.new do |spec|
  spec.name          = "theme"
  spec.version       = Theme::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.summary       = %q{theme}
  spec.description   = %q{theme}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "tilt"
  spec.add_dependency "nokogiri"
  spec.add_dependency "nokogiri-styles"
  spec.add_dependency "eventable"
  spec.add_dependency "mab", "~> 0.0.3"
  spec.add_dependency "hashr", ">= 0.0.22"
end

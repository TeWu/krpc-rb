# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "krpc"
  s.version       = "0.1.0"
  s.authors       = ["Tomasz Więch"]
  s.email         = ["tewu.dev@gmail.com"]
  
  s.summary       = "Client library for kRPC"
  s.homepage      = "https://github.com/TeWu/krpc-rb"
  s.license       = "GPL-3.0"
  
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "ruby_protobuf", "~> 0.4"
  s.add_runtime_dependency "colorize", "~> 0.7"
  
  s.add_development_dependency "bundler", "~> 1.10"
end


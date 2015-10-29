# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "krpc"
  s.version       = "0.2.0"
  s.authors       = ["Tomasz Więch"]
  s.email         = ["tewu.dev@gmail.com"]
  
  s.summary       = "Client library for kRPC"
  s.description   = "kRPC-rb is a Ruby client library for kRPC, a Kerbal Space Program mod that allows you to control KSP from external scripts running outside of the game."
  s.homepage      = "https://github.com/TeWu/krpc-rb"
  s.license       = "GPL-3.0"
  
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(doc|test|spec|features)/}) || f == ".gitignore" }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]
  s.rdoc_options << "--markup" << "markdown" <<
                    "--format" << "hanna" <<
                    "--title"  << "kRPC-rb API Docs" <<
                    "--main"   << "README.md"
  
  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency "ruby_protobuf", "~> 0.4"
  s.add_runtime_dependency "colorize", "~> 0.7"
  s.add_runtime_dependency "nokogiri", "~> 1.6"
  s.add_development_dependency 'bundler', '~> 1.7', '>= 1.7.0'
  s.add_development_dependency "pry", "~> 0.10"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "hanna-nouveau", "~> 0.4"
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'tty-prompt'
  spec.add_dependency 'optparse'
  spec.add_dependency 'parseconfig'
  spec.add_dependency 'ncupdater'
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors = ['Jonas Schwartz']
  spec.description = %q{Easy way to login to hosts}
  spec.email = ['josc@nodes.dk']
  spec.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.extra_rdoc_files = %w(readme.md)
  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.start_with?('test/') }
  spec.homepage = 'http://github.com/nodes-cloud/ncaws'
  spec.name = 'ncaws'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'
  spec.summary = spec.description
  spec.version = `cat ./.semver`
end

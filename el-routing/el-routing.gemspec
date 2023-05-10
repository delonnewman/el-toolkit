# frozen_string_literal: true

version = File.read(File.expand_path('../VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'el-routing'
  spec.version       = version
  spec.authors       = ['Delon Newman']
  spec.email         = ['contact@delonnewman.name']

  spec.summary       = 'Utilities for application routing'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/delonnewman/el-toolkit'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}#changelog"

  spec.files = Dir['README.md', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'el-core', version
  spec.add_dependency 'rack'
end

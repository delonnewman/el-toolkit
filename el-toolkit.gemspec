# frozen_string_literal: true

version = File.read(File.expand_path('VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'el-toolkit'
  spec.version       = version
  spec.authors       = ['Delon Newman']
  spec.email         = ['contact@delonnewman.name']

  spec.summary       = 'A Ruby Toolkit'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/delonnewman/el-toolkit'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}#changelog"

  spec.files = %w[README.md]

  spec.add_dependency 'rack'
end

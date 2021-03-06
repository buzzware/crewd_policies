# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crewd_policies/version'

Gem::Specification.new do |spec|
  spec.name          = "crewd_policies"
  spec.version       = CrewdPolicies::VERSION
  spec.authors       = ["Gary McGhee"]
  spec.email         = ["gary@buzzware.com.au"]

  spec.summary       = %q{A happy path for writing DRY Pundit policies}
  spec.description   = %q{CrewdPolicies enables conventional Pundit (https://github.com/elabs/pundit) policies to be written using an opinionated pattern based on declarative Create, Read, Execute (optional), Write and Destroy (CREWD) permissions for each resource. Conventional pundit create?, show?, update? and destroy? permissions are automatically derived from these, as well as permitted_attributes/strong parameters.}
  spec.homepage      = "https://github.com/buzzware/crewd_policies"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "pundit", '~> 1.1', '>= 1.1.0'
  spec.add_runtime_dependency "standard_exceptions", '~> 0.1.4', '>= 0.1.4.0'
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activerecord", "~> 4.2"
  spec.add_development_dependency "activesupport", "~> 4.2"
end

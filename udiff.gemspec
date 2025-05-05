# frozen_string_literal: true

require_relative "lib/udiff/version"

Gem::Specification.new do |spec|
  spec.name = "udiff"
  spec.version = Udiff::VERSION
  spec.authors = ["Cameron C. Dutro"]
  spec.email = ["camertron@gmail.com"]

  spec.summary = "Diffing and patching utilities for Ruby."
  spec.description = "Diffing and patching utilities for Ruby for parsing and applying git patches."
  spec.homepage = "https://github.com/camertron/udiff"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.3.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["lib/**/*.rb", "ext/**/*.{rs,toml,lock,rb}"]
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/udiff/extconf.rb"]
end

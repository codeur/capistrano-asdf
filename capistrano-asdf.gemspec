# frozen_string_literal: true

require_relative "lib/capistrano/asdf/version"

Gem::Specification.new do |spec|
  spec.name = "capistrano-asdf"
  spec.version = Capistrano::Asdf::VERSION
  spec.licenses = ["MIT"]
  spec.authors = ["Jean-Baptiste Poix", "Codeur"]
  spec.email = ["jbpoix@inosophia.com", "dev@codeur.com"]

  spec.summary = "ASDF integration for Capistrano"
  spec.description = "ASDF integration for Capistrano"
  spec.homepage = "https://github.com/codeur/capistrano-asdf"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://gems.codeur.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/codeur/capistrano-asdf/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", "~> 3.0"
  spec.add_dependency "sshkit", "~> 1.2"
end

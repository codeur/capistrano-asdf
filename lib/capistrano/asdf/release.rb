# frozen_string_literal: true

module Capistrano
  module Asdf
    # Since 0.16 asdf is a pre-compiled binary rather than a set of shell
    # scripts: every install and every update downloads a release archive.
    module Release
      DOWNLOAD_HOST = "https://github.com/asdf-vm/asdf/releases/download"

      # Ubuntu is the only supported target, so only the Linux builds that the
      # asdf releases carry are mapped, keyed by what `uname -m` answers.
      ARCHITECTURES = {
        "x86_64" => "amd64",
        "aarch64" => "arm64"
      }.freeze

      # The archive holds the single `asdf` executable, with no enclosing
      # directory, so it untars straight into a directory of the PATH.
      def self.download_url(version, machine)
        architecture = ARCHITECTURES.fetch(machine) do
          raise ArgumentError, "asdf publishes no Linux build for #{machine} hardware"
        end

        "#{DOWNLOAD_HOST}/v#{version}/asdf-v#{version}-linux-#{architecture}.tar.gz"
      end

      # `asdf version` answers `v0.20.0 (revision 150aaf0)`, so only the
      # version number is read out of it.
      def self.installed_version(output)
        output.to_s[/\d+\.\d+\.\d+/]
      end
    end
  end
end

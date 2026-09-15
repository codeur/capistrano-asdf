# frozen_string_literal: true

require "test_helper"

require "capistrano/asdf/release"

module Capistrano
  module Asdf
    class TestRelease < Minitest::Test
      def test_it_points_at_the_linux_build_of_the_host_hardware
        assert_equal "https://github.com/asdf-vm/asdf/releases/download/v0.20.0/asdf-v0.20.0-linux-amd64.tar.gz",
          Release.download_url("0.20.0", "x86_64")
        assert_equal "https://github.com/asdf-vm/asdf/releases/download/v0.20.0/asdf-v0.20.0-linux-arm64.tar.gz",
          Release.download_url("0.20.0", "aarch64")
      end

      def test_it_refuses_hardware_asdf_publishes_no_build_for
        error = assert_raises(ArgumentError) { Release.download_url("0.20.0", "riscv64") }

        assert_includes error.message, "riscv64"
      end

      def test_it_reads_the_version_number_out_of_the_asdf_output
        assert_equal "0.20.0", Release.installed_version("v0.20.0 (revision 150aaf0)\n")
        # What the 0.15 shell script the servers still run answers, so that an
        # update is detected whatever installed ASDF in the first place.
        assert_equal "0.15.0", Release.installed_version("v0.15.0-31e8c93\n")
      end

      def test_it_reads_no_version_out_of_a_failed_call
        assert_nil Release.installed_version("")
      end
    end
  end
end

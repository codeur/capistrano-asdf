# frozen_string_literal: true

require "test_helper"

require "capistrano/all"
require "sshkit"

# A Capfile mixes the DSL into the top-level object; the rake file under test
# reaches for `Capistrano::DSL.stages` as it loads, which relies on it.
include Capistrano::DSL # standard:disable Style/MixinUsage

module Capistrano
  # `asdf:map_bins` prepends the asdf shims to the PATH that SSHKit exports in
  # front of every remote command. SSHKit writes that environment inside double
  # quotes (`PATH="..."`), and a shell does not expand a tilde there, so the
  # PATH must be built from `$HOME` rather than from `~`.
  class TestMapBins < Minitest::Test
    include Capistrano::DSL

    def setup
      # `capistrano/all` turns Rake's trace on; keep it out of the test output.
      Rake.application.options.trace = false
      Rake::Task.clear
      Capistrano::Configuration.reset!
      SSHKit.config.default_env = {}
      # The rake file hooks itself onto this task as it loads.
      Rake::Task.define_task("deploy:updating")
      load File.expand_path("../../lib/capistrano/tasks/asdf.rake", __dir__)
      Rake::Task["load:defaults"].invoke
      # Keep the task away from its jemalloc branch, which opens an SSH connection.
      set :asdf_tools, %w[nodejs]
    end

    def teardown
      SSHKit.config.default_env = {}
    end

    def test_the_exported_path_holds_no_tilde
      Rake::Task["asdf:map_bins"].invoke

      assert_equal "$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH", exported_path
    end

    def test_it_keeps_a_path_already_set_by_the_application
      SSHKit.config.default_env = {path: "/opt/custom/bin:$PATH"}

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "$HOME/.asdf/shims:$HOME/.asdf/bin:/opt/custom/bin:$PATH", exported_path
    end

    def test_an_absolute_asdf_path_is_left_alone
      set :asdf_path, "/opt/asdf"

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "/opt/asdf/shims:/opt/asdf/bin:$PATH", exported_path
    end

    # What the shell actually receives, tilde expansion included.
    def exported_path
      command = SSHKit::Command.new(:node, "--version").to_command

      command[/PATH="([^"]*)"/, 1]
    end
  end
end

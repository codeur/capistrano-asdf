# frozen_string_literal: true

require "test_helper"

module Capistrano
  # `asdf:map_bins` prepends the asdf shims to the PATH that SSHKit exports in
  # front of every remote command. SSHKit writes that environment inside double
  # quotes (`PATH="..."`), and a shell does not expand a tilde there, so the
  # PATH must be built from `$HOME` rather than from `~`.
  class TestMapBins < Minitest::Test
    include AsdfTasks

    def setup
      # Without ruby, the task stays away from the Ruby build options, which
      # open an SSH connection.
      load_asdf_tasks(%w[nodejs])
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

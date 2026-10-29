# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "capistrano/asdf/version"

require "minitest/autorun"

require "capistrano/all"
require "sshkit"

# A Capfile mixes the DSL into the top-level object; the rake file under test
# reaches for `Capistrano::DSL.stages` as it loads, which relies on it.
include Capistrano::DSL # standard:disable Style/MixinUsage

module AsdfTasks
  include Capistrano::DSL

  # Loads the asdf tasks afresh, for an application whose asdf tools are
  # `tools`.
  def load_asdf_tasks(tools)
    # `capistrano/all` turns Rake's trace on; keep it out of the test output.
    Rake.application.options.trace = false
    Rake::Task.clear
    Capistrano::Configuration.reset!
    SSHKit.config.default_env = {}
    # The rake file hooks itself onto this task as it loads.
    Rake::Task.define_task("deploy:updating")
    load File.expand_path("../lib/capistrano/tasks/asdf.rake", __dir__)
    # Listing the tools keeps the defaults away from the .tool-versions
    # autodetection.
    set :asdf_tools, tools
    Rake::Task["load:defaults"].invoke
  end
end

# Stands for the SSH connection: records each remote command as the shell
# would receive it, and answers it from `replies`, a list of
# `[pattern, exit_status, stdout]` where the first matching pattern wins. Any
# other command succeeds without output.
class FakeBackend < SSHKit::Backend::Abstract
  class << self
    attr_accessor :commands, :replies
  end

  private

  def execute_command(cmd)
    command = cmd.to_command
    self.class.commands << command
    _, exit_status, stdout = self.class.replies.find { |pattern, *| pattern.match?(command) }
    cmd.on_stdout(nil, stdout.to_s)
    cmd.exit_status = exit_status || 0
  end
end

# frozen_string_literal: true

require "test_helper"

module Capistrano
  # Ruby builds YJIT only when it finds rustc at compile time. With rustc on the
  # server, `asdf:map_bins` asks for YJIT in the Ruby build options, and the
  # deploy builds again an installed Ruby that was compiled without it, which
  # `asdf install` alone would skip.
  class TestYjit < Minitest::Test
    include AsdfTasks

    RUSTC = /\Acommand -v rustc\z/
    JEMALLOC = /jemalloc\.h/
    YJIT_SUPPORT = /YJIT_SUPPORT/
    RUBY_PREFIX = "/home/deploy/.asdf/installs/ruby/4.0.6"

    def setup
      load_asdf_tasks(%w[ruby])
      server "app.example.com", roles: %w[app]
      set :deploy_to, "/var/www/app"
      @backend = SSHKit.config.backend
      SSHKit.config.backend = FakeBackend
      FakeBackend.commands = []
      FakeBackend.replies = [[JEMALLOC, 1], [RUSTC, 1]]
    end

    def teardown
      SSHKit.config.backend = @backend
      SSHKit.config.default_env = {}
    end

    def test_rustc_on_the_server_asks_ruby_for_yjit
      reply RUSTC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "--enable-yjit", ruby_configure_opts
    end

    def test_jemalloc_is_kept_beside_yjit
      reply RUSTC, 0
      reply JEMALLOC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "--with-jemalloc=/usr/include/jemalloc --enable-yjit", ruby_configure_opts
    end

    def test_without_rustc_ruby_is_built_as_before
      reply JEMALLOC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "--with-jemalloc=/usr/include/jemalloc", ruby_configure_opts
    end

    def test_the_application_can_turn_yjit_off
      set :asdf_ruby_use_yjit, false
      reply RUSTC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_equal "--disable-yjit", ruby_configure_opts
    end

    def test_the_application_can_still_turn_jemalloc_off
      set :asdf_ruby_use_jemalloc, false
      reply JEMALLOC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_nil ruby_configure_opts
    end

    def test_an_application_without_ruby_gets_no_ruby_build_options
      set :asdf_tools, %w[nodejs]
      reply RUSTC, 0
      reply JEMALLOC, 0

      Rake::Task["asdf:map_bins"].invoke

      assert_nil ruby_configure_opts
    end

    def test_the_deploy_builds_again_a_ruby_without_yjit
      reply RUSTC, 0
      reply YJIT_SUPPORT, 0, RUBY_PREFIX

      deploy

      assert_equal 1, ruby_builds.size
      build = ruby_builds.first
      assert build.start_with?("cd /var/www/app/current && ")
      assert_includes build, 'ASDF_INSTALL_TYPE="version"'
      assert_includes build, 'ASDF_INSTALL_VERSION="4.0.6"'
      assert_includes build, %(ASDF_INSTALL_PATH="#{RUBY_PREFIX}")
      assert_includes build, 'RUBY_CONFIGURE_OPTS="--enable-yjit"'
    end

    def test_the_deploy_leaves_a_ruby_with_yjit_alone
      reply RUSTC, 0
      reply YJIT_SUPPORT, 0, ""

      deploy

      assert_empty ruby_builds
    end

    def test_without_rustc_the_deploy_builds_nothing_again
      reply YJIT_SUPPORT, 0, RUBY_PREFIX

      deploy

      assert_empty FakeBackend.commands.grep(YJIT_SUPPORT)
      assert_empty ruby_builds
    end

    private

    def reply(pattern, exit_status, stdout = "")
      FakeBackend.replies.unshift([pattern, exit_status, stdout])
    end

    # `asdf:map_bins` runs as the stage loads, before the deploy installs the
    # tools.
    def deploy
      Rake::Task["asdf:map_bins"].invoke
      Rake::Task["asdf:install"].invoke
    end

    def ruby_configure_opts
      SSHKit.config.default_env[:ruby_configure_opts]
    end

    def ruby_builds
      FakeBackend.commands.grep(%r{/plugins/ruby/bin/install})
    end
  end
end

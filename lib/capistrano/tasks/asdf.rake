# frozen_string_literal: true

namespace :asdf do
  desc "Install ASDF tools on deploy"
  task :deploy do
    on roles(fetch(:asdf_roles)) do
      invoke "asdf:check"
      invoke "asdf:install"
    end
  end

  desc "Prints the ASDF tools versions on the target host"
  task :check do
    on roles(fetch(:asdf_roles)) do
      within(release_path) do
        execute(:asdf, "current")
      end
    end
  end

  desc "Install ASDF tools versions based on the .tool-versions of your project"
  task :install do
    on roles(fetch(:asdf_roles)) do
      within(release_path) do
        execute(:asdf, "update")
        execute(:asdf, "install")

        already_installed_plugins = capture(:asdf, "plugin", "list")&.split
        fetch(:asdf_tools)&.each do |tool|
          if already_installed_plugins.include?(tool)
            execute(:asdf, "plugin", "update", tool)
          else
            execute(:asdf, "plugin", "add", tool)
          end
        end
      end
    end
  end

  desc "Uninstall ASDF versions based on the .tool-versions of your project"
  task :uninstall do
    on roles(fetch(:asdf_roles)) do
      within(release_path) do
        fetch(:asdf_tools)&.each do |tool|
          execute(:asdf, "uninstall", tool)
        end
      end
    end
  end

  namespace :uninstall do
    desc "Uninstall ASDF Ruby version based on the .tool-versions of your project"
    task :ruby do
      on roles(fetch(:asdf_roles)) do
        within(release_path) do
          execute(:asdf, "uninstall", "ruby")
        end
      end
    end

    desc "Uninstall ASDF NodeJS version based on the .tool-versions of your project"
    task :nodejs do
      on roles(fetch(:asdf_roles)) do
        within(release_path) do
          execute(:asdf, "uninstall", "nodejs")
        end
      end
    end
  end

  task :map_bins do
    path = "#{fetch(:asdf_path)}/shims:#{fetch(:asdf_path)}/bin:" + (SSHKit.config.default_env[:path] || "$PATH")
    SSHKit.config.default_env[:path] = path

    asdf_prefix = fetch(:asdf_prefix, -> { "#{fetch(:asdf_path)}/bin/asdf exec" })
    SSHKit.config.command_map[:asdf] = "#{fetch(:asdf_path)}/bin/asdf"

    if fetch(:asdf_tools).include?("ruby")
      if fetch(:asdf_ruby_use_jemalloc)
        on roles(fetch(:asdf_roles)) do
          if test("[ -f #{fetch(:asdf_jemalloc_path)}/jemalloc.h ]")
            SSHKit.config.default_env.merge!(ruby_configure_opts: "--with-jemalloc=#{fetch(:asdf_jemalloc_path)}")
          end
        end
      end

      fetch(:asdf_map_ruby_bins).uniq.each do |command|
        SSHKit.config.command_map.prefix[command.to_sym].unshift(asdf_prefix)
      end
    end

    if fetch(:asdf_tools).include?("nodejs")
      fetch(:asdf_map_nodejs_bins).uniq.each do |command|
        SSHKit.config.command_map.prefix[command.to_sym].unshift(asdf_prefix)
      end
    end
  end
end

after "deploy:updating", "asdf:deploy"

Capistrano::DSL.stages.each do |stage|
  after stage, "asdf:map_bins"
end

namespace :load do
  task :defaults do
    set :asdf_path, fetch(:asdf_custom_path, "~/.asdf")
    set :asdf_roles, fetch(:asdf_roles, :all)
    set :asdf_ruby_use_jemalloc, fetch(:asdf_ruby_use_jemalloc, true)
    set :asdf_jemalloc_path, fetch(:asdf_jemalloc_path, "/usr/include/jemalloc")
    set :asdf_tools, fetch(:asdf_tools, %w[ruby nodejs])
    set :asdf_map_ruby_bins, fetch(:asdf_map_ruby_bins, %w[rake gem bundle ruby rails])
    set :asdf_map_nodejs_bins, fetch(:asdf_map_nodejs_bins, %w[node npm yarn])
  end
end

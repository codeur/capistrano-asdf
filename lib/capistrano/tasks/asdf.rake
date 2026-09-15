# frozen_string_literal: true

require_relative "../asdf/release"

namespace :asdf do
  desc "Install ASDF tools on deploy"
  task :deploy do
    on roles(fetch(:asdf_roles)) do
      invoke "asdf:setup"
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

  desc "Install ASDF, or update it to :asdf_version, on the target host"
  task :setup do
    next unless fetch(:asdf_setup)

    version = fetch(:asdf_version)
    on roles(fetch(:asdf_roles)) do
      bin_path = "#{fetch(:asdf_path)}/bin"
      installed = if test("[ -x #{bin_path}/asdf ]")
        Capistrano::Asdf::Release.installed_version(capture(:asdf, "version", raise_on_non_zero_exit: false))
      end

      if installed == version
        info "ASDF #{version} is already installed on #{fetch(:asdf_path)}"
        next
      end

      url = Capistrano::Asdf::Release.download_url(version, capture(:uname, "-m"))
      execute :mkdir, "-p", bin_path
      # `asdf update` refuses to upgrade the binary it ships as, so the release
      # archive is downloaded over the installed one.
      execute "curl -fsSL #{url} | tar -xzf - -C #{bin_path} asdf"

      if installed
        info "ASDF is updated from #{installed} to #{version} (on #{fetch(:asdf_path)})"
      else
        info "ASDF #{version} is installed on #{fetch(:asdf_path)}"
      end
    end
  end

  desc "Install ASDF tools versions based on the .tool-versions of your project"
  task :install do
    on roles(fetch(:asdf_roles)) do
      within(release_path) do
        already_installed_plugins = capture(:asdf, "plugin", "list")&.split
        fetch(:asdf_tools)&.each do |tool|
          if already_installed_plugins.include?(tool)
            execute(:asdf, "plugin", "update", tool)
          else
            execute(:asdf, "plugin", "add", tool)
          end
        end
        execute(:asdf, "install")
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
    %i[ruby nodejs].each do |tool|
      desc "Uninstall ASDF #{tool} version based on the .tool-versions of your project"
      task tool do
        on roles(fetch(:asdf_roles)) do
          within(release_path) do
            execute(:asdf, "uninstall", tool.to_s)
          end
        end
      end
    end
  end

  task :map_bins do
    # SSHKit exports the environment inside double quotes (PATH="..."), where a
    # shell leaves a tilde alone, so the PATH has to carry $HOME instead.
    asdf_home = fetch(:asdf_path).sub(%r{\A~(?=/|\z)}, "$HOME")
    path = "#{asdf_home}/shims:#{asdf_home}/bin:" + (SSHKit.config.default_env[:path] || "$PATH")
    SSHKit.config.default_env[:path] = path
    # Since 0.16 the asdf binary no longer derives its data directory from its
    # own location, so a custom :asdf_path has to be handed over explicitly.
    SSHKit.config.default_env[:asdf_data_dir] = asdf_home

    asdf_prefix = fetch(:asdf_prefix, -> { "#{fetch(:asdf_path)}/bin/asdf exec" })
    SSHKit.config.command_map[:asdf] = "#{fetch(:asdf_path)}/bin/asdf"

    if fetch(:asdf_tools).include?("ruby") && fetch(:asdf_ruby_use_jemalloc)
      on roles(fetch(:asdf_roles)) do
        if test("[ -f #{fetch(:asdf_jemalloc_path)}/jemalloc.h ]")
          SSHKit.config.default_env.merge!(ruby_configure_opts: "--with-jemalloc=#{fetch(:asdf_jemalloc_path)}")
        end
      end
    end

    fetch(:asdf_tools).each do |tool|
      fetch(:"asdf_map_#{tool}_bins", []).uniq.each do |command|
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
    set :asdf_path, fetch(:asdf_path, "~/.asdf")
    set :asdf_version, fetch(:asdf_version, "0.20.0")
    set :asdf_setup, fetch(:asdf_setup, true)
    set :asdf_roles, fetch(:asdf_roles, :all)
    set :asdf_ruby_use_jemalloc, fetch(:asdf_ruby_use_jemalloc, true)
    set :asdf_jemalloc_path, fetch(:asdf_jemalloc_path, "/usr/include/jemalloc")
    # Autodetected from the project .tool-versions, but only when the
    # application has not listed its tools itself: a passed default is always
    # evaluated, and reading a missing file would raise.
    set :asdf_tools, fetch(:asdf_tools) { File.read(".tool-versions").lines.map(&:split).to_h.keys }
    set :asdf_map_ruby_bins, fetch(:asdf_map_ruby_bins, %w[rake gem bundle ruby rails])
    set :asdf_map_nodejs_bins, fetch(:asdf_map_nodejs_bins, %w[node npm yarn])
    set :asdf_map_python_bins, fetch(:asdf_map_python_bins, %w[python pip])
  end
end

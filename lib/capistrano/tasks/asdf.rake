# frozen_string_literal: true

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

  desc "Setup ASDF on the target host"
  task :setup do
    if fetch(:asdf_setup)
      on roles(fetch(:asdf_roles)) do
        if test("[ -d #{fetch(:asdf_path)} ]")
          within(fetch(:asdf_path)) do
            version = capture(:cat, "version.txt").strip
            if fetch(:asdf_version) == version
              info "ASDF #{fetch(:asdf_version)} is already installed on #{fetch(:asdf_path)}"
            else
              execute :git, "fetch", "origin"
              execute :git, "checkout", "v#{fetch(:asdf_version)}"
              info "ASDF is updated from #{version} to #{fetch(:asdf_version)} (on #{fetch(:asdf_path)})"
            end
          end
        else
          execute :git, "clone", fetch(:asdf_repository), fetch(:asdf_path)
          within(fetch(:asdf_path)) do
            execute :git, "checkout", "v#{fetch(:asdf_version)}"
            execute :echo, fetch(:asdf_version), ">", "version.txt"
          end
          info "ASDF #{fetch(:asdf_version)} is installed on #{fetch(:asdf_path)}"
        end
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

        # `asdf install` skips a version that is already there, so a Ruby built
        # before rustc was around would never get YJIT: build it again in its
        # own directory. ruby-build compiles in a temporary directory and only
        # then replaces the files, so this Ruby keeps working meanwhile.
        if SSHKit.config.default_env[:ruby_configure_opts]&.include?("--enable-yjit")
          ruby_without_yjit = capture(:asdf, "exec", "ruby", "-e", "'print RbConfig::CONFIG[%q(prefix)] if RbConfig::CONFIG[%q(YJIT_SUPPORT)] == %q(no)'")
          unless ruby_without_yjit.empty?
            with(asdf_install_type: "version", asdf_install_version: File.basename(ruby_without_yjit), asdf_install_path: ruby_without_yjit) do
              execute("#{fetch(:asdf_path)}/plugins/ruby/bin/install")
            end
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

    asdf_prefix = fetch(:asdf_prefix, -> { "#{fetch(:asdf_path)}/bin/asdf exec" })
    SSHKit.config.command_map[:asdf] = "#{fetch(:asdf_path)}/bin/asdf"

    if fetch(:asdf_tools).include?("ruby")
      on roles(fetch(:asdf_roles)) do
        ruby_configure_opts = []
        if fetch(:asdf_ruby_use_jemalloc) && test("[ -f #{fetch(:asdf_jemalloc_path)}/jemalloc.h ]")
          ruby_configure_opts << "--with-jemalloc=#{fetch(:asdf_jemalloc_path)}"
        end
        # Ruby builds YJIT by itself whenever it finds rustc, hence the explicit
        # opt-out. Asking for it turns a rustc unable to build it into a failed
        # install instead of a Ruby silently built without YJIT.
        if !fetch(:asdf_ruby_use_yjit)
          ruby_configure_opts << "--disable-yjit"
        elsif test("command -v rustc")
          ruby_configure_opts << "--enable-yjit"
        end
        SSHKit.config.default_env.merge!(ruby_configure_opts: ruby_configure_opts.join(" ")) if ruby_configure_opts.any?
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
    set :asdf_repository, fetch(:asdf_repository, "https://github.com/asdf-vm/asdf.git")
    set :asdf_version, fetch(:asdf_version, "0.15.0")
    set :asdf_setup, fetch(:asdf_setup, true)
    set :asdf_roles, fetch(:asdf_roles, :all)
    set :asdf_ruby_use_jemalloc, fetch(:asdf_ruby_use_jemalloc, true)
    set :asdf_jemalloc_path, fetch(:asdf_jemalloc_path, "/usr/include/jemalloc")
    set :asdf_ruby_use_yjit, fetch(:asdf_ruby_use_yjit, true)
    # Autodetected from the project .tool-versions, but only when the
    # application has not listed its tools itself: a passed default is always
    # evaluated, and reading a missing file would raise.
    set :asdf_tools, fetch(:asdf_tools) { File.read(".tool-versions").lines.map(&:split).to_h.keys }
    set :asdf_map_ruby_bins, fetch(:asdf_map_ruby_bins, %w[rake gem bundle ruby rails])
    set :asdf_map_nodejs_bins, fetch(:asdf_map_nodejs_bins, %w[node npm yarn])
    set :asdf_map_python_bins, fetch(:asdf_map_python_bins, %w[python pip])
  end
end

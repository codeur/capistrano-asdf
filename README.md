# Capistrano::ASDF

ASDF support for Capistrano v3:

## Notes

**If you use this integration with capistrano-rails, please ensure that you have `capistrano-bundler >= 1.1.0`.**

## Installation

Add this line to your application's Gemfile:

    # Gemfile
    gem 'capistrano', '~> 3.0'
    gem 'capistrano-asdf'

And then execute:

    $ bundle install

## Usage

Require in Capfile to use the default task:

    # Capfile
    require 'capistrano/asdf'

And you should be good to go!

## Configuration

Everything *should work* for a basic ASDF setup *out of the box*.
However we strongly encourage you to use the `.tool-versions` for proper tool version selection.

If you need some special settings, set those in the stage file for your server:

    # deploy.rb or stage file (staging.rb, production.rb or else)
    set :asdf_version, '0.20.0'                     # defaults to '0.20.0'
    set :asdf_setup, false                          # defaults to true
    set :asdf_path, '~/.my_asdf_installation_path'  # only needed if not '~/.asdf'
    set :asdf_tools, %w{ ruby }                            # defaults to %{ ruby nodejs }
    set :asdf_map_ruby_bins, %w{ bundle gem }              # defaults to %w{ rake gem bundle ruby rails }
    set :asdf_map_nodejs_bins, %w{ node npm }              # defaults to %w{ node npm yarn }

### ASDF version: `:asdf_version`

The deploy installs ASDF itself, and keeps it at the requested version. On every
deploy, `asdf:setup` compares `asdf version` on the target host with
`:asdf_version` and, when they differ, downloads the pre-compiled binary of that
release into `#{fetch(:asdf_path)}/bin`.

Set `:asdf_setup` to `false` if you would rather install and update ASDF
yourself.

### Custom ASDF path: `:asdf_path`

If you have a custom ASDF setup with a different path then expected, you have
to define a custom ASDF path to tell capistrano where it is.

### Custom ASDF tools selection: `:asdf_tools`

If you don't want to use all the tools available (`ruby` and `nodejs`), you have
to define which one you want to use.

For example; if you just want to use ASDF for ruby, you may set `:asdf_tools`:

    set :asdf_tools, %w{ ruby }

### Custom ASDF ruby binaries selection: `:asdf_map_ruby_bins`

If you want to add or remove which ruby related binaries will be mapped to ASDF ruby installation, you have
to define which one you want to be mapped.

For example; if you just want to map `bundle` and `gem` ruby binaries, you may set `:asdf_map_ruby_bins`:

    set :asdf_map_ruby_bins, %w{ bundle gem }

### Custom ASDF nodejs binaries selection: `:asdf_map_nodejs_bins`

If you want to add or remove which nodejs related binaries will be mapped to ASDF nodejs installation, you have
to define which one you want to be mapped.

For example; if you just want to map `node` and `npm` nodejs binaries, you may set `:asdf_map_nodejs_bins`:

    set :asdf_map_nodejs_bins, %w{ node npm }

## Restrictions

ASDF is installed from the pre-compiled Linux binary of its GitHub release, so
the target hosts have to run Linux. Ubuntu is the only distribution this is used
on, and `uname -m` has to answer `x86_64` or `aarch64`.

## How it works

This gem adds new tasks `asdf:map_*` before `deploy` task.
It loads the ASDF tools environment for capistrano when it wants to run
some tools related programs like `rake`, `gem`, `bundle`, `node`, `npm` ...

## Generate and upload the ASDF commands wrapper

The ASDF wrapper is needed to correctly run the mapped commands.
Since the wrapper is an executable script, it can be used in Systemd units.

    $ cap production asdf:upload_wrapper

This task is automaticaly called before `asdf:check`

## Install required tools

If you want your tools (ruby, nodejs) to be installed, you can use the `asdf:install` task to
preform plugins add and then install of required versions from your `.tool-versions`.
`asdf:install` will automaticaly add necessary plugins running `asdf:add_plugins`.
If you want to change the plugins to install you may set `:asdf_tools` accordingly.

    $ cap production asdf:install

## Check your configuration

If you want to check your configuration you can use the `asdf:check` task to
get information about the ASDF version and ruby/nodejs tools which would be used for
deployment.

    $ cap production asdf:check

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

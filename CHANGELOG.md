# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-09-15

### Changed

- `asdf_version` now defaults to `0.20.0`, and `asdf:setup` installs it the way
  asdf is distributed since 0.16: the pre-compiled Linux binary of the release
  is downloaded into `#{asdf_path}/bin`, instead of the repository being cloned
  and a tag checked out. The architecture comes from `uname -m` on the target
  host, so only Linux (Ubuntu) targets are supported.
- `asdf:setup` reads the installed version from `asdf version` rather than from
  the `version.txt` it used to write, so an update is detected whatever
  installed asdf in the first place. The stale `version.txt` and the leftover
  0.15 git clone in `#{asdf_path}` can be deleted by hand.
- `asdf:map_bins` exports `ASDF_DATA_DIR`. The asdf binary no longer derives
  its data directory from its own location, so a custom `asdf_path` needs it to
  keep holding the plugins, the installs and the shims.

### Removed

- `asdf_repository` variable, which nothing downloads from any more.

## [1.5.5] - 2026-09-15

### Fixed

- `asdf:map_bins` now builds the `PATH` from `$HOME` instead of a tilde. SSHKit
  exports the environment inside double quotes (`PATH="..."`), where a shell
  never expands a tilde, so the default `asdf_path` of `~/.asdf` produced two
  dead entries and left the asdf shims unreachable. An absolute `asdf_path` is
  still used as is.

## [1.5.4] - 2025-08-22

### Added

- `asdf_map_python_bins` variable, defaulting to `%w[python pip]`.

### Changed

- `asdf_tools` now defaults to the tools listed in the project `.tool-versions`
  instead of the hardcoded `%w[ruby nodejs]`.

### Fixed

- `asdf:setup` installs asdf by cloning the repository then checking out the
  requested tag and writing `version.txt`, which the previous single `git clone
  --branch` call did not produce.

## [1.5.3] - 2025-01-06

### Fixed

- ASDF update when git data is not up-to-date.

## [1.5.2] - 2024-12-24

### Fixed

- The `asdf_version` variable is now really taken into account.

## [1.5.1] - 2024-12-23

### Removed

- ASDF self-update, which has been removed upstream. See
  [asdf-vm/asdf#1806](https://github.com/asdf-vm/asdf/pull/1806).

## [1.5.0] - 2024-10-18

### Added

- `asdf:setup` task, which installs ASDF on `asdf_path` if not already
  installed by cloning the ASDF repository. See
  [ASDF installation](https://asdf-vm.com/guide/getting-started.html).

## [1.4.2] - 2024-10-14

### Fixed

- Plugin installation when no plugin is installed yet.

## [1.4.1] - 2024-09-26

### Fixed

- Task loading.

## [1.4.0] - 2024-09-26

### Added

- `asdf:uninstall:ruby` and `asdf:uninstall:nodejs` tasks, which uninstall the
  current Ruby and NodeJS versions.

### Changed

- `jemalloc` is now optional for Ruby, through the `asdf_ruby_use_jemalloc`
  variable.

## [1.3.0] - 2024-09-17

### Changed

- Commands now run through `asdf exec`.

### Removed

- The `asdf-wrapper` script, the `asdf:upload_wrapper` task and the
  `:asdf_custom_wrapper_path` variable.

## [1.2.0] - 2024-09-16

### Added

- `jemalloc` support for Ruby.

## [1.1.2] - 2024-02-20

### Added

- `asdf:deploy` task, run after `deploy:updating`.

### Changed

- ASDF tasks now run from the release path, so the `.tool-versions` of the
  deployed project is the one being used.

## [1.1.1] - 2024-01-12

### Fixed

- Indentation and typo in the ASDF wrapper template.

## [1.1.0] - 2023-10-31

### Added

- An ASDF wrapper, uploaded and used to fully load the ASDF environment before
  executing commands. It is generated in `<shared_path>/asdf-wrapper` by
  default, or elsewhere through the `:asdf_custom_wrapper_path` Capistrano
  variable.

## [1.0.0] - 2021-04-01

### Added

- `asdf:install` and `asdf:add_plugins` tasks.

## [0.0.3] - 2018-12-05

### Added

- Configuration options:

      set :asdf_path, '~/.my_asdf_installation_path'  # only needed if not '~/.asdf'
      set :asdf_tools, %w{ ruby }                     # defaults to %w{ ruby nodejs }
      set :asdf_map_ruby_bins, %w{ bundle gem }       # defaults to %w{ rake gem bundle ruby rails }
      set :asdf_map_nodejs_bins, %w{ node npm }       # defaults to %w{ node npm yarn }

## [0.0.2] - 2018-12-04

### Added

- Basic working tasks.

[1.5.5]: https://github.com/codeur/capistrano-asdf/compare/v1.5.4...v1.5.5
[1.5.4]: https://github.com/codeur/capistrano-asdf/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/codeur/capistrano-asdf/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/codeur/capistrano-asdf/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/codeur/capistrano-asdf/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/codeur/capistrano-asdf/compare/v1.4.2...v1.5.0
[1.4.2]: https://github.com/codeur/capistrano-asdf/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/codeur/capistrano-asdf/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/codeur/capistrano-asdf/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/codeur/capistrano-asdf/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/codeur/capistrano-asdf/compare/24ec10e...v1.2.0
[1.1.2]: https://github.com/codeur/capistrano-asdf/compare/92966ea...24ec10e
[1.1.1]: https://github.com/codeur/capistrano-asdf/compare/dee171a...92966ea
[1.1.0]: https://github.com/codeur/capistrano-asdf/compare/a099a63...dee171a
[1.0.0]: https://github.com/codeur/capistrano-asdf/compare/c874583...a099a63
[0.0.3]: https://github.com/codeur/capistrano-asdf/compare/4993915...c874583
[0.0.2]: https://github.com/codeur/capistrano-asdf/commits/4993915

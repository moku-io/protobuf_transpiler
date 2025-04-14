# Changelog

<!--[//]: # (
## <Release number> <Date YYYY-MM-DD>
### Breaking changes
### Deprecations
### New features
### Bug fixes
)-->

## 1.2.3 2025-04-14
### Bug fixes
- Fixed service annotations

## 1.2.2 2025-04-10
### Bug fixes
- exception from 1.2.1 version was not caught correctly

## 1.2.1 2025-04-10
### Bug fixes
- fixed NoMethodError that would happen when the module in which the stubs contained constants beyond the ones defined by the stubs

## 1.2.0 2025-04-10
### New features
- generate task can create an initializer that allows the generated stubs to work with zeitwerk
- added possibility to specify stubs path for generate task
- added possibility to specify stubs path for annotate task

## 1.1.3 2025-02-28
### Bug fixes
- remove rails versions constraints, keep only dependency

## 1.1.2 2023-11-20
### Bug fixes
- provide compatibility to ruby < 3.1

## 1.1.1 2023-11-13
### Bug fixes
- require google-protobuf where its monkey patch is made

## 1.1.0 2023-08-21
### New features
- Add annotation support for:
  - streams
  - oneofs
  - maps
  - nested messages
### Bug fixes
- Annotate task now correctly replaces existing annotations

## 1.0.0 2023-07-24

First release. Refer to [README.md](README.md) for the full documentation.

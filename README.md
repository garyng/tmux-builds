# tmux builds

> **This fork** builds tmux from [garyng/tmux](https://github.com/garyng/tmux), where each tmux release gets a branch (`3.7c-kitty`) carrying this fork's fixes as commits, until tmux ships them: reading a kitty keyboard protocol key that has no modifier field (a plain Escape is `CSI 27 u`); sending Ctrl+Backspace as `^H` to a program that hasn't asked for extended keys (tmux dropped it); waiting up to 500 ms for the rest of a mouse report that arrives in two parts, as one over ssh sometimes does (`escape-time` gave up first and typed the rest into the pane); and discarding a device attributes answer the terminal sends twice while tmux's own queries are open, as Windows Terminal over ssh sometimes does (tmux typed the second into the pane). A release tag here, `v<tmux version>-<name>.<n>` such as `v3.7c-kitty.5`, builds garyng/tmux's tag of the same name without the `v`, so a release is a tag in both; a change here alone, such as a build flag, tags garyng/tmux's same commit again. A new tmux release: rebase the branch onto it (`3.8-kitty`), then tag both. tmux is also configured with `--enable-sixel`, which upstream's builds leave out: without it, tmux drops a pane's Sixel images silently. Up to `v3.7c-kitty.4`, the fixes were files in `patches/`, applied to tmux's release tarball.

This repository provides ready to use binaries of the [tmux](https://github.com/tmux/tmux/) terminal multiplexer.

## Available Releases

All releases are available in the [releases](https://github.com/tmux/tmux-builds/releases) section.  

Supported platforms:
- Linux x86_64
- Linux arm64
- macOS x86_64
- macOS arm64 (Apple Silicon)

> **Note:** The macOS binaries are not fully static due to system library dependencies.  
> No external dependencies beyond a standard macOS installation are required.

Two types of builds are provided:

- **Release builds:** Stable versions of tmux (e.g. v3.6a).  
- **Preview builds:** Built from the latest `master` commit; may include experimental features or unstable changes.

## Installation

1. Go to the [releases](https://github.com/tmux/tmux-builds/releases) page.  
2. Download the archive for your platform.  
3. Extract the archive with:
 
   ```bash
   tar -xzf tmux-<version>-<platform>.tar.gz
   ```

4. Move the binary to a directory in your `PATH`, e.g.:

   ```bash
   sudo mv tmux /usr/local/bin
   ```

## Local Build Instructions

### Via Docker (Linux only)

Adjust dependency versions in `versions.env` if needed.  

Set the tmux version and the garyng/tmux tag to build (both without the `v` prefix) via build arguments or environment variables.  
To build upstream's latest `master` commit, set `TMUX_VERSION=preview`.

```bash
docker compose build --build-arg TMUX_VERSION=3.7c --build-arg TMUX_REF=3.7c-kitty.5
# or
TMUX_VERSION=3.7c TMUX_REF=3.7c-kitty.5 docker compose build
```

To build a tmux tree on disk instead, such as an unpushed branch of a garyng/tmux clone, hand it to the build as the `tmux-src` context, and say so with `TMUX_SRC` (the context alone isn't enough: see the Dockerfile):

```bash
docker build --build-context tmux-src=../tmux --build-arg TMUX_SRC=/tmux-src --build-arg TMUX_VERSION=3.7c \
    --build-arg MUSL_VERSION=1.2.5 --build-arg LIBEVENT_VERSION=2.1.12 --build-arg NCURSES_VERSION=6.5 \
    --build-arg PREFIX=/build -t tmux-builder .
```

Extract the binary:

```bash
docker compose create tmux-builder
docker cp tmux-builder:/artifacts ./artifacts
docker compose rm tmux-builder
```

### Via Build Scripts

You can alternatively build tmux directly on your machine using the provided [build scripts](./scripts/).  
See the build stage in the [GitHub Actions workflow](.github/workflows/create-release.yml) reference on how to use these scripts.

## Acknowledgments

The build scripts are inspired by the [build-static-tmux](https://github.com/mjakob-gh/build-static-tmux) repository by mjakob-gh.


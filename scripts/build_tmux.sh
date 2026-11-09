#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PREFIX:-}" ]]; then
    echo "Error: PREFIX must be set" >&2
    exit 1
fi

if [[ -z "${TMUX_VERSION:-}" ]]; then
    echo "Error: TMUX_VERSION must be set" >&2
    exit 1
fi

mkdir -p "$PREFIX/src"
cd "$PREFIX/src"

# A release builds garyng/tmux at TMUX_REF, the tag of the same name without the v (v3.7c-kitty.5
# builds 3.7c-kitty.5): tmux's release with this fork's fixes as commits. TMUX_SRC, a tmux tree on
# disk, is built instead (in Docker, the tmux-src build context: an unpushed branch). A preview
# builds upstream master.
if [[ -n "${TMUX_SRC:-}" ]]; then
    if [[ ! -e "${TMUX_SRC}/autogen.sh" ]]; then
        echo "Error: TMUX_SRC=${TMUX_SRC} holds no tmux tree" >&2
        exit 1
    fi
    echo "Building the tmux tree in ${TMUX_SRC}"
    cp -a "${TMUX_SRC}" tmux
elif [[ "${TMUX_VERSION}" == "preview" ]]; then
    git clone https://github.com/tmux/tmux.git
else
    if [[ -z "${TMUX_REF:-}" ]]; then
        echo "Error: TMUX_REF must be set: the garyng/tmux tag to build" >&2
        exit 1
    fi
    git clone --depth 1 --branch "${TMUX_REF}" https://github.com/garyng/tmux.git
fi
cd tmux
sh autogen.sh

IS_MACOS=false
if [[ "$(uname)" == "Darwin" ]]; then
    IS_MACOS=true
fi

# --enable-sixel: without it tmux drops a pane's Sixel images silently (no external library).
CONFIGURE_FLAGS=(
    --prefix=${PREFIX}
    --enable-sixel
    --includedir="${PREFIX}/include"
    --libdir="${PREFIX}/lib"
    LIBEVENT_LIBS="-L${PREFIX}/lib -levent"
    LIBNCURSES_CFLAGS="-I${PREFIX}/include/ncurses"
    LIBNCURSES_LIBS="-L${PREFIX}/lib -lncurses"
    LIBTINFO_CFLAGS="-I${PREFIX}/include/ncurses"
    LIBTINFO_LIBS="-L${PREFIX}/lib -ltinfo"
    CFLAGS="-I${PREFIX}/include"
    LDFLAGS="-L${PREFIX}/lib"
    CPPFLAGS="-I${PREFIX}/include"
)

if $IS_MACOS; then
    CONFIGURE_FLAGS+=(
        --enable-utf8proc
        LIBUTF8PROC_CFLAGS="-I${PREFIX}/include"
        LIBUTF8PROC_LIBS="${PREFIX}/lib/libutf8proc.a"
        --disable-jemalloc
    )
else
    CONFIGURE_FLAGS+=(
        --enable-static
    )
fi

./configure "${CONFIGURE_FLAGS[@]}"

if $IS_MACOS; then
    make -j$(sysctl -n hw.ncpu)
else
    make -j$(nproc)
fi

make install

rm -rf "$PREFIX/src"

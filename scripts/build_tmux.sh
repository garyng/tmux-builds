#!/usr/bin/env bash
set -euo pipefail

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

if [[ "${TMUX_VERSION}" == "preview" ]]; then
    git clone https://github.com/tmux/tmux.git
    cd tmux
    sh autogen.sh
else
    wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    tar xzf "tmux-${TMUX_VERSION}.tar.gz"
    cd "tmux-${TMUX_VERSION}"
fi

for p in "${SCRIPTDIR}"/../patches/*.patch; do
    [[ -e "$p" ]] || continue
    echo "Applying ${p##*/}"
    patch -p1 < "$p"
done

IS_MACOS=false
if [[ "$(uname)" == "Darwin" ]]; then
    IS_MACOS=true
fi

CONFIGURE_FLAGS=(
    --prefix=${PREFIX}
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

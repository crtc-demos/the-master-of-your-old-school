set -x

BINS=`pwd`/bin

if ! [ -d "$BINS" ]; then
  mkdir -p "$BINS"
fi

if [ ! -x "$BINS/pasta" ]; then
  if [ -x "$(which pasta)" ]; then
    PASTA=$(which pasta)
  else
    PASTA=/home/jules/code/pasta/pasta
  fi

  cp "$PASTA" "$BINS"
fi

if [ ! -x "$BINS/adfs" ]; then
  pushd adfs
  ./compile.sh
  popd
  cp adfs/adfs "$BINS"
fi

if [ ! -x "$BINS/bbcim" ]; then
  pushd bbcim
  ./mkbbcim
  popd
  cp bbcim/bbcim "$BINS"
fi

PATH="$BINS:$PATH"
OUTPUTDISK="`pwd`/tmpdisk"

rm -rf "$OUTPUTDISK"
mkdir -p "$OUTPUTDISK"

export OUTPUTDISK

pushd bbc-cube
./compile.sh
popd

pushd chequer
./compile.sh
popd

pushd crtc-logo
./compile.sh
popd

bbcim -new demodisk.ssd
bbcim -a demodisk.ssd tmpdisk/*

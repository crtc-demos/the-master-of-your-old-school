set -x

cd $(dirname "$0")

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

if [ ! -x "$BINS/pasta" ] || [ ! -x "$BINS/bbcim" ]; then
  echo 'Missing binary for pasta or bbcim! Whoops.'
  exit 1
fi

PATH="$BINS:$PATH"
OUTPUTDISK=$(readlink -f tmpdisk)

mkdir -p "$OUTPUTDISK"
pushd "$OUTPUTDISK"
rm -f *
popd

export OUTPUTDISK

set -e

pushd bbc-cube
./compile.sh
popd

pushd chequer
./compile.sh
popd

pushd crtc-logo
./compile.sh
popd

pushd vgmplayer
./compile.sh
popd

pushd end-screen
./compile.sh
popd

# Get joey's bits...
for x in O.PHASE O.ROTA O.SIERPA O.WHIRL L.SIN L.LOGS; do
  cp "joeys/bin/$x" "joeys/bin/$x.inf" "$OUTPUTDISK"
done

bbcim -new demodisk.ssd
pushd tmpdisk
bbcim -a ../demodisk.ssd *
popd

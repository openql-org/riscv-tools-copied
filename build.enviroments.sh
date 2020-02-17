# build on Ubuntu 18.04 LTS server
# user: siprop
# /home/siprop
#

# ubuntu packages install
apt-get install -y build-essential device-tree-compiler binutils build-essential libtool texinfo gzip zip unzip patchutils curl git make cmake ninja-build automake bison flex gperf grep sed gawk python bc zlib1g-dev libexpat1-dev libmpc-dev libglib2.0-dev libfdt-dev libpixman-1-dev python python-pip gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake texinfo bison libbison-dev liboscpack1 liboscpack-dev

# make working dirs
cd $HOME
mkdir -p work/riscv
mkdir -p work/riscv/bin
export RISCV=$HOME/work/riscv
export PATH=$PATH:$HOME/work/riscv/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/work/riscv/lib

# toolchain
cd $HOME/work
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
rm -rf riscv-binutils riscv-gcc
# enter ID/Password
git clone -b develop-qext https://github.com/openql-org/riscv-binutils-gdb riscv-binutils
git clone -b develop-qext https://github.com/openql-org/riscv-gcc riscv-gcc

mkdir build
cd build
../configure --prefix=${RISCV} --enable-multilib
make -j`nproc`


# riscv-tools
cd $HOME/work/
git clone -b develop-qext https://github.com/openql-org/riscv-tools
cd riscv-tools
git submodule update --init --recursive
rm -rf riscv-isa-sim riscv-opcodes

# quest make
git clone -b develop-qext https://github.com/openql-org/riscv-isa-sim
cd riscv-isa-sim
git submodule update --init --recursive
cd QuEST
git checkout -b develop-qext origin/develop-qext
mkdir build
cd build
cmake ..
make 

# opcode make
cd ../../../
git clone -b develop-qext https://github.com/openql-org/riscv-opcodes
cd riscv-opcodes
pip install future
make

# spike main
cd ../riscv-isa-sim/
autoconf
mkdir build
cd build
../configure  --prefix=$HOME/work/riscv/
make CFLAGS=-DQUEST CPPFLAGS=-DQUEST -j`nproc`
sudo make install

# pk
cd $HOME/work/riscv-tools/riscv-pk
mkdir build
cd build
../configure  --prefix=$HOME/work/riscv/ --host=riscv64-unknown-elf
make
sudo make install


# make llvm
cd $HOME/work/
git clone https://github.com/llvm/llvm-project.git riscv-llvm
pushd riscv-llvm
mkdir build
cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE="Release" \
  -DLLVM_ENABLE_PROJECTS=clang \
  -DBUILD_SHARED_LIBS=True -DLLVM_USE_SPLIT_DWARF=True \
  -DCMAKE_INSTALL_PREFIX=$HOME/work/riscv/ \
  -DLLVM_OPTIMIZED_TABLEGEN=True -DLLVM_BUILD_TESTS=False \
  -DDEFAULT_SYSROOT=$HOME/work/riscv/riscv64-unknown-elf \
  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-elf" \
  -DLLVM_TARGETS_TO_BUILD="RISCV" \
  ../llvm
cmake --build . --target install

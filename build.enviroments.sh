# build on Ubuntu 18.04 LTS server
# user: siprop
# /home/siprop
#

# ubuntu packages install
sudo apt-get -y install binutils build-essential libtool texinfo gzip zip unzip patchutils curl git make cmake ninja-build automake bison flex gperf grep sed gawk python bc zlib1g-dev libexpat1-dev libmpc-dev libglib2.0-dev libfdt-dev libpixman-1-dev python python-pip gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake texinfo bison libbison-dev

# make working dirs
cd $HOME
mkdir -p work/riscv
mkdir -p work/riscv/bin
export RISCV=/home/siprop/work/riscv
export PATH=$PATH:/home/siprop/work/riscv/bin

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

# opcode make
git clone -b develop-qext https://github.com/openql-org/riscv-opcodes
cd riscv-opcodes
pip install future
make

# spike make
cd ../../riscv-tools
git clone -b develop-qext https://github.com/openql-org/riscv-isa-sim
cd riscv-isa-sim
git submodule update --init --recursive
cd QuEST
git checkout -b develop-qext origin/develop-qext
mkdir build
cd build
cmake ..
make 

cd ../../../riscv-isa-sim/
autoconf
mkdir build
cd build
../configure  --prefix=/home/siprop/work/riscv/
make CFLAGS=-DQUEST CPPFLAGS=-DQUEST -j2
sudo make install

# pk
cd $HOME/work/riscv-tools/riscv-pk
mkdir build
cd build
../configure  --prefix=/home/siprop/work/riscv/ --host=riscv64-unknown-elf
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
  -DCMAKE_INSTALL_PREFIX="/home/siprop/work/riscv/" \
  -DLLVM_OPTIMIZED_TABLEGEN=True -DLLVM_BUILD_TESTS=False \
  -DDEFAULT_SYSROOT="/home/siprop/work/riscv/riscv64-unknown-elf" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-elf" \
  -DLLVM_TARGETS_TO_BUILD="RISCV" \
  ../llvm
cmake --build . --target install

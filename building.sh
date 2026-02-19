#!/usr/bin/bash
# Hopefully-helfpul instructions for building ocaml-torch library locally.
# Tested February 17 2026 Debian 13 (Trixie) and 14 (Forky)

LIBTORCH=$HOME/var/libtorch
export LIBTORCH=$LIBTORCH

if [ ! -d "$LIBTORCH" ]; then
	echo "Directory $LIBTORCH not found."
	echo "please edit the script to download or specify its location"
	exit 1
	# example:
	# download libtorch from the pytorch website.
	cd $HOME/var
	wget https://download.pytorch.org/libtorch/cu130/libtorch-shared-with-deps-2.10.0%2Bcu130.zip
	unzip libtorch libtorch-shared-with-deps-2.10.0+cu130.zip
fi

# if you are using a CUDA dev environment not managed by Debian, make sure g++ can find the headers, e.g:
# if cuda_runtime_api.h is not on gcc search path, throw an error
if ! echo "#include <cuda_runtime_api.h>" | gcc -E -xc - >/dev/null 2>&1; then
	echo "Header 'cuda_runtime_api.h' not found in gcc search path. "
	exit 1
	# "example:"
	export C_INCLUDE_PATH="/usr/local/cuda-13.1/targets/x86_64-linux/include"
	export CPLUS_INCLUDE_PATH="/usr/local/cuda-13.1/targets/x86_64-linux/include"
else
    echo "CUDA header found."
fi

# opam packages:
opam install dune stdio core ppx_jane patdiff ctypes-foreign npy cmdliner yaml pyml utop

# clean up the source tree, jic
rm -rf src/wrapper/*generated*
rm -rf src/wrapper_refcounted/*generated*
rm -rf src/bindings/*generated*
rm -rf src/bindings_refcounted/*generated*
rm -rf src/gen_bindings/*generated*

dune build src/gen_bindings/gen.exe
cd _build/default/src/gen_bindings/

# If you are not using Pytorch release 2.10, you'll need to compile Pytorch from source to generate Declarations.yaml
# (The file in the tree was copied from the build tree of pytorch)
# Below commands regenerate wrapper and stub files from this Declarations.yaml.
./gen.exe -declarations ../../../../third_party/pytorch/Declarations-2.10.yaml -bindings -wrappers -refcounted false
cp *.cpp ../../../../src/wrapper/
cp *.h ../../../../src/wrapper/
cp wrapper_generated_intf.ml ../../../../src/wrapper/
cp wrapper_generated.ml ../../../../src/wrapper/
cp torch_bindings_generated.ml ../../../../src/bindings/

./gen.exe -declarations ../../../../third_party/pytorch/Declarations-2.10.yaml -bindings -wrappers -refcounted true
cp *.cpp ../../../../src/wrapper_refcounted/
cp *.h ../../../../src/wrapper_refcounted/
cp wrapper_generated_refcounted_intf.ml ../../../../src/wrapper_refcounted/
cp wrapper_generated_refcounted.ml ../../../../src/wrapper_refcounted/
cp torch_refcounted_bindings_generated.ml ../../../../src/bindings_refcounted/

cd ../../../..
dune build -p torch @install
dune install

# to test out your new library:
echo 'to test:'
echo '#require "torch";;'
echo 'open Torch;;'
echo 'let t = Tensor.randn [3] ;;'
LD_PRELOAD=$LIBTORCH/lib/libtorch.so utop

# Hopefully-helfpul instructions for building this library locally.
# tested February 17 2026 Debian 13 (Trixie) and 14 (Forky)

# download libtorch from the pytorch website.
wget https://download.pytorch.org/libtorch/cu130/libtorch-shared-with-deps-2.10.0%2Bcu130.zip
unzip libtorch libtorch-shared-with-deps-2.10.0+cu130.zip
export LIBTORCH=$HOME/var/libtorch

# if you are using a CUDA dev environment not managed by Debian, make sure g++ can find the headers, e.g:
export C_INCLUDE_PATH="/usr/local/cuda-13.1/targets/x86_64-linux/include"
export CPLUS_INCLUDE_PATH="/usr/local/cuda-13.1/targets/x86_64-linux/include"

# opam packages:
opam install dune stdio core ppx_jane patdiff ctypes-foreign npy cmdliner yaml pyml utop

dune build src/gen_bindings/gen.exe
cd _build/default/src/gen_bindings/

# If you are using a different version of Pytorch, you'll need to compile that from source to generate Declarations.yaml
# Some files below were in the git tree, but have been removed so they can be auto-generated.
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

dune build -p torch @install
dune install

# to test out your new library:
LD_PRELOAD=$LIBTORCH/lib/libtorch.so utop

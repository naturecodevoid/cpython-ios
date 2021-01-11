#! /bin/sh

# Changed install prefix so multiple install coexist
PREFIX=$PWD
XCFRAMEWORKS_DIR=$PREFIX/Python-aux/
export PATH=$PREFIX/Library/bin:$PATH
export PYTHONPYCACHEPREFIX=$PREFIX/__pycache__
OSX_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
DEBUG="-O3 -Wall"
# DEBUG="-g"
OSX_VERSION=$(sw_vers -productVersion |awk -F. '{print $1"."$2}')
# Loading different set of frameworks based on the Application:
APP=$(basename `dirname $PWD`)
#
# Set to 1 if you have gfortran for arm64 installed. gfortran support is highly experimental.
# You might need to edit the script as well.
USE_FORTRAN=0
if [ -e "/usr/local/aarch64-apple-darwin20/lib/libgfortran.dylib" ];then
	USE_FORTRAN=1
fi

# 1) compile for OSX (required)
find . -name \*.o -delete
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L. -lpython3.9" OPT="$DEBUG" ./configure --prefix=$PREFIX/Library --with-system-ffi --enable-shared \
    $EXTRA_CONFIGURE_FLAGS_OSX \
	--without-computed-gotos \
	ac_cv_file__dev_ptmx=no \
	ac_cv_file__dev_ptc=no \
	ac_cv_func_getentropy=no \
	ac_cv_func_sendfile=no \
	ac_cv_func_setregid=no \
	ac_cv_func_setreuid=no \
	ac_cv_func_setsid=no \
	ac_cv_func_setpgid=no \
	ac_cv_func_setpgrp=no \
	ac_cv_func_setuid=no \
    ac_cv_func_forkpty=no \
    ac_cv_func_openpty=no \
	ac_cv_func_clock_settime=no >& configure_osx.log
# enable-framework incompatible with local install
# Other functions copied from iOS so packages are consistent
mkdir -p $PREFIX/Frameworks_macosx
mkdir -p $PREFIX/Frameworks_macosx/lib
mkdir -p $PREFIX/Frameworks_macosx/include
rm -rf Frameworks_macosx/openblas.framework
# The build scripts from numpy need openblas to be in a dylib, not a framework (to detect lapack functions)
# So we create the dylib from the framework:
# TODO: add openssl and zmq headers and libraries here as well (requires changing Python-aux build scripts)
cp $XCFRAMEWORKS_DIR/openblas.xcframework/macos-x86_64/openblas.framework/Headers/* $PREFIX/Frameworks_macosx/include/
cp  $XCFRAMEWORKS_DIR/openblas.xcframework/macos-x86_64/openblas.framework/openblas $PREFIX/Frameworks_macosx/lib/libopenblas.dylib
install_name_tool -id $PREFIX/Frameworks_macosx/lib/libopenblas.dylib   $PREFIX/Frameworks_macosx/lib/libopenblas.dylib
#
rm -rf build/lib.macosx-${OSX_VERSION}-x86_64-3.9
rm $PREFIX/Library/bin/make
make -j 4 >& make_osx.log
mkdir -p build/lib.macosx-${OSX_VERSION}-x86_64-3.9  > make_install_osx.log 2>&1
cp libpython3.9.dylib build/lib.macosx-${OSX_VERSION}-x86_64-3.9  >> make_install_osx.log 2>&1
make  -j 4 install  >> make_install_osx.log 2>&1
export PYTHONHOME=$PREFIX/Library
# When working on frozen importlib, we need to compile twice:
# Otherwise, we can comment the next 6 lines
make regen-importlib >> make_osx.log 2>&1
find . -name \*.o -delete  >> make_osx.log 2>&1
make  -j 4 >> make_osx.log 2>&1 
mkdir -p build/lib.macosx-${OSX_VERSION}-x86_64-3.9  >> make_install_osx.log 2>&1
cp libpython3.9.dylib build/lib.macosx-${OSX_VERSION}-x86_64-3.9  >> make_install_osx.log 2>&1
make  -j 4 install >> make_install_osx.log 2>&1
# Force reinstall and upgrade of pip, setuptools 
python3.9 -m pip install pip --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install setuptools --upgrade >> make_install_osx.log 2>&1
# Pure-python packages that do not depend on anything, keep latest version:
# Order of packages: packages dependent on something after the one they depend on
python3.9 -m pip install six --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install html5lib --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install urllib3 --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install webencodings --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install wheel --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install pygments --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install Babel --upgrade >> make_install_osx.log 2>&1
# markupsafe: prevent compilation of extension:
echo Installing MarkupSafe with no extensions >> $PREFIX/make_install_osx.log 2>&1
mkdir -p packages >> $PREFIX/make_install_osx.log 2>&1
pushd packages >> $PREFIX/make_install_osx.log 2>&1
rm -rf  MarkupSafe* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download --no-binary :all: markupsafe >> $PREFIX/make_install_osx.log 2>&1
tar xvzf MarkupSafe*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm MarkupSafe*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd MarkupSafe* >> $PREFIX/make_install_osx.log 2>&1
sed -i bak  's/run_setup(True)/run_setup(False)/g' setup.py  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# rm -rf MarkupSafe* >> $PREFIX/make_install_osx.log 2>&1
popd >> $PREFIX/make_install_osx.log 2>&1
echo Done installing MarkupSafe >> make_install_osx.log 2>&1
# end markupsafe 
python3.9 -m pip install jinja2 --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install attrs --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install appnope --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install packaging --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install bleach --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install entrypoints --upgrade >> make_install_osx.log 2>&1
# send2trash: don't use OSX FSMoveObjectToTrashSync
echo Installing send2trash >> make_install_osx.log 2>&1
pushd packages >> make_install_osx.log 2>&1
rm -rf Send2Trash*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download send2trash --no-binary :all:  >> $PREFIX/make_install_osx.log 2>&1
tar xvzf Send2Trash*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm Send2Trash*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd Send2Trash* >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/^import sys/&, os/" send2trash/__init__.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/^if sys.platform == 'darwin'/& and not os.uname\(\).machine.startswith\('iP'\)/" send2trash/__init__.py  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# rm -rf Send2Trash* >> $PREFIX/make_install_osx.log 2>&1
popd >> $PREFIX/make_install_osx.log 2>&1
echo done installing send2trash >> make_install_osx.log 2>&1
# end send2trash
# pyrsistent: prevent compilation of extension:
echo Installing pyrsistent with no extension >> make_install_osx.log 2>&1
pushd packages >> make_install_osx.log 2>&1
rm -rf pyrsistent* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download pyrsistent --no-binary :all:  >> $PREFIX/make_install_osx.log 2>&1
tar xvzf pyrsistent*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm pyrsistent*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd pyrsistent* >> $PREFIX/make_install_osx.log 2>&1
sed -i bak 's/^if platform.python_implementation/#&/' setup.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak 's/^    extensions = /#&/' setup.py  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
rm -rf pyrsistent* >> $PREFIX/make_install_osx.log 2>&1
popd >> $PREFIX/make_install_osx.log 2>&1
echo done installing pyrsistent >> make_install_osx.log 2>&1
# end pyrsistent
python3.9 -m pip install ptyprocess --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install jsonschema --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install mistune --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install docutils --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install m2r --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install traitlets --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install pexpect --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install ipython-genutils --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install jupyter-core --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install nbformat --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install pandocfilters --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install testpath --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install defusedxml --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install python-dateutil --upgrade >> make_install_osx.log 2>&1
# Let jedi install the version of parso it needs (since the latest version is not OK)
# python3.9 -m pip install parso --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install jedi --upgrade >> make_install_osx.log 2>&1
# This simple trick prevents tornado from installing extensions:
CC=/bin/false python3.9 -m pip install tornado --upgrade  >> make_install_osx.log 2>&1
python3.9 -m pip install terminado --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install backcall --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install pandocfilters --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install decorator --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install prometheus-client --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install wcwidth --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install pickleshare --upgrade >> make_install_osx.log 2>&1
# To get further, we need cffi:
# OSX install of cffi: we need to recompile or Python crashes. 
# TODO: edit cffi code if static variables inside function create problems.
python3.9 -m pip uninstall cffi -y >> $PREFIX/make_install_osx.log 2>&1
pushd packages >> $PREFIX/make_install_osx.log 2>&1
rm -rf cffi-* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download cffi --no-binary :all: >> $PREFIX/make_install_osx.log 2>&1
tar xvzf cffi*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm cffi*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd cffi-* >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/* >> $PREFIX/make_install_osx.log 2>&1
cp ../setup_cffi.py ./setup.py  >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
# python3.9 -m pip install cffi --upgrade >> make_install_osx.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/_cffi_backend.cpython-39-darwin.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/  >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# First, install the "standard" pyzmq: 
python3.9 -m pip install pyzmq  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install certifi >> make_install_osx.log 2>&1
# Let's install the proper version of prompt-toolkit for Ipython:
python3.9 -m pip install prompt-toolkit==3.0.7 >> make_install_osx.log 2>&1
# ipython: just two files to change, we use sed to patch it: 
echo Installing IPython for OSX  >> make_install_osx.log 2>&1
pushd packages >> make_install_osx.log 2>&1
rm -rf ipython\*  >>  $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download ipython --no-binary :all: >>  $PREFIX/make_install_osx.log 2>&1
tar xzf ipython-7*.tar.gz  >>  $PREFIX/make_install_osx.log 2>&1
rm ipython-7*.tar.gz  >>  $PREFIX/make_install_osx.log 2>&1
pushd ipython-7* >>  $PREFIX/make_install_osx.log 2>&1
# That's one large sed replace, but it's a single file in the repository.
# We need system_ios to replace system_piped *and* system_raw.
sed -i bak 's/^    system = system_piped/    # iOS: use system_ios instead\
    def system_ios(self, cmd): \
        cmd = self.var_expand(cmd, depth=1)\
        p = subprocess.Popen(cmd, shell=True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)\
        os.set_blocking(p.stdout.fileno(), False)\
        os.set_blocking(p.stderr.fileno(), False)\
        while True:\
            if (not p.stdout.closed):\
                outline = p.stdout.readline()\
            if (not p.stderr.closed):\
                errline = p.stderr.readline()\
            if (outline and outline != b""): \
                print(outline.decode("UTF-8"),  end="\\r", flush=True)\
            if (errline and errline != b""): \
                print(errline.decode("UTF-8"),  end="\\r", file = sys.stderr, flush=True)\
            outStreamClosed = p.stdout.closed or outline == b""\
            errStreamClosed = p.stderr.closed or errline == b""\
            # Additional test: check that the process is not still running:\
            processTerminated = False\
            try:\
                pid, sts = os.waitpid(p.pid, os.WNOHANG)\
                if pid != 0:\
                    processTerminated = True\
            except OSError as e:\
                processTerminated = True\
            if (errStreamClosed and outStreamClosed and processTerminated):\
                break\
        retcode = p.poll()\
\
        if retcode is not None: \
            if retcode > 128:\
                retcode = -(retcode - 128)\
            self.user_ns["_exit_code"] = retcode \
        else:\
            self.user_ns["_exit_code"] = 0\
\
    if (sys.platform == "darwin" and os.uname().machine.startswith("iP")):\
        system = system_ios\
    else:\
        system = system_piped/' IPython/core/interactiveshell.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak 's/^    system = InteractiveShell.system_raw/    system = InteractiveShell.system_ios/'  IPython/terminal/interactiveshell.py  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# python3.9 -m pip install ipython --upgrade >> make_install_osx.log 2>&1
# nbconvert: need to fork and clone. git clone https://github.com/jupyter/nbconvert.git
# python3.9 -m pip install nbconvert --upgrade >> make_install_osx.log 2>&1
echo Installing nbconvert, patched for iOS  >> make_install_osx.log 2>&1
pushd packages >> make_install_osx.log 2>&1
pushd nbconvert  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# argon2 for OSX: use precompiled binary. This might cause a crash later, as with cffi.
python3.9 -m pip uninstall argon2-cffi -y >> make_install_osx.log 2>&1
python3.9 -m pip install argon2-cffi --upgrade >> make_install_osx.log 2>&1
# Download argon2 now, while the dependencies are working
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/argon2/  >> make_install_osx.log 2>&1
cp $PREFIX/Library/lib/python3.9/site-packages/argon2/_ffi.abi3.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/argon2/_ffi.abi3.so  >> make_install_osx.log 2>&1
pushd packages >> make_install_osx.log 2>&1
rm -rf argon2-cffi* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download argon2-cffi --no-binary :all:  >> $PREFIX/make_install_osx.log 2>&1
tar xvzf argon2-cffi*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm argon2-cffi*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# Now install everything we need:
# python3.9 -m pip install jupyter --upgrade >> make_install_osx.log 2>&1
# install mpmath manually because the repository is 2 years ahead of Pipy:
pushd packages >> make_install_osx.log 2>&1
pushd mpmath >> $PREFIX/make_install_osx.log 2>&1
git pull  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# Now install sympy:
python3.9 -m pip install sympy --upgrade >> make_install_osx.log 2>&1
# For jupyter: 
# ipykernel (edited to cleanup sockets when we close a kernel)
pushd packages >> make_install_osx.log 2>&1
pushd ipykernel >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . >> $PREFIX/make_install_osx.log 2>&1 
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
export PYZMQ_BACKEND=cffi
# depend on ipykernel:
# Now we can install PyZMQ. We need to compile it ourselves to make sure it uses CFFI as a backend:
# (the wheel uses Cython)
echo Installing PyZMQ for OSX  >> make_install_osx.log 2>&1
# First uninstall standard pyzmq 
python3.9 -m pip uninstall pyzmq -y >> $PREFIX/make_install_osx.log 2>&1
# Then install our own version:
pushd packages  >> make_install_osx.log 2>&1
rm -rf pyzmq* >> $PREFIX/make_install_osx.log 2>&1 
python3.9 -m pip download pyzmq --no-binary :all:  >> $PREFIX/make_install_osx.log 2>&1
tar xvzf pyzmq*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm pyzmq*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd pyzmq* >> $PREFIX/make_install_osx.log 2>&1
cp ../setup_pyzmq.py ./setup.py  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/* >> $PREFIX/make_install_osx.log 2>&1 
export PYZMQ_BACKEND=cffi
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " PYZMQ_BACKEND=cffi python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/zmq/backend/cffi/_cffi_ext.cpython-39-darwin.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9 >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " PYZMQ_BACKEND=cffi python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
echo Done installing PyZMQ with CFFI >> make_install_osx.log 2>&1
python3.9 -m pip install qtpy --upgrade >> make_install_osx.log 2>&1
python3.9 -m pip install qtconsole --upgrade >> make_install_osx.log 2>&1
# python3.9 -m pip install babel --upgrade >> make_install_osx.log 2>&1
# notebook
# notebook (heavily edited to adapt to touchscreens and iOS)
pushd packages >> make_install_osx.log 2>&1
pushd notebook >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# jupyter_client
pushd packages >> make_install_osx.log 2>&1
pushd jupyter_client >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# Now: jupyter
python3.9 -m pip install jupyter --upgrade >> make_install_osx.log 2>&1
# Cython (edited for iOS, reinitialize types at each run):
pushd packages >> make_install_osx.log 2>&1
pushd cython >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install . --install-option="--no-cython-compile" >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# python3.9 -m pip install cython --upgrade >> make_install_osx.log 2>&1
# Numpy:
# Cython options for numpy (and other packages: PEP489_MULTI_PHASE_INIT=0, USE_DICT_VERSIONS=0 to reduce
# amount of memory allocated and not tracked. Also in numpy/tools/cythonize.py, "--cleanup 3" to free
# all memory and reset pointers.
pushd packages >> make_install_osx.log 2>&1
pushd numpy >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
cp site_original.cfg site.cfg >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s|__main_directory__|${PREFIX}/Frameworks_macosx|" site.cfg >> $PREFIX/make_install_osx.log 2>&1
if [ $USE_FORTRAN == 0 ];
then
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG " NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
else
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG " NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" PLATFORM=macosx python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG " LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" PLATFORM=macosx python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
fi
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/core/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/fft/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/random/  >> $PREFIX/make_install_osx.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/core/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/core/ >> $PREFIX/make_install_osx.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/ >> $PREFIX/make_install_osx.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/fft/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/fft/ >> $PREFIX/make_install_osx.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/random/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/random/ >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# change references to openblas back to the framework:
install_name_tool -change $PREFIX/Frameworks_macosx/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/core/_multiarray_umath.cpython-39-darwin.so  >> $PREFIX/make_install_osx.log 2>&1
install_name_tool -change $PREFIX/Frameworks_macosx/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/_umath_linalg.cpython-39-darwin.so  >> $PREFIX/make_install_osx.log 2>&1
install_name_tool -change $PREFIX/Frameworks_macosx/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/lapack_lite.cpython-39-darwin.so  >> $PREFIX/make_install_osx.log 2>&1
# For matplotlib:
## cycler:
python3.9 -m pip install cycler --upgrade  >> make_install_osx.log 2>&1
## kiwisolver
pushd packages >> make_install_osx.log 2>&1
rm -rf kiwisolver* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download --no-binary :all: kiwisolver >> $PREFIX/make_install_osx.log 2>&1
tar xvzf kiwisolver*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm kiwisolver*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd kiwisolver* >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " python3 setup.py build >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ " python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/kiwisolver.cpython-39-darwin.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
## Pillow
pushd packages >> make_install_osx.log 2>&1
rm -rf Pillow*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download --no-binary :all: Pillow >> $PREFIX/make_install_osx.log 2>&1
tar xvzf Pillow*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm Pillow*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd Pillow*  >> $PREFIX/make_install_osx.log 2>&1
cp ../setup_Pillow.py ./setup.py >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
# image show and image capture not implemented on iOS.
sed -i bak 's/^if sys.platform == "darwin"/& and not os.uname\(\).machine.startswith\("iP"\)/' src/PIL/ImageShow.py >> $PREFIX/make_install_osx.log 2>&1
sed -i bak 's/    if sys.platform == "darwin"/& and not os.uname\(\).machine.startswith\("iP"\)/' src/PIL/ImageGrab.py >> $PREFIX/make_install_osx.log 2>&1
#
env CC=clang CXX=clang++ LDSHARED="clang -v -undefined error -dynamiclib -lz -L$PREFIX -lpython3.9 -lc++ " python3 setup.py build >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ LDSHARED="clang -v -undefined error -dynamiclib -lz -L$PREFIX -lpython3.9 -lc++ " python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/PIL/  >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/PIL/*.so  $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/PIL/ >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
## matplotlib itself:
pushd packages >> make_install_osx.log 2>&1
pushd matplotlib  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CFLAGS="-I /opt/X11/include/freetype2/" LDFLAGS="-L/opt/X11/lib" LDSHARED="clang -v -undefined error -dynamiclib -lz -L$PREFIX -lpython3.9 -lc++ " python3 setup.py build >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CFLAGS="-I /opt/X11/include/freetype2/" LDFLAGS="-L/opt/X11/lib" LDSHARED="clang -v -undefined error -dynamiclib -lz -L$PREFIX -lpython3.9 -lc++ " python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
# Somehow, the version number *was* computed but did not make it in the install:
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/_version.py $PREFIX/Library/lib/python3.9/site-packages/matplotlib/
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/backends/  >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/*.so  $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/ >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/backends/*.so  $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/backends/ >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# lxml:
pushd packages >> make_install_osx.log 2>&1
rm -rf lxml*  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download --no-binary :all: lxml >> $PREFIX/make_install_osx.log 2>&1
tar xvzf lxml*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
rm -rf lxml*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd lxml*  >> $PREFIX/make_install_osx.log 2>&1
cp ../setupinfo_lxml.py ./setupinfo.py  >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/* >> $PREFIX/make_install_osx.log 2>&1
# lxml has 2 cython modules. We need PEP489=0 and USE_DICT=0
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG"  PLATFORM=macosx python3 setup.py build --with-cython >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG"  PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/html/  >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/*.so  $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/ >> $PREFIX/make_install_osx.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/html/*.so  $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/html/ >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# cryptography:
pushd packages >> make_install_osx.log 2>&1
rm -rf cryptography* >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip download cryptography --no-binary :all: >> $PREFIX/make_install_osx.log 2>&1
tar xzvf cryptography*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
rm -rf cryptography*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
pushd cryptography* >> $PREFIX/make_install_osx.log 2>&1
rm -rf build/* >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CFLAGS="-I$PREFIX/ -I/usr/local/include/ -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" LDFLAGS="-L$PREFIX/ -L/usr/local/lib" python3 setup.py build >> $PREFIX/make_install_osx.log 2>&1
env CC=clang CXX=clang++ CFLAGS="-I$PREFIX/ -I/usr/local/include/ -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" LDFLAGS="-L$PREFIX/ -L/usr/local/lib" python3 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/hazmat  >> $PREFIX/make_install_osx.log 2>&1
mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/hazmat/bindings  >> $PREFIX/make_install_osx.log 2>&1
cp build//lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/hazmat/bindings/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/hazmat/bindings  >> $PREFIX/make_install_osx.log 2>&1

popd  >> $PREFIX/make_install_osx.log 2>&1
popd  >> $PREFIX/make_install_osx.log 2>&1
# for Carnets specifically (or all apps with Jupyter notebooks):
if [ $APP == "Carnets" ]; 
then
	# Pandas
	pushd packages >> make_install_osx.log 2>&1
	rm -rf pandas*  >> $PREFIX/make_install_osx.log 2>&1
	env NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" python3.9 -m pip download pandas --no-binary :all:  >> $PREFIX/make_install_osx.log 2>&1
	tar xvzf pandas*  >> $PREFIX/make_install_osx.log 2>&1
	rm pandas*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
	pushd pandas*  >> $PREFIX/make_install_osx.log 2>&1
	rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
    sed -i bak 's/warnings.warn(msg)/# iOS: lzma is forbidden on the AppStore\
        import os\
        if (sys.platform != "darwin" or not os.uname().machine.startswith("iP")):\
            &/' pandas/compat/__init__.py >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/io  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/io/sas  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/window  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/tslibs  >> $PREFIX/make_install_osx.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/io/sas/_sas.cpython-39-darwin.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/io/sas >> $PREFIX/make_install_osx.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs >> $PREFIX/make_install_osx.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/window/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/window >> $PREFIX/make_install_osx.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/tslibs/*.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/tslibs >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	# nbextensions
	python3.9 -m pip install --upgrade pyyaml >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip install --upgrade jupyter_contrib_core >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip install --upgrade jupyter_contrib_nbextensions >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip install --upgrade jupyter_nbextensions_configurator >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip install --upgrade ipysheet >> $PREFIX/make_install_osx.log 2>&1
	# ipysheet.renderer_nbext has disappeared?
	# widgetsnbextension is a bit special, because of the need to add touchscreen support:
	pushd packages >> $PREFIX/make_install_osx.log 2>&1
	rm -rf  widgetsnbextension* >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip download --no-binary :all: widgetsnbextension==4.0.0a0 >> $PREFIX/make_install_osx.log 2>&1
	tar xzvf widgetsnbextension*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
	rm  widgetsnbextension*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
	pushd  widgetsnbextension* >> $PREFIX/make_install_osx.log 2>&1
	# force build a first time to download node_module, then clear everything, replace mouse.js and force rebuild:
	rm widgetsnbextension/static/* >> $PREFIX/make_install_osx.log 2>&1
	python3.9 setup.py build >> $PREFIX/make_install_osx.log 2>&1
	rm -rf build >> $PREFIX/make_install_osx.log 2>&1
	rm widgetsnbextension/static/* >> $PREFIX/make_install_osx.log 2>&1
	# Need to specify clang because widgetsnbextensions update node.js for watchpack-chokidar2/node_modules/fsevents
	cp ../touch_widgetsnbextension_node_modules_mouse.js node_modules/jquery-ui/ui/widgets/mouse.js >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	# dill: preparing for the next step
	python3.9 -m pip install dill >> $PREFIX/make_install_osx.log 2>&1
	# bokeh: Pure Python, only one modification, where it stores data:
	pushd packages >> $PREFIX/make_install_osx.log 2>&1
	rm -rf  bokeh* >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip download --no-binary :all: bokeh >> $PREFIX/make_install_osx.log 2>&1
	tar xzvf bokeh*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
	rm  bokeh*.tar.gz >> $PREFIX/make_install_osx.log 2>&1
	pushd  bokeh* >> $PREFIX/make_install_osx.log 2>&1
	sed -i bak 's/^    bokeh_dir = join(expanduser("~"), ".bokeh")/    # iOS: store data in ~\/Documents\/.bokeh\
    import sys\
    import os\
    if (sys.platform == "darwin" and os.uname().machine.startswith("iP")):\
        bokeh_dir = join(expanduser("\~"), "Documents\/.bokeh")\
    else:\
        bokeh_dir = join(expanduser("\~"), ".bokeh")/' bokeh/util/sampledata.py >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	# pyerfa (for astropy 4.6.2)
	pushd packages >> $PREFIX/make_install_osx.log 2>&1
	rm -rf pyerfa*  >> $PREFIX/make_install_osx.log 2>&1
	python3.9 -m pip download --no-binary :all: pyerfa >> $PREFIX/make_install_osx.log 2>&1
	tar xvzf pyerfa*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
	rm pyerfa*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
	pushd pyerfa*  >> $PREFIX/make_install_osx.log 2>&1
	rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
	python3.9 setup.py build >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/erfa/  >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/erfa/ufunc.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/erfa/ >> $PREFIX/make_install_osx.log 2>&1
    python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	# astropy
	python3.9 -m pip install extension_helpers >> $PREFIX/make_install_osx.log 2>&1
	pushd packages >> $PREFIX/make_install_osx.log 2>&1
	rm -rf astropy*  >> $PREFIX/make_install_osx.log 2>&1
	env NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" python3.9 -m pip download --no-binary :all: astropy >> $PREFIX/make_install_osx.log 2>&1
	tar xvzf astropy*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
	rm astropy*.tar.gz  >> $PREFIX/make_install_osx.log 2>&1
	pushd astropy*  >> $PREFIX/make_install_osx.log 2>&1
	rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
	# We need to edit the position of .astropy (updated for 4.6.2):
	sed -i bak 's/^        homedir = os.path.expanduser(...)/&\
        # iOS: change homedir to HOME\/Documents\
        if (sys.platform == "darwin" and os.uname().machine.startswith("iP")):\
            homedir = homedir + "\/Documents"/' astropy/config/paths.py  >> $PREFIX/make_install_osx.log 2>&1
	sed -i bak 's/^LIBRARY_PATH = os.path.dirname(__file__)/# iOS: For load_library to work, we need to give it special arguments\
&\
import sys\
if (sys.platform == "darwin" and os.uname().machine.startswith("iP")):\
	LIBRARY_PATH="astropy.convolution"\
/' astropy/convolution/convolve.py  >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/bls  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/wcs  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/time  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/xml  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/ascii  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/votable  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/modeling  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/cosmology  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/convolution  >> $PREFIX/make_install_osx.log 2>&1
	mkdir -p $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/stats  >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/compiler_version.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/bls/_impl.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/bls/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/cython_impl.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/wcs/_wcs.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/wcs/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/time/_parse_times.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/time/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/ascii/cparser.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/ascii/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/compression.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/_utils.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/votable/tablewriter.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/votable/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/_compiler.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/xml/_iterparser.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/xml/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/modeling/_projections.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/modeling/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/_np_utils.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/_column_mixins.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/cosmology/scalar_inv_efuncs.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/cosmology/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/convolution/_convolve.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/convolution/ >> $PREFIX/make_install_osx.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/stats/_stats.cpython-39-darwin.so \
$PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/stats/ >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
# scipy
if [ $USE_FORTRAN == 1 ];
then
	pushd packages >> make_install_osx.log 2>&1
	pushd scipy  >> make_install_osx.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" PLATFORM=macosx python3 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
# 	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	popd  >> $PREFIX/make_install_osx.log 2>&1
	# jupyterlab requires node.js, which does not exist on iOS for the time being. 
	# Now, jupyterlab:
	# python3.9 -m pip install idna --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install anyio --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install json --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install chardet --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install requests --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install sniffio --upgrade >> make_install_osx.log 2>&1
	# python3.9 -m pip install jupyter-server --upgrade >> make_install_osx.log 2>&1
	# # nbclassic for jupyterlab:
	# pushd packages >> make_install_osx.log 2>&1
	# pushd nbclassic  >> $PREFIX/make_install_osx.log 2>&1
	# rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
	# python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	# python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	# popd  >> $PREFIX/make_install_osx.log 2>&1
	# popd  >> $PREFIX/make_install_osx.log 2>&1
	# # jupyterlab:
	# pushd packages >> make_install_osx.log 2>&1
	# pushd jupyterlab  >> $PREFIX/make_install_osx.log 2>&1
	# rm -rf build/*  >> $PREFIX/make_install_osx.log 2>&1
	# python3.9 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
	# python3.9 -m pip install .  >> $PREFIX/make_install_osx.log 2>&1
	# popd  >> $PREFIX/make_install_osx.log 2>&1
	# popd  >> $PREFIX/make_install_osx.log 2>&1
	# # jupyterlab-server:
	# python3.9 -m pip install jupyterlab-server --upgrade >> make_install_osx.log 2>&1
fi # scipy, USE_FORTRAN == 1
fi # APP == "Carnets"
# for a-Shell specifically: install dulwich (for git) and almost-make
if [ $APP == "a-Shell" ]; 
then
python3.9 -m pip install dulwich --global-option="--pure" >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/^if __name__ == '__main__':/# iOS: We move argv back one step:\
&\
    sys.argv = sys.argv[1:]\
/" $PREFIX/Library/bin/dulwich  >> $PREFIX/make_install_osx.log 2>&1
cp $PREFIX/Library/bin/dulwich $PREFIX/Library/bin/git  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/Usage: dulwich/Usage: git/" $PREFIX/Library/lib/python3.9/site-packages/dulwich/cli.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/usage: dulwich/usage: git/" $PREFIX/Library/lib/python3.9/site-packages/dulwich/cli.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/dulwich help -a/git help -a/" $PREFIX/Library/lib/python3.9/site-packages/dulwich/cli.py  >> $PREFIX/make_install_osx.log 2>&1
sed -i bak "s/^The dulwich command line tool/The git command line tool/" $PREFIX/Library/lib/python3.9/site-packages/dulwich/cli.py  >> $PREFIX/make_install_osx.log 2>&1
python3.9 -m pip install almost-make  >> $PREFIX/make_install_osx.log 2>&1
fi
# 
# 4 different kind of package configuration
# - pure-python packages, no edits: use pip install
# - pure-python packages that I have to edit: git submodules (some with sed)
# - non-pure-python packages, no edits: pip download + python3 setup.py build
# - non-pure-python packages, with edits: git submodules (some with sed)
#
# break here when only installing packages or experimenting:
# exit 0

# 2) compile for iOS:

mkdir -p Frameworks_iphoneos
mkdir -p Frameworks_iphoneos/include
mkdir -p Frameworks_iphoneos/lib
rm -rf Frameworks_iphoneos/ios_system.framework
rm -rf Frameworks_iphoneos/freetype.framework
rm -rf Frameworks_iphoneos/openblas.framework
cp -r $XCFRAMEWORKS_DIR/ios_system.xcframework/ios-arm64_armv7/ios_system.framework $PREFIX/Frameworks_iphoneos
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-arm64/freetype.framework $PREFIX/Frameworks_iphoneos
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/Headers/ffi $PREFIX/Frameworks_iphoneos/include/ffi
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/Headers/ffi/* $PREFIX/Frameworks_iphoneos/include/ffi/
cp -r $XCFRAMEWORKS_DIR/crypto.xcframework/ios-arm64/Headers $PREFIX/Frameworks_iphoneos/include/crypto/
cp -r $XCFRAMEWORKS_DIR/openssl.xcframework/ios-arm64/Headers $PREFIX/Frameworks_iphoneos/include/openssl/
cp -r $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-arm64/freetype.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
# Need to copy all libs after each make clean: 
cp $XCFRAMEWORKS_DIR/crypto.xcframework/ios-arm64/libcrypto.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/openssl.xcframework/ios-arm64/libssl.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/libffi.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-arm64/libzmq.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-arm64/libjpeg.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-arm64/libtiff.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-arm64/libxslt.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-arm64/libexslt.a $PREFIX/Frameworks_iphoneos/lib/
# The build scripts from numpy need openblas to be in a dylib, not a framework (to detect lapack functions)
# So we create the dylib from the framework:
cp $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp  $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/openblas $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
install_name_tool -id $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib   $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
find . -name \*.o -delete
rm -f Programs/_testembed Programs/_freeze_importlib
# preadv / pwritev are iOS 14+ only
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L. -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	PLATFORM=iphoneos \
	OPT="$DEBUG" \
	./configure --prefix=$PREFIX/Library --enable-shared \
	--host arm-apple-darwin --build x86_64-apple-darwin --enable-ipv6 \
	--with-openssl=$PREFIX/Frameworks_iphoneos \
	--without-computed-gotos \
	with_system_ffi=yes \
	ac_cv_file__dev_ptmx=no \
	ac_cv_file__dev_ptc=no \
	ac_cv_func_getentropy=no \
	ac_cv_func_sendfile=no \
	ac_cv_func_setregid=no \
	ac_cv_func_setreuid=no \
	ac_cv_func_setsid=no \
	ac_cv_func_setpgid=no \
	ac_cv_func_setpgrp=no \
	ac_cv_func_setuid=no \
    ac_cv_func_forkpty=no \
    ac_cv_func_openpty=no \
	ac_cv_func_clock_settime=no >& configure_ios.log
# --without-pymalloc  when debugging memory
# --enable-framework fails with iOS compilers
rm -rf build/lib.darwin-arm64-3.9
make -j 4 >& make_ios.log
mkdir -p  build/lib.darwin-arm64-3.9
cp libpython3.9.dylib build/lib.darwin-arm64-3.9
# Don't install for iOS
# Compilation of specific packages:
cp $PREFIX/build/lib.darwin-arm64-3.9/_sysconfigdata__darwin_darwin.py $PREFIX/Library/lib/python3.9/_sysconfigdata__darwin_darwin.py
# cffi: compile with iOS SDK
echo Installing cffi for iphoneos >> make_ios.log 2>&1
pushd packages >> make_ios.log 2>&1
pushd cffi* >> $PREFIX/make_ios.log 2>&1
# override setup.py for arm64 == iphoneos, not Apple Silicon
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9" PLATFORM=iphoneos python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/_cffi_backend.cpython-39-darwin.so $PREFIX/build/lib.darwin-arm64-3.9/  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
echo done compiling cffi >> $PREFIX/make_ios.log 2>&1
# end cffi
# Now we can install PyZMQ. We need to compile it ourselves to make sure it uses CFFI as a backend:
# (the wheel uses Cython)
echo Installing PyZMQ for iOS  >> $PREFIX/make_ios.log 2>&1
pushd packages  >> $PREFIX/make_ios.log 2>&1
pushd pyzmq* >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
export PYZMQ_BACKEND=cffi  >> make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9 -lc++ -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9" PLATFORM=iphoneos PYZMQ_BACKEND=cffi python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/zmq/backend/cffi/_cffi_ext.cpython-39-darwin.so $PREFIX/build/lib.darwin-arm64-3.9/  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Override zmq/backend/cffi with our own because we can only use cdef on iOS, not _verify  or _make_defines:
cp zmq_backend_cffi/_cffi.py $PREFIX/Library/lib/python3.9/site-packages/zmq/backend/cffi/  >> $PREFIX/make_ios.log 2>&1
cp zmq_backend_cffi/defines.h $PREFIX/Library/lib/python3.9/site-packages/zmq/backend/cffi/  >> $PREFIX/make_ios.log 2>&1
cp zmq_backend_cffi/preprocessed.h $PREFIX/Library/lib/python3.9/site-packages/zmq/backend/cffi/  >> $PREFIX/make_ios.log 2>&1
cp zmq_backend_cffi/zmq.h $PREFIX/Library/lib/python3.9/site-packages/zmq/backend/cffi/  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
echo Done installing PyZMQ for iOS >> make_ios.log 2>&1
# end pyzmq
# Installing argon2-cffi:
echo Installing argon2-cffi for iphoneos >> make_ios.log 2>&1
pushd packages  >> $PREFIX/make_ios.log 2>&1
pushd argon2-cffi* >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9" PLATFORM=iphoneos ARGON2_CFFI_USE_SSE2=0 python3 setup.py build >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/argon2/  >> make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/argon2/_ffi.abi3.so $PREFIX/build/lib.darwin-arm64-3.9/argon2/_ffi.abi3.so >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Numpy:
pushd packages >> make_ios.log 2>&1
pushd numpy >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
cp site_original.cfg site.cfg >> $PREFIX/make_ios.log 2>&1
sed -i bak "s|__main_directory__|${PREFIX}/Frameworks_iphoneos|" site.cfg >> $PREFIX/make_ios.log 2>&1
if [ $USE_FORTRAN == 0 ];
then
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
else 
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
fi
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/numpy/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/numpy/core/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/numpy/fft/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/numpy/linalg/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/numpy/random/  >> $PREFIX/make_ios.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/numpy/core/*.so $PREFIX/build/lib.darwin-arm64-3.9/numpy/core/ >> $PREFIX/make_ios.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/numpy/linalg/*.so $PREFIX/build/lib.darwin-arm64-3.9/numpy/linalg/ >> $PREFIX/make_ios.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/numpy/fft/*.so $PREFIX/build/lib.darwin-arm64-3.9/numpy/fft/ >> $PREFIX/make_ios.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/numpy/random/*.so $PREFIX/build/lib.darwin-arm64-3.9/numpy/random/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# change references to openblas back to the framework:
install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.9/numpy/core/_multiarray_umath.cpython-39-darwin.so  >> make_ios.log 2>&1
install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.9/numpy/linalg/_umath_linalg.cpython-39-darwin.so  >> make_ios.log 2>&1
install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.9/numpy/linalg/lapack_lite.cpython-39-darwin.so  >> make_ios.log 2>&1
# Matplotlib
## kiwisolver
pushd packages >> make_ios.log 2>&1
pushd kiwisolver* >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 " LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 -lz -lpython3.9" PLATFORM=iphoneos python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/kiwisolver.cpython-39-darwin.so $PREFIX/build/lib.darwin-arm64-3.9/  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
## Pillow
pushd packages >> make_ios.log 2>&1
pushd Pillow* >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphoneos/lib/ -L$PREFIX/build/lib.darwin-arm64-3.9 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-arm64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphoneos/lib/ -ljpeg -ltiff" PLATFORM=iphoneos python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/PIL/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/PIL/*.so  $PREFIX/build/lib.darwin-arm64-3.9/PIL/ >> $PREFIX/make_ios.log 2>&1
# _imagingmath.cpython-39-darwin.so
# _imagingtk.cpython-39-darwin.so
# _imagingmorph.cpython-39-darwin.so
# _imaging.cpython-39-darwin.so
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
## matplotlib
pushd packages >> make_ios.log 2>&1
pushd matplotlib  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphoneos/lib/ -L$PREFIX/build/lib.darwin-arm64-3.9 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-arm64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphoneos/lib/ -ljpeg -ltiff" PLATFORM=iphoneos python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/matplotlib/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/matplotlib/backends/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/matplotlib/*.so  $PREFIX/build/lib.darwin-arm64-3.9/matplotlib/ >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/matplotlib/backends/*.so  $PREFIX/build/lib.darwin-arm64-3.9/matplotlib/backends/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# lxml:
pushd packages >> make_ios.log 2>&1
pushd lxml*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/ -Isrc/lxml/includes " \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 -L$PREFIX/Frameworks_iphoneos/lib/" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphoneos/lib/" \
PLATFORM=iphoneos python3 setup.py build  --with-cython >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos python3 setup.py build  --with-cython >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/lxml/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/lxml/html/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/lxml/*.so  $PREFIX/build/lib.darwin-arm64-3.9/lxml/ >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.9/lxml/html/*.so  $PREFIX/build/lib.darwin-arm64-3.9/lxml/html/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# cryptography:
pushd packages >> make_ios.log 2>&1
pushd cryptography* >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/ -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM " \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 -L$PREFIX/Frameworks_iphoneos/lib/" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphoneos/lib/" \
PLATFORM=iphoneos python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/cryptography/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/cryptography/hazmat  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/cryptography/hazmat/bindings  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/cryptography/hazmat/bindings/*.so $PREFIX/build/lib.darwin-arm64-3.9/cryptography/hazmat/bindings  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Pandas (but only with Carnets):
if [ $APP == "Carnets" ]; 
then
	pushd packages >> make_ios.log 2>&1
	pushd pandas*  >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
    # Needed to load parser/tokenizer.h before Parser/tokenizer.h:
    PANDAS=$PWD
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX $DEBUG -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/io  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/io/sas  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs/window  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs/tslibs  >> $PREFIX/make_ios.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/pandas/io/sas/_sas.cpython-39-darwin.so $PREFIX/build/lib.darwin-arm64-3.9/pandas/io/sas >> $PREFIX/make_ios.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/pandas/_libs/*.so $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs >> $PREFIX/make_ios.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/pandas/_libs/window/*.so $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs/window >> $PREFIX/make_ios.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-arm64-3.9/pandas/_libs/tslibs/*.so $PREFIX/build/lib.darwin-arm64-3.9/pandas/_libs/tslibs >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# bokeh, dill: pure Python installs
	# pyerfa (for astropy)
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd pyerfa*  >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos python3.9 setup.py build >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/erfa/  >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/erfa/ufunc.cpython-39-darwin.so \
$PREFIX/build/lib.darwin-arm64-3.9/erfa/ >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1	
	# astropy
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd astropy*  >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/timeseries/periodograms/bls  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/timeseries/periodograms/lombscargle/implementations  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/wcs  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/time  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/utils  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/utils/xml  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/ascii  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/fits  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/votable  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/modeling  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/table  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/cosmology  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/convolution  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.9/astropy/stats  >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/compiler_version.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/timeseries/periodograms/bls/_impl.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/timeseries/periodograms/bls/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/cython_impl.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/wcs/_wcs.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/wcs/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/time/_parse_times.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/time/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/io/ascii/cparser.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/ascii/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/io/fits/compression.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/fits/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/io/fits/_utils.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/fits/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/io/votable/tablewriter.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/io/votable/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/utils/_compiler.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/utils/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/utils/xml/_iterparser.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/utils/xml/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/modeling/_projections.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/modeling/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/table/_np_utils.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/table/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/table/_column_mixins.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/table/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/cosmology/scalar_inv_efuncs.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/cosmology/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/convolution/_convolve.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/convolution/ >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-3.9/astropy/stats/_stats.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-arm64-3.9/astropy/stats/ >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
if [ $USE_FORTRAN == 1 ];
then
	# scipy
	pushd packages >> make_ios.log 2>&1
	pushd scipy  >> make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.9 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_ios.log 2>&1
# 	env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-isysroot $OSX_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-isysroot $OSX_SDKROOT $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.9 -lc++ $DEBUG" NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" PLATFORM=macosx python3.9 -m pip install .  >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
fi # scipy, USE_FORTRAN == 1
fi # App == Carnets


# 3) compile for Simulator:

# 3.1) download and install required packages: 
mkdir -p Frameworks_iphonesimulator
mkdir -p Frameworks_iphonesimulator/include
mkdir -p Frameworks_iphonesimulator/lib
rm -rf Frameworks_iphonesimulator/ios_system.framework
rm -rf Frameworks_iphonesimulator/freetype.framework
rm -rf Frameworks_iphonesimulator/openblas.framework
cp -r $XCFRAMEWORKS_DIR/ios_system.xcframework/ios-x86_64-simulator/ios_system.framework $PREFIX/Frameworks_iphonesimulator
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-x86_64-simulator/freetype.framework $PREFIX/Frameworks_iphonesimulator
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-x86_64-simulator/Headers/ffi $PREFIX/Frameworks_iphonesimulator/include/ffi
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-x86_64-simulator/Headers/ffi/* $PREFIX/Frameworks_iphonesimulator/include/ffi/
cp -r $XCFRAMEWORKS_DIR/crypto.xcframework/ios-x86_64-simulator/Headers $PREFIX/Frameworks_iphonesimulator/include/crypto/
cp -r $XCFRAMEWORKS_DIR/openssl.xcframework/ios-x86_64-simulator/Headers $PREFIX/Frameworks_iphonesimulator/include/openssl/
cp -r $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-x86_64-simulator/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
cp -r $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-x86_64-simulator/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
cp -r $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-x86_64-simulator/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
cp -r $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-x86_64-simulator/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
cp -r $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-x86_64-simulator/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-x86_64-simulator/freetype.framework/Headers/* $PREFIX/Frameworks_iphonesimulator/include/
# Need to copy all libs after each make clean: 
cp $XCFRAMEWORKS_DIR/crypto.xcframework/ios-x86_64-simulator/libcrypto.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/openssl.xcframework/ios-x86_64-simulator/libssl.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libffi.xcframework/ios-x86_64-simulator/libffi.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-x86_64-simulator/libzmq.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-x86_64-simulator/libjpeg.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-x86_64-simulator/libtiff.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-x86_64-simulator/libxslt.a $PREFIX/Frameworks_iphonesimulator/lib/
cp $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-x86_64-simulator/libexslt.a $PREFIX/Frameworks_iphonesimulator/lib/
find . -name \*.o -delete
rm -f Programs/_testembed Programs/_freeze_importlib

# preadv / pwritev are iOS 14+ only
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" \
	CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" \
	CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" \
	LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -lz -L. -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib" \
	PLATFORM=iphonesimulator \
	OPT="$DEBUG" \
	./configure --prefix=$PREFIX/Library --enable-shared \
	--host x86_64-apple-darwin --build x86_64-apple-darwin --enable-ipv6 \
	--with-openssl=$PREFIX/Frameworks_iphonesimulator \
	--without-computed-gotos \
	cross_compiling=yes \
	with_system_ffi=yes \
	ac_cv_file__dev_ptmx=no \
	ac_cv_file__dev_ptc=no \
	ac_cv_func_getentropy=no \
	ac_cv_func_sendfile=no \
	ac_cv_func_setregid=no \
	ac_cv_func_setreuid=no \
	ac_cv_func_setsid=no \
	ac_cv_func_setpgid=no \
	ac_cv_func_setpgrp=no \
	ac_cv_func_setuid=no \
    ac_cv_func_forkpty=no \
    ac_cv_func_openpty=no \
	ac_cv_func_clock_settime=no >& configure_simulator.log
#	--without-pymalloc 
#	--with-assertions 
rm -rf build/lib.darwin-x86_64-3.9
make -j 4 >& make_simulator.log
mkdir -p build/lib.darwin-x86_64-3.9
cp libpython3.9.dylib build/lib.darwin-x86_64-3.9
# Don't install for iOS simulator
# Compilation of specific packages:
cp $PREFIX/build/lib.darwin-x86_64-3.9/_sysconfigdata__darwin_darwin.py $PREFIX/Library/lib/python3.9/_sysconfigdata__darwin_darwin.py
# cffi: compile with iOS SDK
echo Installing cffi for iphonesimulator >> make_simulator.log 2>&1
pushd packages >> make_simulator.log 2>&1
pushd cffi* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
# override setup.py for arm64 == iphoneos, not Apple Silicon
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -lz -L$PREFIX/build/lib.darwin-x86_64-3.9 -lpython3.9 -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib " PLATFORM=iphonesimulator python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/_cffi_backend.cpython-39-darwin.so $PREFIX/build/lib.darwin-x86_64-3.9/  >> $PREFIX/make_simulator.log 2>&1
# rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# rm -rf cffi*  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
echo done compiling cffi for iphonesimulator >> $PREFIX/make_simulator.log 2>&1
# end cffi
# Now we can install PyZMQ. We need to compile it ourselves to make sure it uses CFFI as a backend:
# (the wheel uses Cython)
echo Installing PyZMQ for iphonesimulator  >> $PREFIX/make_simulator.log 2>&1
pushd packages >> $PREFIX/make_simulator.log 2>&1
pushd pyzmq* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/* >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0  -isysroot $SIM_SDKROOT -I$PREFIX" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0  -isysroot $SIM_SDKROOT -I$PREFIX" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0  -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -lz -lpython3.9 -lc++ -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9" PLATFORM=iphonesimulator PYZMQ_BACKEND=cffi python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/zmq/backend/cffi/_cffi_ext.cpython-39-darwin.so $PREFIX/build/lib.darwin-x86_64-3.9/  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
echo Done installing PyZMQ for iOS >> make_simulator.log 2>&1
# end pyzmq
# Installing argon2-cffi:
echo Installing argon2-cffi for iphonesimulator >> make_simulator.log 2>&1
pushd packages >> $PREFIX/make_simulator.log 2>&1
pushd argon2-cffi* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/* >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9" PLATFORM=iphonesimulator ARGON2_CFFI_USE_SSE2=0 python3 setup.py build >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/argon2/  >> $PREFIX/make_simulator.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/argon2/_ffi.abi3.so $PREFIX/build/lib.darwin-x86_64-3.9/argon2/_ffi.abi3.so  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# Numpy:
pushd packages >> make_simulator.log 2>&1
pushd numpy >> $PREFIX/make_simulator.log 2>&1
rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
rm site.cfg  >> $PREFIX/make_simulator.log 2>&1
# For the time being, no gfortran compiler for simulator, so no openblas framework for simulator.
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9 $DEBUG" PLATFORM=iphonesimulator NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/numpy/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/numpy/core/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/numpy/fft/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/numpy/linalg/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/numpy/random/  >> $PREFIX/make_simulator.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/core/*.so $PREFIX/build/lib.darwin-x86_64-3.9/numpy/core/ >> $PREFIX/make_simulator.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/linalg/*.so $PREFIX/build/lib.darwin-x86_64-3.9/numpy/linalg/ >> $PREFIX/make_simulator.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/fft/*.so $PREFIX/build/lib.darwin-x86_64-3.9/numpy/fft/ >> $PREFIX/make_simulator.log 2>&1
cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/numpy/random/*.so $PREFIX/build/lib.darwin-x86_64-3.9/numpy/random/ >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# Matplotlib
## kiwisolver
pushd packages >> make_simulator.log 2>&1
pushd kiwisolver* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/build/lib.darwin-x86_64-3.9 " LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -lz -L$PREFIX/build/lib.darwin-x86_64-3.9 -lpython3.9 -F$PREFIX/Frameworks_iphonesimulator -framework ios_system" PLATFORM=iphonesimulator python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/kiwisolver.cpython-39-darwin.so $PREFIX/build/lib.darwin-x86_64-3.9/  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
## Pillow
pushd packages >> make_simulator.log 2>&1
pushd Pillow* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphonesimulator/lib/ -L$PREFIX/build/lib.darwin-x86_64-3.9 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-x86_64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphonesimulator/lib/ -ljpeg -ltiff" PLATFORM=iphonesimulator python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/PIL/  >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/PIL/*.so  $PREFIX/build/lib.darwin-x86_64-3.9/PIL/ >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
## matplotlib
pushd packages >> make_simulator.log 2>&1
pushd matplotlib  >> $PREFIX/make_simulator.log 2>&1
rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphonesimulator/include/" \
	LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphonesimulator/lib/ -L$PREFIX/build/lib.darwin-x86_64-3.9 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-x86_64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphonesimulator/lib/ -ljpeg -ltiff" PLATFORM=iphonesimulator python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/matplotlib/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/matplotlib/backends/  >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/*.so  $PREFIX/build/lib.darwin-x86_64-3.9/matplotlib/ >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/matplotlib/backends/*.so  $PREFIX/build/lib.darwin-x86_64-3.9/matplotlib/backends/ >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# lxml:
pushd packages >> make_simulator.log 2>&1
pushd lxml*  >> $PREFIX/make_simulator.log 2>&1
rm -rf build/* >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphonesimulator/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphonesimulator/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT  -I$PREFIX/Frameworks_iphonesimulator/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9 $DEBUG" PLATFORM=iphonesimulator python3 setup.py build --with-cython >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/lxml/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/lxml/html/  >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/*.so  $PREFIX/build/lib.darwin-x86_64-3.9/lxml/ >> $PREFIX/make_simulator.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-x86_64-3.9/lxml/html/*.so  $PREFIX/build/lib.darwin-x86_64-3.9/lxml/html/ >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# cryptography: 
pushd packages >> make_simulator.log 2>&1
pushd cryptography* >> $PREFIX/make_simulator.log 2>&1
rm -rf build/* >> $PREFIX/make_simulator.log 2>&1
env CC=clang CXX=clang++ \
CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphonesimulator/include/ -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphonesimulator/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM " \
CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphonesimulator/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/build/lib.darwin-x86_64-3.9 -L$PREFIX/Frameworks_iphonesimulator/lib/" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/build/lib.darwin-x86_64-3.9 -lz -lpython3.9 -L$PREFIX/Frameworks_iphonesimulator/lib/" \
PLATFORM=iphonesimulator python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/cryptography/  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/cryptography/hazmat  >> $PREFIX/make_simulator.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/cryptography/hazmat/bindings  >> $PREFIX/make_simulator.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/cryptography/hazmat/bindings/*.so $PREFIX/build/lib.darwin-x86_64-3.9/cryptography/hazmat/bindings >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
popd  >> $PREFIX/make_simulator.log 2>&1
# Pandas (but only with Carnets):
if [ $APP == "Carnets" ]; 
then
	pushd packages >> make_simulator.log 2>&1
	pushd pandas*  >> $PREFIX/make_simulator.log 2>&1
	rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
    # Need to load parser/tokenizer.h before Parser/tokenizer.h
    PANDAS=$PWD
	env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX $DEBUG" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9 $DEBUG" PLATFORM=iphonesimulator NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/io  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/io/sas  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs/window  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs/tslibs  >> $PREFIX/make_simulator.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/io/sas/_sas.cpython-39-darwin.so $PREFIX/build/lib.darwin-x86_64-3.9/pandas/io/sas >> $PREFIX/make_simulator.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/*.so $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs >> $PREFIX/make_simulator.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/window/*.so $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs/window >> $PREFIX/make_simulator.log 2>&1
	cp build/lib.macosx-${OSX_VERSION}-x86_64-3.9/pandas/_libs/tslibs/*.so $PREFIX/build/lib.darwin-x86_64-3.9/pandas/_libs/tslibs >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1
	# bokeh, dill: pure Python installs
	# pyerfa (for astropy)
	pushd packages >> $PREFIX/make_simulator.log 2>&1
	pushd pyerfa*  >> $PREFIX/make_simulator.log 2>&1
	rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX $DEBUG" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ $DEBUG" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9 $DEBUG" PLATFORM=iphonesimulator python3.9 setup.py build >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/erfa/  >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/erfa/ufunc.cpython-39-darwin.so \
$PREFIX/build/lib.darwin-x86_64-3.9/erfa >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1	
	# astropy
	pushd packages >> $PREFIX/make_simulator.log 2>&1
	pushd astropy*  >> $PREFIX/make_simulator.log 2>&1
	rm -rf build/*  >> $PREFIX/make_simulator.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -I$PANDAS/pandas/_libs/src/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot $SIM_SDKROOT -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.9  -F$PREFIX/Frameworks_iphonesimulator -framework ios_system -L$PREFIX/Frameworks_iphonesimulator/lib -L$PREFIX/build/lib.darwin-x86_64-3.9 $DEBUG" PLATFORM=iphonesimulator NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3 setup.py build  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/timeseries/periodograms/bls  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/wcs  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/time  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/utils  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/utils/xml  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/ascii  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/fits  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/votable  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/modeling  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/table  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/cosmology  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/convolution  >> $PREFIX/make_simulator.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-x86_64-3.9/astropy/stats  >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/compiler_version.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/bls/_impl.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/timeseries/periodograms/bls/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/cython_impl.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/timeseries/periodograms/lombscargle/implementations/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/wcs/_wcs.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/wcs/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/time/_parse_times.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/time/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/ascii/cparser.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/ascii/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/compression.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/fits/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/fits/_utils.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/fits/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/io/votable/tablewriter.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/io/votable/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/_compiler.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/utils/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/utils/xml/_iterparser.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/utils/xml/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/modeling/_projections.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/modeling/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/_np_utils.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/table/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/table/_column_mixins.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/table/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/cosmology/scalar_inv_efuncs.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/cosmology/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/convolution/_convolve.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/convolution/ >> $PREFIX/make_simulator.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-x86_64-3.9/astropy/stats/_stats.cpython-39-darwin.so \
      $PREFIX/build/lib.darwin-x86_64-3.9/astropy/stats/ >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1
	popd  >> $PREFIX/make_simulator.log 2>&1
fi
# for a-Shell specifically: install dulwich (for git) and almost-make
if [ $APP == "a-Shell" ]; 
then
cp $PREFIX/Library/bin/almake $PREFIX/Library/bin/make  >> $PREFIX/make_install_osx.log 2>&1
fi


# Python build finished successfully!
# The necessary bits to build these optional modules were not found:
# _bz2                  _curses               _curses_panel      
# _gdbm                 _lzma                 _tkinter           
# _uuid                 nis                   ossaudiodev        
# readline              spwd                                     
# To find the necessary bits, look in setup.py in detect_modules() for the module's name.
# 
# 
# The following modules found by detect_modules() in setup.py, have been
# built by the Makefile instead, as configured by the Setup files:
# _abc                  atexit                pwd                
# time                                                           


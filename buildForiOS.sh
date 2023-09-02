#! /bin/sh
export PS4="  \$ "
set -ev

# jupyter-something adds pandas-2.0.0 and pyzmq-25.0b1, which breaks things down 
# So far, the "fix" is to manually remove them. Add this to the script?
# Don't forget to edit easy-install.pth too!

# Changed install prefix so multiple install coexist
export PREFIX=$PWD
export XCFRAMEWORKS_DIR=$PREFIX/Python-aux/
# $PREFIX/Library/bin so that the new python is in the path, 
# ~/.cargo/bin for rustc
export PATH=$PREFIX/Library/bin:~/.cargo/bin:$PATH
export PYTHONPYCACHEPREFIX=$PREFIX/__pycache__
export OSX_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
export DEBUG="-O3 -Wall"
# DEBUG="-g"
# TODO: remove -3.11 from $PREFIX/build directories, use $ARCH in directory names.
# export ARCH=$(uname -m)
# Loading different set of frameworks based on the Application:
APP=$(basename `dirname $PWD`)
#
# Set to 1 if you have gfortran for arm64 installed. gfortran support is highly experimental.
# You might need to edit the script as well.
USE_FORTRAN=0
if [ -e "/usr/local/aarch64-apple-darwin20/lib/libgfortran.dylib" ];then
	USE_FORTRAN=1
fi

# 2) compile for iOS:
export OSX_VERSION=$(sw_vers -productVersion |awk -F. '{print $1"."$2}')
unset LIBRARY_PATH
mkdir -p Frameworks_iphoneos
mkdir -p Frameworks_iphoneos/include
mkdir -p Frameworks_iphoneos/lib
rm -rf Frameworks_iphoneos/ios_system.framework
rm -rf Frameworks_iphoneos/freetype.framework
rm -rf Frameworks_iphoneos/openblas.framework
cp -r $XCFRAMEWORKS_DIR/ios_system.xcframework/ios-arm64/ios_system.framework $PREFIX/Frameworks_iphoneos
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
cp -r $XCFRAMEWORKS_DIR/libfftw3.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-arm64/freetype.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/liblzma.xcframework/ios-arm64/Headers/lz* $PREFIX/Frameworks_iphoneos/include/
# Need to copy all libs after each make clean: 
cp $XCFRAMEWORKS_DIR/crypto.xcframework/ios-arm64/libcrypto.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/openssl.xcframework/ios-arm64/libssl.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/libffi.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-arm64/libzmq.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-arm64/libjpeg.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-arm64/libtiff.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-arm64/libxslt.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-arm64/libexslt.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libfftw3.xcframework/ios-arm64/libfftw3.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libfftw3_threads.xcframework/ios-arm64/libfftw3_threads.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/liblzma.xcframework/ios-arm64/liblzma.a $PREFIX/Frameworks_iphoneos/lib/
# The build scripts from numpy need openblas to be in a dylib, not a framework (to detect lapack functions)
# So we create the dylib from the framework:
cp $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp  $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/openblas $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
install_name_tool -id $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib   $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
# But the build scripts from scipy want openblas to be in a framework, so we also copy it here:
cp -r $XCFRAMEWORKS_DIR//openblas.xcframework/ios-arm64/openblas.framework $PREFIX/Frameworks_iphoneos/
#
cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/ios-arm64/libgeos_c.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/ios-arm64/libgeos_c.framework  $PREFIX/Frameworks_iphoneos/
rm -rf $PREFIX/Frameworks_iphoneos/include/gdal
cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/ios-arm64/libgdal.framework/Headers $PREFIX/Frameworks_iphoneos/include/gdal
cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/ios-arm64/libgdal.framework  $PREFIX/Frameworks_iphoneos/
cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/ios-arm64/libproj.framework/Headers/* $PREFIX/Frameworks_iphoneos/include
cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/ios-arm64/libproj.framework  $PREFIX/Frameworks_iphoneos/

find . -name \*.o -delete
rm libpython3.11.dylib || true
rm libpython3.11.a || true
rm -f Programs/_testembed Programs/_freeze_importlib
# preadv / pwritev are iOS 14+ only
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -lz -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L. -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	PLATFORM=iphoneos \
	OPT="$DEBUG" \
	./configure --prefix=$PREFIX/Library --enable-shared \
	--host arm-apple-darwin --build x86_64-apple-darwin --enable-ipv6 \
	--with-openssl=$PREFIX/Frameworks_iphoneos \
	--with-build-python=$PREFIX/python3.11 \
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
    ac_cv_func_forkpty=no \
    ac_cv_func_openpty=no \
	ac_cv_func_clock_settime=no >& configure_ios.log
# --without-pymalloc  when debugging memory
# --enable-framework fails with iOS compilers
rm -rf build/lib.darwin-arm64-3.11
make >& make_ios.log
mkdir -p  build/lib.darwin-arm64-3.11
cp libpython3.11.dylib build/lib.darwin-arm64-3.11
# Don't install for iOS
# Compilation of specific packages:
cp $PREFIX/build/lib.darwin-arm64-3.11/_sysconfigdata__darwin_darwin.py $PREFIX/Library/lib/python3.11/_sysconfigdata__darwin_darwin.py
if [ $APP == "Carnets" ]; 
then
cp $PREFIX/build/lib.darwin-arm64-3.11/_sysconfigdata__darwin_darwin.py $PREFIX/with_scipy/Library/lib/python3.11/_sysconfigdata__darwin_darwin.py
fi
USE_RUST_MODULES=0
if [ $USE_RUST_MODULES == 1 ]; 
then
	# rpds-py: new requirement for jsonschema, itself a requirement everywhere.
	# Uses maturin, installed in the host Python 3.7 distribution
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd rpds_py* >> $PREFIX/make_ios.log 2>&1
	env SDKROOT="$OSX_SDKROOT" \
		PYO3_CROSS_LIB_DIR="$PREFIX/build/lib.darwin-arm64-3.11/" \
		CARGO_BUILD_TARGET="aarch64-apple-ios" \
		CARGO_TARGET_AARCH64_APPLE_IOS_RUSTFLAGS="-C link-arg=-isysroot -C link-arg=$IOS_SDKROOT -C link-arg=-arch -C link-arg=arm64 -C link-arg=-miphoneos-version-min=14.0 -C link-arg=-L -C link-arg=$PREFIX/build/lib.darwin-arm64-3.11/ -C link-arg=-lpython3.11" \
		CROSS_DEBUG=1 maturin build --verbose >> $PREFIX/make_ios.log 2>&1
			cp target/aarch64-apple-ios/debug/maturin/librpds.dylib $PREFIX/build/lib.darwin-arm64-3.11/rpds.cpython-311-darwin.so >> $PREFIX/make_ios.log 2>&1
			popd  >> $PREFIX/make_ios.log 2>&1
			popd  >> $PREFIX/make_ios.log 2>&1
fi
# cffi: compile with iOS SDK
echo Installing cffi for iphoneos >> $PREFIX/make_ios.log 2>&1
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd cffi* >> $PREFIX/make_ios.log 2>&1
# override setup.py for arm64 == iphoneos, not Apple Silicon
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11" PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/_cffi_backend.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/  >> $PREFIX/make_ios.log 2>&1
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
export PYZMQ_BACKEND=cffi  >> $PREFIX/make_ios.log 2>&1
export PYZMQ_BACKEND_CFFI=1 >> $PREFIX/make_ios.log 2>&1
env PYZMQ_BACKEND_CFFI=1 CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG  -I$PREFIX" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11 -lc++ -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11" PLATFORM=iphoneos PYZMQ_BACKEND=cffi python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/zmq/backend/cffi >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/zmq/backend/cffi/_cffi.*.so $PREFIX/build/lib.darwin-arm64-3.11/zmq/backend/cffi/  >> $PREFIX/make_ios.log 2>&1
echo PyZMQ libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
echo Done installing PyZMQ for iOS >> $PREFIX/make_ios.log 2>&1
# end pyzmq
# Installing argon2-cffi-bindings:
echo Installing argon2-cffi-bindings for iphoneos >> $PREFIX/make_ios.log 2>&1
pushd packages  >> $PREFIX/make_ios.log 2>&1
pushd argon2-cffi-bindings* >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11" PLATFORM=iphoneos ARGON2_CFFI_USE_SSE2=0 python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/_argon2_cffi_bindings/  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/_argon2_cffi_bindings/_ffi.abi3.so $PREFIX/build/lib.darwin-arm64-3.11/_argon2_cffi_bindings/_ffi.abi3.so >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Numpy:
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd numpy >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
if [ $USE_FORTRAN == 0 ];
then
	rm -f site.cfg  >> $PREFIX/make_ios.log 2>&1
	env CC="clang -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX $DEBUG"\
	CXX="clang++ -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX $DEBUG" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG"\
	PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" BLAS=None LAPACK=None ATLAS=None \
	SETUPTOOLS_USE_DISTUTILS=stdlib python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
else 
	cp site_original.cfg site.cfg >> $PREFIX/make_ios.log 2>&1
	sed -i bak "s|__main_directory__|${PREFIX}/Frameworks_iphoneos|" site.cfg >> $PREFIX/make_ios.log 2>&1

	env CC="clang -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG"\
		CXX="clang++ -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG"\
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
		PLATFORM=iphoneos NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" \
		SETUPTOOLS_USE_DISTUTILS=stdlib python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	# Copy *.a libraries so scipy can find them:
	echo Where are the numpy libraries? >> $PREFIX/make_ios.log 2>&1
	find build -name \*.a >> $PREFIX/make_ios.log 2>&1
    # copy the two libraries so scipy can find them
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/numpy >> $PREFIX/make_ios.log 2>&1
	cp build/temp.macosx-${OSX_VERSION}-arm64-3.11/libnpyrandom.a $PREFIX/build/lib.darwin-arm64-3.11/numpy/libnpyrandom.a >> $PREFIX/make_ios.log 2>&1
	cp build/temp.macosx-${OSX_VERSION}-arm64-3.11/libnpymath.a  $PREFIX/build/lib.darwin-arm64-3.11/numpy/libnpymath.a >> $PREFIX/make_ios.log 2>&1
fi
echo numpy libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
pushd build/lib.macosx-${OSX_VERSION}-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
for library in `find numpy -name \*.so`
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
popd  >> $PREFIX/make_ios.log 2>&1
# Making a single numpy dynamic library:
echo Makign a single numpy library for iOS: >> $PREFIX/make_ios.log 2>&1
if [ $USE_FORTRAN == 1 ];
then
	OPENBLAS="-L $PREFIX/Frameworks_iphoneos/lib -lopenblas"
	mv build/temp.macosx-${OSX_VERSION}-arm64-3.11/numpy/core/src/common/python_xerbla.o build/temp.macosx-${OSX_VERSION}-arm64-3.11/numpy/core/src/common/python_xerbla.op
else
	OPENBLAS=""
fi
clang -v -undefined error -dynamiclib \
-isysroot $IOS_SDKROOT \
-lz -lm \
-lpython3.11 \
 -F$PREFIX/Frameworks_iphoneos -framework ios_system \
-L$PREFIX/Frameworks_iphoneos/lib \
-L$PREFIX/build/lib.darwin-arm64-3.11 \
-O3 -Wall -arch arm64 \
-miphoneos-version-min=14.0 \
`find build -name \*.o` \
-L$PREFIX/Library/lib \
-Lbuild/temp.macosx-${OSX_VERSION}-arm64-3.11 \
-lnpymath \
-lnpyrandom \
$OPENBLAS \
-o build/numpy.so  >> $PREFIX/make_ios.log 2>&1
cp build/numpy.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
if [ $USE_FORTRAN == 1 ];
then
	# change references to openblas back to the framework:
	install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.11/numpy/core/_multiarray_umath.cpython-311-darwin.so  >> $PREFIX/make_ios.log 2>&1
	install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.11/numpy/linalg/_umath_linalg.cpython-311-darwin.so  >> $PREFIX/make_ios.log 2>&1
	install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.11/numpy/linalg/lapack_lite.cpython-311-darwin.so  >> $PREFIX/make_ios.log 2>&1
	install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas   build/lib.darwin-arm64-3.11/numpy.so  >> $PREFIX/make_ios.log 2>&1
fi
# Matplotlib
## kiwisolver
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd kiwisolver* >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 " LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11" PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/kiwisolver/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/kiwisolver/_cext.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/kiwisolver/  >> $PREFIX/make_ios.log 2>&1
echo kiwisolver libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
## Pillow
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd Pillow* >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphoneos/lib/ -L$PREFIX/build/lib.darwin-arm64-3.11 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 -L$PREFIX/Frameworks_iphoneos/lib/ -ljpeg -ltiff" PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
echo Pillow libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/PIL/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/PIL/*.so  $PREFIX/build/lib.darwin-arm64-3.11/PIL/ >> $PREFIX/make_ios.log 2>&1
# _imagingmath.cpython-311-darwin.so
# _imagingft.cpython-311-darwin.so
# _imagingtk.cpython-311-darwin.so
# _imagingmorph.cpython-311-darwin.so
# _imaging.cpython-311-darwin.so
#
# Single library PIL.so
clang -v -undefined error -dynamiclib \
	-isysroot $IOS_SDKROOT \
	-lz -lm \
	-lpython3.11 \
	-F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype \
	-L$PREFIX/Frameworks_iphoneos/lib -ljpeg -ltiff \
	-L$PREFIX/build/lib.darwin-arm64-3.11 \
	-O3 -Wall -arch arm64 \
	-miphoneos-version-min=14.0 \
	`find build -name \*.o` \
	-L$PREFIX/Library/lib \
	-o build/PIL.so  >> $PREFIX/make_ios.log 2>&1
cp build/PIL.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1

## contourpy: 
pushd packages >> $PREFIX/make_ios.log 2>&1
# Because meson cannot handle environment variables
cp iphone-osx_basis.meson iphone-osx.meson  >> $PREFIX/make_ios.log 2>&1
sed -i bak "s|__prefix__|${PREFIX}|" iphone-osx.meson >> $PREFIX/make_ios.log 2>&1
# ./src/_contourpy.cpython-311-darwin.so
pushd contourpy*  >> $PREFIX/make_ios.log 2>&1
rm -rf build  >> $PREFIX/make_ios.log 2>&1
mkdir build >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ meson . build --cross-file ../iphone-osx.meson >> $PREFIX/make_ios.log 2>&1
pushd build  >> $PREFIX/make_ios.log 2>&1
# Something between ninja and meson is preventing the creation of dynamic libraries, creates bundles instead:
sed -i bak "s/bundle/shared/" build.ninja >> $PREFIX/make_ios.log 2>&1
ninja  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/contourpy/  >> $PREFIX/make_ios.log 2>&1
echo contourpy libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
cp ./build/src/*.so  $PREFIX/build/lib.darwin-arm64-3.11/contourpy/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
## matplotlib
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd matplotlib  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/Frameworks_iphoneos/lib/ -L$PREFIX/build/lib.darwin-arm64-3.11 " \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework freetype -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 -L$PREFIX/Frameworks_iphoneos/lib/ -ljpeg -ltiff" PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
echo matplotlib libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
for library in `find matplotlib -name \*.so`
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# lxml:
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd lxml*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" PLATFORM=iphoneos python3.11 setup.py build  --with-cython >> $PREFIX/make_ios.log 2>&1
echo lxml libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/lxml/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/lxml/html/  >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/lxml/*.so  $PREFIX/build/lib.darwin-arm64-3.11/lxml/ >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/lxml/html/*.so  $PREFIX/build/lib.darwin-arm64-3.11/lxml/html/ >> $PREFIX/make_ios.log 2>&1
# Single library for lxml:
clang -v -undefined error -dynamiclib \
	-arch arm64 -miphoneos-version-min=14.0 \
	-isysroot $IOS_SDKROOT \
	-lz -lm -lc++ -lpython3.11 \
	-F$PREFIX/Frameworks_iphoneos -framework ios_system  \
	-L$PREFIX/Frameworks_iphoneos/lib -lxslt -lexslt \
	-L$PREFIX/build/lib.darwin-arm64-3.11 \
	-O3 -Wall \
	`find build -name \*.o` \
	-L$PREFIX/Library/lib \
	-lxml2  \
	-o build/lxml.so >> $PREFIX/make_ios.log 2>&1
cp build/lxml.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# cryptography:
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd cryptography* >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
# As of Feb. 11, 2021, rustc is unable to cross-compile a dynamic library for iOS. We stick to the old version.
env CRYPTOGRAPHY_DONT_BUILD_RUST=1 CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/ -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM " \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/  -DCRYPTOGRAPHY_OSRANDOM_ENGINE=CRYPTOGRAPHY_OSRANDOM_ENGINE_DEV_URANDOM" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -L$PREFIX/Frameworks_iphoneos/lib/" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 -L$PREFIX/Frameworks_iphoneos/lib/" \
PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
echo cryptography libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/cryptography/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/cryptography/hazmat  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/cryptography/hazmat/bindings  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/cryptography/hazmat/bindings/*.so $PREFIX/build/lib.darwin-arm64-3.11/cryptography/hazmat/bindings  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# pycryptodome:
if [ $APP == "a-Shell" ]; 
then
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd pycryptodome-* >> $PREFIX/make_ios.log 2>&1
	rm -rf build/* >> $PREFIX/make_ios.log 2>&1
	rm .separate_namespace >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
		CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -L$PREFIX/Frameworks_iphoneos/lib/" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 $DEBUG" \
		PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
	echo pycryptodome libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
	for library in `find Crypto -name \*.so`
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	# pycryptodomex:
	rm -rf build/* >> $PREFIX/make_ios.log 2>&1
	touch .separate_namespace  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
		CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -L$PREFIX/Frameworks_iphoneos/lib/" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 $DEBUG" \
		PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
	echo pycryptodomex libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
	for library in `find Cryptodome -name \*.so`
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
fi # a-Shell (pycryptodome)
# regex (for nltk)
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd regex*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX  -I$PREFIX/Frameworks_iphoneos/include/" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -L$PREFIX/Frameworks_iphoneos/lib/" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/build/lib.darwin-arm64-3.11 -lz -lpython3.11 $DEBUG" \
	PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
# copy the library in the right place:
find . -name \*.so >> $PREFIX/make_ios.log 2>&1                                                                               
mkdir -p  $PREFIX/build/lib.darwin-arm64-3.11/regex/ >> $PREFIX/make_ios.log 2>&1
cp build//lib.macosx-${OSX_VERSION}-arm64-cpython-311/regex/_regex.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/regex/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# wordcloud
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd word_cloud  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG"\
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG"\
	PLATFORM=iphoneos python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >>  $PREFIX/make_ios.log 2>&1
mkdir -p  $PREFIX/build/lib.darwin-arm64-3.11/wordcloud/ >> $PREFIX/make_ios.log 2>&1
cp build//lib.macosx-${OSX_VERSION}-arm64-cpython-311/wordcloud/query_integral_image.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/wordcloud/ >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# pyfftw: uses libfftw. (not in mini)
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd pyFFTW-*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
# pyfftw build system ignores CFLAGS and LDFLAGS, so we put everything inside CC.
env SDKROOT=$IOS_SDKROOT \
	CC="clang -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ -Wno-error=implicit-function-declaration $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CXX="clang++ -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ -Wno-error=implicit-function-declaration $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG"\
	PLATFORM=iphoneos PYFFTW_INCLUDE=$PREFIX/Frameworks_iphoneos/include/ \
	PYFFTW_LIB_DIR=$PREFIX/Frameworks_iphoneos/lib python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
# ./build/lib.macosx-11.3-arm64-3.11/pyfftw/pyfftw.cpython-311-darwin.so
find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
mkdir -p  $PREFIX/build/lib.darwin-arm64-3.11/pyfftw/ >> $PREFIX/make_ios.log 2>&1
cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/pyfftw/pyfftw.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/pyfftw/  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# cvxopt: Requires BLAS, Lapack, uses libfftw3.a if present, uses SuiteSparse source (new submodule)
if [ $USE_FORTRAN == 1 ];
then
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd cvxopt-* >>  $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
		CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/" \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ $DEBUG" \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include/ $DEBUG" \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
		PLATFORM=macosx \
		CVXOPT_BLAS_LIB=openblas \
		CVXOPT_BLAS_LIB_DIR=$PREFIX/Frameworks_iphoneos/lib \
		CVXOPT_LAPACK_LIB=openblas \
		CVXOPT_LAPACK_LIB_DIR=$PREFIX/Frameworks_iphoneos/lib \
		CVXOPT_BUILD_FFTW=1 \
		CVXOPT_FFTW_LIB_DIR=$PREFIX/Frameworks_iphoneos/lib \
		CVXOPT_FFTW_INC_DIR=$PREFIX/Frameworks_iphoneos/include \
		CVXOPT_SUITESPARSE_SRC_DIR=$PREFIX/packages/SuiteSparse \
		python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo "iOS libraries for cvxopt:"  >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
    # cvxopt/cholmod.cpython-311-darwin.so
    # cvxopt/misc_solvers.cpython-311-darwin.so
    # cvxopt/amd.cpython-311-darwin.so
    # cvxopt/base.cpython-311-darwin.so
    # cvxopt/umfpack.cpython-311-darwin.so
    # cvxopt/fftw.cpython-311-darwin.so
    # cvxopt/blas.cpython-311-darwin.so
    # cvxopt/lapack.cpython-311-darwin.so
    for library in cvxopt/cholmod.cpython-311-darwin.so cvxopt/misc_solvers.cpython-311-darwin.so cvxopt/amd.cpython-311-darwin.so cvxopt/base.cpython-311-darwin.so cvxopt/umfpack.cpython-311-darwin.so cvxopt/fftw.cpython-311-darwin.so cvxopt/blas.cpython-311-darwin.so cvxopt/lapack.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
		# Fix the reference to libopenblas.dylib -> openblas.framework
		if [[ $(otool -l $PREFIX/build/lib.darwin-arm64-3.11/$library | grep libopenblas) ]];
		then 
			install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas  $PREFIX/build/lib.darwin-arm64-3.11/$library  >> $PREFIX/make_ios.log 2>&1
		fi		
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
fi
# Pandas:
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd pandas*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
# Needed to load parser/tokenizer.h before Parser/tokenizer.h:
PANDAS=$PWD
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX $DEBUG -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
echo pandas libraries for iOS: >> $PREFIX/make_ios.log 2>&1
find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/io  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/io/sas  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs/window  >> $PREFIX/make_ios.log 2>&1
mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs/tslibs  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/pandas/io/sas/_sas.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/pandas/io/sas >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/pandas/_libs/*.so $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/pandas/_libs/window/*.so $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs/window >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/pandas/_libs/tslibs/*.so $PREFIX/build/lib.darwin-arm64-3.11/pandas/_libs/tslibs >> $PREFIX/make_ios.log 2>&1
# Making a single pandas dynamic library:
echo Making a single pandas library for iOS: >> $PREFIX/make_ios.log 2>&1
clang -v -undefined error -dynamiclib \
-isysroot $IOS_SDKROOT \
-lz -lm -lc++ \
-lpython3.11 \
 -F$PREFIX/Frameworks_iphoneos -framework ios_system \
-L$PREFIX/Frameworks_iphoneos/lib \
-L$PREFIX/build/lib.darwin-arm64-3.11 \
-O3 -Wall -arch arm64 \
-miphoneos-version-min=14.0 \
`find build -name \*.o` \
-L$PREFIX/Library/lib \
-Lbuild/temp.macosx-${OSX_VERSION}-arm64-cpython-311 \
-o build/pandas.so  >> $PREFIX/make_ios.log 2>&1
cp build/pandas.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
	# bokeh, dill: pure Python installs
	# pyerfa (for astropy)
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd pyerfa-*  >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" PLATFORM=iphoneos python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo pyerfa libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/erfa/  >> $PREFIX/make_ios.log 2>&1
    cp  build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/erfa/ufunc.cpython-311-darwin.so \
$PREFIX/build/lib.darwin-arm64-3.11/erfa/ >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1	
	# astropy
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd astropy*  >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PANDAS/pandas/_libs/src/ -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib $DEBUG" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" PLATFORM=iphoneos NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
	echo astropy libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
	for library in `find astropy -name \*.so`
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd >> $PREFIX/make_ios.log 2>&1
	  # Making a single astropy dynamic library:
	  echo Making a single astropy library for iOS: >> $PREFIX/make_ios.log 2>&1
	  clang -v -undefined error -dynamiclib \
		  -isysroot $IOS_SDKROOT \
		  -lz -lm -lc++ \
		  -lpython3.11 \
		  -F$PREFIX/Frameworks_iphoneos -framework ios_system \
		  -L$PREFIX/Frameworks_iphoneos/lib \
		  -L$PREFIX/build/lib.darwin-arm64-3.11 \
		  -O3 -Wall -arch arm64 \
		  -miphoneos-version-min=14.0 \
		  `find build -name \*.o` \
		  -L$PREFIX/Library/lib \
		  -Lbuild/temp.macosx-${OSX_VERSION}-arm64-cpython-311 \
		  -o build/astropy.so  >> $PREFIX/make_ios.log 2>&1
	cp build/astropy.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
# geopandas and cartopy: require Shapely, fiona, shapely
# Shapely (interface for geos)
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd shapely-* >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
	CPPFLAGS="-isysroot $IOS_SDKROOT -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework libgeos_c" \
	LDSHARED="clang -v -undefined error -dynamiclib -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -lz -L$PREFIX -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system $DEBUG -framework libgeos_c" \
	PLATFORM=iphoneos \
	NO_GEOS_CONFIG=1 \
	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
echo "Shapely libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
for library in `find . -name \*.so`
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Fiona (interface for GDAL)
pushd packages >> $PREFIX/make_ios.log 2>&1
# We need to install from the repository, because the source from pip do not include the .pyx files.
pushd Fiona >> $PREFIX/make_ios.log 2>&1
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework libgdal" \
LDSHARED="clang -v -arch arm64 -miphoneos-version-min=14.0 -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L$PREFIX -lpython3.11 $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework ios_system -framework libgdal" \
PLATFORM=macosx \
GDAL_VERSION=3.6.0 \
	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
echo "Fiona libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
for library in `find fiona -name \*.so`
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
clang -v -undefined error -dynamiclib \
	-arch arm64 -miphoneos-version-min=14.0 \
	-isysroot $IOS_SDKROOT \
	-lz -lm -lc++  \
	-O3 -Wall \
	`find build -name \*.o` \
	-L$PREFIX -lpython3.11 \
	-F$PREFIX/Frameworks_iphoneos -framework libgdal \
	-o build/fiona.so >> $PREFIX/make_ios.log 2>&1
cp build/fiona.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# PyProj (interface for Proj)
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd pyproj-*  >> $PREFIX/make_ios.log 2>&1
rm -rf build/* >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework libgdal" \
LDSHARED="clang -v -arch arm64 -miphoneos-version-min=14.0 -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L$PREFIX -lpython3.11 $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework ios_system -framework libproj" \
PLATFORM=iphoneos \
PROJ_VERSION=9.1.0 \
	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
echo "pyproj libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
   for library in pyproj/_transformer.cpython-311-darwin.so pyproj/_datadir.cpython-311-darwin.so pyproj/list.cpython-311-darwin.so pyproj/_compat.cpython-311-darwin.so pyproj/_crs.cpython-311-darwin.so pyproj/_network.cpython-311-darwin.so pyproj/_geod.cpython-311-darwin.so pyproj/database.cpython-311-darwin.so pyproj/_sync.cpython-311-darwin.so
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
clang -v -undefined error -dynamiclib \
	-arch arm64 -miphoneos-version-min=14.0 \
	-isysroot $IOS_SDKROOT \
	-lz -lm -lc++ -lpython3.11 \
	-L$PREFIX/build/lib.darwin-arm64-3.11 \
	-O3 -Wall \
	`find build -name \*.o` \
	-F$PREFIX/Frameworks_iphoneos -framework libproj \
	-o build/pyproj.so >> $PREFIX/make_ios.log 2>&1
cp build/pyproj.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
# Packages used by geopandas:
# rasterio: must use submodule since the Pip version does not include the Cython sources:
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd rasterio >> $PREFIX/make_ios.log 2>&1
rm -rf build/ >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/gdal -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework libgdal" \
	LDSHARED="clang -v -arch arm64 -miphoneos-version-min=14.0 -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L$PREFIX -lpython3.11 $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework ios_system -framework libgdal" \
	PLATFORM=iphoneos \
	GDAL_VERSION=3.6.0 \
	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
echo "rasterio libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
pushd build/lib.macosx-${OSX_VERSION}-arm64-cpython-311 >> $PREFIX/make_ios.log 2>&1
for library in `find rasterio -name \*.so`
do
	directory=$(dirname $library)
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
	cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
done
popd >> $PREFIX/make_ios.log 2>&1
clang -v -undefined error -dynamiclib \
		-arch arm64 -miphoneos-version-min=14.0 \
		-isysroot $IOS_SDKROOT \
		-lz -lm -lc++ -lpython3.11 \
		-L$PREFIX/build/lib.darwin-arm64-3.11 \
		-O3 -Wall \
		`find build -name \*.o` \
		-L$PREFIX/Library/lib \
		-F$PREFIX/Frameworks_iphoneos -framework libgdal \
		-o build/rasterio.so >> $PREFIX/make_ios.log 2>&1
cp build/rasterio.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
popd >> $PREFIX/make_ios.log 2>&1
popd >> $PREFIX/make_ios.log 2>&1
# 
if [ $USE_FORTRAN == 1 ];
then
    pushd packages >> $PREFIX/make_ios.log 2>&1
    pushd opencv-python  >> $PREFIX/make_ios.log 2>&1
    # Compiling OpenCV for iOS, 
    # use Makefiles rather than Ninja because we need the dynamic library to be a -dynamiclib, not a -bundle.
    rm -rf _skbuild/*  >> $PREFIX/make_ios.log 2>&1
    env CC=clang CXX=clang++ CPPFLAGS="-isysroot $IOS_SDKROOT -I $PREFIX/Frameworks_iphoneos/include" \
    	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I $PREFIX/Frameworks_iphoneos/include/ -I$PREFIX/ -DPNG_ARM_NEON_OPT=0" \
    	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -I $PREFIX/Frameworks_iphoneos/include -I$PREFIX/" \
    	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -L$PREFIX -lpython3.11" \
    	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L$PREFIX -lpython3.11 $DEBUG -F $PREFIX/Frameworks_iphoneos/ " \
    	CMAKE_INSTALL_PREFIX=@rpath \
    	CMAKE_BUILD_TYPE=Release \
    	CMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
    	CMAKE_C_COMPILER=clang \
    	ENABLE_CONTRIB=1 \
    	ENABLE_HEADLESS=1 \
    	PYTHON_DEFAULT_EXECUTABLE=python3.11 \
    	CMAKE_CXX_COMPILER=clang++ \
    	CMAKE_C_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -I$PREFIX/Frameworks_iphoneos/libssh2.framework/Headers -I$PREFIX/Frameworks_iphoneos/include/ -I$PREFIX/ -DPNG_ARM_NEON_OPT=0" \
    	CMAKE_MODULE_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -L$PREFIX -lpython3.11 " \
    	CMAKE_SHARED_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -L$PREFIX -lpython3.11 " \
    	CMAKE_EXE_LINKER_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX -lpython3.11" \
    	CMAKE_LIBRARY_PATH="${IOS_SDKROOT}/lib/:$PREFIX/Frameworks_iphoneos/lib/" \
    	CMAKE_INCLUDE_PATH="${IOS_SDKROOT}/include/:$PREFIX/Frameworks_iphoneos/include" \
        SETUPTOOLS_USE_DISTUTILS=stdlib \
    	PLATFORM=iphoneos \
    	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
    echo "Done first pass, let's create the cv2 library" >> $PREFIX/make_ios.log 2>&1
# I've been unable to convince Cmake + Ninja to create a dynamic library instead of a bundle. Time for some ugly hacking:
    pushd _skbuild/iphoneos-14.0-arm64-3.11/cmake-build >> $PREFIX/make_ios.log 2>&1
	clang++ \
		-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -O3 -Wall -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wuninitialized -Wno-delete-non-virtual-dtor -Wno-unnamed-type-template-args -Wno-comment -fdiagnostics-show-option -Wno-long-long -Qunused-arguments -Wno-semicolon-before-method-body  -fvisibility=hidden -fvisibility-inlines-hidden -Wno-unused-function -Wno-deprecated-declarations -Wno-overloaded-virtual -Wno-unused-private-field -Wno-undef -O3 -DNDEBUG  \
		-dynamiclib -Wl,-headerpad_max_install_names \
		 -F $PREFIX/Frameworks_iphoneos/ -L$PREFIX -lpython3.11  -undefined error \
		-o lib/python3/cv2.cpython-311-darwin.so \
		modules/python3/CMakeFiles/opencv_python3.dir/__/src2/*.cpp.o lib/*.a 3rdparty/lib/*.a \
		-framework Accelerate  -framework AVFoundation  -framework CoreGraphics  -framework CoreImage  -framework CoreMedia  -framework CoreVideo  -framework UIKit  -framework QuartzCore  lib/libopencv_video.a  lib/libopencv_dnn.a  3rdparty/lib/liblibprotobuf.a  lib/libopencv_calib3d.a  lib/libopencv_features2d.a  lib/libopencv_flann.a  lib/libopencv_imgproc.a  lib/libopencv_core.a  3rdparty/lib/libzlib.a  3rdparty/lib/libittnotify.a  -ldl  $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib  -lm  -ldl \
	-lobjc -framework Foundation  >> $PREFIX/make_ios.log 2>&1
    echo "Done creating cv2 library" >> $PREFIX/make_ios.log 2>&1	
    popd  >> $PREFIX/make_ios.log 2>&1
	# All these are the same. They use libopenblas: must change to openblas.framework
	echo "opencv libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so -exec ls -l {} \; >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so -exec file {} \; >> $PREFIX/make_ios.log 2>&1
	for library in cv2/cv2.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		file=$(basename $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./_skbuild/iphoneos-14.0-arm64-3.11/cmake-build/lib/python3/$file $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
		# Fix the reference to libopenblas.dylib -> openblas.framework
		if [[ $(otool -l $PREFIX/build/lib.darwin-arm64-3.11/$library | grep libopenblas) ]];
		then 
			install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas  $PREFIX/build/lib.darwin-arm64-3.11/$library  >> $PREFIX/make_ios.log 2>&1
		fi
	done
    popd  >> $PREFIX/make_ios.log 2>&1
    popd  >> $PREFIX/make_ios.log 2>&1
fi
if [ $APP == "Carnets" ]; 
then
if [ $USE_FORTRAN == 1 ];
then
	export PYTHONHOME=$PREFIX/with_scipy/Library/
	# scipy-1.11.2
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd scipy-*  >> $PREFIX/make_ios.log 2>&1
	# Separate build directories for OSX / iOS using meson
	mkdir -p build_ios  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ FC=aarch64-apple-darwin20-gfortran meson . build_ios -Duse-pythran=false -Dblas=openblas -Dlapack=openblas --cross-file ../iphone-osx.meson >> $PREFIX/make_ios.log 2>&1
	pushd build_ios  >> $PREFIX/make_ios.log 2>&1
	# Something between ninja and meson is preventing the creation of dynamic libraries, creates bundles instead:
	sed -i bak "s/bundle/shared/" build.ninja >> $PREFIX/make_ios.log 2>&1
	ninja  >> $PREFIX/make_ios.log 2>&1
	echo scipy libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	echo number of scipy libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so -print | wc -l >> $PREFIX/make_ios.log 2>&1
	# 118 libraries (as of 1.11.2)! We do this automatically:
	# copy them to build/lib.darwin:
	for library in \
		scipy/linalg/cython_lapack.cpython-311-darwin.so \
		scipy/linalg/_decomp_lu_cython.cpython-311-darwin.so \
		scipy/linalg/cython_blas.cpython-311-darwin.so \
		scipy/linalg/_fblas.cpython-311-darwin.so \
		scipy/linalg/_flapack.cpython-311-darwin.so \
		scipy/linalg/_flinalg.cpython-311-darwin.so \
		scipy/linalg/_interpolative.cpython-311-darwin.so \
		scipy/optimize/_lbfgsb.cpython-311-darwin.so \
		scipy/optimize/_trlib/_trlib.cpython-311-darwin.so \
		scipy/optimize/_minpack2.cpython-311-darwin.so \
		scipy/optimize/_cobyla.cpython-311-darwin.so \
		scipy/optimize/__nnls.cpython-311-darwin.so \
		scipy/optimize/cython_optimize/_zeros.cpython-311-darwin.so \
		scipy/optimize/_minpack.cpython-311-darwin.so \
		scipy/optimize/_slsqp.cpython-311-darwin.so \
		scipy/integrate/_quadpack.cpython-311-darwin.so \
		scipy/integrate/_vode.cpython-311-darwin.so \
		scipy/integrate/_dop.cpython-311-darwin.so \
		scipy/integrate/_test_odeint_banded.cpython-311-darwin.so \
		scipy/integrate/_odepack.cpython-311-darwin.so \
		scipy/integrate/_lsoda.cpython-311-darwin.so \
		scipy/special/_ufuncs_cxx.cpython-311-darwin.so \
		scipy/special/_ellip_harm_2.cpython-311-darwin.so \
		scipy/special/_test_internal.cpython-311-darwin.so \
		scipy/special/_ufuncs.cpython-311-darwin.so \
		scipy/sparse/linalg/_eigen/arpack/_arpack.cpython-311-darwin.so \
		scipy/sparse/linalg/_propack/_cpropack.cpython-311-darwin.so \
		scipy/sparse/linalg/_propack/_zpropack.cpython-311-darwin.so \
		scipy/sparse/linalg/_propack/_dpropack.cpython-311-darwin.so \
		scipy/sparse/linalg/_propack/_spropack.cpython-311-darwin.so \
		scipy/sparse/linalg/_isolve/_iterative.cpython-311-darwin.so \
		scipy/sparse/linalg/_dsolve/_superlu.cpython-311-darwin.so \
		scipy/spatial/_qhull.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp $library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
		# Fix the reference to libopenblas.dylib -> openblas.framework
		if [[ $(otool -l $PREFIX/build/lib.darwin-arm64-3.11/$library | grep libopenblas) ]];
		then 
			install_name_tool -change $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib @rpath/openblas.framework/openblas  $PREFIX/build/lib.darwin-arm64-3.11/$library  >> $PREFIX/make_ios.log 2>&1
		fi
	done
	# Making a big scipy library to load many modules (85 out of 118):
	clang -v -undefined error -dynamiclib \
		-arch arm64 -miphoneos-version-min=14.0 \
		-isysroot $IOS_SDKROOT \
		-lz -lm -lc++ \
		-lpython3.11 \
		-L$PREFIX/build/lib.darwin-arm64-3.11 \
		-L. \
		-O3 -Wall  \
		`find scipy/odr -name \*.o`\
		`find scipy/_lib -name \*.o` \
		`find scipy/cluster -name \*.o` \
		`find scipy/fft -name \*.o` \
		`find scipy/fftpack -name \*.o` \
		scipy/integrate/_test_multivariate.cpython-311-darwin.so.p/tests__test_multivariate.c.o \
		`find scipy/interpolate -name \*.o` \
		`find scipy/io -name \*.o` \
		scipy/linalg/_solve_toeplitz.cpython-311-darwin.so.p/meson-generated__solve_toeplitz.c.o \
		scipy/linalg/_matfuncs_sqrtm_triu.cpython-311-darwin.so.p/meson-generated__matfuncs_sqrtm_triu.c.o \
		scipy/linalg/_decomp_update.cpython-311-darwin.so.p/meson-generated__decomp_update.c.o \
		scipy/linalg/_cythonized_array_utils.cpython-311-darwin.so.p/meson-generated__cythonized_array_utils.c.o \
		scipy/linalg/_matfuncs_expm.cpython-311-darwin.so.p/meson-generated__matfuncs_expm.c.o \
		`find scipy/ndimage -name \*.o` \
		`find scipy/optimize/_moduleTNC.cpython-311-darwin.so.p -name \*.o` \
		scipy/optimize/_lsap.cpython-311-darwin.so.p/_lsap.c.o \
		-Lscipy/optimize -lrectangular_lsap \
		scipy/optimize/_bglu_dense.cpython-311-darwin.so.p/meson-generated__bglu_dense.c.o \
		`find scipy/optimize/_highs -name \*.o` \
		-Lscipy/optimize/_highs -lbasiclu \
		scipy/optimize/_lsq/givens_elimination.cpython-311-darwin.so.p/meson-generated_givens_elimination.c.o \
		scipy/optimize/_zeros.cpython-311-darwin.so.p/zeros.c.o \
        scipy/optimize/_direct.cpython-311-darwin.so.p/*.o \
        scipy/optimize/_group_columns.cpython-311-darwin.so.p/meson-generated__group_columns.c.o \
		`find scipy/signal -name \*.o` \
		`find scipy/spatial/_ckdtree.cpython-311-darwin.so.p -name \*.o` \
		`find scipy/sparse/csgraph -name \*.o` \
		`find scipy/sparse/sparsetools -name \*.o` \
		scipy/sparse/_csparsetools.cpython-311-darwin.so.p/meson-generated__csparsetools.c.o \
		scipy/spatial/_voronoi.cpython-311-darwin.so.p/meson-generated__voronoi.c.o \
		scipy/spatial/_hausdorff.cpython-311-darwin.so.p/meson-generated__hausdorff.c.o \
		scipy/spatial/_distance_wrap.cpython-311-darwin.so.p/src_distance_wrap.c.o \
		scipy/spatial/_distance_pybind.cpython-311-darwin.so.p/src_distance_pybind.cpp.o \
		scipy/spatial/transform/_rotation.cpython-311-darwin.so.p/meson-generated__rotation.c.o \
		scipy/special/_specfun.cpython-311-darwin.so.p/meson-generated_..__specfunmodule.c.o \
		-Lscipy -l_fortranobject \
		`find scipy/special/cython_special.cpython-311-darwin.so.p -name \*.o` \
		-Lscipy/special -lamos -lcephes -lspecfun -lcdflib -lmach \
		-Lscipy/optimize -lrootfind \
		scipy/special/_comb.cpython-311-darwin.so.p/meson-generated__comb.c.o \
		`find scipy/stats/ -name \*.o` \
		-L$PREFIX/build/lib.darwin-arm64-3.11/numpy -lnpymath -lnpyrandom \
		-L$PREFIX/Frameworks_iphoneos/lib -lgfortran \
		-F$PREFIX/Frameworks_iphoneos -framework ios_system -framework openblas\
		-o scipy.so
	cp scipy.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
	# Fix the reference to libopenblas.dylib -> openblas.framework
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# coremltools:
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd coremltools >> $PREFIX/make_ios.log 2>&1
	mkdir -p build_ios >> $PREFIX/make_ios.log 2>&1
	rm -rf  build_ios/*  >> $PREFIX/make_ios.log 2>&1
	rm -f coremltools/*.so  >> $PREFIX/make_ios.log 2>&1
	rm -f build/lib/coremltools/*.so  >> $PREFIX/make_ios.log 2>&1
	BUILD_TAG=$(python3.11 ./scripts/build_tag.py)
	pushd build_ios >> $PREFIX/make_ios.log 2>&1
	# Now compile. This is extracted from scripts/build.sh
    cmake -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
     -DCMAKE_BUILD_TYPE="Release" \
     -DPYTHON_EXECUTABLE:FILEPATH=$PREFIX/Library/bin/python3.11 \
     -DPYTHON_INCLUDE_DIR=$PREFIX/Library/include/python3.11 \
     -DPYTHON_LIBRARY=$PREFIX/Library/lib/libpython3.11.dylib \
     -DOVERWRITE_PB_SOURCE=0 \
     -DBUILD_TAG=$BUILD_TAG \
     -DCMAKE_CROSSCOMPILING=TRUE \
     -DCMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
     -DCMAKE_C_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -D_LIBCPP_STRING_H_HAS_CONST_OVERLOADS -miphoneos-version-min=14 -I$PREFIX " \
     -DCMAKE_CXX_FLAGS="-arch arm64 -target arm64-apple-darwin19.6.0 -O2 -D_LIBCPP_STRING_H_HAS_CONST_OVERLOADS -miphoneos-version-min=14 -I$PREFIX " \
     -DCMAKE_MODULE_LINKER_FLAGS="-nostdlib -O2 -lobjc -lc -lc++ -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework Accelerate -framework Metal -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
     -DCMAKE_SHARED_LINKER_FLAGS="-nostdlib -O2 -lobjc -lc -lc++ -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework Accelerate -framework Metal -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
     -DCMAKE_EXE_LINKER_FLAGS="-nostdlib -O2 -lobjc -lc -lc++ -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11 -miphoneos-version-min=14 -F$PREFIX/Frameworks_iphoneos -framework ios_system -framework Accelerate -framework Metal -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
     ..  >> $PREFIX/make_ios.log 2>&1
    # 1st make, will conclude in error:
    make  >> $PREFIX/make_ios.log 2>&1
    cp ../build_osx/deps/protobuf/cmake/js_embed deps/protobuf/cmake/js_embed  >> $PREFIX/make_ios.log 2>&1
    # 2nd make, will conclude in error: 
    make  >> $PREFIX/make_ios.log 2>&1
    cp ../build_osx/deps/protobuf/cmake/protoc ./deps/protobuf/cmake/protoc  >> $PREFIX/make_ios.log 2>&1
    # 3rd make, will work:
    make  >> $PREFIX/make_ios.log 2>&1
    make dist_macosx_10_15_x86_64 >> $PREFIX/make_ios.log 2>&1
    cp dist/coremltools*.whl dist/coremltools.zip >> $PREFIX/make_ios.log 2>&1
	pushd dist >> $PREFIX/make_ios.log 2>&1
	unzip coremltools.zip >> $PREFIX/make_ios.log 2>&1
    # copy the dynamic libraries for the frameworks later:
    mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/coremltools/>> $PREFIX/make_ios.log 2>&1
    cp coremltools/*.so $PREFIX/build/lib.darwin-arm64-3.11/coremltools/ >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# Now scikit-learn:
	# scikit-learn would like a compiler with "-fopenmp" for more efficiency, but it will install without. 
	# The llvm-project repository has a compiler with "-fopenmp", and you'll also need to add the directory to "-L":
	# ../llvm-project/build_osx/bin/clang -fopenmp ~/src/test.c -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -arch arm64 -miphoneos-version-min=14.0 -L ../llvm-project/build-iphoneos/lib
	# TODO: try with "-fopenmp" for efficiency vs. stability
	# PYODIDE_PACKAGE_ABI=1 removes the check for OpenMP and the check that the compiler can produce executables. No other impacts.
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd scikit-learn >> $PREFIX/make_ios.log 2>&1
	rm -rf build/* >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" \
  CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG -falign-functions=8" \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
 LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 $DEBUG" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
PLATFORM=iphoneos PYODIDE_PACKAGE_ABI=1 SETUPTOOLS_USE_DISTUTILS=stdlib python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo scikit-learn libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	echo number of scikit-learn libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print | wc -l >> $PREFIX/make_ios.log 2>&1
	# 59 libraries by the last count
	# copy them to build/lib.macosx:
	for library in sklearn/tree/_utils.cpython-311-darwin.so \
		sklearn/tree/_splitter.cpython-311-darwin.so \
		sklearn/tree/_tree.cpython-311-darwin.so \
		sklearn/tree/_criterion.cpython-311-darwin.so \
		sklearn/metrics/cluster/_expected_mutual_info_fast.cpython-311-darwin.so \
		sklearn/metrics/_dist_metrics.cpython-311-darwin.so \
		sklearn/metrics/_pairwise_fast.cpython-311-darwin.so \
		sklearn/metrics/_pairwise_distances_reduction.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/_bitset.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/histogram.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/_binning.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/common.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/_predictor.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/_gradient_boosting.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/utils.cpython-311-darwin.so \
		sklearn/ensemble/_hist_gradient_boosting/splitting.cpython-311-darwin.so \
		sklearn/ensemble/_gradient_boosting.cpython-311-darwin.so \
		sklearn/cluster/_k_means_elkan.cpython-311-darwin.so \
		sklearn/cluster/_k_means_common.cpython-311-darwin.so \
		sklearn/cluster/_k_means_minibatch.cpython-311-darwin.so \
		sklearn/cluster/_k_means_lloyd.cpython-311-darwin.so \
		sklearn/cluster/_dbscan_inner.cpython-311-darwin.so \
		sklearn/cluster/_hierarchical_fast.cpython-311-darwin.so \
		sklearn/feature_extraction/_hashing_fast.cpython-311-darwin.so \
		sklearn/__check_build/_check_build.cpython-311-darwin.so \
		sklearn/_loss/_loss.cpython-311-darwin.so \
		sklearn/datasets/_svmlight_format_fast.cpython-311-darwin.so \
		sklearn/linear_model/_sag_fast.cpython-311-darwin.so \
		sklearn/linear_model/_sgd_fast.cpython-311-darwin.so \
		sklearn/linear_model/_cd_fast.cpython-311-darwin.so \
		sklearn/utils/_logistic_sigmoid.cpython-311-darwin.so \
		sklearn/utils/_readonly_array_wrapper.cpython-311-darwin.so \
		sklearn/utils/_openmp_helpers.cpython-311-darwin.so \
		sklearn/utils/_random.cpython-311-darwin.so \
		sklearn/utils/_vector_sentinel.cpython-311-darwin.so \
		sklearn/utils/_heap.cpython-311-darwin.so \
		sklearn/utils/_sorting.cpython-311-darwin.so \
		sklearn/utils/_weight_vector.cpython-311-darwin.so \
		sklearn/utils/_cython_blas.cpython-311-darwin.so \
		sklearn/utils/sparsefuncs_fast.cpython-311-darwin.so \
		sklearn/utils/_fast_dict.cpython-311-darwin.so \
		sklearn/utils/arrayfuncs.cpython-311-darwin.so \
		sklearn/utils/murmurhash.cpython-311-darwin.so \
		sklearn/utils/_seq_dataset.cpython-311-darwin.so \
		sklearn/utils/_typedefs.cpython-311-darwin.so \
		sklearn/svm/_newrand.cpython-311-darwin.so \
		sklearn/svm/_libsvm.cpython-311-darwin.so \
		sklearn/svm/_liblinear.cpython-311-darwin.so \
		sklearn/svm/_libsvm_sparse.cpython-311-darwin.so \
		sklearn/manifold/_utils.cpython-311-darwin.so \
		sklearn/manifold/_barnes_hut_tsne.cpython-311-darwin.so \
		sklearn/_isotonic.cpython-311-darwin.so \
		sklearn/preprocessing/_csr_polynomial_expansion.cpython-311-darwin.so \
		sklearn/decomposition/_cdnmf_fast.cpython-311-darwin.so \
		sklearn/decomposition/_online_lda_fast.cpython-311-darwin.so \
		sklearn/neighbors/_ball_tree.cpython-311-darwin.so \
		sklearn/neighbors/_kd_tree.cpython-311-darwin.so \
		sklearn/neighbors/_partition_nodes.cpython-311-darwin.so \
		sklearn/neighbors/_quad_tree.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./build/lib.macosx-${OSX_VERSION}-arm64-3.11/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# qutip. Can't download with pip, so submodule (also faster with submodule):
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd qutip >> $PREFIX/make_ios.log 2>&1
	rm -rf build/* >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
		CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 $DEBUG" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 $DEBUG" \
		NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" \
		PLATFORM=iphoneos python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo qutip libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	echo number of qutip libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print | wc -l >> $PREFIX/make_ios.log 2>&1
    # qutip/cy/*.so qutip/control/*.so	
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/qutip/cy >> $PREFIX/make_ios.log 2>&1
	mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/qutip/control >> $PREFIX/make_ios.log 2>&1
	cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/qutip/cy/*.so $PREFIX/build/lib.darwin-arm64-3.11/qutip/cy >> $PREFIX/make_ios.log 2>&1
	cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/qutip/control/*.so $PREFIX/build/lib.darwin-arm64-3.11/qutip/control >> $PREFIX/make_ios.log 2>&1
	  # Making a single qutip dynamic library:
	  echo Making a single qutip library for iOS: >> $PREFIX/make_ios.log 2>&1
	  clang -v -undefined error -dynamiclib \
		  -isysroot $IOS_SDKROOT \
		  -lz -lm -lc++ \
		  -lpython3.11 \
		  -F$PREFIX/Frameworks_iphoneos -framework ios_system \
		  -L$PREFIX/Frameworks_iphoneos/lib \
		  -L$PREFIX/build/lib.darwin-arm64-3.11 \
		  -O3 -Wall -arch arm64 \
		  -miphoneos-version-min=14.0 \
		  `find build -name \*.o` \
		  -L$PREFIX/Library/lib \
		  -Lbuild/temp.macosx-${OSX_VERSION}-arm64-cpython-311 \
		  -o build/qutip.so  >> $PREFIX/make_ios.log 2>&1
	cp build/qutip.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1	
	# Cartopy:
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd Cartopy-* >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	rm -rf .eggs  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include " \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include " \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I$PREFIX/Frameworks_iphoneos/include " \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos/  -framework ios_system  -framework libproj -framework libgeos_c -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 $DEBUG" \
		LDSHARED="clang -v -undefined error -dynamiclib -arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -lz -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 $DEBUG -lz -F$PREFIX/Frameworks_iphoneos/ -framework libproj -framework libgeos_c" \
		PLATFORM=iphoneos \
		FORCE_CYTHON="True" \
		python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo "Cartopy libraries for iOS: "  >> $PREFIX/make_ios.log 2>&1
	find . -name \*.so  >> $PREFIX/make_ios.log 2>&1
    for library in cartopy/trace.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# statsmodels:
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd statsmodels-* >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
		CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX $DEBUG" \
		CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
		CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 $DEBUG" \
		LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 -L$PREFIX/build/lib.darwin-arm64-3.11/numpy $DEBUG" \
		LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 -L$PREFIX/build/lib.darwin-arm64-3.11/numpy $DEBUG" \
		NPY_BLAS_ORDER="openblas" NPY_LAPACK_ORDER="openblas" MATHLIB="-lm" \
		PLATFORM=iphoneos python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	echo statsmodels libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print  >> $PREFIX/make_ios.log 2>&1
	echo number of statsmodels libraries for iOS: >> $PREFIX/make_ios.log 2>&1
	find build -name \*.so -print | wc -l >> $PREFIX/make_ios.log 2>&1
	# copy them to build/lib.darwin-arm64:
	for library in statsmodels/tsa/statespace/_filters/_univariate_diffuse.cpython-311-darwin.so \
		           statsmodels/tsa/statespace/_filters/_univariate.cpython-311-darwin.so \
		           statsmodels/tsa/statespace/_filters/_conventional.cpython-311-darwin.so 
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	# Making a single statsmodels dynamic library:
	# without _filters/_univariate_diffuse, _filters/_univariate and _filters/_conventional because of a name collision with _smoothers:
	echo Making a single statsmodels library for iOS: >> $PREFIX/make_ios.log 2>&1
	clang -v -undefined error -dynamiclib \
		  -isysroot $IOS_SDKROOT \
		  -lz -lm -lc++ \
		  -lpython3.11 \
		  -L$PREFIX/build/lib.darwin-arm64-3.11/numpy \
		  -lnpymath -lnpyrandom \
		  -F$PREFIX/Frameworks_iphoneos -framework ios_system \
		  -L$PREFIX/Frameworks_iphoneos/lib \
		  -L$PREFIX/build/lib.darwin-arm64-3.11 \
		  -O3 -Wall -arch arm64 \
		  -miphoneos-version-min=14.0 \
		  `find build -not -path '*/_filters/*' -name \*.o` \
		  build/temp.macosx-${OSX_VERSION}-arm64-cpython-311/statsmodels/tsa/statespace/_filters/_inversions.o \
		  -L$PREFIX/Library/lib \
		  -Lbuild/temp.macosx-${OSX_VERSION}-arm64-cpython-311 \
		  -o build/statsmodels.so  >> $PREFIX/make_ios.log 2>&1
	cp build/statsmodels.so $PREFIX/build/lib.darwin-arm64-3.11 >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1
	# also pygeos:
	pushd packages >> $PREFIX/make_ios.log 2>&1
	pushd pygeos-* >> $PREFIX/make_ios.log 2>&1
	rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
	env CC=clang CXX=clang++ \
CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include" \
CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG  -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include/" \
CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -DCYTHON_PEP489_MULTI_PHASE_INIT=0 -DCYTHON_USE_DICT_VERSIONS=0 -I$PREFIX -I $PREFIX/Frameworks_iphoneos/include" \
LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT $DEBUG -F $PREFIX/Frameworks_iphoneos/ -framework libgeos_c" \
LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz $DEBUG -F $PREFIX/Frameworks_iphoneos/ -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11 -lpython3.11 -framework libgeos_c" \
PLATFORM=iphoneos \
GEOS_INCLUDE_PATH=$PREFIX/Frameworks_iphoneos/include \
GEOS_LIBRARY_PATH=$PREFIX/Frameworks_iphoneos/lib \
	python3.11 setup.py build >> $PREFIX/make_ios.log 2>&1
	for library in pygeos/_geos.cpython-311-darwin.so pygeos/lib.cpython-311-darwin.so pygeos/_geometry.cpython-311-darwin.so
	do
		directory=$(dirname $library)
		mkdir -p $PREFIX/build/lib.darwin-arm64-3.11/$directory >> $PREFIX/make_ios.log 2>&1
		cp ./build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/$library $PREFIX/build/lib.darwin-arm64-3.11/$library >> $PREFIX/make_ios.log 2>&1
	done
	popd  >> $PREFIX/make_ios.log 2>&1
	popd  >> $PREFIX/make_ios.log 2>&1	
	export PYTHONHOME=$PREFIX/Library/	
fi # scipy, USE_FORTRAN == 1
fi # App == Carnets

# Remove this package, it's only useful when building:
# Also Cython, scikit-build?


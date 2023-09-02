#! /bin/sh

#  name /Users/holzschu/src/Xcode_iPad/cpython/install/lib/libpython3.11.dylib (offset 24)
#  name @rpath/ios_system.framework/ios_system (offset 24)
#  name /usr/lib/libSystem.B.dylib (offset 24)
#  name /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (offset 24)
libpython=$PWD/Library/lib/libpython3.11.dylib
APP=$(basename `dirname $PWD`)
# Set to 1 if you have gfortran for arm64 installed. gfortran support is highly experimental.
# You might need to edit the script as well.
USE_FORTRAN=0
if [ -e "/usr/local/aarch64-apple-darwin20/lib/libgfortran.dylib" ];then
	USE_FORTRAN=1
fi

OSX_VERSION=11.5 # `sw_vers -productVersion |awk -F. '{print $1"."$2}'`

USE_SIMULATOR=0
architectures=("lib.macosx-${OSX_VERSION}-x86_64-3.11 lib.darwin-arm64-3.11")
if  [ $USE_SIMULATOR == 1 ]; then
	architectures=("lib.macosx-${OSX_VERSION}-x86_64-3.11 lib.darwin-arm64-3.11 lib.darwin-x86_64-3.11")
fi

edit_Info_plist() 
{
   framework=$1
	# Edit the Info.plist file:
	plutil -replace DTPlatformName -string "iphoneos" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformName -string "iphonesimulator" build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformName -string "macosx" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace DTSDKName -string "iphoneos" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTSDKName -string "iphonesimulator" build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTSDKName -string "macosx" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace DTPlatformVersion -string "14.0" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformVersion -string "14.0" build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformVersion -string "${OSX_VERSION}" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace MinimumOSVersion -string "14.0" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace MinimumOSVersion -string "14.0" build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace MinimumOSVersion -string "${OSX_VERSION}" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace CFBundleSupportedPlatforms.0 -string "iPhoneSimulator" build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -remove CFBundleSupportedPlatforms.1 build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace CFBundleSupportedPlatforms.0 -string "MacOSX" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -remove CFBundleSupportedPlatforms.1 build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

}

edit_Info_plist_noSimulator() 
{
   framework=$1
	# Edit the Info.plist file:
	plutil -replace DTPlatformName -string "iphoneos" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformName -string "macosx" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace DTSDKName -string "iphoneos" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTSDKName -string "macosx" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace DTPlatformVersion -string "14.0" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformVersion -string "${OSX_VERSION}" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace MinimumOSVersion -string "14.0" build/lib.darwin-arm64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -replace MinimumOSVersion -string "${OSX_VERSION}" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

	plutil -replace CFBundleSupportedPlatforms.0 -string "MacOSX" build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist
	plutil -remove CFBundleSupportedPlatforms.1 build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework/Info.plist

}

# 1-level libraries:
# lzma functions are forbidden on the AppStore. 
# You can build the lzma modyle by adding the lzma headers in the Include path and adding _lzma to this list,
# but you can't submit to the AppStore.
# Retrying lzma with a static library version:
# TODO: re-add rpds here
for name in _bz2 _cffi_backend _crypt _ctypes _ctypes_test _dbm _decimal _hashlib _lsprof _lzma _multiprocessing _opcode _posixshmem _queue _sqlite3 _ssl _testbuffer _testcapi _testimportmultiple _testinternalcapi _testmultiphase _xxsubinterpreters _xxtestfuzz syslog xxlimited 
do 
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${name}.cpython-311-darwin.so
			cp $libraryFile $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			
		done
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done



# argon2/_ffi, cryptography/hazmat/bindings/_padding, cryptography//hazmat/bindings/_openssl and cryptography/hazmat/bindings/_rust. 
# Separate because suffix is .abi3.so
# removed until we can cross-compile: cryptography/hazmat/bindings/_rust 
for library in _argon2_cffi_bindings/_ffi cryptography/hazmat/bindings/_padding cryptography/hazmat/bindings/_openssl 
do
	# replace all "/" with "."
	name=${library//\//.}
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${library}.abi3.so
			cp $libraryFile $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			
		done
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done

# Pillow, matplotlib, lxml (more than 2 levels of hierarchy, suffix is .cpython-311-darwin.so)
# except for zmq/backend/cffi/_cffi where it's .abi3.so for MacOSX and .cpython-311-darwin.so for iOS & Simulator
for library in kiwisolver/_cext zmq/backend/cffi/_cffi matplotlib/_ttconv matplotlib/_path matplotlib/_qhull matplotlib/ft2font matplotlib/_c_internal_utils matplotlib/_tri matplotlib/_image matplotlib/backends/_backend_agg matplotlib/backends/_tkagg  regex/_regex contourpy/_contourpy wordcloud/query_integral_image pyfftw/pyfftw 
do
	# replace all "/" with ".
	name=${library//\//.}
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${library}
			cp $libraryFile.*.so $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			
		done
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done

for library in numpy pandas PIL lxml
do
	name=${library}_all
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${library}
			cp $libraryFile.so $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
		done
		# Edit the Info.plist file:
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done


# for Crypto specifically, only in a-Shell: 
if [ $APP == "a-Shell" ]; 
then
	for library in Crypto/PublicKey/_ec_ws Crypto/PublicKey/_ed448 Crypto/PublicKey/_ed25519 Crypto/PublicKey/_x25519 Crypto/Util/_strxor Crypto/Util/_cpuid_c Crypto/Hash/_BLAKE2b Crypto/Hash/_SHA256 Crypto/Hash/_keccak Crypto/Hash/_SHA224 Crypto/Hash/_RIPEMD160 Crypto/Hash/_ghash_portable Crypto/Hash/_MD2 Crypto/Hash/_SHA384 Crypto/Hash/_SHA512 Crypto/Hash/_SHA1 Crypto/Hash/_MD5 Crypto/Hash/_BLAKE2s Crypto/Hash/_MD4 Crypto/Hash/_poly1305 Crypto/Cipher/_raw_ocb Crypto/Cipher/_pkcs1_decode Crypto/Cipher/_raw_ctr Crypto/Cipher/_raw_arc2 Crypto/Cipher/_raw_eksblowfish Crypto/Cipher/_raw_des3 Crypto/Cipher/_raw_cbc Crypto/Cipher/_raw_aes Crypto/Cipher/_raw_ecb Crypto/Cipher/_chacha20 Crypto/Cipher/_raw_cfb Crypto/Cipher/_raw_des Crypto/Cipher/_raw_ofb Crypto/Cipher/_ARC4 Crypto/Cipher/_raw_blowfish Crypto/Cipher/_Salsa20 Crypto/Cipher/_raw_cast Crypto/Protocol/_scrypt Crypto/Math/_modexp \
		Cryptodome/PublicKey/_ec_ws Cryptodome/PublicKey/_ed448 Cryptodome/PublicKey/_ed25519 Cryptodome/PublicKey/_x25519 Cryptodome/Util/_strxor Cryptodome/Util/_cpuid_c Cryptodome/Hash/_BLAKE2b Cryptodome/Hash/_SHA256 Cryptodome/Hash/_keccak Cryptodome/Hash/_SHA224 Cryptodome/Hash/_RIPEMD160 Cryptodome/Hash/_ghash_portable Cryptodome/Hash/_MD2 Cryptodome/Hash/_SHA384 Cryptodome/Hash/_SHA512 Cryptodome/Hash/_SHA1 Cryptodome/Hash/_MD5 Cryptodome/Hash/_BLAKE2s Cryptodome/Hash/_MD4 Cryptodome/Hash/_poly1305 Cryptodome/Cipher/_raw_ocb Cryptodome/Cipher/_pkcs1_decode Cryptodome/Cipher/_raw_ctr Cryptodome/Cipher/_raw_arc2 Cryptodome/Cipher/_raw_eksblowfish Cryptodome/Cipher/_raw_des3 Cryptodome/Cipher/_raw_cbc Cryptodome/Cipher/_raw_aes Cryptodome/Cipher/_raw_ecb Cryptodome/Cipher/_chacha20 Cryptodome/Cipher/_raw_cfb Cryptodome/Cipher/_raw_des Cryptodome/Cipher/_raw_ofb Cryptodome/Cipher/_ARC4 Cryptodome/Cipher/_raw_blowfish Cryptodome/Cipher/_Salsa20 Cryptodome/Cipher/_raw_cast Cryptodome/Protocol/_scrypt Cryptodome/Math/_modexp
	do
		# replace all "/" with ".
		name=${library//\//.}
		for package in python3_ios pythonA pythonB pythonC pythonD pythonE
		do
			framework=${package}-${name}
			for architecture in $architectures
			do
				echo "Creating: " ${architecture}/Frameworks/${name}.framework
				directory=build/${architecture}/Frameworks/
				rm -rf $directory/$framework.framework
				mkdir -p $directory
				mkdir -p $directory/$framework.framework
				libraryFile=build/${architecture}/${library}
				cp $libraryFile.*.so $directory/$framework.framework/$framework
				cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
				plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
				plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
				# underscore is not allowed in CFBundleIdentifier:
				signature=${framework//_/-}
				plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
				# change framework id and libpython:
				install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
				install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework

			done
			# Edit the Info.plist file:
			if  [ $USE_SIMULATOR == 1 ]; then
				edit_Info_plist $framework
				# Create the 3-architecture XCFramework:
				rm -rf XcFrameworks/$framework.xcframework
				xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
			else
				edit_Info_plist_noSimulator $framework
				# Create the 2-architecture XCFramework:
				rm -rf XcFrameworks/$framework.xcframework
				xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
			fi
		done
	done
fi  # [ $APP == "a-Shell" ];


# astropy, shapely, pyproj
# build/lib.macosx-11.5-x86_64-cpython-311/shapely/_geos.cpython-311-darwin.so
# build/lib.macosx-11.5-x86_64-cpython-311/shapely/lib.cpython-311-darwin.so
# build/lib.macosx-11.5-x86_64-cpython-311/shapely/_geometry_helpers.cpython-311-darwin.so
for library in erfa/ufunc \
	shapely/_geos shapely/lib shapely/_geometry_helpers
do
	# replace all "/" with "."
	name=${library//\//.}
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${library}.cpython-311-darwin.so
			cp $libraryFile $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			
		done
		# Edit the Info.plist file:
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done

# Single-module astropy, fiona
for library in astropy fiona pyproj
do
	name=${library}_all
	for package in python3_ios pythonA pythonB pythonC pythonD pythonE
	do
		framework=${package}-${name}
		for architecture in $architectures
		do
			echo "Creating: " ${architecture}/Frameworks/${name}.framework
			directory=build/${architecture}/Frameworks/
			rm -rf $directory/$framework.framework
			mkdir -p $directory
			mkdir -p $directory/$framework.framework
			libraryFile=build/${architecture}/${library}
			cp $libraryFile.so $directory/$framework.framework/$framework
			cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
			plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
			plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
			# underscore is not allowed in CFBundleIdentifier:
			signature=${framework//_/-}
			plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
			# change framework id and libpython:
			install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
			install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
		done
		# Edit the Info.plist file:
		if  [ $USE_SIMULATOR == 1 ]; then
			edit_Info_plist $framework
			# Create the 3-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.11/Frameworks/$framework.framework  -output  XcFrameworks/$framework.xcframework
		else
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		fi
	done
done


if [ $USE_FORTRAN == 1 ];
then
	# Create the gfortran framework, change the reference to libgfortran in the openblas framework:
	cp -r Python-aux/openblas.xcframework XcFrameworks/
	install_name_tool -change /usr/local/aarch64-apple-darwin20/lib/libgfortran.5.dylib @rpath/libgfortran.framework/libgfortran XcFrameworks/openblas.xcframework/ios-arm64/openblas.framework/openblas

	directory=build/lib.darwin-arm64-3.11/Frameworks
	for library in libgfortran
	do
		framework="${library%.*}"
		echo $framework
		mkdir -p  $directory/$framework.framework
		libraryFile=Frameworks_iphoneos/lib/$library.dylib
		cp $libraryFile $directory/$framework.framework/$framework
		cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
		plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
		plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
		# underscore is not allowed in CFBundleIdentifier:
		signature=${framework//_/-}
		plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
		# change framework id: 
		install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
		install_name_tool -change /usr/local/aarch64-apple-darwin20/lib/libgcc_s.2.dylib @rpath/libgcc_s.framework/libgcc_s $directory/$framework.framework/$framework
		plutil -replace DTPlatformName -string "iphoneos" $directory/$framework.framework/Info.plist
		plutil -replace DTSDKName -string "iphoneos" $directory/$framework.framework/Info.plist
		plutil -replace DTPlatformVersion -string "14.0" $directory/$framework.framework/Info.plist
		plutil -replace MinimumOSVersion -string "14.0" $directory/$framework.framework/Info.plist
		# Create a single-architecture XCFramework:
		rm -rf XcFrameworks/$framework.xcframework
		xcodebuild -create-xcframework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output  XcFrameworks/$framework.xcframework
	done 
fi # [ $USE_FORTRAN == 1 ]
	
if [ $APP == "Carnets" ]; then
	# Single-module scipy, qutip, rasterio, statsmodels:
	# Always built for OSX and iOS, not simultaor
	architectures=("lib.macosx-${OSX_VERSION}-x86_64-3.11 lib.darwin-arm64-3.11")
	for library in scipy qutip rasterio statsmodels
	do
		name=${library}_all
		for package in python3_ios pythonA pythonB pythonC pythonD pythonE
		do
			framework=${package}-${name}
			for architecture in $architectures
			do
				echo "Creating: " ${architecture}/Frameworks/${name}.framework
				directory=build/${architecture}/Frameworks/
				rm -rf $directory/$framework.framework
				mkdir -p $directory
				mkdir -p $directory/$framework.framework
				libraryFile=build/${architecture}/${library}
				cp $libraryFile.so $directory/$framework.framework/$framework
				cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
				plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
				plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
				# underscore is not allowed in CFBundleIdentifier:
				signature=${framework//_/-}
				plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
				# change framework id and libpython:
				install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
				install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			done
			# Edit the Info.plist file:
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output  XcFrameworks/$framework.xcframework
		done
	done


	# create the scipy (only those not included above) and scikit-learn modules: 
	# also cvxopt, cv2, statsmodels, pygeos, cartopy
	for library in scipy/odr/__odrpack \
		scipy/linalg/cython_lapack \
		scipy/linalg/cython_blas \
		scipy/linalg/_fblas \
		scipy/linalg/_flapack \
		scipy/linalg/_flinalg \
		scipy/linalg/_interpolative \
		scipy/optimize/_lbfgsb \
		scipy/optimize/_trlib/_trlib \
		scipy/optimize/_minpack \
		scipy/optimize/_minpack2 \
		scipy/optimize/_cobyla \
		scipy/optimize/__nnls \
		scipy/optimize/cython_optimize/_zeros \
		scipy/optimize/_slsqp \
		scipy/integrate/_quadpack \
		scipy/integrate/_vode \
		scipy/integrate/_dop \
		scipy/integrate/_test_odeint_banded \
		scipy/integrate/_odepack \
		scipy/integrate/_lsoda \
		scipy/io/_test_fortran \
		scipy/special/_ufuncs_cxx \
		scipy/special/_ellip_harm_2 \
		scipy/special/_ufuncs \
		scipy/interpolate/dfitpack \
		scipy/sparse/linalg/_eigen/arpack/_arpack \
		scipy/sparse/linalg/_propack/_cpropack \
		scipy/sparse/linalg/_propack/_zpropack \
		scipy/sparse/linalg/_propack/_dpropack \
		scipy/sparse/linalg/_propack/_spropack \
		scipy/sparse/linalg/_isolve/_iterative \
		scipy/sparse/linalg/_dsolve/_superlu \
		scipy/spatial/_qhull \
		scipy/stats/_statlib \
		scipy/stats/_mvn \
		sklearn/tree/_utils \
		sklearn/tree/_splitter \
		sklearn/tree/_tree \
		sklearn/tree/_criterion \
		sklearn/metrics/cluster/_expected_mutual_info_fast \
		sklearn/metrics/_dist_metrics \
		sklearn/metrics/_pairwise_fast \
		sklearn/metrics/_pairwise_distances_reduction \
		sklearn/ensemble/_hist_gradient_boosting/_bitset \
		sklearn/ensemble/_hist_gradient_boosting/histogram \
		sklearn/ensemble/_hist_gradient_boosting/_binning \
		sklearn/ensemble/_hist_gradient_boosting/common \
		sklearn/ensemble/_hist_gradient_boosting/_predictor \
		sklearn/ensemble/_hist_gradient_boosting/_gradient_boosting \
		sklearn/ensemble/_hist_gradient_boosting/utils \
		sklearn/ensemble/_hist_gradient_boosting/splitting \
		sklearn/ensemble/_gradient_boosting \
		sklearn/cluster/_k_means_elkan \
		sklearn/cluster/_k_means_common \
		sklearn/cluster/_k_means_minibatch \
		sklearn/cluster/_k_means_lloyd \
		sklearn/cluster/_dbscan_inner \
		sklearn/cluster/_hierarchical_fast \
		sklearn/feature_extraction/_hashing_fast \
		sklearn/__check_build/_check_build \
		sklearn/_loss/_loss \
		sklearn/datasets/_svmlight_format_fast \
		sklearn/linear_model/_sag_fast \
		sklearn/linear_model/_sgd_fast \
		sklearn/linear_model/_cd_fast \
		sklearn/utils/_logistic_sigmoid \
		sklearn/utils/_readonly_array_wrapper \
		sklearn/utils/_openmp_helpers \
		sklearn/utils/_random \
		sklearn/utils/_vector_sentinel \
		sklearn/utils/_heap \
		sklearn/utils/_sorting \
		sklearn/utils/_weight_vector \
		sklearn/utils/_cython_blas \
		sklearn/utils/sparsefuncs_fast \
		sklearn/utils/_fast_dict \
		sklearn/utils/arrayfuncs \
		sklearn/utils/murmurhash \
		sklearn/utils/_seq_dataset \
		sklearn/utils/_typedefs \
		sklearn/svm/_newrand \
		sklearn/svm/_libsvm \
		sklearn/svm/_liblinear \
		sklearn/svm/_libsvm_sparse \
		sklearn/manifold/_utils \
		sklearn/manifold/_barnes_hut_tsne \
		sklearn/_isotonic \
		sklearn/preprocessing/_csr_polynomial_expansion \
		sklearn/decomposition/_cdnmf_fast \
		sklearn/decomposition/_online_lda_fast \
		sklearn/neighbors/_ball_tree \
		sklearn/neighbors/_kd_tree \
		sklearn/neighbors/_partition_nodes \
		sklearn/neighbors/_quad_tree \
		cvxopt/cholmod cvxopt/misc_solvers cvxopt/amd cvxopt/base cvxopt/umfpack cvxopt/fftw cvxopt/blas cvxopt/lapack \
		cv2/cv2	\
		statsmodels/tsa/statespace/_filters/_univariate_diffuse \
		statsmodels/tsa/statespace/_filters/_univariate \
		statsmodels/tsa/statespace/_filters/_conventional \
		pygeos/_geos pygeos/lib pygeos/_geometry cartopy/trace
		do
			# replace all "/" with ".
			name=${library//\//.}
			for package in python3_ios pythonA pythonB pythonC pythonD pythonE
			do
				framework=${package}-${name}
				for architecture in $architectures 
				do
					echo "Creating: " ${architecture}/Frameworks/${name}.framework
					directory=build/${architecture}/Frameworks/
					rm -rf $directory/$framework.framework
					mkdir -p $directory
					mkdir -p $directory/$framework.framework
					libraryFile=build/${architecture}/${library}.cpython-311-darwin.so
					cp $libraryFile $directory/$framework.framework/$framework
					cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
					plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
					plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
					# underscore is not allowed in CFBundleIdentifier:
					signature=${framework//_/-}
					plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
					# change framework id and libpython:
					install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
					install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
				done
				# Edit the Info.plist file:
				edit_Info_plist_noSimulator $framework
				# Create the 2-architecture XCFramework:
				rm -rf XcFrameworks/$framework.xcframework
				xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output  XcFrameworks/$framework.xcframework
			done
		done

	# ML frameworks: 
	for library in coremltools/libcoremlpython coremltools/libmilstoragepython coremltools/libmodelpackage
	do
		# replace all "/" with ".
		name=${library//\//.}
		for package in python3_ios pythonA pythonB pythonC pythonD pythonE
		do
			framework=${package}-${name}
			for architecture in $architectures 
			do
				echo "Creating: " ${architecture}/Frameworks/${name}.framework
				directory=build/${architecture}/Frameworks/
				rm -rf $directory/$framework.framework
				mkdir -p $directory
				mkdir -p $directory/$framework.framework
				libraryFile=build/${architecture}/${library}.so
				cp $libraryFile $directory/$framework.framework/$framework
				cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
				plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
				plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
				# underscore is not allowed in CFBundleIdentifier:
				signature=${framework//_/-}
				plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
				# change framework id and libpython:
				install_name_tool -change $libpython @rpath/${package}.framework/${package}  $directory/$framework.framework/$framework
				install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
			done
			# Edit the Info.plist file:
			edit_Info_plist_noSimulator $framework
			# Create the 2-architecture XCFramework:
			rm -rf XcFrameworks/$framework.xcframework
			xcodebuild -create-xcframework -framework build/lib.macosx-${OSX_VERSION}-x86_64-3.11/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.11/Frameworks/$framework.framework -output XcFrameworks/$framework.xcframework
		done
	done
fi # [ $APP == "Carnets" ]


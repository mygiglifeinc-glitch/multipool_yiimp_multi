#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$MP_STAGE/system_base.sh"

echo -e " Building daemon server...$COL_RESET"

mp_system_base

echo -e " Installing additional system files required for daemons...$COL_RESET"
daemon_packages=(build-essential libtool autotools-dev automake cmake pkg-config
	libssl-dev libevent-dev bsdmainutils libboost-all-dev libminiupnpc-dev
	qtbase5-dev qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
	libqrencode-dev libzmq3-dev libgmp-dev libsodium-dev zlib1g-dev
	mariadb-client libpsl-dev libnghttp2-dev)
# QtWebKit is no longer packaged in newer releases.
if apt-cache show libqt5webkit5-dev > /dev/null 2>&1; then
	daemon_packages+=(libqt5webkit5-dev)
fi
apt_install "${daemon_packages[@]}"
echo -e "$GREEN Done...$COL_RESET"

build_dir="$STORAGE_ROOT/yiimp/yiimp_setup/tmp"
sudo mkdir -p "$build_dir"

# download <url> <sha256> <file>: fetch a source archive and verify it.
function download {
	sudo curl -fsSL --retry 3 -o "$build_dir/$3" "$1" || return 1
	echo "$2  $build_dir/$3" | sha256sum -c --quiet - || { sudo rm -f "$build_dir/$3"; return 1; }
}

# Build Berkeley DB <version> <archive> <sha256> <url> into $STORAGE_ROOT/berkeley/<dir>.
# These old releases need two fixes for current compilers: the atomic helper
# name clashes with a GCC builtin, and newer GCC rejects implicit function
# declarations in the configure tests.
function build_berkeley {
	local name=$1 archive=$2 sha=$3 url=$4 prefix="$STORAGE_ROOT/berkeley/$5"
	local srcdir="$build_dir/${archive%.tar.gz}"
	download "$url" "$sha" "$archive" || return 1
	sudo rm -rf "$srcdir"
	sudo tar -C "$build_dir" -xzf "$build_dir/$archive" || return 1
	sudo sed -i 's/__atomic_compare_exchange/__atomic_compare_exchange_db/g' "$srcdir/src/dbinc/atomic.h" 2> /dev/null \
		|| sudo sed -i 's/__atomic_compare_exchange/__atomic_compare_exchange_db/g' "$srcdir/dbinc/atomic.h" 2> /dev/null || true
	sudo mkdir -p "$prefix"
	(
		cd "$srcdir/build_unix" &&
		sudo env CFLAGS="-O2 -fPIC -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-error=incompatible-pointer-types -Wno-error=int-conversion" \
			CXXFLAGS="-O2 -fPIC" \
			../dist/configure --enable-cxx --disable-shared --with-pic --prefix="$prefix" &&
		sudo make -j"$(nproc)" &&
		sudo make install
	) > "$build_dir/$name.log" 2>&1 || return 1
	sudo rm -rf "$srcdir" "$build_dir/$archive" "$build_dir/$name.log"
}

# The legacy libraries below are only needed to compile some older coin
# daemons, so a failure is reported but does not stop the installation.
echo -e " Building Berkeley 4.8, this may take several minutes...$COL_RESET"
if build_berkeley db4.8 db-4.8.30.NC.tar.gz \
	12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef \
	https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz db4; then
	echo -e "$GREEN Berkeley 4.8 Completed...$COL_RESET"
else
	echo -e "$RED Berkeley 4.8 failed to build, see $build_dir/db4.8.log$COL_RESET"
fi

echo -e " Building Berkeley 5.1, this may take several minutes...$COL_RESET"
if build_berkeley db5.1 db-5.1.29.tar.gz \
	a943cb4920e62df71de1069ddca486d408f6d7a09ddbbb5637afe7a229389182 \
	https://download.oracle.com/berkeley-db/db-5.1.29.tar.gz db5; then
	echo -e "$GREEN Berkeley 5.1 Completed...$COL_RESET"
else
	echo -e "$RED Berkeley 5.1 failed to build, see $build_dir/db5.1.log$COL_RESET"
fi

echo -e " Building Berkeley 5.3, this may take several minutes...$COL_RESET"
if build_berkeley db5.3 db-5.3.28.tar.gz \
	e0a992d740709892e81f9d93f06daf305cf73fb81b545afe72478043172c3628 \
	https://download.oracle.com/berkeley-db/db-5.3.28.tar.gz db5.3; then
	echo -e "$GREEN Berkeley 5.3 Completed...$COL_RESET"
else
	echo -e "$RED Berkeley 5.3 failed to build, see $build_dir/db5.3.log$COL_RESET"
fi

# OpenSSL 1.0.2 is end of life and only installed privately in
# $STORAGE_ROOT/openssl for old daemons that do not build against OpenSSL 3.
echo -e " Building OpenSSL 1.0.2g, this may take several minutes...$COL_RESET"
if download https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2g/openssl-1.0.2g.tar.gz \
		b784b1b3907ce39abf4098702dade6365522a253ad1552e267a9a0e89594aa33 openssl-1.0.2g.tar.gz &&
	sudo rm -rf "$build_dir/openssl-1.0.2g" &&
	sudo tar -C "$build_dir" -xzf "$build_dir/openssl-1.0.2g.tar.gz" &&
	(
		cd "$build_dir/openssl-1.0.2g" &&
		sudo ./config --prefix="$STORAGE_ROOT/openssl" --openssldir="$STORAGE_ROOT/openssl" shared zlib &&
		sudo make &&
		sudo make install_sw
	) > "$build_dir/openssl.log" 2>&1; then
	sudo rm -rf "$build_dir/openssl-1.0.2g" "$build_dir/openssl-1.0.2g.tar.gz" "$build_dir/openssl.log"
	echo -e "$GREEN OpenSSL 1.0.2g Completed...$COL_RESET"
else
	echo -e "$RED OpenSSL 1.0.2g failed to build, see $build_dir/openssl.log$COL_RESET"
fi

echo -e " Building bls-signatures, this may take several minutes...$COL_RESET"
if sudo curl -fsSL --retry 3 -o "$build_dir/bls-signatures.zip" https://github.com/codablock/bls-signatures/archive/v20181101.zip &&
	sudo rm -rf "$build_dir/bls-signatures-20181101" &&
	sudo unzip -q -o "$build_dir/bls-signatures.zip" -d "$build_dir" &&
	(
		cd "$build_dir/bls-signatures-20181101" &&
		sudo cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 . &&
		sudo make install
	) > "$build_dir/bls-signatures.log" 2>&1; then
	sudo rm -rf "$build_dir/bls-signatures-20181101" "$build_dir/bls-signatures.zip" "$build_dir/bls-signatures.log"
	echo -e "$GREEN bls-signatures Completed...$COL_RESET"
else
	echo -e "$RED bls-signatures failed to build, see $build_dir/bls-signatures.log$COL_RESET"
fi

# blocknotify: built here with the same password as the stratum servers.
echo -e " Building blocknotify...$COL_RESET"
mp_clone_yiimp
yiimp_src="$STORAGE_ROOT/yiimp/yiimp_setup/yiimp"
if [ -n "${blckntifypass:-}" ]; then
	sudo sed -i "s|tu8tu5|$(sed_escape "$blckntifypass")|" "$yiimp_src/blocknotify/blocknotify.cpp"
	hide_output sudo make -C "$yiimp_src/blocknotify"
	sudo install -m 0755 "$yiimp_src/blocknotify/blocknotify" /usr/bin/blocknotify
else
	echo -e "$RED No blocknotify password known, copy blocknotify from your stratum server to /usr/bin manually.$COL_RESET"
fi

# The stratum runs on the DB server in the three server setup.
stratum_ip=${StratumInternalIP:-$DBInternalIP}
sudo tee /usr/bin/blocknotify.sh > /dev/null <<EOF
#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################
blocknotify $(printf '%q' "${stratum_ip}"):"\$1" "\$2" "\$3"
EOF
sudo chmod 0755 /usr/bin/blocknotify.sh
echo -e "$GREEN Done...$COL_RESET"

echo -e "$GREEN Daemon server build completed...$COL_RESET"
exit 0

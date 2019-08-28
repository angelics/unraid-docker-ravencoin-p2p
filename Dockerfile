# Build
FROM jlesage/baseimage:alpine-3.9

# Define working directory.
WORKDIR /tmp

RUN \
	echo "Adding ravend dependencies..." && \
	add-pkg \
		boost-system \
		boost-filesystem \
		boost-program_options \
		boost-thread \
		boost-chrono \
		libevent \
		libzmq \
		g++ \
		libgcc	

# Define download URLs.
ARG RAVENCOIN_VERSION=2.5.0
ARG RAVENCOIN_URL=https://github.com/RavenProject/Ravencoin/archive/v${RAVENCOIN_VERSION}.tar.gz
ARG BERKELEYDB_VERSION=db-4.8.30.NC
ARG BERKELEYDB_URL=https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
ARG BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN \
	add-pkg --virtual build-dependencies \
		curl \
		autoconf \
		automake \
		libtool \
		build-base \
		pkgconf \
		boost-dev \
		openssl-dev \
		libevent-dev \
		zeromq-dev \
		db-dev \
		binutils \
		&& \
	echo "download & install berkeley..." && \
	wget ${BERKELEYDB_URL} && \
	tar -xzf ${BERKELEYDB_VERSION}.tar.gz && \
	sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h && \
	cd ${BERKELEYDB_VERSION}/build_unix/ && \
	mkdir -p ${BERKELEYDB_PREFIX} && \
	../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BERKELEYDB_PREFIX && \
	make -j4 && \
	make install && \
	echo "Make install RavencoinWallet..." && \
	mkdir ravencoin && \
	curl -sS -L ${RAVENCOIN_URL} | tar -xz --strip 1 -C ravencoin && \
	cd ravencoin && \
	sed -i s:sys/fcntl.h:fcntl.h: src/compat.h && \
	./autogen.sh && \
	./configure LDFLAGS="-L${BERKELEYDB_PREFIX}/lib/" CPPFLAGS="-I${BERKELEYDB_PREFIX}/include/" \
				--enable-cxx \
				--disable-shared \
				--without-gui \
				--disable-tests \
				--disable-bench \
				--with-pic CXXFLAGS="-fPIC -O2" \
				&& \
	make -j4 && \
	make install && \
	strip --strip-unneeded /usr/local/bin/ravend && \
	strip --strip-unneeded /usr/local/lib/libravenconsensus.a && \
	strip --strip-unneeded /usr/local/bin/raven-cli && \
    echo "Remove unused packages..." && \
    del-pkg build-dependencies && \
	rm -rf /tmp/* /tmp/.[!.]* /opt/*

# Add files
COPY rootfs/ /

# Set environment variables.
ENV	APP_NAME="RavencoinP2P"

# Define mountable directories.
VOLUME ["/storage"]

# Expose port
EXPOSE 8767 18770 8766 18766 
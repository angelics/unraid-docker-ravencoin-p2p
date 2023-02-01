# Build
FROM jlesage/baseimage:alpine-3.17-v3

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
ARG RAVENCOIN_VERSION=4.6.1
ARG RAVENCOIN_URL=https://github.com/RavenProject/Ravencoin/archive/v${RAVENCOIN_VERSION}.tar.gz

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
		miniupnpc \
		&& \
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
				--disable-wallet \
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
	rm -rf /tmp/* /tmp/.[!.]*

# Add files
COPY rootfs/ /

# Set environment variables.
ENV	APP_NAME="RavencoinP2P"

# Define mountable directories.
VOLUME ["/storage"]

# Expose port
EXPOSE 8767 18770 8766 18766
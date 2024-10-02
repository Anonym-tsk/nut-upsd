FROM alpine:3.20 as builder

# https://networkupstools.org/download.html
ENV NUT_BRANCH="master"

# Find similar config in: https://git.alpinelinux.org/aports/tree/testing/nut/APKBUILD?id=17c662d69ebf24fbff2fa065d7544863ada956a5
RUN set -ex; \
	# run dependencies
	apk add --update  --no-cache \
        git \
		openssh-client \
		libusb-compat \
        nss \
	; \
	# build dependencies
	apk add --update --no-cache --virtual .build-deps \
		libusb-compat-dev \
#        libusb-dev \
        net-snmp-dev \
        openssl-dev \
        nss-dev \
        neon-dev \
		build-base \
        ccache perl curl \
        make autoconf automake libtool valgrind \
        cppcheck gcc g++ clang python3 \
        libmodbus-dev

WORKDIR /usr/src

# download and extract
RUN git clone -b $NUT_BRANCH https://github.com/networkupstools/nut
WORKDIR /usr/src/nut

# build
RUN ./autogen.sh
RUN ./configure \
    --prefix=/usr \
    --includedir=/usr/include \
    --infodir=/usr/share/info \
    --sysconfdir=/etc/nut \
    --localstatedir=/var \
    --libexecdir=/usr/lib/nut \
    --disable-silent-rules \
    --disable-dependency-tracking \
    --enable-strip \
    --disable-static \
    --with-all=no \
    --with-usb=yes \
    --datadir=/usr/share/nut \
    --with-nss \
    --with-openssl \
    --with-neon \
    --with-snmp \
    --with-drvpath=/usr/share/nut \
    #--with-drvpath=/usr/lib/nut \
    --with-statepath=/var/run/nut \
    --with-pidpath=/var/run/nut \
    --with-altpidpath=/var/run/nut \
    --with-user=nut \
    --with-group=nut \
    --with-systemdsystemunitdir=no

RUN make -j 4 all
RUN make -j 4 check

# cleanup
RUN rm -r /usr/share/man/man5 /usr/share/man/man8; \
	apk del .build-deps

FROM alpine:3.20

ENV UPS_NAME="ups"
ENV UPS_DESC="UPS"
ENV UPS_DRIVER="usbhid-ups"
ENV UPS_PORT="auto"

ENV API_PASSWORD=""
ENV ADMIN_PASSWORD=""

ENV SHUTDOWN_CMD="echo 'System shutdown not configured!'"

# Find similar config in: https://git.alpinelinux.org/aports/tree/testing/nut/APKBUILD?id=17c662d69ebf24fbff2fa065d7544863ada956a5
RUN set -ex; \
	apk add --update --no-cache \
		openssh-client \
		libusb-compat \
        nss \
        make

COPY --from=builder /usr/src/nut /usr/src/nut
WORKDIR /usr/src/nut

# install
RUN make install

# create nut user
RUN adduser -D -h /var/run/nut nut; \
	chgrp -R nut /etc/nut; \
	chmod -R o-rwx /etc/nut; \
	install -d -m 750 -o nut -g nut /var/run/nut \

# cleanup
RUN rm -rf /usr/src/nut; \
	rm -r /usr/share/man/man5 /usr/share/man/man8; \

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

WORKDIR /var/run/nut

VOLUME /etc/nut
EXPOSE 3493

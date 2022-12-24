# syntax=docker/dockerfile:1
FROM python:3.11.1-alpine3.16

# Maintainer
MAINTAINER Romain MARIADASSOU <roms2000@free.fr>

# Variables
ARG BURPVER=3.1.4
ARG BURPUIVER=1.0.0
ARG BURPREPORTSVER=1.4.2

# Add packages
RUN apk add --no-cache supervisor bash logrotate curl librsync libressl tzdata coreutils cronie monit postfix
# Add decompress packages
RUN apk add --no-cache --virtual .fetch-deps tar

# Retrieve burp
RUN wget -O burp.tar.gz https://github.com/grke/burp/archive/${BURPVER}.tar.gz
RUN mkdir -p /usr/src/burp
RUN tar -xC /usr/src/burp --strip-components=1 -f burp.tar.gz
RUN rm burp.tar.gz

# Remove decompress packages
RUN apk del .fetch-deps

# Add build packages
RUN apk add --no-cache --virtual .build-deps \
                autoconf \
                automake \
                bsd-compat-headers \
                g++ \
                libc-dev \
                libffi-dev \
                libtool \
                linux-headers \
                make \
                ncurses-dev \
                pkgconfig \
                uthash-dev \
                libressl-dev \
                librsync-dev \
                yajl-dev \
                zlib-dev

# Make burp
RUN cd /usr/src/burp \
        && autoreconf -vif \
        && ./configure --prefix=/usr --sysconfdir=/etc/burp --localstatedir=/var \
        && make && make install && make install-configs
RUN rm -rf /usr/src/burp

# Install burp-ui and burp-reports
RUN pip3 install burp-ui==${BURPUIVER}
RUN pip3 install "burp-ui[sql]"
RUN pip3 install "burp-ui[gunicorn]"
RUN pip3 install "burp-ui[gunicorn-extra]"
RUN pip3 install burp-reports==${BURPREPORTSVER}

# Remove build packages and pip cache
RUN apk del .build-deps && rm -rf /root/.cache

# Some fix
RUN ln -s /proc/1/fd/1 /var/log/burp.log
RUN if [ -e /usr/bin/libressl ] && [ ! -e /usr/bin/openssl ] ; then ln -s /usr/bin/libressl /usr/bin/openssl ; fi
RUN if [ -e /usr/local/bin/burp-reports ] && [ ! -e /usr/bin/burp-reports ] ; then ln -s /usr/local/bin/burp-reports /usr/bin/burp-reports ; fi
RUN mkdir -p /var/log/burp /var/log/gunicorn /var/log/burp-ui

# Copy files
COPY etc /etc
COPY scripts /root/scripts
RUN cp -p  /usr/share/burp/scripts/* /etc/burp/
RUN cp -pr /etc/burp /etc/burp-src-conf
RUN chmod 0600 /etc/monitrc
RUN chmod +x /usr/share/burp/scripts/*
RUN find /root/scripts -name '*.sh' -exec chmod +x "{}" \;

# Healthcheck
HEALTHCHECK --start-period=1m --interval=30s --timeout=5s --retries=2 CMD /root/scripts/healthcheck.sh

# Expose port
EXPOSE 4971
EXPOSE 4972
EXPOSE 5000

# Command to run
CMD ["/root/scripts/entrypoint.sh"]

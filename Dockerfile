FROM ubuntu:noble
LABEL org.opencontainers.image.authors="Somko"
ENV TARGETARCH amd64

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-magic \
        python3-num2words \
        python3-odf \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        python3-rjsmin \
        python3-geoip2 \
        python3-freezegun \
        python3-cbor2 \
        python3-asn1crypto \
        python3-openpyxl \
        gsfonts \
        xz-utils && \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59  ;; \
    "arm64")  WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=5312d7d34a25b321282929df82e3574319aed25c  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client-16 \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Begin install Somko
RUN apt-get update \
    && apt-get -y install --no-install-recommends jq whiptail nano htop wget unzip docutils-common fonts-dejavu-core fonts-font-awesome fonts-inconsolata fonts-roboto-unhinted graphviz gsfonts libann0 libcairo2 libcdt5 libcgraph6 libdatrie1 libev4 libfribidi0 libgd3 libglib2.0-0 libgraphite2-3 libgts-0.7-5 libgvc6 libgvpr2 libharfbuzz0b libice6 liblab-gamut1 libltdl7 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpathplan4 libpixman-1-0 libsass1 libsm6 libthai-data libthai0 libusb-1.0-0 libxaw7 libxcb-render0 libxcb-shm0 libxml2 libxmu6 libxpm4 libxslt1.1 libxt6 python-babel-localedata python3-appdirs python3-attr python3-babel python3-bs4 python3-cached-property python3-certifi python3-decorator python3-defusedxml python3-docutils python3-gevent python3-greenlet python3-idna python3-isodate python3-jinja2 python3-libsass python3-markupsafe python3-mock python3-ofxparse python3-openssl python3-passlib python3-pbr python3-polib python3-psutil python3-psycopg2 python3-pydot python3-pyparsing python3-pypdf2 python3-reportlab python3-reportlab-accel python3-requests python3-requests-file python3-requests-toolbelt python3-roman python3-serial python3-soupsieve python3-stdnum python3-tz python3-urllib3 python3-usb python3-werkzeug python3-xlsxwriter python3-zeep python3-zope.event python3-zope.interface sgml-base xml-core \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

RUN mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.old

ADD requirements.txt /
RUN pip3 install -r /requirements.txt

RUN mkdir -p /mnt/repo/custom /mnt/repo/third /usr/lib/python3/dist-packages/odoo/enterprise

# End install Somko

VOLUME ["/var/lib/odoo", "/mnt/repo"]
# Expose Odoo services
EXPOSE 8069 8071 8072

ENV ODOO_RC /tmp/odoo.conf
COPY ./entrypoint.sh /
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Install Odoo
ARG ODOO_VERSION=18.0
ARG ODOO_RELEASE=latest
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && dpkg -i ./odoo.deb \
    && rm odoo.deb

# Copy Odoo configuration file
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons

COPY custom /mnt/repo/custom
COPY third /mnt/repo/third

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
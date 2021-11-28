FROM debian:bullseye
WORKDIR /opt
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list &&\
    apt-get update && apt-get install --yes --no-install-recommends  \
    apt-transport-https\
    autoconf \
    build-essential \
    ca-certificates\
    git \
    libacl1-dev \
    libasound2-dev \
    libdbus-1-dev \
    libgccjit-10-dev \
    libgif-dev \
    libgnutls28-dev \
    libgpm-dev \
    libgtk-3-dev \
    libjansson-dev \
    libjbig-dev \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    liblcms2-dev\
    liblockfile-dev \
    libm17n-dev \
    libncurses-dev\
    libotf-dev \
    libpng-dev \
    librsvg2-dev  \
    libsystemd-dev \
    libtiff-dev \
    libxml2-dev \
    libxpm-dev \
    pkg-config \
    texinfo


# Clone emacs
RUN update-ca-certificates \
    && git clone --depth 1 https://github.com/emacs-mirror/emacs.git -b feature/pgtk \
    && mv emacs/* .

# Build
ENV CC="gcc-10"
RUN ./autogen.sh && ./configure \
    --prefix "/usr" \
    --with-native-compilation \
    --with-pgtk \
    --with-json \
    --with-gnutls \
    --with-dbus \
    --with-gif \
    --with-jpeg \
    --with-png \
    --with-rsvg \
    --with-tiff \
    --with-xft \
    --with-xpm \
    --with-modules \
    --with-mailutils \
    --without-xaw3d \
    CFLAGS="-O2 -pipe"

RUN make NATIVE_FULL_AOT=1 -j $(nproc)

# Create package
RUN EMACS_VERSION=$(sed -ne 's/AC_INIT(GNU Emacs, \([0-9.]\+\), .*/\1/p' configure.ac) \
    && make install prefix=/opt/emacs-gcc-pgtk_${EMACS_VERSION}/usr/ \
    && mkdir emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN && echo "Package: emacs-gcc-pgtk\n\
Version: ${EMACS_VERSION}\n\
Section: base\n\
Priority: optional\n\
Architecture: amd64\n\
Depends: libgif7, libotf0, libgccjit0, libm17n-0, libgtk-3-0, librsvg2-2, libtiff5, libjansson4, libacl1, libjpeg62-turbo, libdbus-1-3\n\
Maintainer: Andrea Vettorello <andrea.vettorello@gmail.com>\n\
Description: Emacs with native compilation and pure GTK\n\
    --with-native-compilation\n\
    --with-pgtk\n\
    --with-json\n\
    --with-gnutls\n\
    --with-dbus\n\
    --with-gif\n\
    --with-jpeg\n\
    --with-png\n\
    --with-rsvg\n\
    --with-tiff\n\
    --with-xft\n\
    --with-xpm\n\
    --with-modules\n\
    --with-mailutils\n\
    --without-xaw3d\n\
 CFLAGS='-O2 -pipe'" \
    >> emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN/control \
    && dpkg-deb --build emacs-gcc-pgtk_${EMACS_VERSION} \
    && mkdir /opt/deploy \
    && mv /opt/emacs-gcc-pgtk_*.deb /opt/deploy

FROM ubuntu:16.04

# install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git-core \
      curl \
      wget \
      ex \
      nasm \
      yasm \
      build-essential \
      libx264-dev \
      libx265-dev libnuma-dev \
      libvpx-dev \
      libfdk-aac-dev \
      libmp3lame-dev \
      libopus-dev \
      meson \
      ninja-build \
      libglib2.0-dev \
      cmake \
      libx11-dev \
      libnss3 \
      libnspr4 \
      libx11-xcb-dev \
      libxcb1 \
      libxcomposite-dev \
      libxcursor-dev \
      libxdamage-dev \
      libxfixes-dev \
      libxi-dev \
      libxrender-dev \
      libxtst-dev \
      fontconfig \
      libxrandr-dev \
      libxss-dev \
      libasound2 \
      libcairo2 \
      libpango1.0-0 \
      libatk1.0-0 \
      pulseaudio-utils \
      libarchive-dev \
      liborc-dev \
      flex \
      bison \
      libpulse-dev \
      libsoup2.4-dev \
      unzip \
      libatk-adaptor \
      at-spi \
      sudo \
      libjson-glib-dev \
      build-essential \
      autoconf \
      libtool \
      libgflags-dev \
      libgtest-dev \
      clang \
      libc++-dev \
      libcurl4-openssl-dev \
      gcovr \
      lcov \
      python3-pip && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp*

RUN   python3 -m pip install setuptools && \
      python3 -m pip install meson --upgrade

# We compile libx264 ourselves in order to have libx264.so
# provide support for both 8-nit and 10-bit
RUN git clone https://git.videolan.org/git/x264.git && \
    cd x264 && \
    ./configure --prefix=/usr --bit-depth=all --chroma-format=all --enable-pic --enable-shared && \
    make -j && \
    make install && \
    cd .. && \
    rm -rf x264

# We compile ffmpeg ourselves as we depend on a patch that should
# soon land in master for mpeg-2 CC injection support
RUN git clone https://github.com/FFmpeg/FFmpeg.git && \
    cd FFmpeg && \
    ./configure \
      --enable-gpl \
      --enable-libaom \
      --enable-libass \
      --enable-libfdk-aac \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-nonfree \
    --prefix=/usr && \
    make -j && \
    make install && \
    cd .. && \
    rm -rf FFmpeg


### Build grpc and tools

# Install GRPC
RUN git clone -b $(curl -L https://grpc.io/release) https://github.com/grpc/grpc /var/local/git/grpc && \
	cd /var/local/git/grpc && \
    git submodule update --init && \
    echo "--- installing grpc ---" && \
	ex -s -c '356i|CPPFLAGS += -Wno-unused-variable' -c x Makefile && \
    make -j$(nproc) && make install && ldconfig && \
	echo "--- installing protobuf ---" && \
    cd third_party/protobuf && \
    make install && make clean && ldconfig && \
	cd /var/local/git/grpc && make clean && \
    cd / && \
	rm -rf /var/local/git/grpc

# Latest CMake
RUN apt -y purge --auto-remove cmake
RUN mkdir -p /temp \
    && cd /temp \
    && wget https://github.com/Kitware/CMake/releases/download/v3.12.4/cmake-3.12.4-Linux-x86_64.sh \
    && mkdir -p /opt/cmake \
    && sh cmake-3.12.4-Linux-x86_64.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake && rm -rf /temp

# Install dumb-init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/local/bin/dumb-init
FROM circleci/node:8.5.0

RUN sudo apt-get update


RUN \
  sudo apt-get -y -qq install python-dev python-pip groff less && \
  sudo pip install awscli --upgrade && \
  aws --version

# RUN \
#   sudo apt-get -y -qq install build-essential cmake default-jre git-core libstdc++6 && \
#   cd ~/ && \
#   curl https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz | tar -xz && \
#   cd ./emsdk-portable && \
#   ./emsdk update && \
#   ./emsdk install latest && \
#   ./emsdk activate latest && \ 
#   /bin/bash -c "source ~/emsdk-portable/emsdk_env.sh"

# Install Rust
RUN \
  curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="$PATH:/home/circleci/.cargo/bin"

RUN rustup target add wasm32-unknown-emscripten
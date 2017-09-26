FROM node:8.5.0

RUN apt-get update
RUN apt-get install build-essential
RUN apt-get -y -qq install python-dev python-pip cmake default-jre git-core groff less

RUN pip install awscli --upgrade
RUN aws --version

RUN curl https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz | tar -xz
RUN cd ./emsdk-portable && ./emsdk update
RUN cd ./emsdk-portable && ./emsdk install latest
RUN cd ./emsdk-portable && ./emsdk activate latest
# RUN cd ./emsdk-portable && source ./emsdk_env.sh

# Install Rust
RUN \
  curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="$PATH:/root/.cargo/bin"

RUN rustup target add wasm32-unknown-emscripten
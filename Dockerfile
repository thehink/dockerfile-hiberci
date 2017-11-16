FROM circleci/node:9.1.0

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

# RUN \
#   sudo apt-get -y -qq install build-essential cmake default-jre git-core && \
#   cd ~/ && \
#   git clone https://github.com/juj/emsdk.git && \
#   cd ./emsdk && \
#   ./emsdk install sdk-incoming-64bit binaryen-master-64bit && \
#   ./emsdk activate sdk-incoming-64bit binaryen-master-64bit && \
#   /bin/bash -c "source ~/emsdk/emsdk_env.sh"

# BUILD EMSCRIPTEN

ENV EMCC_SDK_VERSION 1.37.22
ENV EMCC_SDK_ARCH 64
ENV EMCC_BINARYEN_VERSION 1.37.22

USER root

WORKDIR /

RUN echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list \
    && apt-get update && apt-get install -y --no-install-recommends -t jessie-backports gnupg ca-certificates build-essential cmake curl git-core openjdk-8-jre-headless ca-certificates-java python \
    && apt-mark hold openjdk-8-jre-headless \
    && apt-mark hold make \
    # && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    # && apt-get install -y nodejs \
    && curl https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz > emsdk-portable.tar.gz \
    && tar xzf emsdk-portable.tar.gz \
    && rm emsdk-portable.tar.gz \
    && cd emsdk-portable \
    && ./emsdk update \
    && ./emsdk install --build=MinSizeRel sdk-tag-$EMCC_SDK_VERSION-${EMCC_SDK_ARCH}bit \
    && ./emsdk install --build=MinSizeRel binaryen-tag-${EMCC_BINARYEN_VERSION}-${EMCC_SDK_ARCH}bit \
\
    && mkdir -p /clang \
    && cp -r /emsdk-portable/clang/tag-e$EMCC_SDK_VERSION/build_tag-e${EMCC_SDK_VERSION}_${EMCC_SDK_ARCH}/bin /clang \
    && mkdir -p /clang/src \
    && cp /emsdk-portable/clang/tag-e$EMCC_SDK_VERSION/src/emscripten-version.txt /clang/src/ \
    && mkdir -p /emscripten \
    && cp -r /emsdk-portable/emscripten/tag-$EMCC_SDK_VERSION/* /emscripten \
    && cp -r /emsdk-portable/emscripten/tag-${EMCC_SDK_VERSION}_${EMCC_SDK_ARCH}bit_optimizer/optimizer /emscripten/ \
    && mkdir -p /binaryen \
    && cp -r /emsdk-portable/binaryen/tag-${EMCC_BINARYEN_VERSION}_${EMCC_SDK_ARCH}bit_binaryen/* /binaryen \
    && echo "import os\nLLVM_ROOT='/clang/bin/'\nNODE_JS='nodejs'\nEMSCRIPTEN_ROOT='/emscripten'\nEMSCRIPTEN_NATIVE_OPTIMIZER='/emscripten/optimizer'\nSPIDERMONKEY_ENGINE = ''\nV8_ENGINE = ''\nTEMP_DIR = '/tmp'\nCOMPILER_ENGINE = NODE_JS\nJS_ENGINES = [NODE_JS]\nBINARYEN_ROOT = '/binaryen/'\n" > ~/.emscripten \
    && rm -rf /emsdk-portable \
    && rm -rf /emscripten/tests \
    && rm -rf /emscripten/site \
    && rm -rf /binaryen/src /binaryen/lib /binaryen/CMakeFiles \
    && for prog in em++ em-config emar emcc emconfigure emmake emranlib emrun emscons emcmake; do \
           ln -sf /emscripten/$prog /usr/local/bin; done \
    && apt-get -y --force-yes --purge remove curl git-core build-essential gcc \
    && apt-get -y clean \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && echo "Installed ... testing"
RUN emcc --version \
    && mkdir -p /tmp/emscripten_test && cd /tmp/emscripten_test \
    && printf '#include <iostream>\nint main(){std::cout<<"HELLO"<<std::endl;return 0;}' > test.cpp \
    && em++ -O2 test.cpp -o test.js && nodejs test.js \
    && em++ test.cpp -o test.js && nodejs test.js \
    && em++ -s WASM=1 test.cpp -o test.js && nodejs test.js \
    && cd / \
    && rm -rf /tmp/emscripten_test \
    && echo "All done."

WORKDIR /src

USER circleci

# Install Rust
# RUN \
#   curl https://sh.rustup.rs -sSf | sh -s -- -y

# ENV PATH="$PATH:/home/circleci/.cargo/bin"

# RUN rustup target add wasm32-unknown-emscripten
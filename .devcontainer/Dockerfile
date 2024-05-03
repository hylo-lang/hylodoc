ARG SWIFT_VERSION=5.9
# Other ARG declarations must follow FROM
FROM swift:${SWIFT_VERSION}

ARG HYLO_LLVM_BUILD_TYPE=MinSizeRel
ARG HYLO_LLVM_BUILD_RELEASE=20240303-215025
ARG HYLO_LLVM_VERSION=17.0.6

ENV HYLO_LLVM_DOWNLOAD_URL="https://github.com/hylo-lang/llvm-build/releases/download"

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y tar zstd libzstd1 libzstd-dev curl

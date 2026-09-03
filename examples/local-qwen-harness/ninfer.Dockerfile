# NInfer source is supplied as the build context by `local-ai prepare qwen-ninfer`.
# CUDA bases are pinned to their 2026-09-03 Linux/amd64 manifests.
FROM nvidia/cuda:13.1.2-devel-ubuntu24.04@sha256:952e42d23230610a2714c8484f38e9c934ed68e6f9c9c7fac62dcd5f98858a6e AS build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        cmake \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libcurl4-openssl-dev \
        libswscale-dev \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN cmake -S . -B /build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DNINFER_BUILD_APPS=ON \
        -DBUILD_TESTING=OFF \
        -DNINFER_BUILD_BENCHMARKS=OFF \
    && cmake --build /build --parallel --target ninfer ninfer-serve

FROM nvidia/cuda:13.1.2-runtime-ubuntu24.04@sha256:f0a6b69a753c1718da17e0d8864cd15c559960c6b68d4045c2d4d2bad0e6a87f

ARG DEBIAN_FRONTEND=noninteractive
ARG NINFER_SOURCE_REVISION=unknown
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        libavcodec60 \
        libavformat60 \
        libavutil58 \
        libcurl4t64 \
        libswscale7 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/apps/ninfer /usr/local/bin/ninfer
COPY --from=build /build/apps/ninfer-serve /usr/local/bin/ninfer-serve

LABEL org.opencontainers.image.source="https://github.com/Neroued/ninfer" \
      org.opencontainers.image.revision="${NINFER_SOURCE_REVISION}"

WORKDIR /workspace
EXPOSE 8080
STOPSIGNAL SIGTERM

CMD ["ninfer-serve", "--help"]

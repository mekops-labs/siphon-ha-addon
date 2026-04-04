ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.0.2

# --- Build Stage ---
FROM golang:1.25-alpine AS builder

WORKDIR /build
ARG BUILD_VERSION=main

RUN apk add --no-cache git
RUN git clone --depth 1 --branch $BUILD_VERSION https://github.com/mekops-labs/siphon.git
RUN cd siphon && go build -o /siphon ./cmd/siphon

# --- Runtime Stage ---
FROM $BUILD_FROM

COPY --from=builder /siphon /usr/bin/siphon
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.0.2
ARG TAG="main"

# --- Build Stage ---
FROM golang:1.25-alpine AS builder
WORKDIR /build

RUN apk add --no-cache git
RUN git clone --depth 1 --branch "$TAG"  https://github.com/mekops-labs/siphon.git .
RUN go build -o /siphon ./cmd/siphon

# --- Runtime Stage ---
FROM $BUILD_FROM

COPY --from=builder /siphon /usr/bin/siphon
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

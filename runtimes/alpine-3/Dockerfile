ARG FIVEM_NUM=7290
ARG FIVEM_VER=7290-a654bcc2adfa27c4e020fc915a1a6343c3b4f921
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

FROM alpine:3 AS builder

LABEL maintainer="Adrian Mejias <adrianmejias@gmail.com>"
LABEL description="FiveM server container"
LABEL version="1.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LD_LIBRARY_PATH=/opt/cfx-server:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib:/lib
ENV LD_PRELOAD=""

ARG FIVEM_NUM
ARG FIVEM_VER
ARG DATA_VER

WORKDIR /output

RUN mkdir -p /output/opt/cfx-server /output/opt/cfx-server-data /config
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk add --no-cache bash curl wget bzip2 unzip xz tini git python3 nodejs npm yarn pnpm \
    && wget -O- https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VER}/fx.tar.xz \
    | tar xJ --strip-components=1 \
    --exclude alpine/dev --exclude alpine/proc \
    --exclude alpine/run --exclude alpine/sys \
    && mkdir -p /output/opt/cfx-server-data /output/usr/local/share \
    && wget -O- http://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz \
    | tar xz --strip-components=1 -C opt/cfx-server-data \
    && apk -p $PWD add tini

COPY stubs/server.cfg.stub /output/opt/cfx-server-data/server.cfg
COPY entrypoint.sh /output/usr/bin/entrypoint
RUN chmod +x /output/usr/bin/entrypoint

FROM scratch

ENV TINI_SUBREAPER=1

ARG FIVEM_NUM
ARG FIVEM_VER
ARG DATA_VER

COPY --from=builder /output/ /

WORKDIR /config

EXPOSE 30120/tcp 30120/udp 40120/tcp

CMD ["/usr/bin/entrypoint"]
ENTRYPOINT ["/sbin/tini", "-s", "--", "/usr/bin/entrypoint"]

FROM golang:latest AS build
RUN mkdir -p /go/src/github.com/nsqio/ \
    && git clone https://github.com/nsqio/nsq.git /go/src/github.com/nsqio/nsq
WORKDIR      /go/src/github.com/nsqio/nsq

RUN git checkout v1.2.0 \
 && export GO111MODULE=on \
 && ./test.sh \
 && CGO_ENABLED=0 make DESTDIR=/opt PREFIX=/nsq BLDFLAGS='-ldflags="-s -w"' install


FROM extvos/alpine:latest
MAINTAINER  "Mingcai SHEN <archsh@gmail.com>"

EXPOSE 4150 4151 4160 4161 4170 4171

RUN mkdir -p /data
WORKDIR      /data

# set up nsswitch.conf for Go's "netgo" implementation
# https://github.com/golang/go/issues/35305
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

# Optional volumes (explicitly configure with "docker run -v ...")
# /data          - used by nsqd for persistent storage across restarts
# /etc/ssl/certs - for SSL Root CA certificates from host

COPY --from=build /opt/nsq/bin/ /usr/local/bin/
RUN ln -s /usr/local/bin/*nsq* / \
 && ln -s /usr/local/bin/*nsq* /bin/

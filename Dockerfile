FROM alpine:3.2

RUN apk update && \
    apk add socat && \
    rm -r /var/cache/apk/*

# `-t` is needed because of https://github.com/docker/docker/issues/16602
ENTRYPOINT ["socat", "-t", "100000000", "TCP-LISTEN:5522,reuseaddr,fork"]

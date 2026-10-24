FROM alpine:latest

RUN apk update && apk upgrade && \
	apk add tini bash shadow iproute2 iptables curl htop openresolv wireguard-tools qbittorrent-nox

RUN rm /sbin/sysctl && echo '#!/bin/sh' > /sbin/sysctl && chmod 755 /sbin/sysctl

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "/bin/bash", "/entrypoint.sh" ]

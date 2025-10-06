FROM --platform=$BUILDPLATFORM balabit/syslog-ng:4.10.1
LABEL oorg.opencontainers.image.source = "https://github.com/sva-s1/sentinelone-syslog-toolkit"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates tzdata gettext-base; \
    rm -rf /var/lib/apt/lists/*

# Runtime dirs
RUN set -eux; \
     mkdir -p /var/lib/syslog-ng \
              /var/log/syslog-ng \
              /var/run/syslog-ng \
              /etc/syslog-ng && \
     chown -R 1000:1000 /var/lib/syslog-ng /var/log/syslog-ng /var/run/syslog-ng /etc/syslog-ng && \
     chmod -R 755 /var/lib/syslog-ng /var/log/syslog-ng /var/run/syslog-ng /etc/syslog-ng

# Templates & entrypoint (repo-root paths)
COPY --chown=1000:1000 syslog-ng.conf.tmpl /etc/syslog-ng/syslog-ng.conf.tmpl
COPY --chmod=755 entrypoint.sh /entrypoint.sh

EXPOSE 5514/udp
WORKDIR /var/lib/syslog-ng
USER 1000:1000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["syslog-ng","-F","--no-caps"]




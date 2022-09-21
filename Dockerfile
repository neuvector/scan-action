FROM registry.suse.com/bci/bci-base:15.4

RUN zypper in -y jq docker && zypper clean

COPY run-scan.sh /usr/bin

ENTRYPOINT ["/usr/bin/run-scan.sh"]

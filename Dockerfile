FROM registry.suse.com/bci/bci-base:15.7

RUN zypper in -y jq docker && zypper clean

COPY run-scan.sh /usr/bin
COPY utils.sh /usr/bin

RUN chmod +x /usr/bin/run-scan.sh

ENTRYPOINT ["/usr/bin/run-scan.sh"]

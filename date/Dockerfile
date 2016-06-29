FROM hepsw/slc-base

COPY yum-alice-daq.slc6_64.repo /etc/yum.repos.d/

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y which date urw-fonts nc tmux \
    openssh-server openssh-clients daqDA-lib && \
    useradd daq -pvmG5WTRjaU3HU

COPY *.sh /

ENV DAQDALIB_PATH /opt/daqDA-lib

ENTRYPOINT ["/date_setup.sh"]

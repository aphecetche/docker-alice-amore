FROM aphecetche/alice-date

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y libXpm libGLU amore amore-web dqmv aliroot

RUN yum install -y openssh-server openssh-clients

ADD ./amore_setup.sh /
ADD ./ssh_setup.sh /

RUN useradd daq -pvmG5WTRjaU3HU

ENTRYPOINT ["/amore_setup.sh"]


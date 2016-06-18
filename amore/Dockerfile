FROM aphecetche/alice-date

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y libXpm libGLU amore amore-web dqmv aliroot \
    openssh-server openssh-clients

ADD ./amore_setup.sh /
ADD ./launch_amoreGui.sh /

RUN useradd daq -pvmG5WTRjaU3HU

ENTRYPOINT ["/amore_setup.sh"]


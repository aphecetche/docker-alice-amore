FROM aphecetche/alice-date

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y libXpm libGLU amore amore-web dqmv aliroot 

ADD ./amore_setup.sh /

ENTRYPOINT ["/amore_setup.sh"]


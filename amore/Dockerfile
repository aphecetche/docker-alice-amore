FROM aphecetche/alice-date

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y libXpm libGLU amore amore-web dqmv 

COPY ./amore_setup.sh /
ADD ./amore_start_agent.sh /

ENTRYPOINT ["/amore_setup.sh"]


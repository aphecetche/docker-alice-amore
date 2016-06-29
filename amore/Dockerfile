FROM alice-date

RUN rpmdb --rebuilddb && \
    yum clean all && \
    yum update -y yum && \
    yum update -y && \
    yum install -y libXpm libGLU amore amore-web dqmv \
    ACT aliroot

COPY *.sh /
COPY data_for_db_agents.raw /

ENTRYPOINT ["/amore_setup.sh"]


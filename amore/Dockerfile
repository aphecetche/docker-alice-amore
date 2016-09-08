FROM alice-date

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm && \
yum install -y libXpm libGLU amore amore-web dqmv \
    ACT aliroot

COPY *.sh /
COPY data_for_db_agents.raw /
COPY AMORE.params /amoreSite/

ENTRYPOINT ["/amore_setup.sh"]


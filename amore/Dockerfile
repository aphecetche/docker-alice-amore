FROM aphecetche/alice-date

RUN yum install -y amore amore-web libXpm dqmv libGLU 

COPY ./amore_setup.sh /
ADD ./amore_start_agent.sh /

ENTRYPOINT ["/amore_setup.sh"]


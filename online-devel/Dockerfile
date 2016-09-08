FROM alice-amore

RUN yum install -y centos-release-scl

RUN yum install -y tar git gettext-devel cmake3 \
        make wget which gcc gcc-c++ libtool automake autoconf zip \
        exinfo bison flex openssl-devel \
        libxml2-devel swig perl-ExtUtils-Embed \
        environment-modules \
        libX11-devel mesa-libGLU-devel libXpm-devel libXft-devel \
        gcc-gfortran bzip2 bzip2-devel python-pip tmux screen \
        ncurses-devel texinfo python-devel \
        file vim rpm-build \
        MySQL-devel ncdu glibc-static libxml2-static zlib-static openssl-static

# get more decent git, python and gcc than the ones in centos 6 stock

RUN yum install -y devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gcc-gfortran devtoolset-3-gdb git19 python27

RUN ln -s /usr/bin/cmake3 /usr/bin/cmake && \
        cd /tmp && \
        curl -O http://mirror.ibcp.fr/pub/gnu/gsl/gsl-1.16.tar.gz && \
        tar -zvxf gsl-1.16.tar.gz && \
        cd gsl-1.16 && \
        ./configure && \
        make && make install && \
        rm -rf /tmp/gsl* 
        
RUN pip install --upgrade pip && pip install alibuild==1.4.0.rc1

RUN yum install -y libpng-devel yaml-cpp-devel

COPY bashrc /root/.bashrc
COPY mock-redhat-release-slc6.txt /etc/redhat-release
COPY mock-uname-slc6.sh /bin/uname

ENTRYPOINT ["/amore_setup.sh"]

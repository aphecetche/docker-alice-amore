FROM alice-amore

RUN rpm --rebuilddb && yum install -y yum-plugin-ovl centos-release-scl

RUN yum install -y tar git gettext-devel cmake3 \
        make wget which gcc gcc-c++ libtool automake autoconf zip \
        exinfo bison flex openssl-devel \
        libxml2-devel swig perl-ExtUtils-Embed \
        environment-modules \
        libX11-devel mesa-libGLU-devel libXpm-devel libXft-devel \
        gcc-gfortran bzip2 bzip2-devel python-pip tmux screen \
        ncurses-devel texinfo python-devel \
        file vim rpm-build \
        MySQL-devel ncdu glibc-static libxml2-static zlib-static openssl-static \
        libpng-devel yaml-cpp-devel \
# get more decent git, svn, python, gcc than the ones in centos 6 stock
        devtoolset-3-gcc \
        devtoolset-3-gcc-c++ \
        devtoolset-3-gcc-gfortran \
        devtoolset-3-gdb git19 python27 \
        sclo-subversion19

RUN pip install alibuild

COPY bashrc /root/.bashrc
COPY mock-redhat-release-slc6.txt /etc/redhat-release
COPY mock-uname-slc6.sh /bin/uname


ENTRYPOINT ["/amore_setup.sh"]

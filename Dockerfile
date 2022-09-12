FROM debian:stretch

RUN apt-get update -y

RUN apt-get install -y \
  lua5.1 \
  liblua5.1-0-dev \
  luarocks \
  git \
  libssl1.0-dev \
  make

RUN git config --global url.https://github.com/.insteadOf git://github.com/

WORKDIR /home/plugin

ADD Makefile .
RUN make setup

ADD kong-plugin-totp-validator-*.rockspec .
RUN chmod -R a+rw /home/plugin
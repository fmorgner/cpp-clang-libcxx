FROM scratch

MAINTAINER Felix Morgner <felix.morgner@gmail.com>

ADD docker-void/* /

ENV CC=clang CXX=clang++

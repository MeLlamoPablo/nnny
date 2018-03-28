FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install curl -y

ADD test.sh /nnny/test.sh

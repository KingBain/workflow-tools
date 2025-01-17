# HMMER and Skewer
FROM debian:buster as debian
WORKDIR /build
RUN apt-get update && apt-get install -y build-essential wget bioperl
RUN wget http://eddylab.org/software/hmmer/hmmer-3.2.1.tar.gz && \
    tar -xf hmmer-3.2.1.tar.gz && \
    cd hmmer-3.2.1 && \
    ./configure --prefix /build/hmmer && \
    make && \
    make install && \
    wget https://github.com/relipmoc/skewer/archive/0.2.2.tar.gz && \
    tar -xf 0.2.2.tar.gz && \
    cd skewer-0.2.2 && \
    make && \
    mv skewer /build

# Bowtie2
FROM alpine:latest as bowtie
WORKDIR /build
RUN wget https://github.com/BenLangmead/bowtie2/releases/download/v2.3.2/bowtie2-2.3.2-legacy-linux-x86_64.zip && \
    unzip bowtie2-2.3.2-legacy-linux-x86_64.zip && \
    mkdir bowtie2 && \
    cp bowtie2-2.3.2-legacy/bowtie2* bowtie2

# FastQC
FROM alpine:latest as fastqc
WORKDIR /build
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip

# Pigz
FROM debian:buster as pigz
WORKDIR /build
RUN apt-get update && apt-get install -y make gcc zlib1g-dev wget
RUN wget https://zlib.net/pigz/pigz-2.7.tar.gz && \
    tar -xzvf pigz-2.7.tar.gz && \
    cd pigz-2.7 && \
    make

#Spring
FROM debian:buster as spring
WORKDIR /build
RUN apt-get update && apt-get install -y make cmake g++ zlib1g-dev  wget
RUN wget https://github.com/shubhamchandak94/Spring/archive/refs/tags/v1.0.1.tar.gz && \
    tar -xzvf v1.0.1.tar.gz && \
    cd Spring-1.0.1 && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make

FROM python:3.8-buster as jre
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jre && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

FROM jre as main
COPY --from=bowtie /build/bowtie2/* /usr/local/bin/
COPY --from=debian /build/hmmer /opt/hmmer
COPY --from=debian /build/skewer /usr/local/bin/
COPY --from=fastqc /build/FastQC /opt/fastqc
COPY --from=pigz /build/pigz-2.7/pigz /usr/local/bin/pigz
COPY --from=spring /build/Spring-1.0.1/build/spring /usr/local/bin/spring

RUN chmod ugo+x /opt/fastqc/fastqc && \
    ln -fs /opt/fastqc/fastqc /usr/local/bin/fastqc && \
    for file in `ls /opt/hmmer/bin`; do ln -fs /opt/hmmer/bin/${file} /usr/local/bin/${file};  done

ENV PATH $PATH:/root/.local/bin
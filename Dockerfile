FROM python:3.6-alpine3.7 as build

ENV LANG C.UTF-8

RUN apk update && apk upgrade && \
    apk add --no-cache git gzip gfortran musl-dev gcc make g++ file libc-dev zlib-dev jpeg-dev lapack-dev && \
    pip3 install --upgrade pip
RUN apk --update add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo Asia/Tokyo > /etc/timezone && \
    rm -rf /var/cache/apk/*

# Build bootloader for alpine
RUN git clone https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && python ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller

RUN pip3 install six packaging ipaddress requests numpy asciimatics ltsv apache-log-parser dnspython
RUN pip3 install scipy

RUN mkdir /app
WORKDIR /app
ADD . /app

RUN cd /app && pyinstaller --hidden-import six \
    --hidden-import packaging \
    --hidden-import packaging.version \
    --hidden-import packaging.specifiers \
    --hidden-import packaging.requirements \
    --clean --strip --noconfirm --onefile -n tip trend_of_ip.py

FROM alpine:3.7

RUN apk update && apk upgrade && apk --update add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo Asia/Tokyo > /etc/timezone && \
    rm -rf /var/cache/apk/* && \
    mkdir /app

WORKDIR /app

COPY --from=build /app/dist/tip /app/dist/tip

ENTRYPOINT ["/app/dist/tip"]

FROM debian:buster

# DMOJ Site Dockerfile
# If you are using external judgers, UNCOMMENT last two lines.

RUN mkdir /site /uwsgi

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y nano debconf-utils default-libmysqlclient-dev gnupg wget git gcc g++ make python-dev libxml2-dev libxslt1-dev zlib1g-dev gettext curl wget openssl vim supervisor mycli python3-pip
RUN echo 'deb http://mirrors.ustc.edu.cn/nodesource/deb/node_12.x buster main' >> /etc/apt/sources.list && \
    echo 'deb http://nginx.org/packages/debian/ buster nginx' >> /etc/apt/sources.list && \
    wget -qO - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    wget -qO - https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    apt-get update && apt-get install -y nodejs nginx
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g sass postcss postcss-cli autoprefixer && \
    apt-get clean

RUN useradd -m -U dmoj

WORKDIR /site
RUN git clone https://github.com/phxoj/site.git /site
RUN git submodule init && \
    git config -f .gitmodules submodule.resources/libs.shallow true && \
    git config -f .gitmodules submodule.resources/pagedown.shallow true && \
    git submodule update
RUN pip3 config set global.index-url https://opentuna.cn/pypi/web/simple && \
    pip3 install --upgrade pip && \
    pip3 install -r requirements.txt && \
    pip3 install mysqlclient django_select2 websocket-client pymysql uWSGI
RUN npm install qu ws simplesets
COPY local_settings.py /site/dmoj
COPY config.js /site/websocket

RUN ./make_style.sh && \
    echo yes | python3 manage.py collectstatic && \
    python3 manage.py compilemessages && \
    python3 manage.py compilejsi18n && \
    mv /site /osite

COPY uwsgi.ini /uwsgi
COPY site.conf bridged.conf wsevent.conf /etc/supervisor/conf.d/

RUN rm /etc/nginx/conf.d/*
ADD nginx.conf /etc/nginx/conf.d
ADD start.sh /

RUN wget https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait -O /wait && \
    chmod +x /wait

CMD /wait && /bin/sh /start.sh

EXPOSE 80
EXPOSE 443
EXPOSE 15100
EXPOSE 15101
EXPOSE 15102
EXPOSE 9998
EXPOSE 9999

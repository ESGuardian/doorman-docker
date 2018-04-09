FROM alpine:latest

# Install Python
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && apk add --update \
              bash \
              build-base \
              git \
              libffi-dev \
              musl \
              nodejs \
              nodejs-npm \
              postgresql-dev \
              py2-pip \
              python \
              python-dev \
              redis \
              runit \
  && pip install --upgrade pip \
  && npm install -g bower less \
  && rm /var/cache/apk/*
  
RUN apk add --no-cashe python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache




# Copy and install our requirements first, so they can be cached
COPY ./requirements/prod.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt \
  && pip install 'gunicorn==19.6.0'

# Add our application to the container
COPY . /src/

# Create service directories to allow running services, along with the Doorman
# user/group.
RUN rm -rf /etc/service \
  && mv /src/docker/service /etc/ \
  && mv /src/docker/redis.conf /etc/ \
  && if [ ! -f /src/settings.cfg ]; then \
       mv /src/docker/default-settings.cfg /src/settings.cfg; \
     fi \
  && addgroup doorman \
  && adduser -G doorman -D doorman

# Install vendor libraries, pre-build static assets, and create default log
# file directory.
RUN cd /src/ \
  && bower install --allow-root \
  && python manage.py assets build \
  && mkdir /var/log/doorman/ \
  && chown doorman:doorman -R . \
  && chown doorman:doorman /var/log/doorman/

CMD ["runsvdir", "/etc/service"]

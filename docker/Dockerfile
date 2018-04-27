FROM python:3.6-slim

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        git \
        build-essential \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/vcap/app/

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY application.py .
COPY gunicorn_config.py .
COPY Makefile .
COPY run_app.sh .
COPY run_uwsgi_app_docker.sh .

ARG PORT
ARG APP_NAME
ENV PORT=$PORT
ENV APP_NAME=$APP_NAME
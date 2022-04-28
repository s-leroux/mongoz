#!/bin/sh

sudo docker run -d \
  -p 127.0.0.1:27017:27017 \
  --name mongo \
  -e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
  -e MONGO_INITDB_ROOT_PASSWORD=mongopass \
  mongo


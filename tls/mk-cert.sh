#!/bin/bash

openssl req -x509 -nodes -days 730 \
  -newkey rsa:2048 -keyout privkey.pem \
  -out fullchain.crt \
  -config req.conf \
  -extensions 'v3_req'
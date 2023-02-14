#!/bin/bash

if [ ! -f nginx/fullchain.pem ] || [ ! -f nginx/privkey.pem ] 
then
  echo '#'
  echo '# WARN: TLS cert or key not found. Generating at nginx/fullchain.pem nginx/privkey.pem'
fi



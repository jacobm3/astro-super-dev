#!/bin/bash

cd astro-dev
astro dev stop
cd -

docker stop nginx statsd prom grafana vault

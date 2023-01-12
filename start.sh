#!/bin/bash

docker start nginx statsd prom grafana vault

cd astro-dev
astro dev start
cd -


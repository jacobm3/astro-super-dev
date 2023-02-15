#!/bin/bash

docker start nginx

cd astro-dev
astro dev start
cd -


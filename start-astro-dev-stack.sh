#!/bin/bash -x

. config.env

if [ -z ${ASTRODIR} ]; then
  echo "\$ASTRODIR not defined"
  exit 1
fi

if [ ! -d $ASTRODIR ]
then
  mkdir -p $ASTRODIR && cd $ASTRODIR && astro dev init && cd -
fi

# Put your TLS cert and key here if you get one from somewhere else.
TLSCERT=nginx/fullchain.pem
TLSKEY=nginx/privkey.pem
if [ ! -f $TLSCERT ] || [ ! -f $TLSKEY ] 
then
  echo "# WARN: TLS cert or key not found. Generating at $TLSCERT $TLSKEY"
  rm -f $TLSCERT $TLSKEY
  openssl req -x509 -nodes -days 730 \
    -newkey rsa:2048 -keyout $TLSKEY \
    -out $TLSCERT \
    -config tls/req.conf \
    -extensions 'v3_req'
fi

# Limit the scheduler to a percentage of system memory. Important for load tests.
# Expressed as a float between 0 and 1.
if [ -z ${SCHEDULER_MEM_PERCENT} ]; then
  export SCHEDULER_MEM_PERCENT=0.70
fi

set -e

cd $ASTRODIR
astro dev start -n 
cd ..

network=$(docker inspect $(docker ps --format {{.Names}} | grep $ASTRODIR | grep postgres-)  -f "{{json .NetworkSettings.Networks }}" | jq -M -r '.[] | .NetworkID')

echo
echo '#################################################################################'
echo 'Astro performance tuning.'

# Determine good scheduler memory limits. Too many concurrent tasks will cause swapping without this.
scheduler_ram_k=$(printf "%.0fk\n" $(echo "$(head -n1 /proc/meminfo | awk '{print $2}')  * $SCHEDULER_MEM_PERCENT " | bc))
scheduler_swap_k=$(printf "%ik" $(head -n1 /proc/meminfo | awk '{print $2}'))
docker container update --memory $scheduler_ram_k --memory-swap $scheduler_swap_k  $(docker ps | grep scheduler-1 | awk '{print $1}')

# Raise postgres connection limits
pgcontainer=$(docker ps | grep $ASTRODIR | grep postgres | cut -f1 -d' ')
docker exec $pgcontainer sed -i 's/max_connections = .*/max_connections = 1000/' /var/lib/postgresql/data/postgresql.conf

echo
echo '#################################################################################'
echo 'Starting nginx.'

# Get webserver container name. Required for nginx config.
webserver=$(docker ps --format {{.Names}} | grep $ASTRODIR | grep webserver-)


sed "s/AIRFLOW-WEBSERVER/$webserver/" < nginx/nginx.conf.template > nginx/nginx.conf
docker run -d \
  -p 80:80 \
  -p 443:443 \
  --restart unless-stopped \
  --network $network \
  --name nginx \
  -v $PWD/nginx:/etc/nginx/ \
  nginx 

# echo
# echo "Airflow:          http://${NODENAME}.${DOMAIN}/"
# echo "Airflow:          http://${NODENAME}.${DOMAIN}:8080/"
# echo "Airflow TLS:      https://${NODENAME}.${DOMAIN}/"
# echo "Grafana:          http://${NODENAME}.${DOMAIN}:3000/"
# echo "Grafana TLS:      https://${NODENAME}.${DOMAIN}:3443/"
# echo "Vault:            http://${NODENAME}.${DOMAIN}:8200/"
# echo "Vault TLS:        https://${NODENAME}.${DOMAIN}:8201/"
# echo

#!/usr/bin/env bash
#####################################################################################################
# Starts up the api, portal, and dependent services via
# docker-compose. The api will be available on localhost:9000 and the
# portal will be on localhost:9001
#
# Relevant overrides can be found at ./.env and ../docker/.env
#
# Options:
#	-t, --timeout seconds: overwrite ping timeout, default of 60
#	-a, --api-only: only starts up vinyldns-api and its dependencies, excludes vinyldns-portal
#####################################################################################################

DIR=$( cd $(dirname $0) ; pwd -P )
TIMEOUT=60
DOCKER_COMPOSE_CONFIG="${DIR}/../docker/docker-compose-build.yml"

function wait_for_url {
	echo "pinging ${URL} ..."
	DATA=""
	RETRY="$TIMEOUT"
	while [ "$RETRY" -gt 0 ]
	do
		DATA=$(curl -I -s "${URL}" -o /dev/null -w "%{http_code}")
		if [ $? -eq 0 ]
		then
			echo "Succeeded in connecting to ${URL}!"
			break
		else
			echo "Retrying Again" >&2

			let RETRY-=1
			sleep 1

			if [ "$RETRY" -eq 0 ]
			then
			  echo "Exceeded retries waiting for ${URL} to be ready, failing"
			  exit 1
			fi
		fi
	done
}

function usage {
    printf "usage: docker-up-vinyldns.sh [OPTIONS]\n\n"
    printf "starts up a local VinylDNS installation using docker compose\n\n"
    printf "options:\n"
    printf "\t-t, --timeout seconds: overwrite ping timeout of 60\n"
}

while [ "$1" != "" ]; do
    case "$1" in
        -t | --timeout ) TIMEOUT="$2";  shift;;
        * ) usage; exit;;
    esac
    shift
done

echo "timeout set to $TIMEOUT"

echo "Starting vinyldns and all dependencies in the background..."
docker-compose -f "$DOCKER_COMPOSE_CONFIG" up -d

echo "Waiting for api..."
URL="http://localhost:9000/ping"
wait_for_url

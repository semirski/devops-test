#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -eq 0 ]
then
    echo "Usage: ./script.sh registry_url/namespace/repository:tag" >&2
    exit 1
fi

# function that checks the existence of a command or file
exists() {
	if command -v "$1" >/dev/null 2>&1; then
		echo "Command $1 exists"
	else
		echo "Please install $1. Exiting..." >&2
		exit 1
	fi
}

# function that checks the docker daemon is running or not
service_running() {
  if pgrep -x "$1" >/dev/null 2>&1; then
    echo "The docker service is running"
  else
    echo "Check the docker service! Is it running? Exiting..." >&2
    exit 1
fi
}


build_image() {
  docker build -t "$1" .
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "Image $1 build was succesful."
  else
    echo "Image $1 build failed. Exiting..." >&2
    exit 1
  fi
}

docker_login() {
  REGISTRY_URL="https://registry-1.docker.io/v2/"
  read -r -p "Enter Docker Hub Username : " USERNAME
  read -r -s -p "Enter Docker Hub Password: " PASSWORD
  echo "$PASSWORD" | docker login $REGISTRY_URL -u "$USERNAME" --password-stdin
  unset PASSWORD
}

push_image() {
  docker push "$1"
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "Image $1 push was succesful."
  else
    echo "Image $1 push failed. Exiting..." >&2
    exit 1
  fi
}

# function rolls out a helm release with the just pushed image
helm_release() {
  PATH_TO_CHART=.infra/k8s/test
  readarray -d : -t strarr <<< "$1"
  yq -i ".appVersion = ${strarr[1]}" $PATH_TO_CHART/Chart.yaml
  yq -i ".image.tag = ${strarr[1]}" $PATH_TO_CHART/values.yaml
  helm upgrade -i test -f $PATH_TO_CHART/values.yaml $PATH_TO_CHART
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "Helm release rolled out succesfully."
  else
    echo "Helm release roll out failed. Exiting..." >&2
    exit 1
  fi
}

exists "helm"
exists "yq"
exists "docker"
exists "dockerd"

service_running "dockerd"

build_image "$1"
docker_login
push_image "$1"
helm_release "$1"













#!/bin/bash -x
USERNAME=$1
HOST=$2
PORT=$3
ssh -Tq ${USERNAME}@${HOST} -p ${PORT} 'sudo sh -s' < setup.sh

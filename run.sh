#!/bin/bash -x
USERNAME=$1
HOST=$2
ssh -Tq ${USERNAME}@${HOST} 'sudo sh -s' < setup.sh

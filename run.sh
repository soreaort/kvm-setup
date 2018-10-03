#!/bin/bash   
ssh -Tq $1 'sudo sh -s' < setup.sh

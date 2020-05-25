#!/usr/bin/env bash

# Initializing the bootnode
nohup bootnode -nodekey bootnode/boot.key -verbosity 9 -addr :30310 2>/dev/null 1>bootnode/enodeAddr.txt &
sleep 1

# Initialising the nodes
numNodes=2
i=0
echo "Starting Signers"
echo "Please Wait"

while [[ $i -lt $numNodes ]]; do
  cd node$i
  chmod 777 init.sh
  nohup bash init.sh  2>errors.txt 1>log.txt &
  sleep 1
  cd ..
  echo "."
  let i++
done

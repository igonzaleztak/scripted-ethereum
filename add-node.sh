#!/usr/bin/env bash

if [[ $1 ]];
then    
    nodeName=$1
    if [[ $2 ]];
    then
        portBase=$2
    else
        portBase=30318
    fi
else
    nodeName="new-node"
    portBase=30318
fi

rm -R $nodeName 2>/dev/null
mkdir $nodeName

# Creating and account for the new node. This step can be ommitted
geth --datadir $nodeName/ account new

# Initializing the node with the genesis.json
geth --datadir $nodeName/ init genesis.json 2>&1 /dev/null

# Getting the bootnode address
regexp="(enode:\S*):0\?discport=([0-9]*)"
text=$(< bootnode/enodeAddr.txt)

if [[ $text =~ $regexp ]];
then
    bootnodeAddr="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
else
    echo "Something went wrong"
fi

# Getting the chain ID
regexp="\S*chainId\S*:\s*([0-9]*)"

if [[ $(cat genesis.json) =~ $regexp ]];
then
    networkID="${BASH_REMATCH[1]}"
fi

# Starting the node
ipAddr=127.0.0.1

geth --datadir $nodeName/  --syncmode full  --verbosity 3 --networkid $networkID --port $portBase  --nat=extip:$ipAddr --gasprice '0' --bootnodes "$bootnodeAddr"
echo -e "#!/usr/bin/env bash\n" > $nodeName/init.sh
echo -n "geth --datadir ./ --syncmode full --verbosity 3 --networkid $networkID --port $portBase --nat=extip:$ipAddr --gasprice '0'  --bootnodes \"$bootnodeAddr\"" >> $nodeName/init.sh
chmod a+x $nodeName/init.sh
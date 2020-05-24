if [[ $1 ]];
then
    numNodes=$1
else
    numNodes=2
fi

# Removing all the nodes, in case they were previously created
# rm -R node* 2> /dev/null
rm -R bootnode 2> /dev/null
killall geth 2> /dev/null
killall bootnode 2> /dev/null
rm alloc.txt 2> /dev/null

rm -R node0/geth/*chain* 2>/dev/null
rm -R node1/geth/*chain* 2>/dev/null
rm -R node2/geth/*chain* 2>/dev/null
rm -R setup 2>/dev/null
rm -R setup/? 2>/dev/null
rm -R node* 2>/dev/null
rm alloc.txt 2>/dev/null


# Create the directories
echo "Insert the passwords for the different users"
echo "."
echo "."
i=0
while [ $i -lt $numNodes ]
do
    mkdir node$i
    mkdir node$i/geth
    mv setup/$i/nodekey node$i/geth/
    geth --datadir node$i/ account new
    let i++
done

# greping the addresses of the accounts that has just been created
regex=".*--(\S{40})"

i=0
while [ $i -lt $numNodes ]
do
  var=$(ls node$i/keystore/)
  if [[ $var =~ $regex ]];
  then
    addr[i]="${BASH_REMATCH[1]}"
    echo ${addr[i]}
    let i++
  else
    echo "Something went wrong while grepping the users' accounts"
  fi
done


# Preparing the field extraData
# Vanity: 32 bytes, all zeroes
vanity="0000000000000000000000000000000000000000000000000000000000000000"

# Variable with the addresses of all the signers concatenated
signers=$(printf "%s\n" "$(IFS= ;printf '%s' "${addr[*]}")")

# Proposer sea: 65 bytes signature suffix, it must be filled with zeroes
proposerSeal="0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

# ExtraData field
extraData='"extraData": "0x'$vanity$signers$proposerSeal'",'

# Swaping the extraData field in the genesis.json
line='"extraData": "0x00000000000000000000000000000000000000000000000000000000000000002fe0aa42988ef1ac0da1040cd333ea3980b4be320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",'
sed -i "s/$line/$extraData/" genesis.json

# initialize all the nodes with the genesis block (genesis.json)
i=0
while [ $i -lt $numNodes ]
do
    geth --datadir ./node$i init genesis.json
    let i++
done

# Creating a bootnode
mkdir bootnode
bootnode --genkey=bootnode/boot.key

# Initializing the bootnode
nohup bootnode -nodekey bootnode/boot.key --nat=extip:127.0.0.1 -verbosity 9 -addr :30310 2>/dev/null 1>bootnode/enodeAddr.txt &
sleep 2

# Getting the bootnode address
regexp="(enode:\S*):0\?discport=([0-9]*)"
text=$(< bootnode/enodeAddr.txt)

if [[ $text =~ $regexp ]];
then
    bootnodeAddr="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
else
    echo "Something went wrong"
fi

echo "$bootnodeAddr"

# Getting the chain ID
regexp="\S*chainId\S*:\s*([0-9]*)"

if [[ $(cat genesis.json) =~ $regexp ]];
then
    networkID="${BASH_REMATCH[1]}"
fi

# Initialising the signer nodes
ipAddr=127.0.0.1
portBase=30300
i=0

while [[ $i -lt $numNodes ]];
do
    echo -e "\n\n"
    echo "Insert the password of node$i"
    read pass
    echo $pass >  node$i/password.txt
    pass=" "

    geth --datadir node$i/  --syncmode full --miner.etherbase "0x${addr[i]}" --nat=extip:$ipAddr --mine --minerthreads 1 --verbosity 3 --networkid $networkID --port $portBase --gasprice '0' --rpccorsdomain "*" --bootnodes "$bootnodeAddr" --unlock ${addr[i]} --password node$i/password.txt  2>node$i/errors.txt 1>node$i/log.txt &
    
    echo -e "#!/usr/bin/env bash" > node$i/init.sh
    echo -n "geth --datadir ./ --syncmode full --nat=extip:$ipAddr --mine --minerthreads 1 --verbosity 3 --networkid $networkID --port $portBase --gasprice '0' --rpccorsdomain \"*\" --bootnodes \"$bootnodeAddr\" --unlock ${addr[i]} --password password.txt" >> node$i/init.sh
    let i++
    let portBase++
    sleep 2
done
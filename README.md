# scripted-ethereum
Script to deploy automatically a clique Ethereum network with M signers.

# Requirements
* Install ethereum
```bash
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum
```
* Install Golang
```bash
sudo snap install --classic go
```

# Usage guide
To deploy a new blockchain network from scratch you just have to start the following script in the folder where you want it deployed. M is the number of signers that will be deployed. If no argument is given to the script, by default, it will deploy 2 signers.
```bash
./deploy-network.sh M
```
As a result of this command, it will create M folders, one per each signer. Moreover, it will iniatilize the signers in background. At this point the blockchain is already deployed.

You can create and initalize a new non-signer node in the blockchain using the following order:
```bash
./add-node.sh
```
This command supports two input arguments. The first one is the name of the folder where the node is deployed. The second one is the port in which the node is listening.
For example, if we want to  deploy a node  in the port "33708" whose name is "client-node" we have to use the following command:
```
./add-node.sh client-node 33708
```

To stop the blockchain use the following script.
```bash
./stop-signer.sh
```
As a result of the execution of this script, all nodes of the blockchain, including signers and non-signers, will be stopped.

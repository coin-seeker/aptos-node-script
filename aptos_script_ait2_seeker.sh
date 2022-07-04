#!/bin/bash
echo "=================================================="
echo -e "\033[0;35m"
echo "      ___                        ___                                    _____    ";
echo "     /  /\          ___         /  /\                      ___         /  /::\   ";
echo "    /  /::|        /__/\       /  /::\                    /  /\       /  /:/\:\  ";
echo "   /  /:/:|        \  \:\     /  /:/\:\    ___     ___   /  /:/      /  /:/  \:\ ";
echo "  /  /:/|:|__       \  \:\   /  /:/~/::\  /__/\   /  /\ /__/::\     /__/:/ \__\:|";
echo " /__/:/ |:| /\  ___  \__\:\ /__/:/ /:/\:\ \  \:\ /  /:/ \__\/\:\__  \  \:\ /  /:/";
echo " \__\/  |:|/:/ /__/\ |  |:| \  \:\/:/__\/  \  \:\  /:/     \  \:\/\  \  \:\  /:/ ";
echo "     |  |:/:/  \  \:\|  |:|  \  \::/        \  \:\/:/       \__\::/   \  \:\/:/  ";
echo "     |  |::/    \  \:\__|:|   \  \:\         \  \::/        /__/:/     \  \::/   ";
echo "     |  |:/      \__\::::/     \  \:\         \__\/         \__\/       \__\/    ";
echo "     |__|/           ~~~~       \__\/                                            ";
echo -e "\e[0m"
echo "=================================================="

sleep 2

echo -e "\e[1m\e[32m1. Lets start... \e[0m" && sleep 1
sudo apt-get update &> /dev/null
sudo apt-get install unzip -y &> /dev/null
rm /usr/bin/aptos &> /dev/null
mkdir -p $HOME/.aptos
cd $HOME/.aptos

echo "=================================================="

echo -e "\e[1m\e[32m2. Enter Aptos Node Name \e[0m"
read -p "Name: " APTOS_NODE_NAME
IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')

echo "=================================================="

echo -e "\e[1m\e[32m3. Checking if Docker is installed... \e[0m" && sleep 1

if ! command -v docker &> /dev/null
then

    echo -e "\e[1m\e[32m3.1 Installing Docker... \e[0m" && sleep 1
    sudo apt-get install ca-certificates curl gnupg lsb-release wget -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi

echo "=================================================="

echo -e "\e[1m\e[32m4. Checking if Docker Compose is installed ... \e[0m" && sleep 1

docker compose version &> /dev/null
if [ $? -ne 0 ]
then

    echo -e "\e[1m\e[32m4.1 Installing Docker Compose v2.5.0 ... \e[0m" && sleep 1
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
    sudo chown $USER /var/run/docker.sock
fi

echo "=================================================="

echo -e "\e[1m\e[32m5. Downloading Aptos Validator/Full node config files ... \e[0m" && sleep 1

wget -P $HOME/.aptos wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml &> /dev/null
wget -P $HOME/.aptos wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml &> /dev/null
wget -P $HOME/.aptos wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/fullnode.yaml &> /dev/null
wget -P $HOME https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-0.2.0/aptos-cli-0.2.0-Ubuntu-x86_64.zip &> /dev/null
unzip $HOME/aptos-cli-0.2.0-Ubuntu-x86_64.zip -d /usr/bin
rm $HOME/aptos-cli-0.2.0-Ubuntu-x86_64.zip

echo "=================================================="

echo -e "\e[1m\e[32m6. Generate key pairs ... \e[0m" && sleep 1

aptos genesis generate-keys --output-dir $HOME/.aptos

echo "=================================================="

echo -e "\e[1m\e[32m7. Configure validator information ... \e[0m" && sleep 1

aptos genesis set-validator-configuration  --keys-dir $HOME/.aptos --local-repository-dir $HOME/.aptos  --username $APTOS_NODE_NAME  --validator-host $IP:6180  --full-node-host $IP:6182

echo "=================================================="

echo -e "\e[1m\e[32m8. Create layout YAML file ... \e[0m" && sleep 1

aptos key generate --output-file root_key
KEY_PUB=$(cat ~/.aptos/root_key.pub) 
KEY=$KEY_PUB
echo "---
root_key: \"$KEY\"
users:
  - \"$APTOS_NODE_NAME\"
chain_id: 40
min_stake: 0
max_stake: 100000
min_lockup_duration_secs: 0
max_lockup_duration_secs: 2592000
epoch_duration_secs: 86400
initial_lockup_timestamp: 1656615600
min_price_per_gas_unit: 1
allow_new_validators: true" > layout.yaml

echo "=================================================="

echo -e "\e[1m\e[32m9. Download AptosFramework Move bytecodes... \e[0m" && sleep 1

wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.2.0/framework.zip &> /dev/null
unzip framework.zip &> /dev/null
rm framework.zip

echo "=================================================="

echo -e "\e[1m\e[32m10. Compile genesis blob and waypoint... \e[0m" && sleep 1

aptos genesis generate-genesis --local-repository-dir $HOME/.aptos --output-dir $HOME/.aptos

echo -e "\e[1m\e[32m11. Starting Aptos Validator/Full Node ... \e[0m" && sleep 1

docker compose up -d

echo "=================================================="

echo -e "\e[1m\e[32mAptos Validator/Full Node Started \e[0m"

echo "==============VALIDATOR/FULL NODE DETAILS=========="

echo -e "\n\e[1m\e[32mVALIDATOR CONSENSUS KEY: \e[0m" 
echo -e "\e[1m\e[39m"    $(awk -F'"' '$1=="consensus_public_key: "{print $2}' $APTOS_NODE_NAME.yaml)" \n \e[0m"
echo -e "\e[1m\e[32mVALIDATOR ACCOUNT KEY: \e[0m" 
echo -e "\e[1m\e[39m"    $(awk -F'"' '$1=="account_public_key: "{print $2}' $APTOS_NODE_NAME.yaml)" \n \e[0m"
echo -e "\e[1m\e[32mVALIDATOR NETWORK KEY: \e[0m" 
echo -e "\e[1m\e[39m"    $(awk -F'"' '$1=="validator_network_public_key: "{print $2}' $APTOS_NODE_NAME.yaml)" \n \e[0m"

echo -e "\e[1m\e[32mFULLNODE NETWORK KEY: \e[0m" 
echo -e "\e[1m\e[39m"    $(awk -F'"' '$1=="full_node_network_public_key: "{print $2}' $APTOS_NODE_NAME.yaml)" \n \e[0m"

echo "=================================================="

echo -e "\e[1m\e[32mTo check validator node sync status: \e[0m" 
echo -e "\e[1m\e[39m    curl 127.0.0.1:9101/metrics 2> /dev/null | grep aptos_state_sync_version | grep type \n \e[0m" 

echo -e "\e[1m\e[32mTo check full node sync status: \e[0m" 
echo -e "\e[1m\e[39m    curl 127.0.0.1:9103/metrics 2> /dev/null | grep aptos_state_sync_version | grep type \n \e[0m" 

echo -e "\e[1m\e[32mTo view full node logs: \e[0m" 
echo -e "\e[1m\e[39m    docker logs -f aptos-fullnode-1 --tail 5000 \n \e[0m" 

echo -e "\e[1m\e[32mTo view validator node logs: \e[0m" 
echo -e "\e[1m\e[39m    docker logs -f aptos-validator-1 --tail 5000 \n \e[0m" 

echo -e "\e[1m\e[32mTo restart: \e[0m" 
echo -e "\e[1m\e[39m    cd ~/.aptos && docker compose restart \n \e[0m" 

echo -e "\e[1m\e[32mTo strt: \e[0m" 
echo -e "\e[1m\e[39m    cd ~/.aptos && docker compose up -d \n \e[0m" 

echo -e "\e[1m\e[32mTo stop: \e[0m" 
echo -e "\e[1m\e[39m    cd ~/.aptos && docker compose stop \n \e[0m" 

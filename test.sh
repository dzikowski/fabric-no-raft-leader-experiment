#!/usr/bin/env sh

set -eu

# Start the network with running chaincode
./fablo up

# Create some transactions
./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:put", "name", "James Bond"]}'
./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'
./fablo chaincode invoke peer1.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'

docker ps --format "{{.Names}}"

# Stop peer1 and relevant chaincode
docker ps --format "{{.Names}}" | grep "peer1" | xargs docker stop

# Stop three last orderers
docker stop orderer2.group1.orderer.example.com
docker stop orderer3.group1.orderer.example.com
docker stop orderer4.group1.orderer.example.com

docker ps --format "{{.Names}}"

./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:put", "name", "Dr No"]}'
./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'
./fablo chaincode invoke peer1.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}' || echo "Expected error for invoking chaincode on peer1"

# Stop peer0 and relevant chaincode
docker ps --format "{{.Names}}" | grep "peer0" | xargs docker stop

# Stop two first orderers
docker stop orderer0.group1.orderer.example.com
docker stop orderer1.group1.orderer.example.com

docker ps --format "{{.Names}}"

# Start peer1 and relevant chaincode (chaincode will start automatically)
docker start peer1.org1.example.com

# Start three last orderers
docker start orderer2.group1.orderer.example.com
docker start orderer3.group1.orderer.example.com
docker start orderer4.group1.orderer.example.com

docker ps --format "{{.Names}}"

# Note: need to invoke manually, since fablo does not support selecting orderer
# It fails with no Raft leader error:
docker exec cli.org1.example.com peer chaincode invoke \
  --peerAddresses peer1.org1.example.com:7042 \
  --tlsRootCertFiles /var/hyperledger/cli/crypto/peers/peer1.org1.example.com/tls/ca.crt \
  --orderer orderer3.group1.orderer.example.com:7033 \
  -C my-channel1 \
  -n chaincode1 \
  -c '{"Args":["KVContract:get", "name"]}' \
  --waitForEvent \
  --waitForEventTimeout 90s \
  --tls \
  --cafile "/var/hyperledger/cli/crypto-orderer/tlsca.orderer.example.com-cert.pem" \
  2>&1
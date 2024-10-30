#!/usr/bin/env sh

set -eu

./fablo up

./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:put", "name", "James Bond"]}'
./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'
./fablo chaincode invoke peer1.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'

docker ps --format "{{.Names}}"

# stopping peer1 and relevant chaincode
docker ps --format "{{.Names}}" | grep "peer1" | xargs docker stop

# stopping two last orderers
docker stop orderer3.group1.orderer.example.com
docker stop orderer4.group1.orderer.example.com

docker ps --format "{{.Names}}"

./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:put", "name", "Dr No"]}'
./fablo chaincode invoke peer0.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}'
./fablo chaincode invoke peer1.org1.example.com my-channel1 chaincode1 '{"Args":["KVContract:get", "name"]}' || echo "Expected error for invoking chaincode on peer1"

# stopping peer0 and relevant chaincode
docker ps --format "{{.Names}}" | grep "peer0" | xargs docker stop

# stopping three first orderers
docker stop orderer0.group1.orderer.example.com
docker stop orderer1.group1.orderer.example.com
docker stop orderer2.group1.orderer.example.com

docker ps --format "{{.Names}}"

# starting peer1 and relevant chaincode (chaincode will start automatically)
docker start peer1.org1.example.com

# starting two last orderers
docker start orderer3.group1.orderer.example.com
docker start orderer4.group1.orderer.example.com

docker ps --format "{{.Names}}"

# note need to call manually, since fablo does not support selecting orderer
# fails with no Raft leader error:
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
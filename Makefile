-include .env

.PHONY: all test deploy

help: 
	@echo "Usage:"
	@echo " make deploy [ARGS=...]"


build:; forge build 


NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast


ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia) 
	NETWORK_ARGS := --rpc-url $(SEP_RPC) --private-key $(PRIVATEKEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif


deploy: 
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "lib/forge-std/src/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { VRFCoordinatorV2Mock } from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import { LinkToken} from "test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    
    NetworkConfig public activeNetworkConfig;
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    struct NetworkConfig {
        uint256 ticketPrice;
        uint256 interval; 
        address vrfCoordinatorV2; 
        bytes32 keyHash; 
        uint64 subscriptionId;   
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

  

    constructor () {
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
         } else {
            activeNetworkConfig = getSlashCreateAnvilEthConfig();
         }

    }

    function getSepoliaEthConfig () public view returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 60,
            vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 8192,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint ("PRIVATEKEY")
        });
    }

    function getSlashCreateAnvilEthConfig () public  returns (NetworkConfig memory anvilNetworkConfig) {
            if (activeNetworkConfig.vrfCoordinatorV2 != address (0)){
                return activeNetworkConfig;
            }

            uint96 baseFee = 0.25 ether;
            uint96 gasPriceLink = 1e9; 
            
            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
                baseFee,
                gasPriceLink
            );
            LinkToken link = new LinkToken();
            vm.stopBroadcast();

            return
                NetworkConfig({
                    ticketPrice: 0.01 ether,
                    interval: 30,
                    vrfCoordinatorV2: address (vrfCoordinatorV2Mock),
                    keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                    subscriptionId: 0,
                    callbackGasLimit: 500000,
                    link: address (link),
                    deployerKey: DEFAULT_ANVIL_KEY
                });
    }
}
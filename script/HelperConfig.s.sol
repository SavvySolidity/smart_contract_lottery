//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "lib/forge-std/src/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { VRFCoordinatorV2Mock } from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 ticketPrice;
        uint256 interval; 
        address vrfCoordinator; 
        bytes32 keyHash; 
        uint64 subscriptionId;   
        uint32 callbackGasLimit;
    }

   NetworkConfig public activeNetworkConfig;

    constructor () {
        if (block.chain == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
         } else {
            activeNetworkConfig = getSlashCreateAntilEthConfig();
         }

    }

    function getSepoliaEthConfig () public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketPrice: 0.01 ether,
            interval: 60,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }

    function getSlashCreateAntilEthConfig () public  returns (NetworkConfig memory) {
            if (activeNetworkConfig.vrfCoordinator != address (0)){
                return activeNetworkConfig;
            }

            uint96 baseFee = 0.25 ether;
            uint96 gasPriceLink = 1e9; 
            
            vm.startBroadcast();
            VRFCoordinatorV2Mock = new VRFCoordinatorV2Mock(
                baseFee,
                gasPriceLink
            );
            vm.stopBroadcast();

            return
                NetworkConfig({
                    ticketPrice: 0.01 ether,
                    interval: 30,
                    vrfCoordinator: address (VRFCoordinatorV2Mock),
                    keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                    subscriptionId: 0,
                    callbackGasLimit: 500000 
                });
    }
}
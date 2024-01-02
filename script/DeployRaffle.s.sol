//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "lib/forge-std/src/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubsciption, AddConsumer } from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (
        uint256 ticketPrice,
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 keyHash, 
        uint64 subscriptionId,   
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey
    ) =helperConfig.activeNetworkConfig();
    

    if (subscriptionId == 0){
        CreateSubscription createSubscription = new CreateSubscription();
        subscriptionId = createSubscription.createSubscription(
            vrfCoordinator, deployerKey
        );
        
        FundSubsciption fundSubsciption = new FundSubsciption();
        fundSubsciption.fundSubscription(
            vrfCoordinator,
            subscriptionId,
            link,
            deployerKey
        );

    }
    
    
    
    vm.startBroadcast();
    Raffle raffle = new Raffle(
        ticketPrice,
        interval,
        vrfCoordinator,
        keyHash,
        subscriptionId,
        callbackGasLimit
    );
    vm.stopBroadcast();

    AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(
        address (raffle),
        vrfCoordinator,
        subscriptionId,
        deployerKey
    );

    return (raffle, helperConfig);

    }

}
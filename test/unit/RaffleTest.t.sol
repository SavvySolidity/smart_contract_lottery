//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Test, console } from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 ticketPrice;
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 keyHash; 
    uint64 subscriptionId;   
    uint32 callbackGasLimit;


    address public PLAYER = makeAddr ("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp () external {
        DeployRaffe deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            ticketPrice,
            interval, 
            vrfCoordinator, 
            keyHash, 
            subscriptionId,   
            callbackGasLimit
        ) =helperConfig.activeNetworkConfig();
        
    }

    function testRaffleInitInOpenState () public view {
        assert (raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
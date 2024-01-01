//SPDX-License-Identifier: MIT

// version
pragma solidity ^0.8.18;
/** 
*@title A solidity based smart contract raffle contract
*@author Sav Solid
*@notice This contract is a raffle contract that allows users to buy tickets and win prizes
*@dev Impletments Chainlink VRFv2
 */
import {VRFCoordinatorV2Interface} from "lib/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
// imports

// errors
    error Raffle__NotEnoughToBuyTicket ();
    error Raffle__NotEnoughTimePassed ();
    error Raffle__RaffleWinnerNotPaid ();
    error Raffle__RaffleClosed ();
    error Raffle__UpKeepNotNeeded (
        uint256 currentBalance,
        uint256 numEntrants,
        uint256 raffleState
     );

// interfaces, libraries, contracts
// Type declarations
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }
// State variables
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_interval; //duration of raffle in seconds
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    
    uint256 private s_lastTimeStamp;
    address payable [] private s_entrants; 
    address private s_recentWinner;

    RaffleState private s_raffleState;
    
    
// Events
    event EnteredRaffle (address indexed entrant);
    event PickedWinner (address indexed winner);
// Modifiers
// Functions

// Layout of Functions:
// constructor
constructor (
        uint256 ticketPrice, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 keyHash, 
        uint64 subscriptionId,
        uint32 callbackGasLimit
        ) VRFConsumerBaseV2 (vrfCoordinator) {
        i_ticketPrice = ticketPrice;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface (vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;   
    }
// receive function (if exists)
// fallback function (if exists)
// external

    function enterRaffle () external payable {
        if (msg.value < i_ticketPrice) {
            revert Raffle__NotEnoughToBuyTicket();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleClosed();
        }
        s_entrants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

// 1. Get a random number from Chainlink VRF
// 2. Use the random number to pick a winner
// 3. Send the winner the prize
    function performUpkeep (bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address (this).balance,
                s_entrants.length,
                uint256 (s_raffleState)
            );
        }

        if((block.timestamp - s_lastTimeStamp) < i_interval){
            revert Raffle__NotEnoughTimePassed();
        }
         s_raffleState = RaffleState.CALCULATING_WINNER;
         i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
}

// public

//Time when winner is picked
    /**
    * @dev This is the funciton that is called by the Chainllink nodes to see if it is time to perform the upkeep.
    * Thefollowing should be true for this to return true:
    * 1. The time interval has passed between raflle runs
    * 2. The raffle is in the OPEN state
    * 3. The contract has entrants 
    * 4. The subsription is funded with $LINK 
    */
    function checkUpKeep (
         bytes memory /*checkData*/
        ) public view returns (bool upKeepNeeded, bytes memory /*performData*/) {
            bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
            bool isOpen = RaffleState.OPEN == s_raffleState;
            bool hasEntrants = s_entrants.length > 0;
            bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasEntrants && hasBalance);
        return (upKeepNeeded, "0x0");
    }    
// internal
    function fulfillRandomWords( 
        uint256 /*requestId*/,
        uint256 []memory randomWords
        ) internal override  {
        uint256 indexOfWinner = randomWords[0] % s_entrants.length;
        address payable winner = s_entrants[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        
        s_entrants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__RaffleWinnerNotPaid();
        }
        emit PickedWinner(winner);


    }
// private
// view & pure functions
/** Getter Functions */

function getTicketPrice() external view returns (uint256) {
    return i_ticketPrice;}

function getInterval() external view returns (uint256) {
    return i_interval;}

function getRaffleState () external view returns (RaffleState) {
    return s_raffleState;}    
}


//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console } from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /*Events */
    event EnteredRaffle (address indexed entrant);




    Raffle raffle;
    HelperConfig helperConfig;

    uint256 ticketPrice;
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 keyHash; 
    uint64 subscriptionId;   
    uint32 callbackGasLimit;
    address link;

    address public ENTRANT = makeAddr ("entrant");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp () external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            ticketPrice,
            interval, 
            vrfCoordinator, 
            keyHash, 
            subscriptionId,   
            callbackGasLimit,
            link,
        ) =helperConfig.activeNetworkConfig();
        vm.deal(ENTRANT, STARTING_USER_BALANCE);
        
    }

    function testRaffleInitInOpenState () public view {
        assert (raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }



    function testRaffleRevertWhenNotEnoughPayment () public {
        vm.prank(ENTRANT); 
        vm.expectRevert(Raffle.Raffle__NotEnoughToBuyTicket.selector);
        raffle.enterRaffle();
        
    }

    function testRaffleRecordsEntrantOnEntry () public {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
       address entrantRecorded = raffle.getEntrant(0);
       assert (entrantRecorded == ENTRANT);
    }

    function testEmitsEventonEntry () public {
        vm.prank (ENTRANT);
        vm.expectEmit (true, false, false, false, address(raffle));
        emit EnteredRaffle(ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
    }

    function testCantEnterWhenCalculatingWinner () public {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
        vm.warp (block.timestamp + interval +1);
        vm.roll (block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleClosed.selector);
        vm.prank(ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();

       
    }

    function testCheckUpkeepReturnsFalseWhenNoBalance () public {
        vm.warp (block.timestamp + interval +1);
        vm.roll (block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpKeep("");
        assert (!upkeepNeeded);
    }

    function testCheckUpkeepRetunsFaslseIfRaffleClosed () public {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
        vm.warp (block.timestamp + interval +1);
        vm.roll (block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpKeep("");
        assert (!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed () public {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
        vm.warp (block.timestamp + interval -3);
        vm.roll (block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpKeep("");
        assert (!upkeepNeeded);
    }
    
    
    //testCheckUpkeepReturnsTrueWhenParamsAreMet

    function testPerformUpkeepCanOnlyRunWhenCheckUpkeepIsTrue () public {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
        vm.warp (block.timestamp + interval +1);
        vm.roll (block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse () public {
        uint256 currentBalance = 0;
        uint256 numEntrants =0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        
        vm.expectRevert (
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numEntrants,
                rState));
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed () {
        vm.prank (ENTRANT);
        raffle.enterRaffle {value: ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerfromUpkeepUpdatesRaffleStateAndEmitsRequestId () 
        public 
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();  

        assert (uint256 (requestId) > 0);
        assert (uint256 (rState) ==1);
      }


    modifier skipFork (){
        if (block.chainid != 31337) {
            return;
        }
            _;
    }
    
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep (
        uint256 randomRequestId
    ) 
        public 
        raffleEnteredAndTimePassed skipFork{
    
        vm.expectRevert ("nonexistent request");
        VRFCoordinatorV2Mock (vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address (raffle)
        );


    }

    function testFulfillRandomWordsPicksWinnerAndSendsMoney ()
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        uint256 additionalEntrants =5;
        uint256 startingIndex =1;
        for (
            uint256 i = startingIndex;
            i< startingIndex + additionalEntrants; i++
            ) {
            address entrant = address (uint160(i));
            hoax(entrant, STARTING_USER_BALANCE );
            raffle.enterRaffle {value: ticketPrice}();
        }

        uint256 prize = ticketPrice * (additionalEntrants +1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock (vrfCoordinator).fulfillRandomWords(
            uint256 (requestId),
            address (raffle)
        );

        assert (uint256 (raffle.getRaffleState()) == 0);
        assert (raffle.getRecentWinner() != address(0));
        assert (raffle.getLengthOfEntrants() ==0);
        assert (previousTimeStamp < raffle.getLastTimeStamp() );

        console.log (raffle.getRecentWinner().balance);
        console.log (prize + STARTING_USER_BALANCE);
        assert (raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - ticketPrice);


    }

    

    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle smart contract
 * @author Alan
 * @notice A simple sample raffle smart contract
 * @dev implements ChainLink VRFv2.5 
 */
contract Raffle is VRFConsumerBaseV2Plus {
    
    /* Errors Syntax [ContractName]__[ErrorHandling] */
    error Raffle__InsufficientEntranceFee();
    error Raffle__TransferFailed();
    error Raffle__CalculatingWinner();
    error Raffle__NotReadyToPickWinner(uint256 balance, uint256 playersLenght, uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable [] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events Syntax [ContractName][Event](<params>); */
    event RaffleAccepted(address indexed player);
    event RaffleWinnerPicked(address indexed winner);

    modifier onlyWhenOpen() {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingWinner();
        }
        _;
    }

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint256 subscriptionId, uint32  callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable onlyWhenOpen {
        /**
         * this error treatment is more gas efficient than using require with a string message or require with error object, example:
         * require(msg.value >= i_entranceFee, "Value is insufficient to enter the Raffle");
         * require(msg.value >= i_entranceFee, Raffle__InsufficientEntranceFee());
         */
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEntranceFee();
        }
        s_players.push(payable(msg.sender));

        emit RaffleAccepted(msg.sender);
    }

    /**
     * @dev this is the function that the Chainlink nodes will call to see 
     * if the lottery is ready to have a winner picked.
     * the following should be true in order for upkeepNeeded to be true:
     * 1. the time interval has passed between raffle runs
     * 2. the lottery is open
     * 3. the contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery 
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns(bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__NotReadyToPickWinner(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /**
     * We're picking the winner, since the number of words that we request is always 1, the array randomWords will have only one value.
     * the index is the module of this value by the number of players.
     */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }

        emit RaffleWinnerPicked(s_recentWinner);
    }

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title A sample Raffle smart contract
 * @author Alan
 * @notice A simple sample raffle smart contract
 * @dev implements ChainLink VRFv2.5 
 */
contract Raffle {
    /**
     * Errors
     * Syntax [Contract_name]__[ErrorHandling]
     */
    error Raffle__InsufficientEntranceFee();

    uint256 private immutable i_entranceFee;
    address payable [] private s_players;

    event RaffleAccepted(address index player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
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

    function pickWinner() public {

    }

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}
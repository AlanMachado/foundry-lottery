// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title A sample Raffle smart contract
 * @author Alan
 * @notice A simple sample raffle smart contract
 * @dev implements ChainLink VRFv2.5 
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {

    }

    function pickWinner() public {

    }

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}
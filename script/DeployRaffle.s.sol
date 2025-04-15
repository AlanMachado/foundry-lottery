// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {

    }

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSub.createSubscription(config.vrfCoordinator, config.account);
        
            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(config.subscriptionId, config.vrfCoordinator, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // don't need to broadcast because addConsumer is already broadcasting
        addConsumer.addConsumer(config.subscriptionId, config.vrfCoordinator, address(raffle), config.account);

        return (raffle, helperConfig);
    }
}
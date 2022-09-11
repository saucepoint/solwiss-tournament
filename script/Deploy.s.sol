// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SwissTournamentManagerFactory.sol";
import "../test/mocks/MockGame.sol";

contract CounterScript is Script {
    SwissTournamentManagerFactory factory;
    MockGame game;
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        factory = new SwissTournamentManagerFactory();
        game = new MockGame();
        vm.stopBroadcast();
        
        console.log("factory", address(factory));
        console.log("game", address(game));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SwissTournament.sol";
import "../src/SwissTournamentManager.sol";
import "../src/SwissTournamentManagerFactory.sol";
import "./lib.sol";
import "./mocks/MockGame.sol";

contract SwissTournamentFactoryTest is Test {
    SwissTournamentManagerFactory factory;
    MockGame game;
    function setUp() public {
        factory = new SwissTournamentManagerFactory();
        game = new MockGame();
    }

    function testCreate() public {
        address organizer = address(0x00DEADBEEF);
        uint256 tournamentId = factory.tournamentCounter(organizer);
        uint256[] memory playerIds = TournamentLibrary.getPlayerIds(16);

        vm.startPrank(organizer);
        address tournamentAddr = factory.create(address(game), 3, 3, playerIds);
        assertEq(tournamentAddr, factory.getTournament(organizer, tournamentId));
        vm.stopPrank();

        assertEq(tournamentAddr, factory.getLatestTournament(organizer));
        assertEq(factory.tournamentCounter(organizer), 1);
        TournamentLibrary.simTournament(SwissTournament(tournamentAddr));
    }
}
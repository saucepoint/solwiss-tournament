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
        address tournamentAddr = factory.create(address(game), 3, 3, playerIds, 0);
        assertEq(tournamentAddr, factory.tournamentAddress(organizer, tournamentId));
        assertEq(tournamentAddr == address(0x0), false);
        vm.stopPrank();

        SwissTournament tournament = SwissTournament(tournamentAddr);

        assertEq(tournamentAddr, factory.getLatestTournament(organizer));
        assertEq(factory.tournamentCounter(organizer), 1);
        TournamentLibrary.simTournament(tournament);
        
        // in 16 player 3W/3L there should be 33 matches leading to 8 winners and 8 losers
        (, uint256 numMatches, uint256 numWinners, uint256 numLosers) = TournamentLibrary.getTournamentStats(tournament, playerIds);
        assertEq(numMatches, 33);
        assertEq(numWinners, 8);
        assertEq(numLosers, 8);
    }
}
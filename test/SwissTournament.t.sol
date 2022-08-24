// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/MockGame.sol";
import "./mocks/MockGameSwissTournament.sol";

contract SwissTournamentTest is Test {
    MockGame game;
    MockGameSwissTournament tournament;
    uint256[] playerIds;
    
    function setUp() public {
        game = new MockGame();
        tournament = new MockGameSwissTournament(address(game));
        
        for(uint256 i = 1; i <= 16; i++) {
            playerIds.push(i);
        }
        tournament.newTournament(playerIds);
    }

    function testTournamentInitialGroup() public {
        MatchId memory matchId = tournament.getNextMatch();
        Match memory matchup = tournament.getMatch(matchId.group.wins, matchId.group.losses, matchId.matchIndex);
        
        // spot check the very first match -- 1st seed (playerId 1) vs 16th seed (playerId 16)
        assertEq(matchup.player0, 1);
        assertEq(matchup.player1, 16);

        // spot check the second match -- 2nd seed (playerId 2) vs 15th seed (playerId 15)
        matchup = tournament.getMatch(0, 0, 1);
        assertEq(matchup.player0, 2);
        assertEq(matchup.player1, 15);

        // spot check the last matchup -- 8th seed (playerId 8) vs 9th seed (playerId 9)
        matchup = tournament.getMatch(0, 0, tournament.matchBookTail());
        assertEq(matchup.player0, 8);
        assertEq(matchup.player1, 9);

        // 16 players --> 8 matchups
        // loop over, and confirm that all player Ids sum to 17
        for(uint256 i = 0; i < 8; i++) {
            matchup = tournament.getMatch(0, 0, i);
            assertEq(matchup.player0 + matchup.player1, 17);
        }
    }

    function testSimTournamentEntirely() public {
        // 33 matches in 16-player swiss tournament
        // i dont know if theres a math formula for this. i just counted the matches

        // make sure theres no errors
        for (uint256 i = 0; i < 33; i++) {
            tournament.playNextMatch();
        }

        // loop over the 16 players. there should be 8 winners, and 8 losers
        // confirms we arent double counting winners or losers
        uint256 winners;
        uint256 losers;
        bool out;
        for (uint256 i = 1; i < 17; i++) {
            out = tournament.eliminated(i);
            out ? losers++ : winners++;
        }
        assertEq(winners, 8);
        assertEq(losers, 8);
    }
}

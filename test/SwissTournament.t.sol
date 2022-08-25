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
            // player ids are [10, 20, ..., 150, 160]. Reduces confusion between playerId and index
            playerIds.push(i * 10);
        }
        tournament.newTournament(playerIds);
    }

    /// Verify the first set of matchups were setup correctly
    function testTournamentInitialGroup() public {
        MatchId memory matchId = tournament.getNextMatch();
        Match memory matchup = tournament.getMatch(matchId.group.wins, matchId.group.losses, matchId.matchIndex);
        
        // spot check the very first match -- 1st seed (playerId 10) vs 16th seed (playerId 160)
        assertEq(matchup.player0, 10);
        assertEq(matchup.player1, 160);

        // spot check the second match -- 2nd seed (playerId 20) vs 15th seed (playerId 150)
        matchup = tournament.getMatch(0, 0, 1);
        assertEq(matchup.player0, 20);
        assertEq(matchup.player1, 150);

        // spot check the last matchup -- 8th seed (playerId 80) vs 9th seed (playerId 90)
        matchup = tournament.getMatch(0, 0, tournament.matchBookTail());
        assertEq(matchup.player0, 80);
        assertEq(matchup.player1, 90);

        // 16 players --> 8 matchups
        // loop over, and confirm that all player Ids sum to 170
        for(uint256 i = 0; i < 8; i++) {
            matchup = tournament.getMatch(0, 0, i);
            assertEq(matchup.player0 + matchup.player1, 170);
        }
    }

    /// Simulate the entire tournament and verify the end state (winners & losers)
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
        for (uint256 i = 0; i < playerIds.length; i++) {
            out = tournament.eliminated(playerIds[i]);
            out ? losers++ : winners++;
        }
        assertEq(winners, 8);
        assertEq(losers, 8);
    }

    /// Verify that the swiss-advancement logic is working correctly
    function testAdvancement() public {
        // play the matchup between playerId 10 and playerId 160
        tournament.playNextMatch();

        uint256 winnerId = game.result(playerIds[0], playerIds[playerIds.length - 1]);
        uint256 loserId = winnerId == playerIds[0] ? playerIds[playerIds.length - 1] : playerIds[0];
        
        // verify the scores:
        ResultCounter memory result = tournament.getOutcomes(winnerId);
        assertEq(result.wins, 1);
        assertEq(result.losses, 0);

        result = tournament.getOutcomes(loserId);
        assertEq(result.wins, 0);
        assertEq(result.losses, 1);

        // verify winner was moved to group (win: 1, lose: 0)
        Match memory matchup = tournament.getMatch(1, 0, 0);
        assertEq(matchup.player0 == winnerId, true);

        // verify loser was moved to group (win: 0, lose: 1)
        matchup = tournament.getMatch(0, 1, 0);
        assertEq(matchup.player0 == loserId, true);
    }

    /// verify that we can invoke playMatch via calldata
    function testPlayMatchCallData() public {
        ResultCounter memory group;  // default ResultCounter(0, 0)
        for (uint256 i = 0; i < 8; i++) {
            tournament.playMatchCalldata(group, i);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./lib.sol";
import "./mocks/MockGame.sol";

import "../src/interfaces/IMatchResolver.sol";
import "../src/SwissTournament.sol";
import "../src/SwissTournamentManager.sol";

contract SwissTournamentTest is Test {
    IMatchResolver game;
    SwissTournamentManager tournament;
    uint64[] playerIds;
    address organizer = address(0x00DEADBEEF);
    
    function setUp() public {
        MockGame mockGame = new MockGame();
        game = IMatchResolver(address(mockGame));

        playerIds = TournamentLibrary.getPlayerIds(16);
        tournament = new SwissTournamentManager(organizer, address(game), 3, 3, playerIds);
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
        vm.startPrank(organizer);
        for (uint256 i = 0; i < 33; i++) {
            tournament.playNextMatch(0, 0, 0, 0);
        }
        vm.stopPrank();

        // loop over the 16 players. there should be 8 winners, and 8 losers
        // confirms we arent double counting winners or losers
        // in 16 player 3W/3L there should be 33 matches leading to 8 winners and 8 losers
        SwissTournament _tournament = SwissTournament(address(tournament));
        (, uint256 numMatches, uint256 numWinners, uint256 numLosers) = TournamentLibrary.getTournamentStats(_tournament, playerIds);
        assertEq(numMatches, 33);
        assertEq(numWinners, 8);
        assertEq(numLosers, 8);
    }

    /// Logs the matchups & groupings for an entire tournament
    /// Useful for discovering optimal parameters of a tournament
    function testTournamentGroupLog() public {
        uint16 NUM_PLAYERS = 32;
        uint128 WIN_THRESHOLD = 3;
        uint128 ELIMINATION_THRESHOLD = 3;

        playerIds = TournamentLibrary.getPlayerIds(NUM_PLAYERS);
        tournament = new SwissTournamentManager(organizer, address(game), WIN_THRESHOLD, ELIMINATION_THRESHOLD, playerIds);
        vm.startPrank(organizer);
        TournamentLibrary.simTournament(tournament);
        vm.stopPrank();

        // Log results to a file
        string memory filepath = string.concat("logs/", vm.toString(address(tournament)), ".txt");
        vm.writeFile(filepath, "Groups\n");
        for (uint128 wins=0; wins <= tournament.winnerThreshold(); wins++) {
            for (uint128 losses=0; losses <= tournament.eliminationThreshold(); losses++) {
                uint256 len = tournament.groupMatchLength(wins, losses);
                if (len == 0) continue;
                vm.writeLine(
                    filepath,
                    string.concat("\n   ",
                        vm.toString(wins), " : ",
                        vm.toString(losses), " (",
                        vm.toString(len), ")\n  ----------"
                    )
                );
                for (uint256 i=0; i < len; i++) {
                    Match memory matchup = tournament.getMatch(wins, losses, i);
                    vm.writeLine(
                        filepath,
                        string.concat("   ",
                            vm.toString(matchup.player0), " : ",
                            vm.toString(matchup.player1)
                        )
                    );
                }
            }
        }

        (uint256 numGroups, uint256 numMatches, uint256 numWinners, uint256 numLosers) = getTournamentStats();
        emit log_named_uint("numGroups", numGroups);
        emit log_named_uint("numMatches", numMatches);
        emit log_named_uint("numWinners", numWinners);
        emit log_named_uint("numLosers", numLosers);
        assertEq(numWinners + numLosers, NUM_PLAYERS);
    }

    /// Generate a few differently parameterized swiss tournaments
    /// Log the results
    function testGenerateCombinations() public {
        string memory filepath = string.concat("logs/", "tournamentCombinations.csv");
        vm.writeFile(filepath, "num_players,win_threshold,lose_threshold,num_groups,num_matches,num_winners,num_losers\n");

        uint16[9] memory numPlayers = [uint16(8), uint16(16), uint16(20), uint16(32), uint16(40), uint16(64), uint16(100), uint16(128), uint16(256)];

        uint256 maxWins = 12;
        uint256 maxLosses = 5;
        for (uint64 i; i < numPlayers.length; i++) {
            for (uint128 winThreshold = 3; winThreshold <= maxWins; winThreshold++) {
                for (uint128 lossThreshold = 3; lossThreshold <= maxLosses; lossThreshold++) {
                    // create a new tournament and simulate its entirety
                    playerIds = TournamentLibrary.getPlayerIds(numPlayers[i]);
                    tournament = new SwissTournamentManager(organizer, address(game), winThreshold, lossThreshold, playerIds);

                    vm.startPrank(organizer);
                    TournamentLibrary.simTournament(tournament);
                    vm.stopPrank();
                    
                    (uint256 numGroups, uint256 numMatches, uint256 numWinners, uint256 numLosers) = getTournamentStats();
                    vm.writeLine(
                        filepath,
                        string.concat(
                            vm.toString(numPlayers[i]), ",",
                            vm.toString(winThreshold), ",",
                            vm.toString(lossThreshold), ",",
                            vm.toString(numGroups), ",",
                            vm.toString(numMatches), ",",
                            vm.toString(numWinners), ",",
                            vm.toString(numLosers)
                        )
                    );
                }
            }
        }
    }


    /// Verify that the swiss-advancement logic is working correctly
    function testAdvancement() public {
        // play the matchup between playerId 10 and playerId 160
        vm.prank(organizer);
        tournament.playNextMatch(0, 0, 0, 0);

        uint256 winnerId = game.matchup(playerIds[0], playerIds[playerIds.length - 1]);
        assertEq(winnerId != 0, true);
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

    
    // ------ Helper Functions ------
    function getTournamentStats() public view returns (uint256 numGroups, uint256 numMatches, uint256 numWinners, uint256 numLosers) {
        for (uint128 wins=0; wins <= tournament.winnerThreshold(); wins++) {
            for (uint128 losses=0; losses <= tournament.eliminationThreshold(); losses++) {
                uint256 len = tournament.groupMatchLength(wins, losses);
                if (0 < len) {
                    numGroups++;
                    numMatches += len;
                }
            }
        }
        bool out;
        for (uint64 i = 0; i < playerIds.length; i++) {
            out = tournament.eliminated(playerIds[i]);
            out ? numLosers++ : numWinners++;
        }
    }
}

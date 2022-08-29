// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../src/SwissTournament.sol";
import "../src/SwissTournamentManager.sol";

library TournamentLibrary {
    function simTournament(SwissTournamentManager tournament) internal {
        while (tournament.matchBookHead() <= tournament.matchBookTail()) {
            tournament.playNextMatch(0,0,0,0);
        }
    }

    function getPlayerIds(uint16 numPlayers) internal pure returns (uint64[] memory) {
        uint64[] memory playerIds = new uint64[](numPlayers);
        for(uint64 i = 1; i <= numPlayers; i++) {
            // player ids are [10, 20, ..., 150, 160]. Reduces confusion between playerId and index
            playerIds[i - 1] = i * 10;
        }
        return playerIds;
    }

    function getTournamentStats(SwissTournament tournament, uint64[] memory playerIds) public view returns (uint256 numGroups, uint256 numMatches, uint256 numWinners, uint256 numLosers) {
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
        for (uint256 i = 0; i < playerIds.length; i++) {
            out = tournament.eliminated(playerIds[i]);
            out ? numLosers++ : numWinners++;
        }
    }
}
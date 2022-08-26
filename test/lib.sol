// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../src/SwissTournament.sol";

library TournamentLibrary {
    function simTournament(SwissTournament tournament) internal {
        while (tournament.matchBookHead() <= tournament.matchBookTail()) {
            tournament.playNextMatch();
        }
    }

    function getPlayerIds(uint256 numPlayers) internal pure returns (uint256[] memory) {
        uint256[] memory playerIds = new uint256[](numPlayers);
        for(uint256 i = 1; i <= numPlayers; i++) {
            // player ids are [10, 20, ..., 150, 160]. Reduces confusion between playerId and index
            playerIds[i - 1] = i * 10;
        }
        return playerIds;
    }
}
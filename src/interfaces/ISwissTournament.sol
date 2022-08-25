// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../SwissTournament.sol";

interface ISwissTournament {
    
    // ordered list of players by elo
    // playerIds[0] is matched against playerIds[playerIds.length - 1]
    // playerIds[1] is matched against playerIds[playerIds.length - 2]
    // and so on
    function newTournament(uint256[] calldata playerIds) external;

    // plays the next match between two players (from the FIFO queue of matches)
    // advances the players into the next group based on results
    function playNextMatch() external;

    // manually invoke a match. Should avoid using this, unless you're using the result of getNextMatch()
    // Swiss tournaments have a match order
    function playMatch(ResultCounter memory group, uint256 matchIndex) external;

    // Optimized for L2 calls, which benefit from calldata compression
    // wrapper for playMatch()
    function playMatchCalldata(ResultCounter calldata group, uint256 matchIndex) external;

    // Returns whether or not a player has been eliminated
    function eliminated(uint256 player) external view returns (bool);

    // Returns Matchup information (players and outcome if applicable)
    function getMatch(uint256 wins, uint256 losses, uint256 matchIndex) external view returns (Match memory);
    
    // Gets the next match to be played, according to the FIFO queue of matches
    function getNextMatch() external view returns (MatchId memory);

    // Get the outcome/results of a player (number of wins and losses)
    function getOutcomes(uint256 playerId) external view returns (ResultCounter memory);

    // Index of the next match to be played in matchBook. The head of the FIFO queue
    function matchBookHead() external view returns (uint256);

    // Index of the last match to be played in matchBook. The tail of the FIFO queue
    function matchBookTail() external view returns(uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISwissTournament {
    // ordered list of players by elo
    // playerIds[0] is matched against playerIds[playerIds.length - 1]
    // playerIds[1] is matched against playerIds[playerIds.length - 2]
    // and so on
    function newTournament(uint256[] calldata playerIds) external;

    // plays a match between two players
    // advances the players into the next group based on results
    // will mark players as eliminated
    // function playMatch(GroupId calldata group, uint256 matchIndex) external;

    function eliminated(uint256 player) external view returns (bool);

    function getNextMatch() external view;

}
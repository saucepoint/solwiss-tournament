// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Your game contract must implement this interface to be compatible
// with SwissTournamentManager (created via the factory)
interface IMatchResolver {
    // Given two player IDs, return the ID of the winner
    // Cannot return 0
    function matchup(uint64 player0, uint64 player1) external view returns (uint64);
}
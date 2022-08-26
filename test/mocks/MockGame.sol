// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/interfaces/IMatchResolver.sol";

/// @title Demo Game
/// @author @saucepoint <saucepoint@protonmail.com>
/// @notice Demonstrate how an on-chain game can faciliate a Swiss Tournament
/// @notice You can manage player data here, but just note that Swiss Tournament
///         will manage the matchups. It tracks players as uint256 (starting at 1. playerId=0 is not allowed)
contract MockGame is IMatchResolver {
    function playerScore(uint256 playerId) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(playerId)));
    }

    // the larger hash of a player's id is the winner
    function matchup(uint256 player0, uint256 player1) public pure returns (uint256){
        return playerScore(player0) < playerScore(player1) ? player1 : player0;
    }
}
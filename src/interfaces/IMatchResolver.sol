// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMatchResolver {
    function matchup(uint256 player0, uint256 player1) external view returns (uint256);
}
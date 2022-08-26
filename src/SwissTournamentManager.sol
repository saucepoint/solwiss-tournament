// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SwissTournament.sol";
import "./interfaces/IMatchResolver.sol";

/// @title Swiss tournament manager
/// @author @saucepoint <saucepoint@protonmail.com>
/// @notice Instances will be created by the factory. Assumes the provided contract adheres to IMatchResolver
contract SwissTournamentManager is SwissTournament {
    IMatchResolver matchResolver;

    constructor(address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] memory playerIds)
        SwissTournament(_winThreshold, _eliminationThreshold, playerIds)
    {
        matchResolver = IMatchResolver(_matchResolver);
    }

    /// Implement SwissTournament.playMatch()
    /// Must decorate with SwissTournament.advancePlayers() modifier
    function playMatch(ResultCounter memory group, uint256 matchIndex) public override advancePlayers(group, matchIndex) {
        // modifier will validate that the match has not yet been played
        Match storage matchup = matches[group.wins][group.losses][matchIndex];
        
        // the game logic just needs to return the id (uint256) of the winner
        // the game logic can accept an arbitrary amount of parameters
        // however given 2 players, return the id of the winner!
        uint256 winnerId = matchResolver.matchup(matchup.player0, matchup.player1);

        /// @dev Implementing playMatch() requires you to update the outcome of the match
        matchup.winnerId = winnerId;
        matchup.played = true;
        
        // the advancePlayers() modifier will handle advancing the players to the next group
    }
}
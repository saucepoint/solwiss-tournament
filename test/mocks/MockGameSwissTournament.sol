// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/SwissTournament.sol";
import "./MockGame.sol";

contract MockGameSwissTournament is SwissTournament {
    MockGame game;
    
    constructor(address _game) {
        game = MockGame(_game);

        // after contract deploys/initializes
        // you should call newTournament() to initialize the tournament
        // this is because newTournament() takes in calldata (for the L2 compression baby!)
        // and constructors dont accept calldata arrays :thonk:
    }

    /// @dev take note of the advancePlayers modifier
    ///      the modifier will update the swiss tournament logic for you
    function playMatch(ResultCounter memory group, uint256 matchIndex) public override advancePlayers(group, matchIndex) {
        // modifier will validate that the match has not yet been played
        Match storage matchup = matches[group.wins][group.losses][matchIndex];
        
        // the game logic just needs to return the id (uint256) of the winner
        // the game logic can accept an arbitrary amount of parameters
        // however given 2 players, return the id of the winner!
        uint256 winnerId = game.result(matchup.player0, matchup.player1);

        /// @dev Implementing playMatch() requires you to update the outcome of the match
        matchup.winnerId = winnerId;
        matchup.played = true;
        
        // the advancePlayers() modifier will handle advancing the players to the next group
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// NOTE: playerIds should be 1-indexed
// Mappings / structs will default to 0, 
// we dont want mistake a default 0 as a player or a result!
struct Match {
    uint64 player0;   // playerIds are 1-indexed
    uint64 player1;   // playerIds are 1-indexed
    uint64 winnerId;  // 0 no winner, otherwise is assigned to a playerId
    bool played;       // true if match has been played
}

// Defines a group (based on win/loss count)
// Also used for tracking a player's results (which determines which group they are in)
struct ResultCounter {
    uint64 wins;
    uint64 losses;
}//16bytes

// helper struct for accessing a unique match
struct MatchId {
    ResultCounter group;
    uint128 matchIndex;
}//32bytes

/// @title Swiss Tournament Manager
/// @author @saucepoint <saucepoint@protonmail.com>
/// @notice Create & manage a Swiss Tournament. Handles multiple tournaments
abstract contract SwissTournament {
    // tracks the head and the tail of the match book for monotonic traversal
    // these values track the head and tail of `matchBook` (mapping above)
    // i.e. traverse for upcoming to-be-played matches
    // indexer value for `matchBook`
    uint256 public matchBookHead;
    uint256 public matchBookTail;
    uint16 public numPlayers;

    // TODO: what happens when the win condition is higher? what does the swiss lattice look like?
    // typically both are the same
    uint128 public winnerThreshold;  // number of wins required to "win" or "advance into playoffs"
    uint128 public eliminationThreshold;  // number of losses suffered to be eliminated

    // Groups are identified via win count / lose count
    // Matches within a group are identified via an index
    // therefore a unique 'match id' is the composite of win-count, lose-count, and match index
    // win count => lose count => match index => Match
    mapping(uint128 => mapping(uint128 => mapping(uint256 => Match))) public matches;

    // win count => lose count => number of matches in this group
    mapping(uint128 => mapping(uint128 => uint128)) public groupMatchLength;
    
    // playerId => current scores
    mapping(uint256 => ResultCounter) public outcomes;

    // Match queue (FIFO), simplifies client calls for the order of upcoming match ups
    // TODO: not sure if a linkedlist is cheaper for gas, if we even want popping functionality?
    // match order number => Match information
    mapping(uint256 => MatchId) public matchBook;

    constructor(uint128 _winThreshold, uint128 _eliminationThreshold, uint64[] memory _playerIds) {
        winnerThreshold = _winThreshold;
        eliminationThreshold = _eliminationThreshold;
        numPlayers = uint16(_playerIds.length);
        _newTournament(_playerIds);
    }

    // ////////////////////////////////////////////////////
    // ----- Tournament Management (Write) Functions -----
    // ////////////////////////////////////////////////////
    
    /// @dev Play a match between two players
    /// @param group Tuple(uint256, uint256) representing the group the match is in
    /// @param matchIndex The index of the match in the group. 0 = first match in the group
    // TODO: YOU SHOULD MODIFY YOUR IMPLEMENTATION WITH advancePlayers() modifier
    // the modifier will ensure the match has not yet been played
    // the modifier will execute your logic and then advance the players to the next group
    function playMatch(ResultCounter memory group, uint256 matchIndex) internal virtual;

    /// @dev Called by tournament organizers to run the matchups in order
    function _playNextMatch() internal {
        require(matchBookHead <= matchBookTail, "Match book is empty");
        MatchId memory matchId = matchBook[matchBookHead];
        playMatch(matchId.group, matchId.matchIndex);
        unchecked { matchBookHead++; }
    }

    // ordered list of players by elo
    // playerIds[0] is matched against playerIds[playerIds.length - 1]
    // Must be an even number of players
    // playerId cannot be 0!!!!
    function _newTournament(uint64[] memory playerIds) private {
        require(0 < playerIds.length && playerIds.length % 2 == 0, "Odd number of players");
        
        // we'll seed the first match manually
        // this is an optimization so we dont have an conditional check
        // for matchBookTail = 0 in `_addMatchToQueue()`
        // Removing the check (which only ever runs once) less gas for all _addMatchToQueue() calls

        // first matchup is being seeded manually, so verify non-zero playerIds        
        require(playerIds[0] != 0, "PlayerId cannot be 0");
        require(playerIds[playerIds.length - 1] != 0, "PlayerId cannot be 0");

        uint128 matchIndex = groupMatchLength[0][0];
        Match storage nextMatchup = matches[0][0][matchIndex];
        nextMatchup.player0 = playerIds[0];
        nextMatchup.player1 = playerIds[playerIds.length - 1];
        unchecked { groupMatchLength[0][0]++; }
        ResultCounter memory zeroPair;
        matchBook[matchBookTail] = MatchId(zeroPair, matchIndex);
        
        // assign the remaining matchups i.e. indexes (1, 14) (2, 13) (3, 12) (4, 11) (5, 10) (6, 9) (7, 8)
        uint256 i = 1;
        uint256 half = playerIds.length / 2;
        uint64 player0;
        uint64 player1;
        for (i; i < half;) {
            player0 = playerIds[i];
            player1 = playerIds[playerIds.length - 1 - i];
            require(player0 != 0, "PlayerId cannot be 0");
            require(player1 != 0, "PlayerId cannot be 0");
            
            _addPlayerToNextMatch(player0, zeroPair);
            _addPlayerToNextMatch(player1, zeroPair);
            unchecked{ i++; }
        }
    }


    // //////////////////////////////////
    // ----- View Functions -----
    // //////////////////////////////////

    function eliminated(uint256 playerId) public view returns (bool) {
        return outcomes[playerId].losses == eliminationThreshold;
    }
    
    // TODO: for some reason tests didnt have access to implicit getters. look into why?
    // i.e. tournament.match(uint256,uin256, uin256) -> Match
    function getMatch(uint128 wins, uint128 losses, uint256 matchIndex) public view returns (Match memory) {
        return matches[wins][losses][matchIndex];
    }

    function getNextMatch() public view returns (MatchId memory) {
        MatchId memory matchId = matchBook[matchBookHead];
        return matchId;
    }

    function getOutcomes(uint256 playerId) public view returns (ResultCounter memory) {
        return outcomes[playerId];
    }


    // //////////////////////////////////
    // ----- Private Functions -----
    // //////////////////////////////////

    function _addMatchToQueue(ResultCounter memory group, uint128 matchIndex) private {
        unchecked { matchBookTail++; }
        matchBook[matchBookTail] = MatchId(group, matchIndex);
    }

    function _addPlayerToNextMatch(uint64 playerId, ResultCounter memory result) private {        
        // player has completed all possible matches and cannot advance further
        if (result.wins == winnerThreshold) return;
        if (result.losses == eliminationThreshold) return;
        
        uint128 matchIndex = groupMatchLength[result.wins][result.losses];
        Match storage nextMatchup = matches[result.wins][result.losses][matchIndex];
        
        // kind of useful to have, but tests prove we are not overwriting matches
        // require(nextMatchup.played == false, "match already played");
        
        // next matchup does not have a player0
        if (nextMatchup.player0 == 0) {
            nextMatchup.player0 = playerId;
            
            _addMatchToQueue(result, matchIndex);
        } else {
            nextMatchup.player1 = playerId;
            
            // matchup has been filled so advance the pointer to the next matchup
            // for subsequent matches
            unchecked { groupMatchLength[result.wins][result.losses]++; }
        }
    }


    // //////////////////////////////////
    // ----- Modifiers -----
    // //////////////////////////////////

    // 'decorates' the playMatch function
    // verifies that the given match has not yet been played
    // also reads the outcome of the matchup and advances the players to the next group
    modifier advancePlayers(ResultCounter memory group, uint256 matchIndex) {
        Match storage matchup = matches[group.wins][group.losses][matchIndex];

        // player has no opponent
        if (matchup.player1 == 0) return;
        require(!matchup.played, "Match has already been played");
        
        // play the match
        _;
        
        Match storage postMatchResult = matches[group.wins][group.losses][matchIndex];

        // i could handle this automatically; but i want to be explicit
        // and ensure the implementer is reading carefully :)
        require(postMatchResult.played, "Matchup did not resolve");
        require(postMatchResult.winnerId != 0, "Matchup did not resolve");
        
        // update the results of the players
        unchecked {
            if (postMatchResult.winnerId == postMatchResult.player0) {
                outcomes[postMatchResult.player0].wins++;
                outcomes[postMatchResult.player1].losses++;
            } else {
                outcomes[postMatchResult.player0].losses++;
                outcomes[postMatchResult.player1].wins++;
            }
        }

        _addPlayerToNextMatch(postMatchResult.player0, outcomes[postMatchResult.player0]);
        _addPlayerToNextMatch(postMatchResult.player1, outcomes[postMatchResult.player1]);
    }
}

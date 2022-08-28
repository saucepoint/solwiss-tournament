// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SwissTournament.sol";
import "./interfaces/IMatchResolver.sol";

/// @title Swiss tournament manager
/// @author @saucepoint <saucepoint@protonmail.com>
/// @notice Instances will be created by the factory. Assumes the provided contract adheres to IMatchResolver
contract SwissTournamentManager is SwissTournament {
    mapping(address => bool) public isAdmin;
    mapping(bytes32 => bool) public signatureUsed;
    address public adminSigner;
    IMatchResolver matchResolver;

    constructor(address admin, address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] memory playerIds)
        SwissTournament(_winThreshold, _eliminationThreshold, playerIds)
    {
        matchResolver = IMatchResolver(_matchResolver);
        isAdmin[admin] = true;
    }

    /// Implement SwissTournament.playMatch()
    /// Must decorate with SwissTournament.advancePlayers() modifier
    function playMatch(ResultCounter memory group, uint256 matchIndex) internal override advancePlayers(group, matchIndex) {
        // modifier will validate that the match has not yet been played
        Match storage matchup = matches[group.wins][group.losses][matchIndex];
        
        // Creating tournaments using the factory assumes that the Game contract adheres to IMatchResolver interface
        // given two playerIds, return the id of the winner
        uint256 winnerId = matchResolver.matchup(matchup.player0, matchup.player1);
        require(winnerId != 0, "Winner or playerId cannot be 0");

        /// @dev Implementing playMatch() requires you to update the outcome of the match
        matchup.winnerId = winnerId;
        matchup.played = true;
        
        // the advancePlayers() modifier will handle advancing the players to the next group
    }

    /// Wraps the next-match manager behind permissioned access
    function playNextMatch(bytes32 r, bytes32 s, uint8 v, bytes32 _hash) public allowable(r, s, v, _hash) {
        _playNextMatch();
    }


    // ------------------------------------
    // ------ Permissions Management ------
    // ------------------------------------

    function addTournamentAdmin(address _newAdmin) public onlyAdmin() {
        isAdmin[_newAdmin] = true;
    }

    function removeTournamentAdmin(address _admin) public onlyAdmin() {
        isAdmin[_admin] = false;
    }

    function setAdminSigner(address _adminSigner) public onlyAdmin() {
        adminSigner = _adminSigner;
    }


    // ------------------------
    // ------ Modifiers ------
    // ------------------------

    modifier allowable(bytes32 r, bytes32 s, uint8 v, bytes32 _hash) {
        if (!isAdmin[msg.sender]) {
            require(ecrecover( _hash, v, r, s) == adminSigner, "Invalid signature");
            require(!signatureUsed[_hash], "Signature used");
            signatureUsed[_hash] = true;
        }
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin");
        _;
    }
}
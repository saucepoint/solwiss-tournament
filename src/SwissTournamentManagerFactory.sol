// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SwissTournamentManager.sol";

contract SwissTournamentManagerFactory {
    // tournament organizer (creator) => tournamentId => address(SwissTournamentManager)
    mapping(address => mapping(uint256 => address)) public tournamentAddress;

    // tournament organizer (creator) => number of created tournaments
    // used for fetching the current tournament, or historical tournaments
    mapping(address => uint256) public tournamentCounter;

    event TournamentCreated(address organizer, uint256 tournamentId, address tournament);

    function create(address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] calldata _playerIds, uint256 _salt) public returns (address) {
        require(_winThreshold != 0, "Invalid threshold");
        require(_eliminationThreshold != 0, "Invalid threshold");

        bytes memory bytecode = _getCreationByteCodeWithConstructor(msg.sender, _matchResolver, _winThreshold, _eliminationThreshold, _playerIds);

        address tournamentAddr;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, tournamentCounter[msg.sender], _salt));
        assembly {
            tournamentAddr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        tournamentAddress[msg.sender][tournamentCounter[msg.sender]] = tournamentAddr;
        emit TournamentCreated(msg.sender, tournamentCounter[msg.sender], tournamentAddr);
        unchecked { tournamentCounter[msg.sender]++; }
        return tournamentAddr;
    }

    function getLatestTournament(address creator) public view returns (address) {
        return tournamentAddress[creator][tournamentCounter[creator] - 1];
    }

    function _getCreationByteCodeWithConstructor(address _admin, address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] memory _playerIds) private pure returns (bytes memory){
        return abi.encodePacked(type(SwissTournamentManager).creationCode, abi.encode(_admin, _matchResolver, _winThreshold, _eliminationThreshold, _playerIds));
    }
}
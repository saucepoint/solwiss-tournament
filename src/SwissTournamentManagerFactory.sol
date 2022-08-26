// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SwissTournamentManager.sol";

contract SwissTournamentManagerFactory {

    mapping(address => mapping(uint256 => address)) public tournament;
    mapping(address => uint256) public tournamentCounter;

    event TournamentCreated(address organizer, uint256 tournamentId, address tournament);

    function create(address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] calldata _playerIds) public returns (address) {
        require(_winThreshold != 0, "Invalid threshold");
        require(_eliminationThreshold != 0, "Invalid threshold");

        bytes memory bytecode = _getCreationByteCodeWithConstructor(_matchResolver, _winThreshold, _eliminationThreshold, _playerIds);

        address tournamentAddr;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, tournamentCounter[msg.sender]));
        assembly {
            tournamentAddr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        tournament[msg.sender][tournamentCounter[msg.sender]] = tournamentAddr;
        emit TournamentCreated(msg.sender, tournamentCounter[msg.sender], tournamentAddr);
        unchecked { tournamentCounter[msg.sender]++; }
        return tournamentAddr;
    }

    function getTournament(address creator, uint256 tournamentId) public view returns (address) {
        return tournament[creator][tournamentId];
    }

    function getLatestTournament(address creator) public view returns (address) {
        return tournament[creator][tournamentCounter[creator] - 1];
    }

    function _getCreationByteCodeWithConstructor(address _matchResolver, uint256 _winThreshold, uint256 _eliminationThreshold, uint256[] memory _playerIds) private pure returns (bytes memory){
        return abi.encodePacked(type(SwissTournamentManager).creationCode, abi.encode(_matchResolver, _winThreshold, _eliminationThreshold, _playerIds));
    }
}
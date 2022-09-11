// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SwissTournamentManagerFactory.sol";
import "../test/mocks/MockGame.sol";
import "../test/lib.sol";

contract MatchSim is Script {
    SwissTournamentManagerFactory factory = SwissTournamentManagerFactory(address(0x6Fdd00a14Ba88956FE10d0653b270a8087f93E0c));
    SwissTournamentManager tournament;
    MockGame game = MockGame(address(0x918bb1C316f76d0189eEadD7cBCF1139508CfA3d));
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        uint64[] memory _playerIds = TournamentLibrary.getPlayerIds(16);
        address tournamentAddr = factory.create(address(game), 3, 3, _playerIds, 0);
        vm.stopBroadcast();

        tournament = SwissTournamentManager(tournamentAddr);
        vm.startBroadcast();
        tournament.addTournamentAdmin(address(0xdeadbeef));
        tournament.setAdminSigner(address(0xbeef));
        vm.stopBroadcast();
        
        while (tournament.matchBookHead() <= tournament.matchBookTail()) {
            vm.broadcast();
            tournament.playNextMatch(0,0,0,0);
        }
        console.log("tournamentAddr", tournamentAddr);
    }
}

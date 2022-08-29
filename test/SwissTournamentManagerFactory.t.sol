// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SwissTournament.sol";
import "../src/SwissTournamentManager.sol";
import "../src/SwissTournamentManagerFactory.sol";
import "./lib.sol";
import "./mocks/MockGame.sol";

contract SwissTournamentFactoryTest is Test {
    SwissTournamentManagerFactory factory;
    MockGame game;
    function setUp() public {
        factory = new SwissTournamentManagerFactory();
        game = new MockGame();
    }

    function testCreate() public {
        address organizer = address(0x00DEADBEEF);
        uint256 tournamentId = factory.tournamentCounter(organizer);
        uint64[] memory playerIds = TournamentLibrary.getPlayerIds(16);

        vm.startPrank(organizer);
        address tournamentAddr = factory.create(address(game), 3, 3, playerIds, 0);
        assertEq(tournamentAddr, factory.tournamentAddress(organizer, tournamentId));
        assertEq(tournamentAddr == address(0x0), false);
        vm.stopPrank();

        SwissTournamentManager tournament = SwissTournamentManager(tournamentAddr);

        assertEq(tournamentAddr, factory.getLatestTournament(organizer));
        assertEq(factory.tournamentCounter(organizer), 1);

        assertEq(tournament.isAdmin(organizer), true);
        vm.startPrank(organizer);
        TournamentLibrary.simTournament(tournament);
        vm.stopPrank();
        
        // in 16 player 3W/3L there should be 33 matches leading to 8 winners and 8 losers
        (, uint256 numMatches, uint256 numWinners, uint256 numLosers) = TournamentLibrary.getTournamentStats(tournament, playerIds);
        assertEq(numMatches, 33);
        assertEq(numWinners, 8);
        assertEq(numLosers, 8);
    }

    function testSignaturePermission() public {
        address organizer = address(0x00DEADBEEF);
        uint256 tournamentId = factory.tournamentCounter(organizer);
        uint64[] memory playerIds = TournamentLibrary.getPlayerIds(16);

        vm.startPrank(organizer);
        address tournamentAddr = factory.create(address(game), 3, 3, playerIds, 0);
        assertEq(tournamentAddr, factory.tournamentAddress(organizer, tournamentId));
        assertEq(tournamentAddr == address(0x0), false);
        vm.stopPrank();

        SwissTournamentManager tournament = SwissTournamentManager(tournamentAddr);
        address signer = vm.addr(111_111_111);
        vm.prank(organizer);
        tournament.setAdminSigner(signer);
        assertEq(tournament.adminSigner(), signer);

        address alice = address(0x111222);
        bytes32 _hash = keccak256(abi.encodePacked(uint256(1)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(111_111_111, _hash);
        vm.prank(alice);
        tournament.playNextMatch(r, s, v, _hash);
        assertEq(tournament.matchBookHead(), 1);  // match was played and head advanced

        // verify the hash is not usable anymore
        vm.startPrank(alice);
        vm.expectRevert(bytes("Signature used"));
        tournament.playNextMatch(r, s, v, _hash);
        vm.stopPrank();
    }

    function testSignaturePermissionFail() public {
        address organizer = address(0x00DEADBEEF);
        uint256 tournamentId = factory.tournamentCounter(organizer);
        uint64[] memory playerIds = TournamentLibrary.getPlayerIds(16);

        vm.startPrank(organizer);
        address tournamentAddr = factory.create(address(game), 3, 3, playerIds, 0);
        assertEq(tournamentAddr, factory.tournamentAddress(organizer, tournamentId));
        assertEq(tournamentAddr == address(0x0), false);
        vm.stopPrank();

        SwissTournamentManager tournament = SwissTournamentManager(tournamentAddr);
        address signer = vm.addr(111_111_111);
        vm.prank(organizer);
        tournament.setAdminSigner(signer);
        assertEq(tournament.adminSigner(), signer);

        address alice = address(0x111222);
        bytes32 _hash = keccak256(abi.encodePacked(uint256(1)));
        // forge a fake signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(222_222_222, _hash);

        // verify the signature is not valid
        vm.startPrank(alice);
        vm.expectRevert(bytes("Invalid signature"));
        tournament.playNextMatch(r, s, v, _hash);
        vm.stopPrank();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CivilRegistry.sol";
import "../src/UnionRings.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract CivilRegistryTest is Test {
    uint64 schema = 0x4c;
    address deployerPublicKey;
    uint256 scrollSepoliaFork;
    CivilRegistry civilRegistry;
    UnionRings ringsContract;
    address scrollSepoliaSP = 0x4e4af2a21ebf62850fD99Eb6253E1eFBb56098cD;

    
    address proposer = address(0x1);
    address proposee = address(0x2);

    function setUp() public {
     deployerPublicKey = vm.envAddress("PUBLIC_KEY");
      string memory scrollSepoliaRPC =  vm.envString("SCROLL_SEPOLIA_RPC");
      scrollSepoliaFork = vm.createFork(scrollSepoliaRPC);
        vm.selectFork(scrollSepoliaFork);

    // deploy union rings contract
    address unionRingsProxy = Upgrades.deployTransparentProxy(
    "UnionRings.sol",
    deployerPublicKey,
    abi.encodeCall(UnionRings.initialize, (deployerPublicKey, deployerPublicKey))
);


    // deploy civil registry contract
    address civilRegistryProxy = Upgrades.deployTransparentProxy(
    "CivilRegistry.sol:CivilRegistry",
    deployerPublicKey,
    abi.encodeCall(CivilRegistry.initialize, (address(unionRingsProxy), schema, scrollSepoliaSP))
);
    // set the contracts addresses
    civilRegistry = CivilRegistry(address(civilRegistryProxy));
    ringsContract = UnionRings(address(unionRingsProxy));

    // handle permissions 
    vm.prank(deployerPublicKey);
    ringsContract.grantRole(keccak256("MINTER_ROLE"), civilRegistryProxy);

    console.log("UnionRings deployed at: ", unionRingsProxy);
    console.log("CivilRegistry deployed at: ", civilRegistryProxy);
    }

    function testProposeUnion() public {
        vm.startPrank(proposer);
        uint256 tokenId = 1;
        string memory vow = "I promise to love you forever";
        bytes32 secretHash = keccak256(abi.encodePacked("secret"));

        civilRegistry.proposeUnion(tokenId, vow, secretHash);

        // (address[] memory participants, , , , , , ) = civilRegistry.unions(0);
        // assertEq(participants[0], proposer);
        // assertEq(participants.length, 1);
        vm.stopPrank();
    }

    function testAcceptUnion() public {
        vm.startPrank(proposer);
        string memory vow = "I promise to love you forever";
        bytes32 secretHash = keccak256(abi.encodePacked("secret"));

        civilRegistry.proposeUnion(0, vow, secretHash);
        vm.stopPrank();

        (address[] memory participants, string[] memory vows , uint256[] memory ringids , bool accepted , ) = civilRegistry.getUnion(0);
        
        console.log(participants[0], "proposer");
        console.log(vows[0], "proposer vows");
        console.log(ringids[0], "proposer ringId");
        console.log(accepted, "is accepted");

        vm.startPrank(proposee);
        string memory proposeeVow = "lov u 2";
        civilRegistry.acceptUnion(0, 1, proposeeVow, "secret");

        (address[] memory participantsAfter, string[] memory vowsAfter, uint256[] memory ringidsAfter, bool acceptedAfter, ) = civilRegistry.getUnion(0);

        console.log(participantsAfter[1], "proposee address");
        console.log(vowsAfter[1], "proposee vows");
        console.log(ringidsAfter[1], "proposee ringID");
        console.log(acceptedAfter, "is accepted");
        // (address[] memory participants, , , , , , ) = civilRegistry.unions(0);
        // assertEq(participants[1], proposee);
        // assertEq(participants.length, 2);
        vm.stopPrank();
    }
}
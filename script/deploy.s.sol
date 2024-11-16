// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {UnionRings} from "../src/UnionRings.sol";
import {CivilRegistry} from "../src/CivilRegistry.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract testDeploy is Script {
    address scrollSepoliaSP = 0x4e4af2a21ebf62850fD99Eb6253E1eFBb56098cD;
    TransparentUpgradeableProxy ringSelectorProxy;
    UnionRings unionRings;
    CivilRegistry civilRegistry;
    ProxyAdmin proxyAdmin;
    string private ringData = "";
    string private description = "An ever growing collection of rings that are used to attest to Unions";
    string private name = "Union Rings";

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployerPublicKey = vm.envAddress("PUBLIC_KEY");
        uint64 schema = 0x4c;
        vm.startBroadcast(deployerPrivateKey);

        // proxyAdmin = new ProxyAdmin();
        // ringSelectorImplementation = new UnionRings();
        // ringSelectorProxy = new TransparentUpgradeableProxy(
        //     address(ringSelectorImplementation),
        //     address(proxyAdmin),
        //     abi.encodeWithSelector(UnionRings(ringSelector).initialize.selector)
        // );
        // ringSelector = UnionRings(address(ringSelectorProxy));

        // deploy union rings contract
     address unionRingsProxy = Upgrades.deployTransparentProxy(
    "UnionRings.sol",
    msg.sender,
    abi.encodeCall(UnionRings.initialize, (deployerPublicKey, deployerPublicKey))
);


    // deploy civil registry contract
    address civilRegistryProxy = Upgrades.deployTransparentProxy(
    "CivilRegistry.sol:CivilRegistry",
    msg.sender,
    abi.encodeCall(CivilRegistry.initialize, (address(unionRingsProxy), schema, scrollSepoliaSP))
);
    console.log("UnionRings deployed at: ", unionRingsProxy);
    console.log("CivilRegistry deployed at: ", civilRegistryProxy);
    UnionRings(unionRingsProxy).grantRole(keccak256("MINTER_ROLE"), civilRegistryProxy);
}  

    }

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {UnionRings} from "../src/UnionRings.sol";
import {CivilRegistry} from "../src/CivilRegistry.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract testUpgrade is Script {
address unionRingsProxy = 0x6aF03854Fb688c1Ed5C28aB696e08E9B91c518fa;
address civilRegistryProxy = 0x123D13d263FED961e3de8780d5feFb7acd04A0eF;

function run() public {
    Upgrades.upgradeProxy(
    civilRegistryProxy,
    "CivilRegistry.sol:CivilRegistry",
    ""
);
}

}
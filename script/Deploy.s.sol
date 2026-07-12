// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Hoodlings} from "../src/Hoodlings.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        Hoodlings nft = new Hoodlings();
        vm.stopBroadcast();
        console.log("Hoodlings deployed:", address(nft));
        console.log("Founder supply minted:", nft.totalSupply());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HoodlingRenderer} from "../src/HoodlingRenderer.sol";

/// Prints trait JSON for the preview sample ids so diverse ones can be
/// picked for marketing images.
contract TraitDump is Script {
    function run() external pure {
        uint256[24] memory ids = [
            uint256(1), 7, 42, 99, 163,
            164, 300, 500, 777, 1000, 1337, 1777,
            2048, 2500, 2900, 3141, 3333, 3700,
            4000, 4200, 4444, 4551, 4662, 4663
        ];
        for (uint256 i = 0; i < ids.length; i++) {
            console.log(ids[i], HoodlingRenderer.attributesOf(ids[i]));
        }
    }
}

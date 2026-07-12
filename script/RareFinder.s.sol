// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HoodlingRenderer} from "../src/HoodlingRenderer.sol";

/// Scans token ids for rare trait combos to feature in marketing images.
contract RareFinder is Script {
    function run() external pure {
        uint256 lasers;
        uint256 ghosts;
        uint256 voids;
        for (uint256 id = 1; id <= 1200; id++) {
            HoodlingRenderer.Traits memory t = HoodlingRenderer.traitsOf(id);
            if (t.eyes == 5 && lasers < 4) {
                lasers++;
                console.log("LASER id", id, "hood", uint256(t.hood));
                console.log("  bg", uint256(t.bg), t.aura ? "AURA" : "-");
            }
            if (t.hood == 9 && ghosts < 3) {
                ghosts++;
                console.log("GHOST-WHITE id", id, "bg", uint256(t.bg));
            }
            if (t.bg == 7 && voids < 3) {
                voids++;
                console.log("VOID id", id, "hood", uint256(t.hood));
            }
        }
    }
}

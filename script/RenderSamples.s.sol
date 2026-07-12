// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HoodlingRenderer} from "../src/HoodlingRenderer.sol";

/// Writes sample SVGs to ./samples so the art can be previewed before deploy.
contract RenderSamples is Script {
    function run() external {
        uint256[24] memory ids = [
            uint256(1), 7, 42, 99, 163,          // Founders
            164, 300, 500, 777, 1000, 1337, 1777,
            2048, 2500, 2900, 3141, 3333, 3700,
            4000, 4200, 4444, 4551, 4662, 4663
        ];
        for (uint256 i = 0; i < ids.length; i++) {
            vm.writeFile(
                string(abi.encodePacked("samples/hoodling-", vm.toString(ids[i]), ".svg")),
                HoodlingRenderer.svgOf(ids[i])
            );
        }
    }
}

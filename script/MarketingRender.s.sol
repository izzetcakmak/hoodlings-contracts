// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HoodlingRenderer} from "../src/HoodlingRenderer.sol";

/// Renders the hero Hoodlings used in OpenSea marketing images.
contract MarketingRender is Script {
    function run() external {
        uint256[8] memory ids = [uint256(52), 89, 42, 99, 1000, 2900, 4444, 77];
        for (uint256 i = 0; i < ids.length; i++) {
            vm.writeFile(
                string(abi.encodePacked("samples/hoodling-", vm.toString(ids[i]), ".svg")),
                HoodlingRenderer.svgOf(ids[i])
            );
        }
    }
}

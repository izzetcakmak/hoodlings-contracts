// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {PublicDrop} from "seadrop/lib/SeaDropStructs.sol";
import {ISeaDropTokenContractMetadata} from "seadrop/interfaces/ISeaDropTokenContractMetadata.sol";
import {Base64} from "openzeppelin-contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {HoodlingsDrop} from "../src/HoodlingsDrop.sol";
import {HoodlingRenderer} from "../src/HoodlingRenderer.sol";

/// Deploys HoodlingsDrop and configures the OpenSea SeaDrop public drop
/// entirely on-chain in a single broadcast.
contract DeployDrop is Script {
    // Canonical SeaDrop v1 (verified deployed on Robinhood Chain).
    address constant SEADROP = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    // OpenSea's fee recipient (must be allowed for mints via opensea.io).
    address constant OPENSEA_FEE = 0x0000a26b00c1F0DF003000390027140000fAa719;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(pk);
        uint16 feeBps = uint16(vm.envOr("FEE_BPS", uint256(0)));

        address[] memory allowed = new address[](1);
        allowed[0] = SEADROP;

        vm.startBroadcast(pk);

        HoodlingsDrop nft = new HoodlingsDrop(allowed);
        nft.setMaxSupply(4663);
        nft.mintFounders(owner);
        nft.updateCreatorPayoutAddress(SEADROP, owner);
        nft.updateAllowedFeeRecipient(SEADROP, OPENSEA_FEE, true);
        nft.updateAllowedFeeRecipient(SEADROP, owner, true);
        nft.updatePublicDrop(
            SEADROP,
            PublicDrop({
                mintPrice: 0.0005 ether,
                startTime: uint48(block.timestamp),
                endTime: uint48(block.timestamp + 365 days),
                maxTotalMintableByWallet: 10,
                feeBps: feeBps,
                restrictFeeRecipients: true
            })
        );
        nft.setRoyaltyInfo(ISeaDropTokenContractMetadata.RoyaltyInfo(owner, 500));
        nft.setContractURI(_contractURI(owner));

        vm.stopBroadcast();

        console.log("HoodlingsDrop deployed:", address(nft));
        console.log("Founders minted:", nft.totalSupply());
    }

    function _contractURI(address owner) internal pure returns (string memory) {
        string memory json = string(
            abi.encodePacked(
                '{"name":"Hoodlings","description":"4663 fully on-chain hooded spirits of Robinhood Chain \\u2014 one for every unit of chain id 4663. No IPFS, no servers: every Hoodling is generated and stored inside the contract, forever.",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(HoodlingRenderer.svgOf(1))),
                '","seller_fee_basis_points":500,"fee_recipient":"',
                Strings.toHexString(uint160(owner), 20), '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}

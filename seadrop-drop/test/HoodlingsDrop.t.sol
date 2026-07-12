// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SeaDrop} from "seadrop/SeaDrop.sol";
import {PublicDrop} from "seadrop/lib/SeaDropStructs.sol";
import {ISeaDropTokenContractMetadata} from "seadrop/interfaces/ISeaDropTokenContractMetadata.sol";
import {HoodlingsDrop} from "../src/HoodlingsDrop.sol";

contract HoodlingsDropTest is Test {
    SeaDrop seadrop;
    HoodlingsDrop nft;
    address owner = address(0xD4F1);
    address minter = address(0xBEEF);
    address feeRecipient = address(0xFEE);

    function setUp() public {
        seadrop = new SeaDrop();
        address[] memory allowed = new address[](1);
        allowed[0] = address(seadrop);

        vm.startPrank(owner);
        nft = new HoodlingsDrop(allowed);
        nft.setMaxSupply(4663);
        nft.mintFounders(owner);
        nft.updateCreatorPayoutAddress(address(seadrop), owner);
        nft.updateAllowedFeeRecipient(address(seadrop), feeRecipient, true);
        nft.updatePublicDrop(
            address(seadrop),
            PublicDrop({
                mintPrice: 0.0005 ether,
                startTime: uint48(block.timestamp),
                endTime: uint48(block.timestamp + 365 days),
                maxTotalMintableByWallet: 10,
                feeBps: 0,
                restrictFeeRecipients: true
            })
        );
        nft.setRoyaltyInfo(ISeaDropTokenContractMetadata.RoyaltyInfo(owner, 500));
        vm.stopPrank();

        vm.deal(minter, 1 ether);
    }

    function test_FoundersMintedToOwner() public {
        assertEq(nft.balanceOf(owner), 163);
        assertEq(nft.totalSupply(), 163);
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.ownerOf(163), owner);
    }

    function test_FoundersOnlyOnce() public {
        vm.prank(owner);
        vm.expectRevert(HoodlingsDrop.FoundersAlreadyMinted.selector);
        nft.mintFounders(owner);
    }

    function test_FoundersOnlyOwner() public {
        vm.prank(minter);
        vm.expectRevert();
        nft.mintFounders(minter);
    }

    function test_PublicMintThroughSeaDrop() public {
        uint256 creatorBefore = owner.balance;
        vm.prank(minter);
        seadrop.mintPublic{value: 0.0015 ether}(address(nft), feeRecipient, address(0), 3);
        assertEq(nft.balanceOf(minter), 3);
        assertEq(nft.ownerOf(164), minter);
        assertEq(nft.totalSupply(), 166);
        // feeBps = 0: full price goes to the creator payout address
        assertEq(owner.balance, creatorBefore + 0.0015 ether);
    }

    function test_WrongPaymentReverts() public {
        vm.prank(minter);
        vm.expectRevert();
        seadrop.mintPublic{value: 0.0001 ether}(address(nft), feeRecipient, address(0), 1);
    }

    function test_WalletLimitEnforced() public {
        vm.startPrank(minter);
        seadrop.mintPublic{value: 0.005 ether}(address(nft), feeRecipient, address(0), 10);
        vm.expectRevert();
        seadrop.mintPublic{value: 0.0005 ether}(address(nft), feeRecipient, address(0), 1);
        vm.stopPrank();
    }

    function test_UnallowedFeeRecipientReverts() public {
        vm.prank(minter);
        vm.expectRevert();
        seadrop.mintPublic{value: 0.0005 ether}(address(nft), address(0xBAD), address(0), 1);
    }

    function test_MaxSupplyEnforced() public {
        // Fresh instance capped just above the founder reserve.
        address[] memory allowed = new address[](1);
        allowed[0] = address(seadrop);
        vm.startPrank(owner);
        HoodlingsDrop small = new HoodlingsDrop(allowed);
        small.setMaxSupply(165);
        small.mintFounders(owner);
        small.updateCreatorPayoutAddress(address(seadrop), owner);
        small.updateAllowedFeeRecipient(address(seadrop), feeRecipient, true);
        small.updatePublicDrop(
            address(seadrop),
            PublicDrop(0.0005 ether, uint48(block.timestamp), uint48(block.timestamp + 1 days), 10, 0, true)
        );
        vm.stopPrank();

        vm.startPrank(minter);
        vm.expectRevert();
        seadrop.mintPublic{value: 0.0015 ether}(address(small), feeRecipient, address(0), 3);
        seadrop.mintPublic{value: 0.001 ether}(address(small), feeRecipient, address(0), 2);
        vm.stopPrank();
        assertEq(small.totalSupply(), 165);
    }

    function test_TokenURIFullyOnChain() public {
        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 500);
        bytes memory prefix = new bytes(29);
        bytes memory b = bytes(uri);
        for (uint256 i = 0; i < 29; i++) prefix[i] = b[i];
        assertEq(string(prefix), "data:application/json;base64,");

        vm.expectRevert();
        nft.tokenURI(500); // not minted yet
    }

    function test_RoyaltyInfo() public {
        (address receiver, uint256 amount) = nft.royaltyInfo(1, 10000);
        assertEq(receiver, owner);
        assertEq(amount, 500);
    }

    function test_MintBeforeStartReverts() public {
        vm.prank(owner);
        nft.updatePublicDrop(
            address(seadrop),
            PublicDrop(0.0005 ether, uint48(block.timestamp + 1 hours), uint48(block.timestamp + 365 days), 10, 0, true)
        );
        vm.prank(minter);
        vm.expectRevert();
        seadrop.mintPublic{value: 0.0005 ether}(address(nft), feeRecipient, address(0), 1);
    }
}

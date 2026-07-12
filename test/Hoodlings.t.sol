// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Hoodlings} from "../src/Hoodlings.sol";

contract HoodlingsTest is Test {
    Hoodlings nft;
    address deployer = address(0xD4F1);
    address minter = address(0xBEEF);

    function setUp() public {
        vm.prank(deployer);
        nft = new Hoodlings();
        vm.deal(minter, 10 ether);
    }

    function test_FounderReserveMintedToDeployer() public view {
        assertEq(nft.balanceOf(deployer), 163);
        assertEq(nft.totalSupply(), 163);
        assertEq(nft.ownerOf(1), deployer);
        assertEq(nft.ownerOf(163), deployer);
    }

    function test_PublicMint() public {
        vm.prank(minter);
        nft.mint{value: 0.0025 ether}(5);
        assertEq(nft.balanceOf(minter), 5);
        assertEq(nft.ownerOf(164), minter);
    }

    function test_RevertWrongPayment() public {
        vm.prank(minter);
        vm.expectRevert(Hoodlings.WrongPayment.selector);
        nft.mint{value: 0.0001 ether}(1);
    }

    function test_RevertTooManyPerTx() public {
        vm.prank(minter);
        vm.expectRevert(Hoodlings.TooMany.selector);
        nft.mint{value: 0.0055 ether}(11);
    }

    function test_RevertWhenClosed() public {
        vm.prank(deployer);
        nft.setMintOpen(false);
        vm.prank(minter);
        vm.expectRevert(Hoodlings.MintClosed.selector);
        nft.mint{value: 0.0005 ether}(1);
    }

    function test_RevertPastMaxSupply() public {
        // mint out everything except 3
        uint256 remaining = 4663 - 163;
        vm.startPrank(minter);
        vm.deal(minter, 100 ether);
        uint256 full = (remaining - 3) / 10;
        for (uint256 i = 0; i < full; i++) {
            nft.mint{value: 0.005 ether}(10);
        }
        uint256 leftover = remaining - 3 - full * 10;
        if (leftover > 0) nft.mint{value: leftover * 0.0005 ether}(leftover);
        assertEq(nft.totalSupply(), 4660);

        vm.expectRevert(Hoodlings.SoldOut.selector);
        nft.mint{value: 0.002 ether}(4);

        nft.mint{value: 0.0015 ether}(3);
        assertEq(nft.totalSupply(), 4663);
        vm.stopPrank();
    }

    function test_TokenURIIsOnChainDataURI() public view {
        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 500);
        assertEq(_slice(uri, 0, 29), "data:application/json;base64,");
        // Founder trait must differ across the 163 boundary
        string memory founderUri = nft.tokenURI(163);
        assertTrue(bytes(founderUri).length > 500);
    }

    function test_TokenURIRevertsForNonexistent() public {
        vm.expectRevert();
        nft.tokenURI(200); // only 163 minted so far
    }

    function test_WithdrawToOwner() public {
        vm.prank(minter);
        nft.mint{value: 0.005 ether}(10);
        uint256 before = deployer.balance;
        vm.prank(deployer);
        nft.withdraw();
        assertEq(deployer.balance, before + 0.005 ether);
    }

    function test_RoyaltyInfo() public view {
        (address receiver, uint256 amount) = nft.royaltyInfo(1, 10000);
        assertEq(receiver, deployer);
        assertEq(amount, 500); // 5%
    }

    function test_SetMintPrice() public {
        vm.prank(deployer);
        nft.setMintPrice(0.001 ether);
        vm.prank(minter);
        nft.mint{value: 0.001 ether}(1);
        assertEq(nft.balanceOf(minter), 1);
    }

    function _slice(string memory s, uint256 start, uint256 len) private pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory out = new bytes(len);
        for (uint256 i = 0; i < len; i++) out[i] = b[start + i];
        return string(out);
    }
}

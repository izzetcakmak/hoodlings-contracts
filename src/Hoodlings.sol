// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {HoodlingRenderer} from "./HoodlingRenderer.sol";

/// @title Hoodlings
/// @notice 4663 fully on-chain hooded spirits of Robinhood Chain — one for
///         every unit of the chain id (4663). The first 163 are Founder
///         Hoodlings, minted to the creator at deploy. Art and metadata are
///         generated entirely inside this contract: no IPFS, no servers.
contract Hoodlings is ERC721A, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4663; // = Robinhood Chain id
    uint256 public constant FOUNDER_SUPPLY = 163;
    uint256 public constant MAX_PER_TX = 10;

    uint256 public mintPrice = 0.0005 ether;
    bool public mintOpen = true;

    error MintClosed();
    error SoldOut();
    error TooMany();
    error WrongPayment();

    constructor() ERC721A("Hoodlings", "HOODLING") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, 500); // 5%
        _mint(msg.sender, FOUNDER_SUPPLY);
    }

    // ---------------------------------------------------------------------
    // Minting
    // ---------------------------------------------------------------------

    function mint(uint256 quantity) external payable {
        if (!mintOpen) revert MintClosed();
        if (quantity == 0 || quantity > MAX_PER_TX) revert TooMany();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert SoldOut();
        if (msg.value != mintPrice * quantity) revert WrongPayment();
        _mint(msg.sender, quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ---------------------------------------------------------------------
    // Metadata — fully on-chain
    // ---------------------------------------------------------------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory svg = HoodlingRenderer.svgOf(tokenId);
        string memory json = string(
            abi.encodePacked(
                '{"name":"Hoodling #', tokenId.toString(),
                '","description":"One of 4663 fully on-chain hooded spirits of Robinhood Chain \\u2014 one for every unit of chain id 4663. Art and metadata live entirely inside the contract. The first 163 are Founder Hoodlings.",',
                '"attributes":', HoodlingRenderer.attributesOf(tokenId),
                ',"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice OpenSea collection-level metadata.
    function contractURI() external view returns (string memory) {
        string memory json = string(
            abi.encodePacked(
                '{"name":"Hoodlings","description":"4663 fully on-chain hooded spirits of Robinhood Chain \\u2014 one for every unit of chain id 4663. No IPFS, no servers: every Hoodling is generated and stored inside the contract, forever.",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(HoodlingRenderer.svgOf(1))),
                '","external_link":"","seller_fee_basis_points":500,"fee_recipient":"',
                Strings.toHexString(uint160(owner()), 20), '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ---------------------------------------------------------------------
    // Admin
    // ---------------------------------------------------------------------

    function setMintOpen(bool open) external onlyOwner {
        mintOpen = open;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function withdraw() external onlyOwner {
        (bool ok,) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "withdraw failed");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}

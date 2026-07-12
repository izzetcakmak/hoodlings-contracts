// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @title HoodlingRenderer
/// @notice Fully on-chain generative art for Hoodlings. Every trait and the
///         final SVG are derived deterministically from the token id — no
///         IPFS, no external dependencies, the art lives on Robinhood Chain
///         forever.
library HoodlingRenderer {
    using Strings for uint256;

    uint256 internal constant FOUNDER_SUPPLY = 163;

    struct Traits {
        uint8 bg;
        uint8 hood;
        uint8 eyes;
        uint8 emblem;
        bool aura;
        bool stars;
        bool founder;
    }

    // ---------------------------------------------------------------------
    // Trait derivation
    // ---------------------------------------------------------------------

    function traitsOf(uint256 tokenId) internal pure returns (Traits memory t) {
        uint256 r = uint256(keccak256(abi.encodePacked("HOODLING", tokenId)));

        t.bg = _weighted(r % 100, _bgWeights());
        t.hood = _weighted((r >> 16) % 100, _hoodWeights());
        t.eyes = _weighted((r >> 32) % 100, _eyeWeights());
        t.emblem = _weighted((r >> 48) % 100, _emblemWeights());
        t.aura = (r >> 64) % 100 < 12;
        t.stars = (r >> 80) % 100 < 42;
        t.founder = tokenId <= FOUNDER_SUPPLY;
    }

    function _weighted(uint256 roll, uint8[10] memory weights) private pure returns (uint8) {
        uint256 acc;
        for (uint8 i = 0; i < 10; i++) {
            acc += weights[i];
            if (roll < acc) return i;
        }
        return 0;
    }

    function _bgWeights() private pure returns (uint8[10] memory w) {
        w = [18, 16, 14, 14, 12, 12, 9, 5, 0, 0];
    }

    function _hoodWeights() private pure returns (uint8[10] memory w) {
        w = [15, 13, 12, 12, 11, 10, 9, 8, 6, 4];
    }

    function _eyeWeights() private pure returns (uint8[10] memory w) {
        w = [28, 24, 20, 13, 10, 5, 0, 0, 0, 0];
    }

    function _emblemWeights() private pure returns (uint8[10] memory w) {
        w = [22, 20, 18, 16, 14, 10, 0, 0, 0, 0];
    }

    // ---------------------------------------------------------------------
    // Palettes
    // ---------------------------------------------------------------------

    function _bgColors(uint8 i) private pure returns (string memory, string memory, string memory) {
        if (i == 0) return ("#0b1026", "#24345c", "Midnight Vault");
        if (i == 1) return ("#1a0b2e", "#6b2d5e", "Neon Dusk");
        if (i == 2) return ("#0b2618", "#14532d", "Deep Forest");
        if (i == 3) return ("#062033", "#0e5a7a", "Ocean Ledger");
        if (i == 4) return ("#1c2b0b", "#4d7c0f", "Bull Dawn");
        if (i == 5) return ("#260b0b", "#7f1d1d", "Bear Blood");
        if (i == 6) return ("#2b1d05", "#b8860b", "Feather Gold");
        return ("#000000", "#1c1c24", "The Void");
    }

    function _hoodColors(uint8 i) private pure returns (string memory, string memory) {
        if (i == 0) return ("#10b981", "Emerald");
        if (i == 1) return ("#7c3aed", "Royal Purple");
        if (i == 2) return ("#dc2626", "Crimson");
        if (i == 3) return ("#38bdf8", "Arctic");
        if (i == 4) return ("#f97316", "Sunset");
        if (i == 5) return ("#f43f5e", "Rose");
        if (i == 6) return ("#64748b", "Slate");
        if (i == 7) return ("#84cc16", "Lime");
        if (i == 8) return ("#f5c542", "Gold");
        return ("#e2e8f0", "Ghost White");
    }

    function _eyeColor(uint8 i) private pure returns (string memory, string memory) {
        if (i == 0) return ("#f8fafc", "Moon Glow");
        if (i == 1) return ("#fb923c", "Ember");
        if (i == 2) return ("#a5f3fc", "Slits");
        if (i == 3) return ("#fde047", "Star");
        if (i == 4) return ("#67e8f9", "Diamond");
        return ("#ef4444", "Laser");
    }

    function _emblemName(uint8 i) private pure returns (string memory) {
        if (i == 0) return "Feather";
        if (i == 1) return "Arrow";
        if (i == 2) return "Green Candle";
        if (i == 3) return "Bow";
        if (i == 4) return "Diamond";
        return "Lightning";
    }

    // ---------------------------------------------------------------------
    // SVG assembly
    // ---------------------------------------------------------------------

    function svgOf(uint256 tokenId) internal pure returns (string memory) {
        Traits memory t = traitsOf(tokenId);
        (string memory bg1, string memory bg2,) = _bgColors(t.bg);
        (string memory hoodC,) = _hoodColors(t.hood);
        (string memory eyeC,) = _eyeColor(t.eyes);

        return string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>",
                _defs(bg1, bg2, eyeC),
                "<rect width='100' height='100' fill='url(#b)'/>",
                t.stars ? _stars(tokenId) : "",
                t.aura ? "<circle cx='50' cy='52' r='36' fill='url(#a)'/>" : "",
                _figure(hoodC, t.founder),
                _eyes(t.eyes, eyeC),
                _emblem(t.emblem),
                "</svg>"
            )
        );
    }

    function _defs(string memory bg1, string memory bg2, string memory eyeC)
        private
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<defs><linearGradient id='b' x1='0' y1='0' x2='0' y2='1'>",
                "<stop offset='0' stop-color='", bg1, "'/>",
                "<stop offset='1' stop-color='", bg2, "'/></linearGradient>",
                "<radialGradient id='a'><stop offset='0' stop-color='", eyeC,
                "' stop-opacity='.55'/><stop offset='1' stop-color='", eyeC,
                "' stop-opacity='0'/></radialGradient></defs>"
            )
        );
    }

    function _stars(uint256 tokenId) private pure returns (string memory) {
        uint256 s = uint256(keccak256(abi.encodePacked("STARS", tokenId)));
        bytes memory out;
        for (uint256 i = 0; i < 7; i++) {
            uint256 x = (s >> (i * 14)) % 96 + 2;
            uint256 y = (s >> (i * 14 + 7)) % 52 + 2;
            out = abi.encodePacked(
                out,
                "<circle cx='", x.toString(), "' cy='", y.toString(),
                "' r='.7' fill='#fff' opacity='.7'/>"
            );
        }
        return string(out);
    }

    function _figure(string memory hoodC, bool founder) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<ellipse cx='50' cy='88' rx='24' ry='4' fill='#000' opacity='.35'/>",
                "<path d='M50 14C31 19 26 38 26 55L23 87L77 87L74 55C74 38 69 19 50 14Z' fill='",
                hoodC,
                founder ? "' stroke='#f5c542' stroke-width='1.6'/>" : "'/>",
                // hood fold shading
                "<path d='M50 14C31 19 26 38 26 55L23 87L38 87L36 55C36 36 40 20 50 14Z' fill='#000' opacity='.22'/>",
                // hood tip
                "<path d='M46 13Q50 6 54 13Q50 17 46 13Z' fill='", hoodC, "'/>",
                // face void
                "<ellipse cx='50' cy='41' rx='13' ry='15' fill='#0a0a12'/>"
            )
        );
    }

    function _eyes(uint8 style, string memory c) private pure returns (string memory) {
        if (style == 2) {
            // Slits
            return string(
                abi.encodePacked(
                    "<rect x='40' y='41' width='7' height='1.8' rx='.9' fill='", c, "'/>",
                    "<rect x='53' y='41' width='7' height='1.8' rx='.9' fill='", c, "'/>"
                )
            );
        }
        if (style == 3) {
            // Star eyes
            return string(
                abi.encodePacked(
                    "<path d='M44 39l1 2.4 2.4 1-2.4 1-1 2.4-1-2.4-2.4-1 2.4-1z' fill='", c, "'/>",
                    "<path d='M56 39l1 2.4 2.4 1-2.4 1-1 2.4-1-2.4-2.4-1 2.4-1z' fill='", c, "'/>"
                )
            );
        }
        if (style == 4) {
            // Diamond eyes
            return string(
                abi.encodePacked(
                    "<path d='M44 39l2.6 2.6-2.6 3.4-2.6-3.4z' fill='", c, "'/>",
                    "<path d='M56 39l2.6 2.6-2.6 3.4-2.6-3.4z' fill='", c, "'/>"
                )
            );
        }
        if (style == 5) {
            // Laser eyes with beams
            return string(
                abi.encodePacked(
                    "<rect x='44' y='41' width='56' height='1.4' fill='", c, "' opacity='.5'/>",
                    "<rect x='56' y='42.5' width='44' height='1.4' fill='", c, "' opacity='.5'/>",
                    "<circle cx='44' cy='42' r='2.4' fill='", c, "'/>",
                    "<circle cx='56' cy='42' r='2.4' fill='", c, "'/>"
                )
            );
        }
        // Moon Glow / Ember: round glowing eyes
        return string(
            abi.encodePacked(
                "<circle cx='44' cy='42' r='3.4' fill='", c, "' opacity='.25'/>",
                "<circle cx='56' cy='42' r='3.4' fill='", c, "' opacity='.25'/>",
                "<circle cx='44' cy='42' r='2' fill='", c, "'/>",
                "<circle cx='56' cy='42' r='2' fill='", c, "'/>"
            )
        );
    }

    function _emblem(uint8 i) private pure returns (string memory) {
        if (i == 0) {
            // Feather
            return "<path d='M50 60c5.5 2.5 5.5 10 0 14c-3.5-3.5-4.5-10 0-14z' fill='#fff' opacity='.85'/><line x1='50' y1='62' x2='50' y2='76' stroke='#fff' stroke-width='.7' opacity='.85'/>";
        }
        if (i == 1) {
            // Arrow
            return "<line x1='44' y1='74' x2='55' y2='63' stroke='#fff' stroke-width='1.4'/><path d='M56 60l-6 1.5 4.5 4.5z' fill='#fff'/>";
        }
        if (i == 2) {
            // Green candle
            return "<line x1='50' y1='59' x2='50' y2='76' stroke='#22c55e' stroke-width='1.2'/><rect x='47' y='63' width='6' height='9' rx='1' fill='#22c55e'/>";
        }
        if (i == 3) {
            // Bow
            return "<path d='M46 60q9 7 0 15' fill='none' stroke='#fff' stroke-width='1.4'/><line x1='46' y1='60' x2='46' y2='75' stroke='#fff' stroke-width='.7'/>";
        }
        if (i == 4) {
            // Diamond
            return "<path d='M50 61l5.5 4.5L50 74l-5.5-8.5z' fill='#67e8f9'/><path d='M44.5 65.5h11' stroke='#0e7490' stroke-width='.6'/>";
        }
        // Lightning
        return "<path d='M52.5 59l-7 9h4.5l-2.5 8 7-9.5h-4.5z' fill='#fde047'/>";
    }

    // ---------------------------------------------------------------------
    // Metadata
    // ---------------------------------------------------------------------

    function attributesOf(uint256 tokenId) internal pure returns (string memory) {
        Traits memory t = traitsOf(tokenId);
        (,, string memory bgName) = _bgColors(t.bg);
        (, string memory hoodName) = _hoodColors(t.hood);
        (, string memory eyeName) = _eyeColor(t.eyes);

        return string(
            abi.encodePacked(
                '[{"trait_type":"Background","value":"', bgName,
                '"},{"trait_type":"Hood","value":"', hoodName,
                '"},{"trait_type":"Eyes","value":"', eyeName,
                '"},{"trait_type":"Emblem","value":"', _emblemName(t.emblem),
                '"},{"trait_type":"Aura","value":"', t.aura ? "Yes" : "No",
                '"},{"trait_type":"Founder","value":"', t.founder ? "Yes" : "No",
                '"}]'
            )
        );
    }
}

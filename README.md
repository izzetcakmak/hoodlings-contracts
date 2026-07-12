# Hoodlings

**4663 fully on-chain hooded spirits of Robinhood Chain — one for every unit of chain id 4663.**

No IPFS. No servers. Every Hoodling's art and metadata are generated and stored entirely inside the contract, forever.

- **Mint:** https://izzetcakmak.github.io/hoodlings/ — 0.0005 ETH, max 10 per tx
- **Contract:** [`0x2ac39f76ddb6cfb48bb9d39bad95b55396c52334`](https://robinhoodchain.blockscout.com/address/0x2ac39f76ddb6cfb48bb9d39bad95b55396c52334) (Robinhood Chain mainnet, chain id 4663)
- **OpenSea:** https://opensea.io/assets/robinhood/0x2ac39f76ddb6cfb48bb9d39bad95b55396c52334

## The 4663 story

Robinhood Chain's chain id is **4663** — so that's the supply. The first **163 Founder Hoodlings** wear gold-trimmed hoods and carry the `Founder` trait on-chain.

## Traits

| Trait | Options | Rarest |
|---|---|---|
| Background | 8 gradient palettes | The Void (5%) |
| Hood | 10 colors | Ghost White (4%) |
| Eyes | 6 styles | Laser (5%) |
| Emblem | Feather, Arrow, Green Candle, Bow, Diamond, Lightning | Lightning (10%) |
| Aura | glow behind the figure | 12% |
| Founder | token ids 1–163 | 3.5% |

## Stack

- Solidity 0.8.24, [Foundry](https://getfoundry.sh), ERC721A, OpenZeppelin (Ownable, ERC2981 5% royalty, Base64)
- `tokenURI` returns a `data:application/json;base64` URI with the SVG embedded — fully self-contained
- `contractURI()` provides OpenSea collection metadata

## Repo layout

This repo (`hoodlings-contracts`, private) holds the contract source, tests, and deploy scripts. The public mint page is deployed from the separate [`hoodlings`](https://github.com/izzetcakmak/hoodlings) repo; to update it, edit `docs/` here, copy to `../hoodlings-site`, and push there.

## Develop

```bash
forge test            # 11 tests
forge script script/RenderSamples.s.sol   # writes sample SVGs to ./samples
```

Deploy (needs `PRIVATE_KEY` in env):

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url robinhood --broadcast
```

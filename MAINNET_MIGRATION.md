# Migrating from Mandala Testnet to Mandala Mainnet

This guide documents everything needed to move the app from Mandala Testnet
to Mandala Mainnet. Network parameters below were confirmed against the
official docs (`docs.mandalachain.io`) in September 2026 — **re-verify them
against the docs site before migrating**, since testnet/mainnet endpoints can
change.

## 1. What actually changes (and what doesn't)

Nothing about the app's *architecture* changes — same wallet-driven,
fully-on-chain design described in `SYSTEM_DESIGN.md`. What changes is:

1. Which network the frontend points MetaMask at.
2. The contract address the frontend talks to (mainnet needs its **own**
   deployment — a testnet contract address does not exist on mainnet).
3. The currency used to pay gas is real, tradeable money (KPG) instead of
   free testnet tokens (KPGT).

## 2. Network parameters: testnet vs. mainnet

| | Testnet (current) | Mainnet |
|---|---|---|
| Chain name | Mandala Testnet | Mandala Mainnet |
| Chain ID (decimal) | `20011` | `20010` |
| Chain ID (hex) | `0x4E2B` | `0x4E2A` |
| Native currency | **KPGT** (test token, no real value) | **KPG** ("Kepeng" — real, tradeable token) |
| Currency decimals | 18 | 18 |
| RPC URL | `https://rpc1-testnet.mandalachain.io` | `https://rpc1-mainnet.mandalachain.io` |
| Block explorer | `https://explorer.testnet.mandalachain.io` | `https://explorer.mandalachain.io` |
| Settlement layer | Sepolia | Ethereum L1 (Arbitrum Orbit stack) |

⚠️ **KPGT and KPG are not the same token and are not interchangeable.**
Mainnet KPG has real market value (it's listed on CoinMarketCap); testnet
KPGT does not. Don't assume "the team has KPGT so we're fine" — mainnet gas
must be paid for in real KPG, acquired separately.

## 3. Code change: update the network config

Everything network-related in the frontend flows from a single config object
in `frontend/index.html`. Today it looks like this:

```js
const MANDALA_TESTNET = {
  chainId: "0x4E2B", // 20011 in hex
  chainName: "Mandala Testnet",
  nativeCurrency: { name: "KPGT", symbol: "KPGT", decimals: 18 },
  rpcUrls: ["https://rpc1-testnet.mandalachain.io"],
  blockExplorerUrls: ["https://explorer.testnet.mandalachain.io"]
};
```

For mainnet, replace it with:

```js
const MANDALA_MAINNET = {
  chainId: "0x4E2A", // 20010 in hex
  chainName: "Mandala Mainnet",
  nativeCurrency: { name: "Kepeng", symbol: "KPG", decimals: 18 },
  rpcUrls: ["https://rpc1-mainnet.mandalachain.io"],
  blockExplorerUrls: ["https://explorer.mandalachain.io"]
};
```

Every other reference in the file uses the constant by name (`ensureNetwork`,
`connect`, and the transaction-history "Tx hash" links via
`MANDALA_TESTNET.blockExplorerUrls[0]`) — so a straight rename of the
constant everywhere it's used (`MANDALA_TESTNET` → `MANDALA_MAINNET`) plus the
value swap above is enough. No other logic needs to change.

**Better long-term option — don't hardcode a single network at all.** Since
this exact situation (testnet today, mainnet tomorrow, maybe both later) is
likely to recur, consider replacing the single constant with a small selector
instead of doing a find-and-replace each time:

```js
const NETWORKS = {
  testnet: {
    chainId: "0x4E2B",
    chainName: "Mandala Testnet",
    nativeCurrency: { name: "KPGT", symbol: "KPGT", decimals: 18 },
    rpcUrls: ["https://rpc1-testnet.mandalachain.io"],
    blockExplorerUrls: ["https://explorer.testnet.mandalachain.io"]
  },
  mainnet: {
    chainId: "0x4E2A",
    chainName: "Mandala Mainnet",
    nativeCurrency: { name: "Kepeng", symbol: "KPG", decimals: 18 },
    rpcUrls: ["https://rpc1-mainnet.mandalachain.io"],
    blockExplorerUrls: ["https://explorer.mandalachain.io"]
  }
};
// Flip this one line to switch networks, or read it from a query param
// (?network=mainnet) so testnet and mainnet builds can share one deploy.
const ACTIVE_NETWORK = NETWORKS.testnet;
```

Then replace every `MANDALA_TESTNET` reference in the file with
`ACTIVE_NETWORK`.

## 4. Blocking dependency: the smart contract

This is the part that isn't a code edit — **the "Housework Credits" contract
itself has to be deployed fresh on mainnet.** A contract address only exists
on the network it was deployed to; the current testnet address will not
resolve on mainnet.

This is where the gap flagged in `HANDOVER.md` becomes a hard blocker: **we do
not have the contract's Solidity source code**, only its ABI. Concretely,
before mainnet migration can happen, someone needs to:

1. Recover the original `.sol` source (from the original deployer, or by
   checking whether the testnet contract is verified on
   `explorer.testnet.mandalachain.io`, which would publish its source).
2. Review it — this app moves from "fake" credits to gas paid in real money,
   so it's worth (re-)checking: who is allowed to call `sendCredits`, whether
   amounts can go negative or overflow, and whether the 3 hardcoded account
   addresses baked into the constructor are correct (**they cannot be
   changed after deployment** — see `SYSTEM_DESIGN.md` §4).
3. Deploy it to Mandala Mainnet (chain ID `20010`) with the real wallet
   addresses of the 3 family members, paying deployment gas in real KPG.
4. Update `frontend/index.html`'s default/placeholder for the contract
   address field (or just note the new address somewhere handy — the field
   is user-entered, so this is a convenience, not a requirement).

**Do not attempt to "migrate" by reusing the testnet contract address on
mainnet** — it will simply fail to resolve (or, worse, silently resolve to
an unrelated contract if that address happens to be used by something else
on mainnet).

## 5. Operational changes once live on mainnet

- **Real gas costs money.** Each of the 3 accounts needs a real KPG balance,
  acquired through an exchange or the project's official channels — there is
  no mainnet faucet. Budget for this before flipping the switch.
- **Private key hygiene matters more.** Testnet MetaMask accounts used during
  development should not be reused for mainnet if their private keys were
  ever pasted into chat, code, or screen-shared — treat mainnet accounts as
  a fresh start.
- **Mistakes are permanent and cost real money.** A wrong recipient address
  or a wrong amount sent via `sendCredits` cannot be undone (no admin/refund
  function was found in the ABI). Test the full flow thoroughly on testnet
  first, and consider a small first transaction on mainnet before routine use.
- **Update the deployed frontend.** If `frontend/index.html` is redeployed
  (e.g. to Netlify) with the mainnet config baked in, remember it must still
  be served over `http(s)` — see `HANDOVER.md` item 1, the `file://` issue
  applies regardless of which network is configured.

## 6. Pre-migration checklist

- [ ] Mainnet network parameters re-confirmed against `docs.mandalachain.io`
      (endpoints can change between when this doc was written and migration
      time)
- [ ] Contract source code recovered and reviewed
- [ ] Contract redeployed to Mandala Mainnet with correct real-world account
      addresses
- [ ] `frontend/index.html` network config updated (§3) and tested end-to-end
      on a **test** mainnet transaction first
- [ ] All 3 accounts funded with real KPG for gas
- [ ] Mainnet contract address documented for the team
- [ ] Fresh MetaMask accounts used if testnet keys were ever exposed

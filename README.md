# Smart contract

## ⚠️ Source code not available

At the time of this handover, the Solidity source code (`.sol`) for the
deployed contract could not be located — only its **ABI** (the public
interface the frontend calls) was recoverable, by reading the calls made in
`frontend/index.html`. This is listed as the top-priority open item in
`../docs/HANDOVER.md`.

`ABI.json` in this folder is that reconstructed interface — enough to *call*
the contract, but not to see, audit, redeploy, or modify its internal logic
(access control, overflow handling, ownership, etc.).

## What we know from the ABI alone

```solidity
function getAllAccounts() view returns (address[3])
function getAllBalances() view returns (uint256[3])
function nameOf(address) view returns (string)
function sendCredits(address to, uint256 amount, string reason)
event CreditsSent(address indexed from, address indexed to, uint256 amount, string reason)
```

- Exactly **3 hardcoded accounts** (fixed-size `address[3]` return type — not a
  dynamic array), each with a human-readable name and an integer balance.
- `sendCredits` takes no `from` parameter — the sender is implicitly
  `msg.sender`, meaning the connected wallet's account.
- No ERC-20 interface (`transfer`, `approve`, `balanceOf`, `decimals`, ...) —
  this is a bespoke ledger, not a standard token (see `../docs/SYSTEM_DESIGN.md`).
- No visible way to add/remove accounts or change names from outside the
  contract — likely set once in the constructor.

## Recommended next step

Whoever deployed the contract (or has access to the deployment transaction on
`https://explorer.testnet.mandalachain.io`) should retrieve the original
source and either:
1. Verify it on the block explorer (if supported), which publishes the source
   permanently and publicly, or
2. Add the `.sol` file directly into this folder.

Until then, treat the contract as a black box: its authorization rules (can
anyone call `sendCredits` for any `to`, or only for accounts they own?) and
edge-case behavior (what happens if `amount` exceeds the sender's balance?)
are unverified.

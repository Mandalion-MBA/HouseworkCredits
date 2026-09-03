# Handover: Fixed Issues, Known Bugs & Open Tasks

This document compiles everything found while getting the app working, so the
next developer doesn't have to rediscover it.

## 1. Issues fixed during development

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | Clicking "Connect" did nothing — no error, no popup | Page opened via `file://` (double-clicking the HTML file). MetaMask's content-script ↔ page-script bridge uses `postMessage`, which breaks when the page's origin is the opaque `null` origin that `file://` pages get. Requests silently hang forever. | Documented that the app **must** be served over `http(s)` (a local static server or a real host), never opened as a local file. |
| 2 | Repeated clicks on Connect/Send piled up multiple pending MetaMask confirmation requests (seen as "1 of 7" in the MetaMask popup) | Buttons weren't disabled while a request was in flight, so an impatient re-click queued a second, third... request instead of reusing the first | Both buttons are now `disabled` for the duration of their async flow (`try/finally`) |
| 3 | Connecting required manually pre-configuring "Mandala Testnet" in MetaMask, with no way to do it from the app | Code only *checked* the current chain ID and told the user to switch manually — the `MANDALA_TESTNET` network config object existed but was never used | Added `ensureNetwork()`: calls `wallet_switchEthereumChain`, and falls back to `wallet_addEthereumChain` automatically if MetaMask doesn't know the network yet (error code `4902`) |
| 4 | "Transaction history" failed to load: `could not coalesce error ... "query range is too big"` | `contract.queryFilter(filter, 0, "latest")` asked the RPC for *all* blocks in one `eth_getLogs` call; the public RPC node caps how many blocks a single call may span | Rewrote history loading to query in 2000-block chunks in parallel, with automatic recursive halving of a chunk if it's still rejected as "too big" |
| 5 | Deployed (Netlify) version only showed a plain one-line log per transfer, missing Date/Time/From/To/Amount/Reason | The Netlify deploy was running an older/simpler build than the one being iterated on locally | Replaced with a proper table sourced from `CreditsSent` event logs (also added a clickable **Tx hash** column linking to the block explorer) |
| 6 | Netlify site returned "Page not found" after redeploying | The uploaded file wasn't named exactly `index.html` (static hosts serve `index.html` at `/` by default) | Renamed the file to `index.html` before dragging it onto Netlify |
| 7 | Sending credits from the "Dad" account failed with a red "Frais de réseau" warning in MetaMask | That account had **0 KPGT** (the native gas token) — unrelated to its credit balance | Sent a small amount of KPGT from the funded "Mom" account to "Dad" to cover gas |

## 2. Known limitations / open tasks

Roughly ordered by priority.

### 🔴 High priority

- **Smart contract source code is missing.** Only the ABI (as called by the
  frontend) is documented in `contract/ABI.json`. The actual Solidity source,
  its access-control rules, and edge-case behavior (e.g. sending more credits
  than the sender's balance, negative amounts, re-entrancy) are unverified.
  **Action:** locate the original `.sol` file or the deployer, or check
  whether the contract is verified on the block explorer.
- **No `accountsChanged` / `chainChanged` event listeners.** If the user
  switches accounts or networks inside MetaMask *while the page is already
  connected*, the app keeps using the old `signer`/`provider` silently instead
  of picking up the change — the user currently has to manually reload the
  page after switching. **Action:** add
  `window.ethereum.on('accountsChanged', ...)` /
  `on('chainChanged', ...)` handlers that re-run `connect()` (or at least
  prompt the user to reload).

### 🟠 Medium priority

- **Gas funding is entirely manual.** Each of the 3 hardcoded accounts needs
  its own KPGT balance, topped up by hand from whichever account already has
  funds. There's no in-app balance check before attempting a send, and no
  faucet integration. **Action:** either surface the sender's KPGT balance
  next to the Send button and warn before submitting if it looks
  insufficient, or integrate a testnet faucet if Mandala Testnet has one.
- **Fixed set of exactly 3 accounts**, hardcoded in the contract
  (`address[3]`). Adding a 4th family member requires redeploying the
  contract; the frontend has no "add account" concept at all.
- **No persistence of the contract address.** The user must re-paste the
  deployed contract address every time the page loads. **Action:** cache it
  in `localStorage` (safe here since it's public information, not a secret).

### 🟡 Lower priority / polish

- Error messages surfaced to the user are sometimes still fairly raw
  JSON-RPC text (improved for the cases found during testing, but any new
  RPC error shape will still show through mostly unformatted).
- No input validation on the "Amount" and "Reason" fields (e.g. no max
  length on reason, no explicit handling of `amount <= 0`).
- No automated tests of any kind (unit, integration, or e2e).
- No CI/CD — deployment is a manual drag-and-drop onto Netlify.
- Single-file architecture (no framework, no bundler) is fine at this scale
  but will get harder to maintain if the feature set grows — see
  `docs/TECH_STACK.md` for trade-offs.

## 3. Useful reference values

| Item | Value |
|---|---|
| Chain ID | `20011` (`0x4E2B`) |
| Chain name | Mandala Testnet |
| Native currency | KPGT |
| RPC URL | `https://rpc1-testnet.mandalachain.io` |
| Block explorer | `https://explorer.testnet.mandalachain.io` |
| Live deployment | `https://spontaneous-muffin-d0f871.netlify.app/` |

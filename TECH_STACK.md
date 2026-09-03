# Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Markup / styling | HTML5, plain CSS3 (CSS custom properties) | No CSS framework, no build step, no bundler |
| Frontend logic | Vanilla JavaScript (ES2020+, `async`/`await`) | No framework (no React/Vue/etc.) — a single inline `<script>` block |
| Web3 library | [ethers.js v6.13.4](https://docs.ethers.org/v6/) | Loaded from a CDN (`cdnjs.cloudflare.com`), not bundled/npm-installed |
| Wallet / signer | [MetaMask](https://metamask.io/) browser extension | Accessed via the injected `window.ethereum` provider (EIP-1193). Also uses `wallet_switchEthereumChain` (EIP-3326) and `wallet_addEthereumChain` (EIP-3085) |
| Blockchain | Mandala Testnet (custom EVM-compatible chain) | Chain ID `20011` (`0x4E2B`); native currency `KPGT`; RPC: `https://rpc1-testnet.mandalachain.io` |
| Smart contract language | Solidity (version unknown) | ⚠️ Source code (`.sol`) was not available at handover time — only the ABI reconstructed from the frontend's calls. See `docs/HANDOVER.md` |
| Off-chain database | **None** | All state lives on-chain; see `docs/SYSTEM_DESIGN.md` §4 |
| Hosting | [Netlify](https://www.netlify.com/) | Manual drag-and-drop deploy of a single static file (must be named `index.html`) |
| Block explorer (external) | Mandala Testnet explorer (`explorer.testnet.mandalachain.io`) | Third-party tool, used only for manual verification / linked to from the UI |

## Why no framework / no build step?

The whole app is one static `index.html` file with inline `<style>` and
`<script>` — no `npm install`, no bundler, no transpilation. This keeps
deployment trivial (drag one file onto a static host) but has trade-offs worth
knowing for the next developer:

- No component reuse, no state management library — all DOM updates are manual
  (`element.innerHTML = ...`).
- No TypeScript — no compile-time type checking of contract calls or ABI
  shapes.
- No automated tests, no CI/CD pipeline.
- No package manager — the ethers.js version is pinned only by the CDN URL in
  the `<script src>` tag; upgrading it means editing that URL by hand.

These are reasonable trade-offs for a small family/demo project, but should be
reconsidered if the project grows (see `docs/HANDOVER.md` for suggested next
steps).

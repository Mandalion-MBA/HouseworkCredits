# Housework Credits

A tiny web3 dApp that turns household chores into an on-chain "credits" ledger. Three
family accounts (Mom, Dad, Kid) can send each other credits for chores completed
("Tidy bathroom", "Did the dishes", ...), tracked entirely on a custom EVM testnet
called **Mandala Testnet**.

Live deployment: https://spontaneous-muffin-d0f871.netlify.app/

## Handover documentation

This repository was prepared for handover. Start here:

| Doc | Contents |
|---|---|
| [`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md) | Architecture diagram, components, on-chain data model (no off-chain DB) |
| [`docs/TECH_STACK.md`](docs/TECH_STACK.md) | Languages, frameworks, libraries, hosting |
| [`docs/USER_FLOW.md`](docs/USER_FLOW.md) | Flowchart of the app journey + sequence diagram of a credit transfer |
| [`docs/HANDOVER.md`](docs/HANDOVER.md) | What was fixed, what's still open, known bugs, missing pieces |
| [`docs/MAINNET_MIGRATION.md`](docs/MAINNET_MIGRATION.md) | How to move the app from Mandala Testnet to Mandala Mainnet |

## Repository layout
housework-credits/
├── README.md ← you are here
├── docs/
│ ├── SYSTEM_DESIGN.md
│ ├── TECH_STACK.md
│ ├── USER_FLOW.md
│ └── HANDOVER.md
├── frontend/
│ └── index.html ← the entire app (HTML + CSS + JS, single file)
└── contract/
└── ABI.json ← contract interface as used by the frontend
(⚠ .sol source not available — see HANDOVER.md)
Quick start (running it yourself)
Deploy (or obtain the address of) the "Housework Credits" smart contract on
Mandala Testnet.
Serve frontend/index.html over http(s), not file:// (MetaMask's
internal messaging breaks on file:// origins — see docs/HANDOVER.md).
Locally: any static server, e.g. python -m http.server 8000.
Or deploy the file as index.html to a static host (Netlify, GitHub
Pages, Vercel, ...).
Open the page, paste the deployed contract address, click Connect wallet
& load (requires the MetaMask browser extension).
Approve the connection and, if prompted, let the app switch/add the
Mandala Testnet network in MetaMask.
Pick a recipient, an amount, a reason, and click Send.
Each of the three wallet accounts needs its own small balance of KPGT
(the testnet's native gas currency) to pay transaction fees — KPGT is
unrelated to the "credits" themselves. See docs/SYSTEM_DESIGN.md for the
distinction.

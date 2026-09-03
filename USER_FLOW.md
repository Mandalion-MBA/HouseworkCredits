# User Flow

## 1. Overall journey (flowchart)

```mermaid
flowchart TD
    Start(["Open the app"]) --> Paste["Paste the deployed<br/>contract address"]
    Paste --> Connect["Click 'Connect wallet & load'"]
    Connect --> HasMM{"MetaMask<br/>installed?"}
    HasMM -- No --> ErrMM["Show error:<br/>'MetaMask not found'"]
    HasMM -- Yes --> Approve["MetaMask popup:<br/>approve connection"]
    Approve --> NetCheck{"Already on<br/>Mandala Testnet?"}
    NetCheck -- No --> SwitchNet["Auto wallet_switchEthereumChain<br/>(or wallet_addEthereumChain<br/>if network unknown to MetaMask)"]
    SwitchNet --> Load
    NetCheck -- Yes --> Load["Load accounts, names,<br/>balances, history from contract"]
    Load --> Ready(["Dashboard ready:<br/>3 account cards + send form + history table"])
    Ready --> Pick["Pick recipient, amount, reason"]
    Pick --> Send["Click 'Send'"]
    Send --> Confirm["MetaMask popup:<br/>confirm transaction"]
    Confirm --> HasGas{"Sender account has<br/>enough KPGT for gas?"}
    HasGas -- No --> ErrGas["MetaMask shows a<br/>network-fee warning;<br/>transaction can't be confirmed"]
    HasGas -- Yes --> Wait["Wait for on-chain confirmation"]
    Wait --> Refresh["Balances + history<br/>refresh automatically"]
    Refresh --> Ready
```

## 2. Sequence diagram — sending credits

This is the core action of the app. It involves four actors: the person, the
page's JavaScript, the MetaMask extension, and the blockchain (RPC + contract).

```mermaid
sequenceDiagram
    actor User
    participant Page as "Frontend (index.html)"
    participant MM as MetaMask
    participant Chain as "Mandala Testnet<br/>(RPC + contract)"

    User->>Page: Fill in To / Amount / Reason, click "Send"
    Page->>Page: Disable Send button (prevents duplicate requests)
    Page->>MM: contract.sendCredits(to, amount, reason)
    MM-->>User: Show confirmation popup<br/>(network, fee estimate, contract address)
    User->>MM: Click "Confirm"
    MM->>Chain: Signed transaction (eth_sendTransaction)
    Chain-->>MM: Transaction hash (pending)
    MM-->>Page: tx object (hash available immediately)
    Page->>Page: status = "Transaction sent,<br/>waiting for confirmation..."
    Chain->>Chain: Transaction mined into a block
    Page->>Chain: tx.wait() polls for the receipt
    Chain-->>Page: Receipt (success/failure)
    alt Success
        Page->>Chain: getAllBalances(), CreditsSent events
        Chain-->>Page: Updated balances + history
        Page-->>User: Show "Sent! Tx: 0x..." + refreshed table
    else Reverted / error
        Page-->>User: Show "Error: ..." message
    end
    Page->>Page: Re-enable Send button
```

## 3. Notes for the next developer

- **Every wallet approval is a real, separate user action.** There are two
  distinct MetaMask popups in a full "connect + send" cycle: one to approve
  the site connection (`eth_requestAccounts`), one to approve each
  transaction. Neither can be skipped or auto-approved by the frontend.
- **Nothing happens silently.** If a popup doesn't visibly appear, it's
  usually still pending — check the MetaMask extension icon for a badge/dot.
  This was the single most common source of confusion during testing (see
  `docs/HANDOVER.md`).
- **The account currently active in MetaMask is always the sender.** The "To"
  dropdown only controls the recipient; there is no way to pick a different
  sender from the page itself — the user must switch accounts inside MetaMask
  and reload the page.

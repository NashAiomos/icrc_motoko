# ICRC-1 & ICRC-2 Motoko Implementation

English | [Français](./docs/README.fr.md) | [简体中文](./docs/README.zh.md) | [日本語](./docs/README.jp.md) | [español](./docs/README.es.md) 

This repository contains the implementation of the ICRC token standard.

The `main` branch is the primary branch that includes all features and adds the ability to freeze specific accounts on top of ICRC-2.

The `ICRC-2` branch is the standard implementation of ICRC-2.

The `ICRC-1` branch contains the standard implementation of ICRC-1.

<br>

## Local Test Deployment

To get started, ensure you have **Node.js**, **npm**, **dfx**, and **mops** installed on your system.

### Install [dfx](https://internetcomputer.org/docs/building-apps/getting-started/install) (Linux or macOS):
```sh
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

### Install [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install):
`dfx extension install mops` or `npm i -g ic-mops`

### Run the Project (replace parameters as needed):
```sh
git clone https://github.com/NashAiomos/icrc_motoko
cd icrc_motoko
mops install
dfx start --background --clean

dfx deploy icrc --argument '( record {                    
    name = "aaa";
    symbol = "aaa";
    decimals = 8;
    fee = 1_000;
    max_supply = 100_000_000_000_000;
    initial_balances = vec {
        record {
            record {
                owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
                subaccount = null;
            };
            100_000_000_000_000
        };
    };
    min_burn_amount = 10_000;
    minting_account = opt record {
        owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
        subaccount = null;
    };
    advanced_settings = null;
})'
```

### Additional Configuration:
advanced_settings:
```sh
type AdvancedSettings = {
    burned_tokens : Balance;
    transaction_window : Timestamp;
    permitted_drift : Timestamp;
}
```

<br>

## Project Architecture

The project implements the **ICRC-2 token standard** using the **Motoko** programming language, with the primary logic located in the `src` folder. It consists of two main canisters:

### 1. Token Canister
- **Purpose**: Provides all core token functionalities and state management per the ICRC-2 standard, along with integrated transaction archiving logic.
- **Definition**: Defined in `Token.mo`.

### 2. Archive Canister
- **Purpose**: Dedicated to storing and querying archived transaction records, expanding the storage capacity of the main ledger. It supports automatic scaling, with each canister capable of storing **375 GiB** of transactions.
- **Definition**: Defined in `Archive.mo`.

Additionally, the project includes auxiliary modules for account encoding/decoding, transaction processing, type definitions, and utility functions. Test code is located in the `tests` folder and requires separate deployment.

<br>

## Token Canister

### Implementation File: `Token.mo`

The Token Canister provides the **ICRC-2 token standard interfaces**, including querying token details (name, symbol, decimals, balance, total supply, fees, supported standards) and implementing token state management, transfers, minting, burning, and other business logic.

#### Archiving Logic:
- When the number of transactions in the main ledger exceeds a set limit (e.g., 2,000 transactions), the archiving logic is triggered to transfer older transactions to the **Archive Canister**.
- The overall logic is integrated in `lib.mo`, which calls `Transfer.mo` to handle transaction validation and requests. Final transactions are written to a local transaction buffer, and when the buffer exceeds the maximum transaction limit, archiving is initiated (see `update_canister` and `append_transactions`).

#### Main Methods:
- **`icrc1_name()`**: Returns the token's name.
- **`icrc1_symbol()`**: Returns the token's symbol.
- **`icrc1_decimals()`**: Returns the number of decimal places for the token.
- **`icrc1_fee()`**: Returns the fee per transfer.
- **`icrc1_metadata()`**: Returns the token's metadata.
- **`icrc1_total_supply()`**: Returns the current circulating supply of the token.
- **`icrc1_minting_account()`**: Returns the account authorized to mint/burn tokens.
- **`icrc1_balance_of(account)`**: Queries the balance of a specified account.
- **`icrc1_transfer(args)`**: Executes a transfer operation (internally determines if it’s a regular transfer, minting, or burning based on sender/receiver).
- **`icrc2_approve()`**: Authorizes an account to transfer tokens on behalf of the authorizer.
- **`icrc2_transfer_from()`**: Allows an authorized account to perform token transfers.
- **`icrc2_allowance()`**: Queries the number of tokens an account (owner) has authorized another account (spender) to transfer.
- **`mint(args)`** and **`burn(args)`**: Helper functions for minting and burning tokens, respectively.
- **`get_transaction(tx_index)`** and **`get_transactions(req)`**: Provide queries for single or batch transactions; redirects to the Archive Canister when the transaction limit is exceeded.
- **`deposit_cycles()`**: Allows users to deposit Cycles into the canister.
- **`freeze_account(account)`**: Freezes the specified account, preventing it from performing any transactions.
- **`unfreeze_account(account)`**: Unfreezes the specified account, restoring its ability to perform transactions.
- **`is_account_frozen(account)`**: Checks if a specific account is currently frozen.

<br>

## Archive Canister

### Implementation File: `Archive.mo`

The Archive Canister provides transaction archiving storage for the Token Canister. When the main canister’s transaction storage exceeds a certain capacity, the `append_transactions` method is called to archive older transactions, reducing storage pressure on the main ledger.

#### Storage Mechanism:
- Uses **stable memory** (via `ExperimentalStableMemory`) and a **stable trie map** (`StableTrieMap`) to manage data, organized in fixed-size buckets for archiving.

#### Main Methods:
- **`append_transactions(txs)`**: Verifies caller permissions (only the Ledger canister can call it) and stores transaction records in fixed-size buckets (1,000 transactions each) in the archive storage.
- **`total_transactions()`**: Returns the total number of transactions in the archive.
- **`get_transaction(tx_index)`**: Queries a single transaction by its index.
- **`get_transactions(req)`**: Queries transaction records within a requested range, supporting pagination.
- **`remaining_capacity()`**: Returns the remaining storage capacity before the archive canister is full.
- **`deposit_cycles()`**: Receives and deposits Cycles.

<br>

## Auxiliary Modules

### Type Definitions (Types)
- **File**: `src/ICRC/Types.mo`
- **Purpose**: Defines types such as `Account`, `TransferArgs`, `Transaction`, `TransferResult`, and the overall token data structure `TokenData`. These form the foundational data structures and interface protocols of the system.

### Account Operations (Account)
- **File**: `src/ICRC/Account.mo`
- **Purpose**: Provides encoding and decoding functions for ICRC-1 accounts, converting between text representation and internal binary format per the ICRC-1 standard.

### Transaction Processing (Transfer)
- **File**: `src/ICRC/Transfer.mo`
- **Purpose**: Implements transaction request validation logic, checking memo length, fees, account balances, creation time (expired or future), and duplicate transactions. It returns validation results and assists in determining whether the transaction is a transfer, minting, or burning.

### Utility Functions (Utils)
- **File**: `src/ICRC/Utils.mo`
- **Purpose**: Includes functions for initializing metadata, generating supported standards, creating default subaccounts, hash functions, and converting transaction requests to final transaction formats. It serves as a utility module called by `lib.mo`.

### Main Logic (lib)
- **File**: `src/ICRC/lib.mo`
- **Purpose**: Combines various modules to provide all external ICRC-2 Token interfaces. It calls `Utils`, `Transfer`, and `Account` to handle token initialization, state management, transaction operations, archiving logic, and balance queries.

### Freeze Logic (Freeze)
- **File**: `src/ICRC/Freeze.mo`
- **Purpose**: The freeze functionality allows administrators to restrict specific accounts from performing any token operations (e.g., transfers, approvals).Frozen accounts are stored in a dedicated data structure for quick lookup.The `freeze_account` and `unfreeze_account` methods can only be called by authorized accounts (e.g., the minting account or a designated admin account).
Before processing any transaction, the system checks if the involved accounts are frozen. If an account is frozen, the transaction is rejected with an appropriate error message.

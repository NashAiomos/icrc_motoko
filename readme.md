# ICRC-1 Motoko Implementation
This repo contains the implementation of the 
[ICRC-1](https://github.com/dfinity/ICRC-1) token standard. 

## Getting Started

- Launch the basic token with all the standard functions for ICRC-1
  Install the [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install) package manager 

```motoko
    git clone https://github.com/NashAiomos/icrc1_motoko
    cd icrc1_motoko
    dfx extension install mops
    mops install
    dfx start --background --clean

    dfx deploy icrc1 --argument '( record {                    
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
        minting_account = record {
            owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
        };
        advanced_settings = null;
    })'
```


```
advanced_settings:

type AdvancedSettings = { burned_tokens : Balance; transaction_window : Timestamp; permitted_drift : Timestamp }
```

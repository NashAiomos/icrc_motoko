## 启动

```sh
cd code/icrc_motoko
dfx start --background --clean
dfx deploy icrc --argument '( record {
    name = "aaa";
    symbol = "aaa";
    decimals = 8;
    fee = 1_000;
    max_supply = 100_000_000_00000000;
    initial_balances = vec {
        record {
            record {
                owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
                subaccount = null;
            };
            5_000_00000000
        };
    };
    min_burn_amount = 10_000;
    minting_account = null;
    advanced_settings = null;
})'
```

如果没有设置 minting_account ，系统会自动设置一个默认值。一般这个默认值会是部署 canister 的身份（principal）或者 canister 的控制者。

从 minting_account 发出的币视为铸造，发给  minting_account 的币视为燃烧。

<br>

## 测试

### 冻结账户
```sh
dfx canister call icrc freeze_account '(principal "elpzo-dtg6m-altd3-gdb27-koyhb-wl42f-yjowp-3vnus-bbxvt-uldr3-4ae")'
```
输出成功：
```
2025-04-10 09:13:44.685071026 UTC: [Canister bkyz2-fmaaa-aaaaa-qaaaq-cai] [Freeze] Account: elpzo-dtg6m-altd3-gdb27-koyhb-wl42f-yjowp-3vnus-bbxvt-uldr3-4ae
(variant { ok })
```

<br>

### 解冻账户
```sh
dfx canister call icrc unfreeze_account '(principal "elpzo-dtg6m-altd3-gdb27-koyhb-wl42f-yjowp-3vnus-bbxvt-uldr3-4ae")'
```
输出成功：
```
2025-04-10 09:15:27.500734135 UTC: [Canister bkyz2-fmaaa-aaaaa-qaaaq-cai] [Unfreeze] Account: elpzo-dtg6m-altd3-gdb27-koyhb-wl42f-yjowp-3vnus-bbxvt-uldr3-4ae
(variant { ok })
```

<br>

### 发送 10 个 Token 给 sckqo 
```sh
dfx canister call icrc icrc1_transfer "(record {
  to = record {
    owner = principal \"sckqo-e2vyl-4rqqu-5g4wf-pqskh-iynjm-46ixm-awluw-ucnqa-4sl6j-mqe\";
  };
  amount = 10_00000000;
})"
```

<br>

### Approve 批准
```sh
dfx canister call icrc icrc2_approve '(record {
  fee = opt 1000;
  memo = null;
  from_subaccount = null;
  created_at_time = null;
  amount = 1_00000000;
  expected_allowance = null;
  expires_at = null;
  spender = record {
    owner = principal "sckqo-e2vyl-4rqqu-5g4wf-pqskh-iynjm-46ixm-awluw-ucnqa-4sl6j-mqe";
    subaccount = null;
  }
})'
```
输出成功：
```
2025-04-11 13:19:43.168597150 UTC: [Canister bkyz2-fmaaa-aaaaa-qaaaq-cai] Approval successful: hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe approved {owner = sckqo-e2vyl-4rqqu-5g4wf-pqskh-iynjm-46ixm-awluw-ucnqa-4sl6j-mqe; subaccount = null} for 100000000 tokens.
(variant { Ok = 100_000_000 : nat })
```

<br>

### Allowance 查询授权
```sh
dfx canister call icrc icrc2_allowance '(
  record {
    owner = record {
      owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
      subaccount = null
    };
    spender = record {
      owner = principal "sckqo-e2vyl-4rqqu-5g4wf-pqskh-iynjm-46ixm-awluw-ucnqa-4sl6j-mqe";
      subaccount = null
    }
  }
)'
```
输出成功：
```
(record { allowance = 100_000_000 : nat; expires_at = null })
```

<br>


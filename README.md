# ICRC Motoko Implementation
This repo contains the implementation of the ICRC token standard. 

## Local Test Deployment
First, we have to have nodejs, npm, dfx and [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install).

安装[dfx](https://internetcomputer.org/docs/building-apps/getting-started/install)：（Linux or macOS）
```
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

安装 mops ：
```
dfx extension install mops
```

运行项目：(替换其中的参数)
```motoko
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

额外的配置：
```
advanced_settings:

type AdvancedSettings = { burned_tokens : Balance; transaction_window : Timestamp; permitted_drift : Timestamp }
```

## 项目整体架构

项目实现了 ICRC-2 代币标准，采用 Motoko 语言开发，主要逻辑在 src 文件夹中。

由两个 canister 组成， Token 和 Archive ：

* Token Canister

  提供 ICRC-2 标准的所有核心代币功能和状态管理，并集成了交易存档逻辑。由 Token.mo 定义。

* Archive Canister

  专门用于存储和查询存档的交易记录，用以扩展主账本存储容量。支持自动扩容，每个 canister 储存 375GiB 交易。由 Archive.mo 定义。

还有其他辅助模块，账户编码/解码、交易处理、各类类型定义和工具函数。

测试代码在 tests 文件夹里。（需要单独部署）

## Token Canister
实现文件： Token.mo

提供 ICRC-2 代币标准接口，包括查询代币名称、符号、小数位、余额、总供应量、手续费、支持标准等。
实现代币的状态管理、转账、铸币、销币等业务逻辑。

集成存档逻辑：
当主账本中交易数量超过设定上限（如 2000 笔时），调用存档逻辑将老交易转存到 Archive Canister 。

在 lib.mo 中集成了 Token 的整体逻辑，并调用 Transfer.mo 处理交易验证和请求，将最终交易写入本地的交易缓冲区。缓冲区超出最大交易数量后，会触发存档逻辑（见 update_canister 和 append_transactions）。

主要方法：

icrc1_name()：返回代币的名称。

icrc1_symbol()：返回代币的符号。

icrc1_decimals()：返回代币的小数位数。

icrc1_fee()：返回每次转账的手续费。

icrc1_metadata()：返回代币的元数据。

icrc1_total_supply()：返回当前流通中的代币供应量。

icrc1_minting_account()：返回允许铸币/销币的账户。

icrc1_balance_of(account)：查询指定账户的余额。

icrc1_transfer(args)：执行转账操作（内部根据发送者/接收者判断是普通转账、铸币或销币）。

mint(args) 和 burn(args)：辅助函数分别用于铸币和销币操作。

get_transaction(tx_index) 与 get_transactions(req)：提供对单笔或批量交易的查询，当交易数量超过上限时转而查询 Archive Canister。

deposit_cycles()：允许用户向 canister 存入周期（cycles）。

## Archive Canister
实现文件： Archive.mo

为 Token Canister 提供交易存档存储。当主 canister 中存储的交易超出一定容量时，调用 append_transactions 方法将老交易存档保存，从而降低主账本存储压力。

存档模块内部使用稳定内存（通过 ExperimentalStableMemory）以及稳定树映射（StableTrieMap）来管理存储数据，并以固定 bucket 形式进行存档操作。

主要方法：

append_transactions(txs)：验证调用权限（仅 Ledger canister 可调用），按照每个 bucket（固定大小 1000 笔）存储交易记录到存档存储中。

total_transactions()：返回存档中的交易总数。

get_transaction(tx_index)：根据交易索引在存档中查询单笔交易。

get_transactions(req)：按请求范围查询存档中的交易记录，支持分页式查询。

remaining_capacity()：返回存档 canister 在存满之前剩余的存储容量。

deposit_cycles()：接收并存入周期（Cycles）。


## 辅助模块
类型定义（Types）

文件：src/ICRC/Types.mo

定义了各种类型，比如 Account、TransferArgs、Transaction、TransferResult、以及 Token 的整体数据结构 TokenData。这些类型构成整个系统的基本数据结构和接口协议。

<br>

账户操作（Account）

文件：src/ICRC/Account.mo

提供了 ICRC-1 账户的编码与解码功能，依据 ICRC-1 标准实现账户地址的文本表示和内部二进制格式的转换。

<br>

交易处理（Transfer）

文件：src/ICRC/Transfer.mo

实现了交易请求的验证逻辑，包括检查备注长度、手续费、账户余额、创建时间是否过期或未来、以及重复交易检查等。该模块返回验证结果，并辅助决定交易是转账、铸币或销币。

<br>

工具函数（Utils）

文件：src/ICRC/Utils.mo

包含了元数据的初始化、支持标准的生成、账户的默认子账户、哈希函数、以及从交易请求到最终交易的格式转换等功能。也是 lib.mo 调用的工具模块。

<br>

主逻辑（lib）

文件：src/ICRC/lib.mo

将各个部分组合在一起，提供了对外 ICRC-2 Token 的所有接口。它调用 Utils、Transfer、Account 等模块，实现了代币的初始化、状态管理、交易操作、存档逻辑以及余额查询等功能。

## 测试模块
测试代码分布在 ICRC1 下，主要包括：

ICRC1.ActorTest.mo

测试包括 Token 的初始化、查询 name、symbol、decimals、fee 等基本接口，以及 mint、burn、transfer 等交易方法，验证账户余额更新、交易存档等功能。

<br>

Account.Test.mo

专门测试账户编码、解码功能，确保账户文本表示与内部二进制格式的正确转换。

<br>

Archive.ActorTest.mo

专门测试 Archive Canister 的存档功能，包括追加交易、批量查询交易和单笔查询交易等。

<br>

ActorTest.mo

测试入口文件，负责依次运行上述测试模块，并输出整体测试结果。

<br>

测试工具（ActorSpec）
文件：tests/utils/ActorSpec.mo
提供简单的测试描述、断言和分组运行功能，用于帮助编写和运行测试用例。

<br>

makefile：提供了测试、文档生成、actor-test 等命令，方便本地构建和执行测试。

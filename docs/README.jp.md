# ICRC-1 & ICRC-2 Motoko 実装

リポジトリには、ICRC-1 および ICRC-2 標準の実装が含まれています。

`main` ブランチは、すべての機能を含む主要なブランチであり、ICRC-2 に特定のアカウントを凍結する機能を追加します。

`ICRC-2` ブランチは、標準の ICRC-2 実装です。

`ICRC-1` ブランチは、標準の ICRC-1 実装です。

<br>

## ローカルテスト
まず、Node.js、npm、dfx、および [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install) を用意する必要があります。

[dfx のインストール](https://internetcomputer.org/docs/building-apps/getting-started/install)：（Linux または macOS）
```sh
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

mops のインストール：
`dfx extension install mops` または `npm i -g ic-mops`

プロジェクトの実行：（パラメータを適宜置き換えてください）
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

追加設定：

advanced_settings:

```sh
type AdvancedSettings = {
    burned_tokens : Balance;
    transaction_window : Timestamp;
    permitted_drift : Timestamp;
}
```

<br>

## プロジェクト全体構成

本プロジェクトは、ICRC-2 トークン標準を実装し、Motoko 言語で開発されています。主要なロジックは `src` フォルダ内にあります。

2 つの canister で構成されています：Token と Archive ：

* **Token Canister**

  ICRC-2 標準のすべてのコアトークン機能と状態管理を提供し、トランザクションのアーカイブロジックを統合します。実装は `Token.mo` で定義されています。

* **Archive Canister**

  アーカイブされたトランザクション記録を保存および検索する専用の canister で、メインレジャーのストレージ容量を拡張します。自動拡張をサポートしており、各 canister は 375GiB のトランザクションを保存できます。実装は `Archive.mo` で定義されています。

その他、アカウントのエンコード/デコード、トランザクション処理、各種型定義、ユーティリティ関数などの補助モジュールがあります。

テストコードは `tests` フォルダにあります。（個別にデプロイが必要）

<br>

## Token Canister
実装ファイル：`Token.mo`

ICRC-2 トークン標準のインターフェースを提供し、トークン名、シンボル、小数点以下の桁数、残高、総供給量、手数料、サポートする標準などを取得できます。  
また、トークンの状態管理、送金、鋳造（mint）、焼却（burn）などのビジネスロジックを実装しています。

### アーカイブロジックの統合
メインレジャー内のトランザクション数が設定上限（例：2000 件）を超えると、アーカイブロジックが呼び出され、古いトランザクションが `Archive Canister` に移動されます。

`lib.mo` において、Token の全体ロジックが統合され、`Transfer.mo` を呼び出してトランザクションの検証およびリクエスト処理を行い、最終的なトランザクションをローカルのトランザクションバッファに書き込みます。バッファが最大トランザクション数を超えると、アーカイブロジックがトリガーされます（`update_canister` および `append_transactions` を参照）。

### 主なメソッド

- **icrc1_name()**：トークンの名称を返します。
- **icrc1_symbol()**：トークンのシンボルを返します。
- **icrc1_decimals()**：トークンの小数点以下の桁数を返します。
- **icrc1_fee()**：各送金時の手数料を返します。
- **icrc1_metadata()**：トークンのメタデータを返します。
- **icrc1_total_supply()**：現在流通中のトークン供給量を返します。
- **icrc1_minting_account()**：鋳造／焼却を許可されたアカウントを返します。
- **icrc1_balance_of(account)**：指定アカウントの残高を照会します。
- **icrc1_transfer(args)**：送金操作を実行します（内部で送信者／受信者に基づいて、通常の送金、鋳造または焼却を判断します）。

**icrc2_approve()**：あるアカウントが、他のアカウントの代理としてトークン転送を行えるように承認します。

**icrc2_transfer_from()**：承認を受けたアカウントがトークン転送を実行できるようにします。

**icrc2_allowance()**：あるアカウント（owner）が、別のアカウント（spender）に対して承認した転送可能なトークン数量を照会し、返します。

**mint(args)** と **burn(args)**：それぞれ鋳造と焼却操作を行う補助関数です。

**get_transaction(tx_index)** および **get_transactions(req)**：単一または複数のトランザクションを照会します。トランザクション数が上限を超える場合は、`Archive Canister` から照会します。

**deposit_cycles()**：ユーザーが canister に Cycles を入金できるようにします。

## Archive Canister
実装ファイル：`Archive.mo`

Token Canister に対してトランザクションのアーカイブストレージを提供します。メイン canister に保存されるトランザクションが一定容量を超えた場合、`append_transactions` メソッドを呼び出して古いトランザクションをアーカイブに保存し、メインレジャーのストレージ負荷を軽減します。

アーカイブモジュール内部では、安定メモリ（ExperimentalStableMemory）および安定ツリーマップ（StableTrieMap）を使用してストレージデータを管理し、固定サイズのバケット形式（1000 件単位）でアーカイブ操作を行います。

### 主なメソッド

- **append_transactions(txs)**：呼び出し権限を検証し（Ledger canister のみ呼び出し可能）、固定サイズのバケット（1000 件単位）ごとにトランザクション記録をアーカイブストレージに保存します。
- **total_transactions()**：アーカイブ内のトランザクション総数を返します。
- **get_transaction(tx_index)**：トランザクションインデックスに基づいて、アーカイブから単一のトランザクションを取得します。
- **get_transactions(req)**：要求された範囲でアーカイブ内のトランザクション記録を照会し、ページネーションに対応します。
- **remaining_capacity()**：アーカイブ canister が満杯になる前に残っているストレージ容量を返します。
- **deposit_cycles()**：Cycles を受け取り、保存します。

<br>

## 補助モジュール
### 型定義（Types）
ファイル：`src/ICRC/Types.mo`

`Account`、`TransferArgs`、`Transaction`、`TransferResult`、およびトークンの全体データ構造である `TokenData` など、さまざまな型を定義しています。これらの型はシステム全体の基本データ構造およびインターフェースプロトコルを構成します。

<br>

### アカウント操作（Account）
ファイル：`src/ICRC/Account.mo`

ICRC-1 アカウントのエンコードおよびデコード機能を提供し、ICRC-1 標準に基づいてアカウントアドレスのテキスト表現と内部のバイナリ形式との変換を実現します。

<br>

### トランザクション処理（Transfer）
ファイル：`src/ICRC/Transfer.mo`

トランザクションリクエストの検証ロジックを実装しています。検証内容には、備考の長さ、手数料、アカウント残高、作成時刻が期限切れまたは未来であるかのチェック、重複トランザクションの確認などが含まれます。このモジュールは検証結果を返し、トランザクションが送金、鋳造、または焼却のどれであるかを判断するのを補助します。

<br>

### ユーティリティ関数（Utils）
ファイル：`src/ICRC/Utils.mo`

メタデータの初期化、サポートする標準の生成、アカウントのデフォルトサブアカウント、ハッシュ関数、そしてトランザクションリクエストから最終トランザクションへのフォーマット変換などの機能を含んでいます。また、`lib.mo` で呼び出されるユーティリティモジュールでもあります。

<br>

### 主ロジック（lib）
ファイル：`src/ICRC/lib.mo`

各モジュールを統合し、外部に ICRC-2 トークンのすべてのインターフェースを提供します。`Utils`、`Transfer`、`Account` などのモジュールを呼び出し、トークンの初期化、状態管理、トランザクション操作、アーカイブロジック、残高照会などの機能を実装しています。

<br>

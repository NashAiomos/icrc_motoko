import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import EC "mo:base/ExperimentalCycles";
import Time "mo:base/Time";

import Itertools "mo:itertools/Iter";
import StableTrieMap "mo:StableTrieMap";

import Account "Account";
import T "Types";
import Utils "Utils";
import Transfer "Transfer";
import Archive "Canisters/Archive";
import Freeze "Freeze";

/// ICRC-1 类，包含在 ICP 上创建 ICRC-1 代币的所有函数
module {
    let { SB } = Utils;

    public type Account = T.Account;
    public type Subaccount = T.Subaccount;
    public type AccountBalances = T.AccountBalances;
    public type Timestamp = T.Timestamp;

    public type Transaction = T.Transaction;
    public type Balance = T.Balance;
    public type TransferArgs = T.TransferArgs;

    // ICRC-2 相关类型
    public type ApproveArgs = T.ApproveArgs;
    public type ApproveError = T.ApproveError;
    public type TransferFromArgs = T.TransferFromArgs;
    public type AllowanceArgs = T.AllowanceArgs;

    public type Mint = T.Mint;
    public type BurnArgs = T.BurnArgs;
    public type TransactionRequest = T.TransactionRequest;
    public type TransferError = T.TransferError;

    public type SupportedStandard = T.SupportedStandard;

    public type InitArgs = T.InitArgs;
    public type TokenInitArgs = T.TokenInitArgs;
    public type TokenData = T.TokenData;
    public type MetaDatum = T.MetaDatum;
    public type TxLog = T.TxLog;
    public type TxIndex = T.TxIndex;

    public type TokenInterface = T.TokenInterface;
    public type RosettaInterface = T.RosettaInterface;
    public type FullInterface = T.FullInterface;

    public type ArchiveInterface = T.ArchiveInterface;

    public type GetTransactionsRequest = T.GetTransactionsRequest;
    public type GetTransactionsResponse = T.GetTransactionsResponse;
    public type QueryArchiveFn = T.QueryArchiveFn;
    public type TransactionRange = T.TransactionRange;
    public type ArchivedTransaction = T.ArchivedTransaction;

    public type TransferResult = T.TransferResult;

    public let MAX_TRANSACTIONS_IN_LEDGER = 2000;
    public let MAX_TRANSACTION_BYTES : Nat64 = 196;
    public let MAX_TRANSACTIONS_PER_REQUEST = 5000;

    /// 初始化一个新 ICRC-1 代币
    public func init(args : T.InitArgs) : T.TokenData {
        let {
            name;
            symbol;
            decimals;
            fee;
            minting_account;
            max_supply;
            initial_balances;
            min_burn_amount;
            advanced_settings;
        } = args;

        var _burned_tokens = 0;
        var permitted_drift = 60_000_000_000;
        var transaction_window = 86_400_000_000_000;

        switch(advanced_settings){
            case(?options) {
                _burned_tokens := options.burned_tokens;
                permitted_drift := Nat64.toNat(options.permitted_drift);
                transaction_window := Nat64.toNat(options.transaction_window);
            };
            case(null) { };
        };

        if (not Account.validate(minting_account)) {
            Debug.trap("minting_account is invalid");
        };

        let accounts : T.AccountBalances = StableTrieMap.new();

        var _minted_tokens = _burned_tokens;

        for ((i, (account, balance)) in Itertools.enumerate(initial_balances.vals())) {

            if (not Account.validate(account)) {
                Debug.trap(
                    "Invalid Account: Account at index " # debug_show i # " is invalid in 'initial_balances'",
                );
            };

            let encoded_account = Account.encode(account);

            StableTrieMap.put(
                accounts,
                Blob.equal,
                Blob.hash,
                encoded_account,
                balance,
            );

            _minted_tokens += balance;
        };

        {
            name = name;
            symbol = symbol;
            decimals;
            var _fee = fee;
            max_supply;
            var _minted_tokens = _minted_tokens;
            var _burned_tokens = _burned_tokens;
            min_burn_amount;
            minting_account;
            accounts;
            metadata = Utils.init_metadata(args);
            supported_standards = Utils.init_standards();
            transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            permitted_drift;
            transaction_window;
            archive = {
                var canister = actor ("aaaaa-aa");
                var stored_txs = 0;
            };
            allowances = StableTrieMap.new();
            frozen_accounts = StableTrieMap.new(); // 初始化冻结账户存储
        };
    };

    /// 获取代币名称
    public func name(token : T.TokenData) : Text {
        token.name;
    };

    /// 获取代币符号
    public func symbol(token : T.TokenData) : Text {
        token.symbol;
    };

    /// 获取代币的小数位数
    public func decimals({ decimals } : T.TokenData) : Nat8 {
        decimals;
    };

    /// 获取每次转账的手续费
    public func fee(token : T.TokenData) : T.Balance {
        token._fee;
    };

    /// 设置每次转账的手续费
    public func set_fee(token : T.TokenData, fee : Nat) {
        token._fee := fee;
    };

    /// 获取代币所有元数据
    public func metadata(token : T.TokenData) : [T.MetaDatum] {
        SB.toArray(token.metadata);
    };

    /// 返回流通中的代币总供应量
    public func total_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens - token._burned_tokens;
    };

    /// 返回已铸造代币的总供应量
    public func minted_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens;
    };

    /// 返回已销毁代币的数量
    public func burned_supply(token : T.TokenData) : T.Balance {
        token._burned_tokens;
    };

    /// 返回代币的最大供应量
    public func max_supply(token : T.TokenData) : T.Balance {
        token.max_supply;
    };

    /// 返回具有铸造代币权限的账户
    ///
    /// 注意：**铸造账户仅参与铸造和销毁交易，因此发送到该账户的任何代币将被视为销毁。**
    public func minting_account(token : T.TokenData) : T.Account {
        token.minting_account;
    };

    /// 获取指定账户的余额
    public func balance_of({ accounts } : T.TokenData, account : T.Account) : T.Balance {
        let encoded_account = Account.encode(account);
        Utils.get_balance(accounts, encoded_account);
    };

    /// 返回该代币支持的标准数组
    public func supported_standards(token : T.TokenData) : [T.SupportedStandard] {
        SB.toArray(token.supported_standards);
    };

    /// 将浮点数格式化为 nat 余额，并应用正确的小数位数
    public func balance_from_float(token : T.TokenData, float : Float) : T.Balance {
        if (float <= 0) {
            return 0;
        };

        let float_with_decimals = float * (10 ** Float.fromInt(Nat8.toNat(token.decimals)));

        Int.abs(Float.toInt(float_with_decimals));
    };

    /// 从一个账户转账到另一个账户（包括铸造和销毁）
    public func transfer(
        token : T.TokenData,
        args : T.TransferArgs,
        caller : Principal,
    ) : async T.TransferResult {

        let from = {
            owner = caller;
            subaccount = args.from_subaccount;
        };

        // 检查冻结状态
        if (Freeze.is_frozen(token, from.owner)) {
            return #Err(#FrozenAccount);
        };

        let tx_kind = if (from == token.minting_account) {
            #mint
        } else if (args.to == token.minting_account) {
            #burn
        } else {
            #transfer
        };

        let tx_req = Utils.create_transfer_req(args, caller, tx_kind);

        switch (Transfer.validate_request(token, tx_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount } = tx_req; 

        // 处理交易
        switch(tx_req.kind){
            case(#mint){
                Utils.mint_balance(token, encoded.to, amount);
            };
            case(#burn){
                Utils.burn_balance(token, encoded.from, amount);
            };
            case(#transfer){
                Utils.transfer_balance(token, tx_req);

                // 销毁手续费
                Utils.burn_balance(token, encoded.from, token._fee);
            };
        };

        // 存储交易
        let index = SB.size(token.transactions) + token.archive.stored_txs;
        let tx = Utils.req_to_tx(tx_req, index);
        SB.add(token.transactions, tx);

        // 如果需要，将交易转移到归档
        await update_canister(token);

        #Ok(tx.index);
    };

    /// 辅助函数，使用最少参数铸造代币
    public func mint(token : T.TokenData, args : T.Mint, caller : Principal) : async T.TransferResult {

        if (caller != token.minting_account.owner) {
            return #Err(
                #GenericError {
                    error_code = 401;
                    message = "Unauthorized: Only the minting_account can mint tokens.";
                },
            );
        };

        let transfer_args : T.TransferArgs = {
            args with from_subaccount = token.minting_account.subaccount;
            fee = null;
        };

        await transfer(token, transfer_args, caller);
    };

    /// 辅助函数，使用最少参数销毁代币
    public func burn(token : T.TokenData, args : T.BurnArgs, caller : Principal) : async T.TransferResult {

        let transfer_args : T.TransferArgs = {
            args with to = token.minting_account;
            fee = null;
        };

        await transfer(token, transfer_args, caller);
    };

    /// 返回给定代币已处理的交易总数
    public func total_transactions(token : T.TokenData) : Nat {
        let { archive; transactions } = token;
        archive.stored_txs + SB.size(transactions);
    };

    /// 检索由给定 `tx_index` 指定的交易
    public func get_transaction(token : T.TokenData, tx_index : T.TxIndex) : async ?T.Transaction {
        let { archive; transactions } = token;

        let archived_txs = archive.stored_txs;

        if (tx_index < archive.stored_txs) {
            await archive.canister.get_transaction(tx_index);
        } else {
            let local_tx_index = (tx_index - archive.stored_txs) : Nat;
            SB.getOpt(token.transactions, local_tx_index);
        };
    };

    /// 检索由给定范围指定的交易
    public func get_transactions(token : T.TokenData, req : T.GetTransactionsRequest) : T.GetTransactionsResponse {
        let { archive; transactions } = token;

        var first_index = 0xFFFF_FFFF_FFFF_FFFF; // 如果找不到交易则返回此值

        let req_end = req.start + req.length;
        let tx_end = archive.stored_txs + SB.size(transactions);

        var txs_in_canister: [T.Transaction] = [];
        
        if (req.start < tx_end and req_end >= archive.stored_txs) {
            first_index := Nat.max(req.start, archive.stored_txs);
            let tx_start_index = (first_index - archive.stored_txs) : Nat;

            txs_in_canister:= SB.slice(transactions, tx_start_index, req.length);
        };

        let archived_range = if (req.start < archive.stored_txs) {
            {
                start = req.start;
                end = Nat.min(
                    archive.stored_txs,
                    (req.start + req.length) : Nat,
                );
            };
        } else {
            { start = 0; end = 0 };
        };

        let txs_in_archive = (archived_range.end - archived_range.start) : Nat;

        let size = Utils.div_ceil(txs_in_archive, MAX_TRANSACTIONS_PER_REQUEST);

        let archived_transactions = Array.tabulate(
            size,
            func(i : Nat) : T.ArchivedTransaction {
                let offset = i * MAX_TRANSACTIONS_PER_REQUEST;
                let start = offset + archived_range.start;
                let length = Nat.min(
                    MAX_TRANSACTIONS_PER_REQUEST,
                    archived_range.end - start,
                );

                let callback = token.archive.canister.get_transactions;

                { start; length; callback };
            },
        );

        {
            log_length = txs_in_archive + txs_in_canister.size();
            first_index;
            transactions = txs_in_canister;
            archived_transactions;
        };
    };

    // 更新代币数据并管理交易
    // 在创建新交易的任何函数末尾添加
    func update_canister(token : T.TokenData) : async () {
        let txs_size = SB.size(token.transactions);

        if (txs_size >= MAX_TRANSACTIONS_IN_LEDGER) {
            await append_transactions(token);
        };
    };

    // 将交易从 Token 容器转移到存档容器，并返回一个指示数据传输是否成功的布尔值
    func append_transactions(token : T.TokenData) : async () {
        let { archive; transactions } = token;

        if (archive.stored_txs == 0) {
            EC.add(200_000_000_000);
            archive.canister := await Archive.Archive();
        };

        let res = await archive.canister.append_transactions(
            SB.toArray(transactions),
        );

        switch (res) {
            case (#ok(_)) {
                archive.stored_txs += SB.size(transactions);
                SB.clear(transactions);
            };
            case (#err(_)) {};
        };
    };

    // ICRC-2 授权函数
    public func approve(token : T.TokenData, args : T.ApproveArgs, caller : Principal) : { #Ok : Nat; #Err : T.ApproveError } {
        // 验证调用者非匿名
        if (Principal.isAnonymous(caller)) {
            return #Err(#GenericError {
                error_code = 401;
                message = "Anonymous caller not allowed"
            });
        };

        // 验证 spender 不等于发起者自己
        if (args.spender.owner == caller) {
            return #Err(#GenericError {
                error_code = 400;
                message = "Cannot approve self"
            });
        };
        
        // 验证 spender 账户
        if (not Account.validate(args.spender)) {
            return #Err(#GenericError {
                error_code = 400;
                message = "Invalid spender account"
            });
        };

        // 检查冻结状态
        if (Freeze.is_frozen(token, caller)) {
            return #Err(#GenericError {
                error_code = 403;
                message = "Frozen account cannot approve transfers"
            });
        };

        // 构造 caller 的 Account 对象
        let caller_account : T.Account = {
            owner = caller;
            subaccount = args.from_subaccount;
        };

        // 构造授权 key - 使用完整的 Account 对象
        let owner_encoded = Account.encode(caller_account);
        let spender_encoded = Account.encode(args.spender);
        let key = Utils.encode_allowance(owner_encoded, spender_encoded);
        
        // 将 null 默认解析为 0 ，然后与当前额度做一致性校验
        let current = StableTrieMap.get(token.allowances, Blob.equal, Blob.hash, key);
        let current_allowance = switch (current) {
            case (?info) { info.allowance };
            case (_) { 0 };
        };
        let expected : Nat = Option.get(args.expected_allowance, 0);
        if (expected != current_allowance) {
            return #Err(#AllowanceChanged { current_allowance });
        };

        // 设置新的授权额度和过期时间
        StableTrieMap.put(
            token.allowances,
            Blob.equal,
            Blob.hash,
            key,
            { allowance = args.amount; expires_at = args.expires_at },
        );
        Debug.print("Approval successful: " # Principal.toText(caller) # " approved " # debug_show(args.spender) # " for " # Nat.toText(args.amount) # " tokens.");
        return #Ok(args.amount);
    };

    // ICRC-2 转账函数
    public func transfer_from(token : T.TokenData, args : T.TransferFromArgs, caller : Principal) : async T.TransferResult {
        // 验证调用者非匿名
        if (Principal.isAnonymous(caller)) {
            return #Err(#GenericError { 
                error_code = 401; 
                message = "Anonymous caller not allowed"
            });
        };

        // 检查冻结状态 
        if (Freeze.is_frozen(token, args.from.owner)) {
            return #Err(#FrozenAccount);
        };
        if (Freeze.is_frozen(token, args.to.owner)) {
            return #Err(#FrozenAccount);
        };

        let owner_encoded = Account.encode(args.from);
        let spender_account : T.Account = { owner = caller; subaccount = args.spender_subaccount };
        let spender_encoded = Account.encode(spender_account);
        let key = Utils.encode_allowance(owner_encoded, spender_encoded);
        
        // 检查授权额度及过期时间
        let opt_allowance = StableTrieMap.get(token.allowances, Blob.equal, Blob.hash, key);
        switch (opt_allowance) {
            case (?info) {
                let now = Nat64.fromNat(Int.abs(Time.now()));
                switch(info.expires_at) {
                    case (?expire_time) {
                        if (now > expire_time) {
                            // 删除过期的批准,使用 ignore 处理返回值
                            ignore StableTrieMap.remove(token.allowances, Blob.equal, Blob.hash, key);
                            return #Err(#InsufficientFunds { balance = 0 });
                        };
                    };
                    case (null) {};
                };
                switch(args.fee) {
                    case (?provided_fee) {
                        if (provided_fee != token._fee) { 
                            return #Err(#GenericError { 
                                error_code = 400;
                                message = "BadFee: provided fee is not equal to ledger fee"
                            });
                        };
                    };
                    case (null) {
                        return #Err(#GenericError { 
                            error_code = 400;
                            message = "BadFee: fee is required"
                        });
                    }
                };
                if (info.allowance < (args.amount + token._fee)) {
                    return #Err(#GenericError { 
                        error_code = 400;
                        message = "Insufficient allowance"
                    });
                };
                let new_allowance = info.allowance - (args.amount + token._fee);
                // 更新授权额度,使用 ignore 处理返回值 
                ignore StableTrieMap.put(
                    token.allowances,
                    Blob.equal,
                    Blob.hash,
                    key,
                    { allowance = new_allowance; expires_at = info.expires_at },
                );
            };
            case (_) {
                return #Err(#InsufficientFunds { balance = 0 });
            }
        };

        // 构造 transfer_args，对 memo 与 created_at_time 提供默认值以保证完整性
        let transfer_args : T.TransferArgs = {
            from_subaccount = args.from.subaccount;
            to = args.to;
            amount = args.amount;
            fee = args.fee;
            memo = args.memo;
            created_at_time = args.created_at_time;
        };

        // 生成交易请求，调用转账函数中相同的验证逻辑
        let tx_req = Utils.create_transfer_req(transfer_args, args.from.owner, #transfer);
        switch (Transfer.validate_request(token, tx_req)) {
            case (#err(errorType)) { return #Err(errorType); };
            case (#ok(_)) {};
        };

        // 处理交易：转账、燃烧手续费、存储交易及归档
        Utils.transfer_balance(token, tx_req);
        Utils.burn_balance(token, tx_req.encoded.from, token._fee);
        let index = SB.size(token.transactions) + token.archive.stored_txs;
        let tx = Utils.req_to_tx(tx_req, index);
        SB.add(token.transactions, tx);
        await update_canister(token);
        return #Ok(tx.index);
    };

    // 授权查询函数
    public func allowance(token : T.TokenData, args : { owner : T.Account; spender : T.Account }) : { allowance : T.Balance; expires_at : ?T.Timestamp } {
        // 验证 owner 和 spender 账户
        if (not Account.validate(args.owner) or not Account.validate(args.spender)) {
            // 返回默认值而不是抛出异常
            return { allowance = 0; expires_at = null };
        };
        let owner_encoded = Account.encode(args.owner);
        let spender_encoded = Account.encode(args.spender);
        let key = Utils.encode_allowance(owner_encoded, spender_encoded);
        let opt_allowance = StableTrieMap.get(token.allowances, Blob.equal, Blob.hash, key);
        switch (opt_allowance) {
            case (?info) {
                let now = Nat64.fromNat(Int.abs(Time.now()));
                // 检查授权是否过期
                switch(info.expires_at) {
                    case (?expire_time) {
                        if (now > expire_time) {
                            return { allowance = 0; expires_at = null };
                        };
                    };
                    case (null) {};
                };
                return { allowance = info.allowance; expires_at = info.expires_at };
            };
            case (_) { return { allowance = 0; expires_at = null } }
        }
    };

};

import Deque "mo:base/Deque";
import List "mo:base/List";
import Time "mo:base/Time";
import Result "mo:base/Result";

import STMap "mo:StableTrieMap";
import StableBuffer "mo:StableBuffer/StableBuffer";

module {

    public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };

    public type BlockIndex = Nat;
    public type Subaccount = Blob;
    public type Balance = Nat;
    public type StableBuffer<T> = StableBuffer.StableBuffer<T>;
    public type StableTrieMap<K, V> = STMap.StableTrieMap<K, V>;

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type EncodedAccount = Blob;

    public type SupportedStandard = {
        name : Text;
        url : Text;
    };

    public type Memo = Blob;
    public type Timestamp = Nat64;
    public type Duration = Nat64;
    public type TxIndex = Nat;
    public type TxLog = StableBuffer<Transaction>;

    public type MetaDatum = (Text, Value);
    public type MetaData = [MetaDatum];

    public type TxKind = {
        #mint;
        #burn;
        #transfer;
    };

    public type Mint = {
        to : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type BurnArgs = {
        from_subaccount : ?Subaccount;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type Burn = {
        from : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    /// 转账操作的参数
    public type TransferArgs = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;

        /// 交易创建的时间
        /// 如果设置，则 canister 将检查重复交易并拒绝
        created_at_time : ?Nat64;
    };

    public type Transfer = {
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type TransferFromArgs = {
        spender_subaccount : ?Subaccount;
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    /// 交易请求的内部表示
    public type TransactionRequest = {
        kind : TxKind;
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
        encoded : {
            from : EncodedAccount;
            to : EncodedAccount;
        };
    };

    public type Transaction = {
        kind : Text;
        mint : ?Mint;
        burn : ?Burn;
        transfer : ?Transfer;
        index : TxIndex;
        timestamp : Timestamp;
    };

    public type TimeError = {
        #TooOld;
        #CreatedInFuture : { ledger_time : Timestamp };
    };

    public type TransferError = TimeError or {
        #BadFee : { expected_fee : Balance };
        #BadBurn : { min_burn_amount : Balance };
        #InsufficientFunds : { balance : Balance };
        #Duplicate : { duplicate_of : TxIndex };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };
    
    public type TransferResult = {
        #Ok : TxIndex;
        #Err : TransferError;
    };

    /// ICRC token canister 的接口
    public type TokenInterface = actor {

        /// 返回 token 的名称
        icrc1_name : shared query () -> async Text;

        /// 返回 token 的符号
        icrc1_symbol : shared query () -> async Text;

        /// 返回 token 使用的小数位数
        icrc1_decimals : shared query () -> async Nat8;

        /// 返回每次转账收取的费用
        icrc1_fee : shared query () -> async Balance;

        /// 返回 token 的元数据
        icrc1_metadata : shared query () -> async MetaData;

        /// 返回 token 的总供应量
        icrc1_total_supply : shared query () -> async Balance;

        /// 返回允许铸造新 token 的账户
        icrc1_minting_account : shared query () -> async ?Account;

        /// 返回指定账户的余额
        icrc1_balance_of : shared query (Account) -> async Balance;

        /// 从发送者转移指定数量的 token 到接收者
        icrc1_transfer : shared (TransferArgs) -> async TransferResult;

        /// 返回此 token 实现所支持的标准
        icrc1_supported_standards : shared query () -> async [SupportedStandard];

    };

    public type TxCandidBlob = Blob;

    /// Archive canister 的接口
    public type ArchiveInterface = actor {
        /// 将给定的交易追加到档案中
        /// > 只有 Ledger canister 被允许调用此方法
        append_transactions : shared ([Transaction]) -> async Result.Result<(), Text>;

        /// 返回存储在 archive 中的交易总数
        total_transactions : shared query () -> async Nat;

        /// 返回指定索引处的交易
        get_transaction : shared query (TxIndex) -> async ?Transaction;

        /// 返回给定范围内的交易
        get_transactions : shared query (GetTransactionsRequest) -> async TransactionRange;

        /// 返回 archive 在满之前剩余的字节数
        /// > archive canister 的容量为 375GB
        remaining_capacity : shared query () -> async Nat;
    };

    /// 初始化 icrc1 token canister 的参数
    public type InitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        minting_account : Account;
        max_supply : Balance;
        initial_balances : [(Account, Balance)];
        min_burn_amount : Balance;

        /// icrc1 canister 的可选设置
        advanced_settings: ?AdvancedSettings
    };

    /// [InitArgs](#type.InitArgs)，带有初始化 token canister 的可选字段
    public type TokenInitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        max_supply : Balance;
        initial_balances : [(Account, Balance)];
        min_burn_amount : Balance;

        /// 如果没提供，则默认为调用者的可选值
        minting_account : ?Account;

        advanced_settings: ?AdvancedSettings;
    };

    /// 在初始化 icrc1 token canister 时，[InitArgs](#type.InitArgs) 的其他设置
    public type AdvancedSettings = {
        /// 如果 token 需要迁移到新 canister，则需要此项
        burned_tokens : Balance; 
        transaction_window : Timestamp;
        permitted_drift : Timestamp;
    };

    public type AccountBalances = StableTrieMap<EncodedAccount, Balance>;

    /// archive canister 的详细信息
    public type ArchiveData = {
        /// archive canister 的引用
        var canister : ArchiveInterface;

        /// 存储在 archive 中的交易数量
        var stored_txs : Nat;
    };

    /// token canister 的状态
    public type TokenData = {
        /// token 的名称
        name : Text;

        /// token 的符号
        symbol : Text;

        /// token 使用的小数位数
        decimals : Nat8;

        /// 每笔交易收取的费用
        var _fee : Balance;

        /// token 的最大供应量
        max_supply : Balance;

        /// 铸造的 token 总量
        var _minted_tokens : Balance;

        /// 销毁的 token 总量
        var _burned_tokens : Balance;

        /// 允许铸造新 tokens 的账户
        /// 初始化时，最大供应量被铸造到此账户
        minting_account : Account;

        /// 所有账户的余额
        accounts : AccountBalances;

        /// token 的元数据
        metadata : StableBuffer<MetaDatum>;

        /// 此 token 实现所支持的标准
        supported_standards : StableBuffer<SupportedStandard>;

        /// 不允许重复交易的时间窗口
        transaction_window : Nat;

        /// 交易中必须销毁的最小 token 数量
        min_burn_amount : Balance;

        /// 账本时间与交易创建设备时间之间允许的差异
        permitted_drift : Nat;

        /// 由账本处理的最近交易。
        /// 仅存储最后2000笔交易，然后归档。
        transactions : StableBuffer<Transaction>;

        /// 存储 archive canister 详细信息及其中存储的交易数量的记录
        archive : ArchiveData;

        /// 存储授权额度映射，键为由拥有者与被授权方拼接得到的 EncodedAccount
        allowances : StableTrieMap<EncodedAccount, Balance>;
    };

    // Rosetta API
    /// 从账本 canister 请求一段交易的类型
    public type GetTransactionsRequest = {
        start : TxIndex;
        length : Nat;
    };

    public type TransactionRange = {
        transactions: [Transaction];
    };

    public type QueryArchiveFn = shared query (GetTransactionsRequest) -> async TransactionRange;

    public type ArchivedTransaction = {
        /// 待查询的 archive canister 中首个交易的索引
        start : TxIndex;
        /// 待查询的 archive canister 中的交易数量
        length : Nat;

        /// 用于查询 archive canister 的回调函数
        callback: QueryArchiveFn;
    };

    public type GetTransactionsResponse = {
        /// 指定范围内账本和 archive canister 中有效交易的数量
        log_length : Nat;

        /// `transactions` 字段中第一笔交易的索引
        first_index : TxIndex;

        /// 账本 canister 中处于给定范围的交易
        transactions : [Transaction];

        /// 给定范围内 archive canister 的分页请求
        archived_transactions : [ArchivedTransaction];
    };

    /// Rosetta 所支持的功能
    public type RosettaInterface = actor {
        get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
    };

    /// ICRC token 及 Rosetta canister 的接口
    public type FullInterface = TokenInterface and RosettaInterface;
};

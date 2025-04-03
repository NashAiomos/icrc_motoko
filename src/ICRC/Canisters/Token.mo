import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import SB "mo:StableBuffer/StableBuffer";

import ICRC "..";
import Archive "Archive";
import Principal "mo:base/Principal";
import Freeze "../Freeze.mo";

shared ({ caller = _owner }) actor class Token(
    init_args : ICRC.TokenInitArgs,
) : async ICRC.FullInterface {

    let icrc_args : ICRC.InitArgs = {
        init_args with minting_account = Option.get(
            init_args.minting_account,
            {
                owner = _owner;
                subaccount = null;
            },
        );
    };

    stable let token = ICRC.init(icrc_args);

    /// ICRC-1 代币标准函数
    public shared query func icrc1_name() : async Text {
        ICRC.name(token);
    };

    public shared query func icrc1_symbol() : async Text {
        ICRC.symbol(token);
    };

    public shared query func icrc1_decimals() : async Nat8 {
        ICRC.decimals(token);
    };

    public shared query func icrc1_fee() : async ICRC.Balance {
        ICRC.fee(token);
    };

    public shared query func icrc1_metadata() : async [ICRC.MetaDatum] {
        ICRC.metadata(token);
    };

    public shared query func icrc1_total_supply() : async ICRC.Balance {
        ICRC.total_supply(token);
    };

    public shared query func icrc1_minting_account() : async ?ICRC.Account {
        ?ICRC.minting_account(token);
    };

    public shared query func icrc1_balance_of(args : ICRC.Account) : async ICRC.Balance {
        ICRC.balance_of(token, args);
    };

    public shared query func icrc1_supported_standards() : async [ICRC.SupportedStandard] {
        ICRC.supported_standards(token);
    };

    public shared ({ caller }) func icrc1_transfer(args : ICRC.TransferArgs) : async ICRC.TransferResult {
        await ICRC.transfer(token, args, caller);
    };

    public shared ({ caller }) func mint(args : ICRC.Mint) : async ICRC.TransferResult {
        await ICRC.mint(token, args, caller);
    };

    public shared ({ caller }) func burn(args : ICRC.BurnArgs) : async ICRC.TransferResult {
        await ICRC.burn(token, args, caller);
    };

    // ICRC-2 代币标准函数
    public shared ({ caller }) func icrc2_approve(spender : ICRC.Account, amount : ICRC.Balance) : async () {
        ICRC.approve(token, spender, amount, caller);
    };

    public shared ({ caller }) func icrc2_transfer_from(args : ICRC.TransferFromArgs) : async ICRC.TransferResult {
        await ICRC.transfer_from(token, args, caller);
    };
    
    public shared ({ caller }) func icrc2_allowance(args : ICRC.AllowanceArgs) : async { allowance : ICRC.Balance; expires_at : ?Nat64 } {
        await ICRC.allowance(token, args);
    };

    // 用于集成 Rosetta 标准函数
    public shared query func get_transactions(req : ICRC.GetTransactionsRequest) : async ICRC.GetTransactionsResponse {
        ICRC.get_transactions(token, req);
    };

    public shared func get_transaction(i : ICRC.TxIndex) : async ?ICRC.Transaction {
        await ICRC.get_transaction(token, i);
    };

    // 向 canister 存入 cycles
    public shared func deposit_cycles() : async () {
        let amount = ExperimentalCycles.available();
        let accepted = ExperimentalCycles.accept(amount);
        assert (accepted == amount);
    };

    // freeze
    public shared ({ caller }) func freeze_account(account : Principal) : async () {
        Freeze.freeze_account(token, account, _owner, caller);
    };

    public shared ({ caller }) func unfreeze_account(account : Principal) : async () {
        Freeze.unfreeze_account(token, account, _owner, caller);
    };

    public shared query func is_frozen(account : Principal) : async Bool {
        Freeze.is_frozen(token, account);
    };
    
};

import Principal "mo:base/Principal";
import STMap "mo:StableTrieMap";
import Debug "mo:base/Debug";

import T "Types";

/// 账户冻结模块: 提供账户冻结和解冻功能
module {
    public type FreezeResult<T> = {
        #ok : T;
        #err : Text;
    };

    public func freeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) : FreezeResult<()> {
        // 检查账户是否已被冻结
        if (is_frozen(token, account)) {
            return #err("Account is already frozen");
        };
        
        if (caller != owner) {
            return #err("Only owner can freeze accounts");
        };
        
        STMap.put(
            token.frozen_accounts,
            Principal.equal,
            Principal.hash,
            account,
            true,
        );
        Debug.print("[Freeze] Account: " # Principal.toText(account));
        #ok();
    };

    public func unfreeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) : FreezeResult<()> {
        // 检查账户是否已被冻结
        if (not is_frozen(token, account)) {
            return #err("Account is already frozen");
        };

        if (caller != owner) {
            return #err("Only owner can freeze accounts");
        };
        
        ignore STMap.remove(
            token.frozen_accounts, 
            Principal.equal,
            Principal.hash,
            account,
        );
        Debug.print("[Unfreeze] Account: " # Principal.toText(account));
        #ok();
    };

    public func is_frozen(token : T.TokenData, account : Principal) : Bool {
        switch(STMap.get(
            token.frozen_accounts,
            Principal.equal,
            Principal.hash,
            account,
        )) {
            case (?status) { status };
            case (_) { false };
        };
    };
};




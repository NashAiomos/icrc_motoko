import Principal "mo:base/Principal";
import STMap "mo:StableTrieMap";
import Debug "mo:base/Debug";

import T "Types";

/// 账户冻结模块: 提供账户冻结和解冻功能
module {
    public type FreezeEvent = { account : Principal };
    public type UnfreezeEvent = { account : Principal };

    public func freeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
        // 检查账户是否已被冻结
        if (is_frozen(token, account)) {
            Debug.trap("Account is already frozen");
        };
        
        if (caller != owner) {
            Debug.trap("Only owner can freeze accounts");
        };
        
        STMap.put(
            token.frozen_accounts,
            Principal.equal,
            Principal.hash,
            account,
            true,
        );
        Debug.print("[Freeze] Account: " # Principal.toText(account));
    };

    public func unfreeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
        // 检查账户是否已被冻结
        if (not is_frozen(token, account)) {
            Debug.trap("Account is not frozen");
        };

        if (caller != owner) {
            Debug.trap("Only owner can unfreeze accounts");
        };
        
        ignore STMap.remove(
            token.frozen_accounts, 
            Principal.equal,
            Principal.hash,
            account,
        );
        Debug.print("[Unfreeze] Account: " # Principal.toText(account));
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




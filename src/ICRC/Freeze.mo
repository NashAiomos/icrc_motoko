import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";

import T "Types";

module {
    // 类型定义
    public type FreezeEvent = { account : Principal };
    public type UnfreezeEvent = { account : Principal };

    public func freeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
        if (caller != owner) {
            Debug.trap("Only owner can freeze accounts");
        };
        token.frozen_accounts.put(account, true);
        Debug.print("FreezeEvent: " # Principal.toText(account));
    };

    public func unfreeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
        if (caller != owner) {
            Debug.trap("Only owner can unfreeze accounts");
        };
        token.frozen_accounts.delete(account);
        Debug.print("UnfreezeEvent: " # Principal.toText(account));
    };

    // 同步检查账户是否被冻结
    public func is_frozen(token : T.TokenData, account : Principal) : Bool {
        switch(token.frozen_accounts.get(account)) {
            case (?status) { status };
            case (_) { false };
        };
    };
};




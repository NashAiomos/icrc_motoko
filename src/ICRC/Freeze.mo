import Principal "mo:base/Principal";
import STMap "mo:StableTrieMap";
import Debug "mo:base/Debug";

import T "Types";

module {
    public type FreezeEvent = { account : Principal };
    public type UnfreezeEvent = { account : Principal };

    public func freeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
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
        Debug.print("Freeze: " # Principal.toText(account));
    };

    public func unfreeze_account(token : T.TokenData, account : Principal, owner : Principal, caller : Principal) {
        if (caller != owner) {
            Debug.trap("Only owner can unfreeze accounts");
        };
        ignore STMap.remove(
            token.frozen_accounts,
            Principal.equal,
            Principal.hash,
            account,
        );
        Debug.print("Unfreeze: " # Principal.toText(account));
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




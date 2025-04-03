import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import ArrayModule "mo:array/Array";
import Itertools "mo:itertools/Iter";
import StableBuffer "mo:StableBuffer/StableBuffer";
import STMap "mo:StableTrieMap";

import T "Types";

module {
    type Iter<A> = Iter.Iter<A>;

    /// 检查子账户是否有效
    public func validate_subaccount(subaccount : ?T.Subaccount) : Bool {
        switch (subaccount) {
            case (?bytes) {
                bytes.size() == 32;
            };
            case (_) true;
        };
    };

    /// 检查账户是否有效
    public func validate(account : T.Account) : Bool {
        let is_anonymous = Principal.isAnonymous(account.owner);
        let invalid_size = Principal.toBlob(account.owner).size() > 29;

        if (is_anonymous or invalid_size) {
            false;
        } else {
            validate_subaccount(account.subaccount);
        };
    };

    func shrink_subaccount(sub : Blob) : (Iter.Iter<Nat8>, Nat8) {
        let bytes = Blob.toArray(sub);
        var size = Nat8.fromNat(bytes.size());

        let iter = Itertools.skipWhile(
            bytes.vals(),
            func(byte : Nat8) : Bool {
                if (byte == 0x00) {
                    size -= 1;
                    return true;
                };

                false;
            },
        );

        (iter, size);
    };

    func encode_subaccount(sub : Blob) : Iter.Iter<Nat8> {

        let (sub_iter, size) = shrink_subaccount(sub);
        if (size == 0) {
            return Itertools.empty();
        };

        let suffix : [Nat8] = [size, 0x7f];

        Itertools.chain<Nat8>(
            sub_iter,
            suffix.vals(),
        );
    };

    public func encode({ owner; subaccount } : T.Account) : T.EncodedAccount {
        let owner_blob = Principal.toBlob(owner);

        switch (subaccount) {
            case (?subaccount) {
                Blob.fromArray(
                    Iter.toArray(
                        Itertools.chain(
                            owner_blob.vals(),
                            encode_subaccount(subaccount),
                        ),
                    ),
                );
            };
            case (_) {
                owner_blob;
            };
        };
    };

    /// ICRC-1 账户的文本表示形式解码标准
    public func decode(encoded : T.EncodedAccount) : ?T.Account {
        let bytes = Blob.toArray(encoded);
        let size = bytes.size();

        // 检查空输入
        if (size == 0) {
            return null;
        };

        // 检查子账户编码（末尾为 0x7f）
        if (size >= 2 and bytes[size - 1] == 0x7f) {
            let subaccount_size = Nat8.toNat(bytes[size - 2]);

            // 验证子账户大小（1-32 字节）
            if (subaccount_size == 0 or subaccount_size > 32) {
                return null;
            };

            // 计算 principal 和 subaccount 的分割点
            let split_index = size - 2 - subaccount_size;
            if (split_index < 0 or split_index >= size) {
                return null;
            };

            // 子账户不能以零字节开头
            if (subaccount_size > 0 and bytes[split_index] == 0) {
                return null;
            };

            // 确保 principal 非空
            if (split_index == 0) {
                return null;
            };

            // 提取并验证 principal
            let principal = Principal.fromBlob(
                Blob.fromArray(
                    ArrayModule.slice(bytes, 0, split_index),
                ),
            );
            if (Principal.isAnonymous(principal) or Principal.toBlob(principal).size() > 29) {
                return null;
            };

            // 补齐子账户至 32 字节
            let prefix_zeroes = Itertools.take(
                Iter.make(0 : Nat8),
                (32 - subaccount_size) : Nat,
            );
            let encoded_subaccount = Itertools.fromArraySlice(bytes, split_index, size - 2);
            let subaccount = Blob.fromArray(
                Iter.toArray(
                    Itertools.chain(prefix_zeroes, encoded_subaccount),
                ),
            );

            return ?{ owner = principal; subaccount = ?subaccount };
        } else {
            // 无子账户，直接解析 principal
            let principal = Principal.fromBlob(encoded);
            if (Principal.isAnonymous(principal) or Principal.toBlob(principal).size() > 29) {
                return null;
            };
            return ?{ owner = principal; subaccount = null };
        };
    };

    /// 将 ICRC-1 账户从文本表示转换为 Account 类型
    public func fromText(encoded : Text) : ?T.Account {
        let p = Principal.fromText(encoded);
        let blob = Principal.toBlob(p);

        decode(blob);
    };

    /// 将 ICRC-1 Account 转换为文本表示
    public func toText(account : T.Account) : Text {
        let blob = encode(account);
        let principal = Principal.fromBlob(blob);
        Principal.toText(principal);
    };

    func from_hex(char : Char) : Nat8 {
        let charCode = Char.toNat32(char);

        if (Char.isDigit(char)) {
            let digit = charCode - Char.toNat32('0');

            return Nat8.fromNat(Nat32.toNat(digit));
        };

        if (Char.isUppercase(char)) {
            let digit = charCode - Char.toNat32('A') + 10;

            return Nat8.fromNat(Nat32.toNat(digit));
        };

        // 小写
        let digit = charCode - Char.toNat32('a') + 10;

        return Nat8.fromNat(Nat32.toNat(digit));
    };
};

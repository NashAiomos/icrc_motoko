import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Account {
  'owner' : Principal,
  'subaccount' : [] | [Subaccount],
}
export interface Account__1 {
  'owner' : Principal,
  'subaccount' : [] | [Subaccount],
}
export interface AdvancedSettings {
  'permitted_drift' : Timestamp,
  'burned_tokens' : Balance,
  'transaction_window' : Timestamp,
}
export interface ApproveArgs {
  'fee' : [] | [Balance],
  'memo' : [] | [Uint8Array | number[]],
  'from_subaccount' : [] | [Subaccount],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
  'expected_allowance' : [] | [Balance],
  'expires_at' : [] | [Timestamp],
  'spender' : Account,
}
export type ApproveError = {
    'GenericError' : { 'message' : string, 'error_code' : bigint }
  } |
  { 'TemporarilyUnavailable' : null } |
  { 'Duplicate' : { 'duplicate_of' : TxIndex } } |
  { 'BadFee' : { 'expected_fee' : Balance } } |
  { 'AllowanceChanged' : { 'current_allowance' : Balance } } |
  { 'CreatedInFuture' : { 'ledger_time' : Timestamp } } |
  { 'TooOld' : null } |
  { 'Expired' : { 'ledger_time' : Timestamp } } |
  { 'InsufficientFunds' : { 'balance' : Balance } };
export interface ArchivedTransaction {
  'callback' : QueryArchiveFn,
  'start' : TxIndex,
  'length' : bigint,
}
export type Balance = bigint;
export type Balance__1 = bigint;
export interface Burn {
  'from' : Account,
  'memo' : [] | [Uint8Array | number[]],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export interface BurnArgs {
  'memo' : [] | [Uint8Array | number[]],
  'from_subaccount' : [] | [Subaccount],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export interface GetTransactionsRequest { 'start' : TxIndex, 'length' : bigint }
export interface GetTransactionsRequest__1 {
  'start' : TxIndex,
  'length' : bigint,
}
export interface GetTransactionsResponse {
  'first_index' : TxIndex,
  'log_length' : bigint,
  'transactions' : Array<Transaction>,
  'archived_transactions' : Array<ArchivedTransaction>,
}
export type MetaDatum = [string, Value];
export interface Mint {
  'to' : Account,
  'memo' : [] | [Uint8Array | number[]],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export interface Mint__1 {
  'to' : Account,
  'memo' : [] | [Uint8Array | number[]],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export type QueryArchiveFn = ActorMethod<
  [GetTransactionsRequest__1],
  TransactionRange
>;
export type Subaccount = Uint8Array | number[];
export interface SupportedStandard { 'url' : string, 'name' : string }
export type Timestamp = bigint;
export type Timestamp__1 = bigint;
export interface Token {
  'burn' : ActorMethod<[BurnArgs], TransferResult>,
  'deposit_cycles' : ActorMethod<[], undefined>,
  'freeze_account' : ActorMethod<[Principal], undefined>,
  'get_transaction' : ActorMethod<[TxIndex__1], [] | [Transaction__1]>,
  'get_transactions' : ActorMethod<
    [GetTransactionsRequest],
    GetTransactionsResponse
  >,
  'icrc1_balance_of' : ActorMethod<[Account__1], Balance__1>,
  'icrc1_decimals' : ActorMethod<[], number>,
  'icrc1_fee' : ActorMethod<[], Balance__1>,
  'icrc1_metadata' : ActorMethod<[], Array<MetaDatum>>,
  'icrc1_minting_account' : ActorMethod<[], [] | [Account__1]>,
  'icrc1_name' : ActorMethod<[], string>,
  'icrc1_supported_standards' : ActorMethod<[], Array<SupportedStandard>>,
  'icrc1_symbol' : ActorMethod<[], string>,
  'icrc1_total_supply' : ActorMethod<[], Balance__1>,
  'icrc1_transfer' : ActorMethod<[TransferArgs], TransferResult>,
  'icrc2_allowance' : ActorMethod<
    [{ 'owner' : Account__1, 'spender' : Account__1 }],
    { 'allowance' : Balance__1, 'expires_at' : [] | [Timestamp__1] }
  >,
  'icrc2_approve' : ActorMethod<
    [ApproveArgs],
    { 'Ok' : bigint } |
      { 'Err' : ApproveError }
  >,
  'icrc2_transfer_from' : ActorMethod<[TransferFromArgs], TransferResult>,
  'is_frozen' : ActorMethod<[Principal], boolean>,
  'mint' : ActorMethod<[Mint], TransferResult>,
  'unfreeze_account' : ActorMethod<[Principal], undefined>,
}
export interface TokenInitArgs {
  'fee' : Balance,
  'advanced_settings' : [] | [AdvancedSettings],
  'decimals' : number,
  'minting_account' : [] | [Account],
  'name' : string,
  'initial_balances' : Array<[Account, Balance]>,
  'min_burn_amount' : Balance,
  'max_supply' : Balance,
  'symbol' : string,
}
export interface Transaction {
  'burn' : [] | [Burn],
  'kind' : string,
  'mint' : [] | [Mint__1],
  'timestamp' : Timestamp,
  'index' : TxIndex,
  'transfer' : [] | [Transfer],
}
export interface TransactionRange { 'transactions' : Array<Transaction> }
export interface Transaction__1 {
  'burn' : [] | [Burn],
  'kind' : string,
  'mint' : [] | [Mint__1],
  'timestamp' : Timestamp,
  'index' : TxIndex,
  'transfer' : [] | [Transfer],
}
export interface Transfer {
  'to' : Account,
  'fee' : [] | [Balance],
  'from' : Account,
  'memo' : [] | [Uint8Array | number[]],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export interface TransferArgs {
  'to' : Account,
  'fee' : [] | [Balance],
  'memo' : [] | [Uint8Array | number[]],
  'from_subaccount' : [] | [Subaccount],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export type TransferError = {
    'GenericError' : { 'message' : string, 'error_code' : bigint }
  } |
  { 'FrozenAccount' : null } |
  { 'TemporarilyUnavailable' : null } |
  { 'BadBurn' : { 'min_burn_amount' : Balance } } |
  { 'Duplicate' : { 'duplicate_of' : TxIndex } } |
  { 'BadFee' : { 'expected_fee' : Balance } } |
  { 'CreatedInFuture' : { 'ledger_time' : Timestamp } } |
  { 'TooOld' : null } |
  { 'InsufficientFunds' : { 'balance' : Balance } };
export interface TransferFromArgs {
  'to' : Account,
  'fee' : [] | [Balance],
  'spender_subaccount' : [] | [Subaccount],
  'from' : Account,
  'memo' : [] | [Uint8Array | number[]],
  'created_at_time' : [] | [bigint],
  'amount' : Balance,
}
export type TransferResult = { 'Ok' : TxIndex } |
  { 'Err' : TransferError };
export type TxIndex = bigint;
export type TxIndex__1 = bigint;
export type Value = { 'Int' : bigint } |
  { 'Nat' : bigint } |
  { 'Blob' : Uint8Array | number[] } |
  { 'Text' : string };
export interface _SERVICE extends Token {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];

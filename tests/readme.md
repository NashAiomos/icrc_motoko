# Tests

#### Internal Tests
- Download and Install [vessel](https://github.com/dfinity/vessel)
- Run `make test` 
- Run `make actor-test`

#### [Dfinity's ICRC-1 Reference Tests](https://github.com/dfinity/ICRC-1/tree/main/test)
- Install Rust and Cargo via [rustup](https://rustup.rs/)

```
    curl https://sh.rustup.rs -sSf | sh
```

- Follow these [instructions](./readme.md#L16-42) to start the dfx local replica and deploy the icrc1 token
- Once the canister is deployed you should see a message like this

```
    ...
    Building canisters...
    Shrink WASM module size.
    Installing canisters...
    Installing code for canister icrc, 
    with canister ID 73fc5-haaaa-aaaaa-aaahq-cai
```
- Copy the text on the last line after the `ID` and replace it with the `<Enter Canister ID>` in the command below

```
    make ref-test ID=<Enter Canister ID>
```


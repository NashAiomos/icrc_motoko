# Implementación de ICRC-1 e ICRC-2 en Motoko

Este repositorio contiene la implementación del estándar de token ICRC.

La rama `main` es la rama principal que incluye todas las características y añade la capacidad de congelar cuentas específicas además de ICRC-2.

La rama `ICRC-2` es la implementación estándar de ICRC-2.

La rama `ICRC-1` contiene la implementación estándar de ICRC-1.

<br>

## Despliegue de Prueba Local

Para comenzar, asegúrese de tener instalados **Node.js**, **npm**, **dfx** y **[mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)** en su sistema.

### Instalar [dfx](https://internetcomputer.org/docs/building-apps/getting-started/install) (Linux o macOS):
```sh
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

### Instalar mops:
`dfx extension install mops` o `npm i -g ic-mops`

### Ejecutar el Proyecto (reemplace los parámetros según sea necesario):
```sh
git clone https://github.com/NashAiomos/icrc_motoko
cd icrc_motoko
mops install
dfx start --background --clean

dfx deploy icrc --argument '( record {                    
    name = "aaa";
    symbol = "aaa";
    decimals = 8;
    fee = 1_000;
    max_supply = 100_000_000_000_000;
    initial_balances = vec {
        record {
            record {
                owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
                subaccount = null;
            };
            100_000_000_000_000
        };
    };
    min_burn_amount = 10_000;
    minting_account = opt record {
        owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
        subaccount = null;
    };
    advanced_settings = null;
})'
```

### Configuración Adicional:
```motoko
advanced_settings:

type AdvancedSettings = {
    burned_tokens : Balance;
    transaction_window : Timestamp;
    permitted_drift : Timestamp
}
```

<br>

## Arquitectura del Proyecto

El proyecto implementa el **estándar de token ICRC-2** utilizando el lenguaje de programación **Motoko**, con la lógica principal ubicada en la carpeta `src`. Consta de dos canisters principales:

### 1. Canister de Token
- **Propósito**: Proporciona todas las funcionalidades principales del token y la gestión del estado según el estándar ICRC-2, junto con la lógica integrada de archivado de transacciones.
- **Definición**: Definido en `Token.mo`.

### 2. Canister de Archivo
- **Propósito**: Dedicado a almacenar y consultar registros de transacciones archivadas, expandiendo la capacidad de almacenamiento del ledger principal. Admite escalado automático, con cada canister capaz de almacenar **375 GiB** de transacciones.
- **Definición**: Definido en `Archive.mo`.

Además, el proyecto incluye módulos auxiliares para la codificación/decodificación de cuentas, procesamiento de transacciones, definiciones de tipos y funciones de utilidad. El código de prueba se encuentra en la carpeta `tests` y requiere un despliegue separado.

<br>

## Canister de Token

### Archivo de Implementación: `Token.mo`

El Canister de Token proporciona las **interfaces del estándar de token ICRC-2**, incluyendo la consulta de detalles del token (nombre, símbolo, decimales, balance, suministro total, tarifas, estándares soportados) y la implementación de la gestión del estado del token, transferencias, acuñación, quema y otra lógica de negocio.

#### Lógica de Archivado:
- Cuando el número de transacciones en el ledger principal excede un límite establecido (por ejemplo, 2,000 transacciones), se activa la lógica de archivado para transferir transacciones más antiguas al **Canister de Archivo**.
- La lógica general está integrada en `lib.mo`, que llama a `Transfer.mo` para manejar la validación y solicitudes de transacciones. Las transacciones finales se escriben en un buffer de transacciones local, y cuando el buffer excede el límite máximo de transacciones, se inicia el archivado (ver `update_canister` y `append_transactions`).

#### Métodos Principales:
- **`icrc1_name()`**: Devuelve el nombre del token.
- **`icrc1_symbol()`**: Devuelve el símbolo del token.
- **`icrc1_decimals()`**: Devuelve el número de decimales del token.
- **`icrc1_fee()`**: Devuelve la tarifa por transferencia.
- **`icrc1_metadata()`**: Devuelve los metadatos del token.
- **`icrc1_total_supply()`**: Devuelve el suministro circulante actual del token.
- **`icrc1_minting_account()`**: Devuelve la cuenta autorizada para acuñar/quemar tokens.
- **`icrc1_balance_of(account)`**: Consulta el balance de una cuenta especificada.
- **`icrc1_transfer(args)`**: Ejecuta una operación de transferencia (determina internamente si es una transferencia regular, acuñación o quema según el remitente/destinatario).
- **`icrc2_approve()`**: Autoriza a una cuenta a transferir tokens en nombre del autorizador.
- **`icrc2_transfer_from()`**: Permite a una cuenta autorizada realizar transferencias de tokens.
- **`icrc2_allowance()`**: Consulta la cantidad de tokens que una cuenta (propietario) ha autorizado a otra cuenta (gastador) a transferir.
- **`mint(args)`** y **`burn(args)`**: Funciones auxiliares para acuñar y quemar tokens, respectivamente.
- **`get_transaction(tx_index)`** y **`get_transactions(req)`**: Proporcionan consultas para transacciones individuales o por lotes; redirige al Canister de Archivo cuando se excede el límite de transacciones.
- **`deposit_cycles()`**: Permite a los usuarios depositar Cycles en el canister 🙂.

<br>

## Canister de Archivo

### Archivo de Implementación: `Archive.mo`

El Canister de Archivo proporciona almacenamiento de archivado de transacciones para el Canister de Token. Cuando el almacenamiento de transacciones del canister principal excede cierta capacidad, se llama al método `append_transactions` para archivar transacciones más antiguas, reduciendo la presión de almacenamiento en el ledger principal.

#### Mecanismo de Almacenamiento:
- Utiliza **memoria estable** (a través de `ExperimentalStableMemory`) y un **mapa trie estable** (`StableTrieMap`) para gestionar los datos, organizados en buckets de tamaño fijo para el archivado.

#### Métodos Principales:
- **`append_transactions(txs)`**: Verifica los permisos del llamador (solo el canister del Ledger puede llamarlo) y almacena los registros de transacciones en buckets de tamaño fijo (1,000 transacciones cada uno) en el almacenamiento de archivo.
- **`total_transactions()`**: Devuelve el número total de transacciones en el archivo.
- **`get_transaction(tx_index)`**: Consulta una sola transacción por su índice.
- **`get_transactions(req)`**: Consulta registros de transacciones dentro de un rango solicitado, admitiendo paginación.
- **`remaining_capacity()`**: Devuelve la capacidad de almacenamiento restante antes de que el canister de archivo esté lleno.
- **`deposit_cycles()`**: Recibe y deposita Cycles.

<br>

## Módulos Auxiliares

### Definiciones de Tipos (Types)
- **Archivo**: `src/ICRC/Types.mo`
- **Propósito**: Define tipos como `Account`, `TransferArgs`, `Transaction`, `TransferResult` y la estructura de datos general del token `TokenData`. Estos forman las estructuras de datos fundamentales y los protocolos de interfaz del sistema.

### Operaciones de Cuenta (Account)
- **Archivo**: `src/ICRC/Account.mo`
- **Propósito**: Proporciona funciones de codificación y decodificación para cuentas ICRC-1, convirtiendo entre la representación de texto y el formato binario interno según el estándar ICRC-1.

### Procesamiento de Transacciones (Transfer)
- **Archivo**: `src/ICRC/Transfer.mo`
- **Propósito**: Implementa la lógica de validación de solicitudes de transacciones, comprobando la longitud del memo, las tarifas, los balances de las cuentas, la hora de creación (caducada o futura) y las transacciones duplicadas. Devuelve los resultados de la validación y ayuda a determinar si la transacción es una transferencia, acuñación o quema.

### Funciones de Utilidad (Utils)
- **Archivo**: `src/ICRC/Utils.mo`
- **Propósito**: Incluye funciones para inicializar metadatos, generar estándares soportados, crear subaccounts predeterminados, funciones de hash y convertir solicitudes de transacciones a formatos de transacción finales. Sirve como un módulo de utilidad llamado por `lib.mo`.

### Lógica Principal (lib)
- **Archivo**: `src/ICRC/lib.mo`
- **Propósito**: Combina varios módulos para proporcionar todas las interfaces externas del Token ICRC-2. Llama a `Utils`, `Transfer` y `Account` para manejar la inicialización del token, la gestión del estado, las operaciones de transacciones, la lógica de archivado y las consultas de balance.


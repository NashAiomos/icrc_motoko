# Implémentation Motoko ICRC-1 & ICRC-2

Ce dépôt contient l'implémentation de la norme de token ICRC.

La branche `main` est la branche principale qui inclut toutes les fonctionnalités et ajoute la capacité de geler des comptes spécifiques sur ICRC-2.

La branche `ICRC-2` est l'implémentation standard de l'ICRC-2.

La branche `ICRC-1` contient l'implémentation standard de l'ICRC-1.

<br>

## Déploiement Local de Test

Pour commencer, assurez-vous d'avoir **Node.js**, **npm**, **dfx** et **[mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)** installés sur votre système.

### Installer [dfx](https://internetcomputer.org/docs/building-apps/getting-started/install) (Linux ou macOS) :
```sh
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
```

### Installer mops :
`dfx extension install mops` ou `npm i -g ic-mops`

### Exécuter le Projet (remplacez les paramètres si nécessaire) :
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

### Configuration Supplémentaire :

advanced_settings:

```sh
type AdvancedSettings = {
    burned_tokens : Balance;
    transaction_window : Timestamp;
    permitted_drift : Timestamp;
}
```

<br>

## Architecture du Projet

Le projet implémente la **norme de token ICRC-2** en utilisant le langage de programmation **Motoko**, avec la logique principale située dans le dossier `src`. Il se compose de deux canisters principaux :

### 1. Canister de Token
- **But** : Fournit toutes les fonctionnalités de base du token et la gestion d'état conformément à la norme ICRC-2, avec une logique d'archivage des transactions intégrée.
- **Définition** : Définie dans `Token.mo`.

### 2. Canister d'Archive
- **But** : Consacrée au stockage et à la consultation des enregistrements de transactions archivées, augmentant la capacité de stockage du grand livre principal. Elle prend en charge la montée en charge automatique, chaque canister pouvant stocker **375 GiB** de transactions.
- **Définition** : Définie dans `Archive.mo`.

De plus, le projet inclut des modules auxiliaires pour l'encodage/décodage de comptes, le traitement des transactions, les définitions de types et les fonctions utilitaires. Le code de test se trouve dans le dossier `tests` et nécessite un déploiement séparé.

<br>

## Canister de Token

### Fichier d'Implémentation : `Token.mo`

Le Canister de Token fournit les **interfaces de la norme de token ICRC-2**, incluant la consultation des détails du token (nom, symbole, décimales, solde, offre totale, frais, normes supportées) et la mise en œuvre de la gestion d'état du token, des transferts, de la création (minting), de la destruction (burning) et d'autres logiques métier.

#### Logique d'Archivage :
- Lorsque le nombre de transactions dans le grand livre principal dépasse une limite fixée (par exemple, 2 000 transactions), la logique d'archivage est déclenchée pour transférer les transactions plus anciennes vers le **Canister d'Archive**.
- La logique globale est intégrée dans `lib.mo`, qui appelle `Transfer.mo` pour gérer la validation et les demandes de transaction. Les transactions finales sont écrites dans un tampon local, et lorsque le tampon dépasse la limite maximale de transactions, l'archivage est lancé (voir `update_canister` et `append_transactions`).

#### Méthodes Principales :
- **`icrc1_name()`** : Retourne le nom du token.
- **`icrc1_symbol()`** : Retourne le symbole du token.
- **`icrc1_decimals()`** : Retourne le nombre de décimales du token.
- **`icrc1_fee()`** : Retourne les frais par transfert.
- **`icrc1_metadata()`** : Retourne les métadonnées du token.
- **`icrc1_total_supply()`** : Retourne l'offre en circulation actuelle du token.
- **`icrc1_minting_account()`** : Retourne le compte autorisé à créer/détruire des tokens.
- **`icrc1_balance_of(account)`** : Consulte le solde d'un compte spécifié.
- **`icrc1_transfer(args)`** : Exécute une opération de transfert (détermine en interne s'il s'agit d'un transfert régulier, d'une création ou d'une destruction en fonction de l'expéditeur/destinataire).
- **`icrc2_approve()`** : Autorise un compte à transférer des tokens pour le compte de l'autorisateur.
- **`icrc2_transfer_from()`** : Permet à un compte autorisé d'effectuer des transferts de tokens.
- **`icrc2_allowance()`** : Consulte le nombre de tokens qu'un compte (propriétaire) a autorisé un autre compte (bénéficiaire) à transférer.
- **`mint(args)`** et **`burn(args)`** : Fonctions d'aide pour la création et la destruction de tokens, respectivement.
- **`get_transaction(tx_index)`** et **`get_transactions(req)`** : Fournissent des requêtes pour une transaction unique ou par lots ; redirigent vers le Canister d'Archive lorsque la limite de transactions est dépassée.
- **`deposit_cycles()`** : Permet aux utilisateurs de déposer des Cycles dans le canister.
- **`freeze_account(account)`**: Gèle le compte spécifié, empêchant ainsi toute transaction.
- **`unfreeze_account(account)`**: Débloque le compte spécifié, rétablissant ainsi sa capacité à effectuer des transactions.
- **`is_account_frozen(account)`**: Vérifie si le compte spécifié est actuellement bloqué.

<br>

## Canister d'Archive

### Fichier d'Implémentation : `Archive.mo`

Le Canister d'Archive fournit un stockage d'archivage des transactions pour le Canister de Token. Lorsque le stockage des transactions du canister principal dépasse une certaine capacité, la méthode `append_transactions` est appelée pour archiver les transactions plus anciennes, réduisant ainsi la pression sur le grand livre principal.

#### Mécanisme de Stockage :
- Utilise la **mémoire stable** (via `ExperimentalStableMemory`) et une **carte trie stable** (`StableTrieMap`) pour gérer les données, organisées en compartiments de taille fixe pour l'archivage.

#### Méthodes Principales :
- **`append_transactions(txs)`** : Vérifie les permissions de l'appelant (seul le canister du grand livre peut l'appeler) et stocke les enregistrements de transactions dans des compartiments de taille fixe (1 000 transactions chacun) dans le stockage d'archive.
- **`total_transactions()`** : Retourne le nombre total de transactions dans l'archive.
- **`get_transaction(tx_index)`** : Consulte une transaction unique par son index.
- **`get_transactions(req)`** : Consulte les enregistrements de transactions dans une plage demandée, en prenant en charge la pagination.
- **`remaining_capacity()`** : Retourne la capacité de stockage restante avant que le canister d'archive ne soit plein.
- **`deposit_cycles()`** : Reçoit et dépose des Cycles.

<br>

## Modules Auxiliaires

### Définitions de Types (Types)
- **Fichier** : `src/ICRC/Types.mo`
- **But** : Définit des types tels que `Account`, `TransferArgs`, `Transaction`, `TransferResult` et la structure de données globale du token `TokenData`. Ceux-ci forment les structures de données fondamentales et les protocoles d'interface du système.

### Opérations sur les Comptes (Account)
- **Fichier** : `src/ICRC/Account.mo`
- **But** : Fournit des fonctions d'encodage et de décodage pour les comptes ICRC-1, convertissant entre la représentation textuelle et le format binaire interne selon la norme ICRC-1.

### Traitement des Transactions (Transfer)
- **Fichier** : `src/ICRC/Transfer.mo`
- **But** : Implémente la logique de validation des demandes de transaction, en vérifiant la longueur du mémo, les frais, les soldes des comptes, l'heure de création (expirée ou future) et les transactions en double. Il retourne des résultats de validation et aide à déterminer si la transaction est un transfert, une création ou une destruction.

### Fonctions Utilitaires (Utils)
- **Fichier** : `src/ICRC/Utils.mo`
- **But** : Comprend des fonctions pour initialiser les métadonnées, générer les normes supportées, créer des sous-comptes par défaut, des fonctions de hachage et convertir les demandes de transaction en formats de transactions finales. Il sert de module utilitaire appelé par `lib.mo`.

### Logique Principale (lib)
- **Fichier** : `src/ICRC/lib.mo`
- **But** : Combine divers modules pour fournir toutes les interfaces externes du Token ICRC-2. Il appelle `Utils`, `Transfer` et `Account` pour gérer l'initialisation du token, la gestion d'état, les opérations de transaction, la logique d'archivage et les requêtes de solde.

### Logique de gel (Freeze)
- **Fichier** : `src/ICRC/Freeze.mo`
- **But** : La fonctionnalité de gel permet aux administrateurs de restreindre l'exécution d'opérations liées aux tokens (par exemple, transferts, approbations) sur des comptes spécifiques. Les comptes gelés sont stockés dans une structure de données dédiée pour permettre une recherche rapide.Les méthodes freeze_account et unfreeze_account ne sont accessibles qu'aux comptes autorisés (par exemple, le compte de mint ou un compte administrateur désigné).Avant tout traitement de transaction, le système vérifie si le compte concerné est gelé. Si c'est le cas, la transaction est rejetée avec un message d'erreur approprié.


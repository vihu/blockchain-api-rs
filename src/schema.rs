table! {
    accounts (block, address) {
        block -> Int8,
        timestamp -> Timestamptz,
        address -> Text,
        dc_balance -> Int8,
        dc_nonce -> Int8,
        security_balance -> Int8,
        security_nonce -> Int8,
        balance -> Int8,
        nonce -> Int8,
    }
}

table! {
    block_signatures (block, signer) {
        block -> Int8,
        signer -> Text,
        signature -> Text,
    }
}

table! {
    blocks (height) {
        height -> Int8,
        time -> Int8,
        timestamp -> Timestamptz,
        prev_hash -> Nullable<Text>,
        block_hash -> Text,
        transaction_count -> Int4,
        hbbft_round -> Int8,
        election_epoch -> Int8,
        epoch_start -> Int8,
        rescue_signature -> Text,
    }
}

table! {
    gateways (block, address) {
        block -> Int8,
        address -> Text,
        owner -> Text,
        location -> Nullable<Text>,
        alpha -> Float8,
        beta -> Float8,
        delta -> Int4,
        score -> Float8,
        last_poc_challenge -> Nullable<Int8>,
        last_poc_onion_key_hash -> Nullable<Text>,
        witnesses -> Jsonb,
    }
}

table! {
    locations (location) {
        location -> Text,
        long_street -> Nullable<Text>,
        short_street -> Nullable<Text>,
        long_city -> Nullable<Text>,
        short_city -> Nullable<Text>,
        long_state -> Nullable<Text>,
        short_state -> Nullable<Text>,
        long_country -> Nullable<Text>,
        short_country -> Nullable<Text>,
    }
}

table! {
    pending_transactions (hash) {
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
        hash -> Text,
        #[sql_name = "type"]
        type_ -> crate::models::txn::Transaction_type,
        address -> Text,
        nonce -> Int8,
        nonce_type -> crate::models::pending_txn::Pending_transaction_nonce_type,
        status -> crate::models::pending_txn::Pending_transaction_status,
        failed_reason -> Nullable<Text>,
        data -> Bytea,
    }
}

table! {
    transaction_actors (actor, actor_role, transaction_hash) {
        actor -> Text,
        actor_role -> crate::models::txn::Transaction_actor_role,
        transaction_hash -> Text,
    }
}

table! {
    transactions (hash) {
        block -> Int8,
        hash -> Text,
        #[sql_name = "type"]
        type_ -> crate::models::txn::Transaction_type,
        fields -> Jsonb,
    }
}

joinable!(accounts -> blocks (block));
joinable!(block_signatures -> blocks (block));
joinable!(transaction_actors -> transactions (transaction_hash));
joinable!(transactions -> blocks (block));

allow_tables_to_appear_in_same_query!(
    accounts,
    block_signatures,
    blocks,
    gateways,
    locations,
    pending_transactions,
    transaction_actors,
    transactions,
);

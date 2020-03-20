-- :up

CREATE TABLE blocks (
       height BIGINT NOT NULL,

       time BIGINT NOT NULL,
       timestamp TIMESTAMPTZ NOT NULL,
       prev_hash TEXT,
       block_hash TEXT NOT NULL,
       transaction_count INT NOT NULL,
       hbbft_round BIGINT NOT NULL,
       election_epoch BIGINT NOT NULL,
       epoch_start BIGINT NOT NULL,
       rescue_signature TEXT NOT NULL,

       PRIMARY KEY(height)
);

CREATE TABLE block_signatures (
       block BIGINT NOT NULL references blocks on delete cascade,
       signer TEXT NOT NULL,
       signature TEXT NOT NULL,

       PRIMARY KEY(block, signer)
);

-- Types are created outside of a transaction
-- already exists :-/
CREATE TYPE transaction_type as ENUM (
        'coinbase_v1',
        'security_coinbase_v1',
        'oui_v1',
        'gen_gateway_v1',
        'routing_v1',
        'payment_v1',
        'security_exchange_v1',
        'consensus_group_v1',
        'add_gateway_v1',
        'assert_location_v1',
        'create_htlc_v1',
        'redeem_htlc_v1',
        'poc_request_v1',
        'poc_receipts_v1',
        'vars_v1',
        'rewards_v1',
        'token_burn_v1',
        'dc_coinbase_v1',
        'token_burn_exchange_rate_v1'
);

CREATE TABLE transactions (
       block BIGINT NOT NULL references blocks on delete cascade,
       hash TEXT NOT NULL,
       type transaction_type NOT NULL,
       fields jsonb NOT NULL,

       PRIMARY KEY (hash)
);

CREATE INDEX transaction_type_idx on transactions(type);
CREATE INDEX transaction_block_idx on transactions(block);

CREATE TYPE transaction_actor_role as ENUM (
       'payee',
       'payer',
       'owner',
       'gateway',
       'reward_gateway',
       'challenger',
       'challengee',
       'witness',
       'consensus_member',
       'escrow'
);


CREATE TABLE transaction_actors (
       actor TEXT NOT NULL,
       actor_role transaction_actor_role NOT NULL,
       transaction_hash TEXT references transactions on delete cascade,

       PRIMARY KEY (actor, actor_role, transaction_hash)
);


-- migrations/1577040141-create-account.sql
-- :up

CREATE TABLE accounts (
       block BIGINT NOT NULL references blocks on delete cascade,
       timestamp TIMESTAMPTZ NOT NULL,
       address TEXT NOT NULL,

       dc_balance BIGINT NOT NULL DEFAULT 0,
       dc_nonce BIGINT NOT NULL DEFAULT 0,

       security_balance BIGINT NOT NULL DEFAULT 0,
       security_nonce BIGINT NOT NULL DEFAULT 0,

       balance BIGINT NOT NULL DEFAULT 0,
       nonce BIGINT NOT NULL DEFAULT 0,

       PRIMARY KEY (block, address)
);


-- A collapsed view of accounts that includes all known accounts at the
-- highest block
create materialized view account_ledger as
       select * from accounts
       where (block, address) in
             (select max(block) as block, address from accounts group by address);

-- This allows a quick lookup of an account by it's address. Any index on
-- the materialized view also allows a concurrent view refresh
create unique index account_ledger_address_idx on account_ledger(address);

-- migrations/1577890272-create-gateway.sql
-- :up

CREATE TABLE gateways (
       block BIGINT NOT NULL references blocks on delete cascade,
       address TEXT NOT NULL,

       owner TEXT NOT NULL,

       location TEXT,

       alpha FLOAT NOT NULL,
       beta FLOAT NOT NULL,
       delta INT NOT NULL,
       score FLOAT NOT NULL,

       last_poc_challenge BIGINT references blocks(height) on delete set NULL,
       last_poc_onion_key_hash TEXT,

       witnesses jsonb NOT NULL,

       PRIMARY KEY (block, address)
);


CREATE INDEX gateway_owner_idx on gateways(owner);

-- A collapsed view of gateways that includes all gateways at the
-- highest block
create materialized view gateway_ledger as
       select * from gateways
       where (block, address) in
             (select max(block) as block, address from gateways group by address);

-- This allows a quick lookup of a gateway by it's owner. Any index on
-- the materialized view also allows a concurrent view refresh
create unique index gateway_ledger_gateway_idx on gateway_ledger(address);


-- migrations/1580305069-pending-transactions.sql
-- :up

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TYPE pending_transaction_status as ENUM (
       'received',
       'pending',
       'failed'
);

CREATE TYPE pending_transaction_nonce_type as ENUM (
       'balance',
       'security',
       'dc'
);

CREATE TABLE pending_transactions (
       created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
       updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
       hash TEXT NOT NULL,
       type transaction_type NOT NULL,
       address TEXT NOT NULL,
       nonce BIGINT NOT NULL,
       nonce_type pending_transaction_nonce_type NOT NULL,
       status pending_transaction_status NOT NULL,
       failed_reason TEXT,
       data BYTEA NOT NULL,

       PRIMARY KEY (hash)
);

CREATE INDEX pending_transaction_created_idx ON pending_transactions(created_at);
CREATE INDEX pending_transaction_nonce_type_idx ON pending_transactions(nonce_type);

CREATE TRIGGER pending_transaction_set_updated_at
BEFORE UPDATE ON pending_transactions
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_updated_at();


-- migrations/1582467907-gateway_account_idx.sql
-- :up

-- Add block and address indexes to the gateways and accounts table to
-- speed up materialized view refreshes for gateway_ledger and
-- account_ledger
CREATE INDEX IF NOT EXISTS gateway_block_idx on gateways(block);
CREATE INDEX IF NOT EXISTS gateway_address_idx on gateways(address);

CREATE INDEX IF NOT EXISTS account_block_idx on accounts(block);
CREATE INDEX IF NOT EXISTS account_address_idx on accounts(address);



-- migrations/1582900136-locations.sql
-- :up

CREATE TABLE locations (
       location TEXT NOT NULL,

       long_street TEXT,
       short_street TEXT,

       long_city TEXT,
       short_city TEXT,

       long_state TEXT,
       short_state TEXT,

       long_country TEXT,
       short_country TEXT,

       PRIMARY KEY (location)
);


-- migrations/1583473459-payment_v2.sql
-- :up

ALTER TYPE transaction_type ADD VALUE 'payment_v2';

-- migrations/1584239323-actor_block.sql
-- :up

-- Create index for transaction_actor transaction_hash
create index transaction_actor_transaction_hash_idx on transaction_actors(transaction_hash);

-- add block to transaction_actor table
alter table transaction_actors add column block bigint references blocks(height);
-- For each block update block in transaction_actor. This can take a
-- _long_ time
do
$$
begin
    for b in 1..(select max(height) from blocks)
    loop
        update transaction_actors set block = b
               where transaction_hash in (select hash from transactions where block = b);
    end loop;
end
$$;

-- finally update actor block constraint to be non null.
alter table transaction_actors alter column block set not null;
-- Create index for transaction_actor block
create index transaction_actor_block_idx on transaction_actors(block);

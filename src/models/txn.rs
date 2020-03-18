#![feature(proc_macro)]
#![allow(unused)]
#![allow(clippy::all)]

use chrono::prelude::*;
use chrono::DateTime;
use chrono::offset::Utc;
use diesel::sql_types::{Double, Jsonb};
use serde::{Serialize, Deserialize};

#[allow(non_camel_case_types)]
#[derive(DbEnum, Debug)]
pub enum Transaction_type {
    CoinbaseV1,
    SecurityCoinbaseV1,
    OuiV1,
    GenGatewayV1,
    RoutingV1,
    PaymentV1,
    SecurityExchangeV1,
    ConsensusGroupV1,
    AddGatewayV1,
    AssertLocationV1,
    CreateHtlcV1,
    RedeemHtlcV1,
    PocRequestV1,
    PocReceiptsV1,
    VarsV1,
    RewardsV1,
    TokenBurnV1,
    DcCoinbaseV1,
    TokenBurnExchangeRateV1,
    PaymentV2
}

#[allow(non_camel_case_types)]
#[derive(DbEnum, Debug)]
pub enum Transaction_actor_role {
    Payee,
    Payer,
    Owner,
    Gateway,
    RewardGateway,
    Challenger,
    Challengee,
    Witness,
    ConsensusMember,
    Escrow
}

#[derive(Queryable, Debug)]
pub struct TransactionActor {
    pub actor: String,
    pub actor_role: Transaction_actor_role,
    pub transaction_hash: String,
}

#[derive(Queryable, Debug)]
pub struct Transaction {
    pub block: i64,
    pub hash: String,
    pub type_: Transaction_type,
    pub fields: Jsonb,
}


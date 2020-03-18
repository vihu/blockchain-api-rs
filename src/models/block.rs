#![feature(proc_macro)]
#![allow(unused)]
#![allow(clippy::all)]

use chrono::prelude::*;
use chrono::DateTime;
use chrono::offset::Utc;
use diesel::sql_types::{Double, Jsonb};
use serde::{Serialize, Deserialize};

#[derive(Queryable, Debug)]
pub struct BlockSignature {
    pub block: i64,
    pub signer: String,
    pub signature: String,
}

#[derive(Queryable, Debug, Serialize, Deserialize)]
pub struct Block {
    pub height: i64,
    pub time: i64,
    pub timestamp: DateTime<Utc>,
    pub prev_hash: Option<String>,
    pub block_hash: String,
    pub transaction_count: i32,
    pub hbbft_round: i64,
    pub election_epoch: i64,
    pub epoch_start: i64,
    pub rescue_signature: String,
}

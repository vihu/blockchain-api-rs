#![feature(proc_macro)]
#![allow(unused)]
#![allow(clippy::all)]

use chrono::prelude::*;
use chrono::DateTime;
use chrono::offset::Utc;
use diesel::sql_types::{Double, Jsonb};
use serde::{Serialize, Deserialize};

#[derive(Queryable, Debug, Serialize, Deserialize)]
pub struct Account {
    pub block: i64,
    pub timestamp: DateTime<Utc>,
    pub address: String,
    pub dc_balance: i64,
    pub dc_nonce: i64,
    pub security_balance: i64,
    pub security_nonce: i64,
    pub balance: i64,
    pub nonce: i64,
}


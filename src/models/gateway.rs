#![feature(proc_macro)]
#![allow(unused)]
#![allow(clippy::all)]

use chrono::prelude::*;
use chrono::DateTime;
use chrono::offset::Utc;
use diesel::sql_types::{Double, Jsonb};
use serde::{Serialize, Deserialize};

#[derive(Queryable, Debug)]
pub struct Gateway {
    pub block: i64,
    pub address: String,
    pub owner: String,
    pub location: Option<String>,
    pub alpha: Double,
    pub beta: Double,
    pub delta: i32,
    pub score: Double,
    pub last_poc_challenge: Option<i64>,
    pub last_poc_onion_key_hash: Option<String>,
    pub witnesses: Jsonb,
}

#[derive(Queryable, Debug)]
pub struct Location {
    pub location: String,
    pub long_street: Option<String>,
    pub short_street: Option<String>,
    pub long_city: Option<String>,
    pub short_city: Option<String>,
    pub long_state: Option<String>,
    pub short_state: Option<String>,
    pub long_country: Option<String>,
    pub short_country: Option<String>,
}


use chrono::prelude::*;
use serde::{Serialize, Deserialize};
use sqlx::{Row, error::Error, FromRow};
use sqlx::postgres::{PgRow, Postgres};
use serde_json::{Value as JsonValue};

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockTxn {
    pub height: i64,
    pub timestamp: DateTime<Utc>,
    pub txn_count: i32,
    pub hash: String,
    pub txn_type: String,
    pub fields: JsonValue
}

impl<'a> FromRow<'a, PgRow<'a>> for BlockTxn {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<BlockTxn, Error<Postgres>> {
        Ok(Self {
            height: Row::get(&row, "height"),
            timestamp: Row::get(&row, "timestamp"),
            txn_count: Row::get(&row, "transaction_count"),
            hash: Row::get(&row, "hash"),
            txn_type: Row::get(&row, "type"),
            fields: Row::get(&row, "fields")
        })
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockTxnsResponse {
    pub data: Vec<BlockTxn>
}

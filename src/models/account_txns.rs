use serde::{Serialize, Deserialize};
use sqlx::{Row, error::Error, FromRow};
use sqlx::postgres::{PgRow, Postgres};

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxn {
    pub block: i64,
    pub txn_type: String,
    pub hash: String,
    // XXX: fields is actually json
    pub fields: String
}

impl<'a> FromRow<'a, PgRow<'a>> for AccountTxn {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<AccountTxn, Error<Postgres>> {
        Ok(Self {
            block: Row::get(&row, "block"),
            txn_type: Row::get(&row, "type"),
            hash: Row::get(&row, "hash"),
            fields: Row::get(&row, "fields")
        })
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxnsResponse {
    pub data: Vec<AccountTxn>
}

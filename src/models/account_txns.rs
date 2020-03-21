use serde::{Serialize, Deserialize};
use sqlx::{Row, FromRow};
use sqlx::postgres::PgRow;

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxn {
    pub block: i64,
    pub txn_type: String,
    pub hash: String,
    pub fields: String
}

impl FromRow<PgRow> for AccountTxn {
    fn from_row(row: PgRow) -> Self {
        Self {
            block: Row::get(&row, "block"),
            txn_type: Row::get(&row, "type"),
            hash: Row::get(&row, "hash"),
            fields: Row::get(&row, "fields")
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxnsResponse {
    pub data: Vec<AccountTxn>
}

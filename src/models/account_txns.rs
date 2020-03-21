use serde::{Serialize, Deserialize};
use sqlx::{Row, FromRow};
use sqlx::postgres::PgRow;

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxn<'a> {
    pub block: i64,
    pub txn_type: String,
    pub hash: String,
    // XXX: fields is actually json
    pub fields: String
}

impl<'a> FromRow<'_, PgRow<'a>> for AccountTxn<'a> {
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
pub struct AccountTxnsResponse<'a> {
    pub data: Vec<AccountTxn<'a>>
}

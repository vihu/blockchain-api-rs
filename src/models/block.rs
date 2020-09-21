use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug, sqlx::FromRow)]
pub struct Block {
    pub height: i64,
    pub time: i64,
    pub block_hash: String,
    pub transaction_count: i32,
}

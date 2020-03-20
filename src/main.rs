extern crate dotenv;

use std::env;
use sqlx::PgPool;
use chrono::prelude::*;
use serde::{Serialize, Deserialize};
use dotenv::dotenv;

#[derive(Serialize, Deserialize, Debug)]
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

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    dotenv().ok();
    let mut pool = PgPool::new(&env::var("DATABASE_URL")?).await?;

    let blocks = sqlx::query_as!(Block,
        "select * from blocks order by height desc limit 2")
        .fetch_all(&mut pool)
        .await?;

    println!("blocks: {:?}", blocks);

    Ok(())
}


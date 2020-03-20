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

async fn db_pool() -> anyhow::Result<PgPool> {
    dotenv().ok();
    let pool = PgPool::new(&env::var("DATABASE_URL")?).await?;
    Ok(pool)
}

async fn list_blocks(pool: &mut PgPool) -> anyhow::Result<Vec<Block>> {
    let blocks = sqlx::query_as!(Block,
        "select * from blocks order by height desc")
        .fetch_all(pool)
        .await?;

    Ok(blocks)
}

async fn get_block(pool: &mut PgPool, height: i64) -> anyhow::Result<Block> {
    let block = sqlx::query_as!(Block,
        "SELECT * FROM blocks WHERE height = $1", height)
        .fetch_one(pool)
        .await?;

    Ok(block)
}

#[async_std::main]
async fn main() -> anyhow::Result<()> {

    let mut pool = db_pool().await?;
    let blocks = list_blocks(&mut pool).await?;
    let block = get_block(&mut pool, 30).await?;

    println!("blocks: {:?}", blocks);
    println!("block_30: {:?}", block);

    Ok(())
}


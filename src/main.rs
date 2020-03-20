use std::env;
use sqlx::PgPool;
use chrono::prelude::*;
use serde::{Serialize, Deserialize};
use dotenv::dotenv;
use tide::{Request, Response};

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
    pub rescue_signature: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BlocksResponse {
    pub data: Vec<Block>
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockResponse {
    pub data: Block
}

async fn db_pool() -> anyhow::Result<PgPool> {
    dotenv().ok();
    let pool = PgPool::new(&env::var("DATABASE_URL")?).await?;
    Ok(pool)
}

async fn list_blocks(req: Request<PgPool>) -> Response {
    let mut pool = req.state();
    let blocks = sqlx::query_as!(Block,
        "select * from blocks order by height desc limit 2")
        .fetch_all(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&BlocksResponse {data: blocks})
        .unwrap()
}

async fn get_block(req: Request<PgPool>) -> Response {
    let mut pool = req.state();

    let height: i64 = req.param("height").unwrap_or(1);

    let block = sqlx::query_as!(Block,
        "SELECT * FROM blocks WHERE height = $1", height)
        .fetch_one(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&BlockResponse {data: block})
        .unwrap()
}

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = db_pool().await?;
    let mut server = tide::with_state(pool);

    server.at("/api/blocks").get(list_blocks);
    server.at("/api/blocks/:height").get(get_block);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


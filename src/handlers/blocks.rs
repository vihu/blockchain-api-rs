use tide::Request;
use sqlx::PgPool;
use crate::models::blocks::{Block, BlocksResponse, BlockResponse};

pub async fn list_blocks(req: Request<PgPool>) -> BlocksResponse {
    let mut pool = req.state();

    let blocks = sqlx::query_as!(Block,
        "select * from blocks order by height desc limit 2")
        .fetch_all(&mut pool)
        .await;

    match blocks {
        Ok(bs) => BlocksResponse { data: Some(bs) },
        Err(_err) => BlocksResponse { data: None }
    }
}

pub async fn get_block(req: Request<PgPool>) -> BlockResponse {
    let mut pool = req.state();

    let height: i64 = req.param("height").unwrap();

    let block = sqlx::query_as!(Block,
        "select * from blocks where height = $1", height)
        .fetch_optional(&mut pool)
        .await;

    match block {
        Ok(b) => BlockResponse { data: b },
        Err(_err) => BlockResponse { data: None}
    }
}

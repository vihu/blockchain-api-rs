use tide::Request;
use sqlx::{postgres::PgQueryAs, PgPool};
use crate::models::block::{BlocksResponse, BlockResponse, BlockHeightResponse};

pub async fn list(req: Request<PgPool>) -> BlocksResponse {
    let mut pool = req.state();

    let blocks = sqlx::query_as(
        "select height, time, block_hash, transaction_count \
        from blocks \
        order by height desc limit 2")
        .fetch_all(&mut pool)
        .await;

    match blocks {
        Ok(bs) => BlocksResponse { data: Some(bs) },
        Err(_err) => BlocksResponse { data: None }
    }
}

pub async fn get(req: Request<PgPool>) -> BlockResponse {
    let mut pool = req.state();

    let height: i64 = req.param("height").unwrap();

    let block = sqlx::query_as(
        "select height, time, block_hash, transaction_count \
        from blocks \
        where height = $1")
        .bind(height)
        .fetch_optional(&mut pool)
        .await;

    match block {
        Ok(b) => BlockResponse { data: b },
        Err(_err) => BlockResponse { data: None}
    }
}

pub async fn height(req: Request<PgPool>) -> BlockHeightResponse {
    let mut pool = req.state();

    let block = sqlx::query_as(
        "select height, time, block_hash, transaction_count from blocks order by height desc limit 1")
        .fetch_optional(&mut pool)
        .await;

    match block {
        Ok(b) =>
            match b {
                Some(blk) => BlockHeightResponse::from_block(blk),
                None => BlockHeightResponse { data: None }
            }
        Err(_err) => BlockHeightResponse { data: None }
    }
}

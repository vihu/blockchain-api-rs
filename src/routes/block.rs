use tide::Request;
use sqlx::PgPool;
use crate::models::block;
use tide::prelude::*;

pub async fn list(req: Request<PgPool>) -> tide::Result<serde_json::value::Value> {
    let pool = req.state();

    let blocks = sqlx::query_as::<_, block::Block>(
        "select height, time, block_hash, transaction_count \
        from blocks \
        order by height desc limit 2")
        .fetch_all(pool)
        .await;

    match blocks {
        Ok(bs) => Ok(json!({ "data": bs })),
        Err(_err) => Ok(json!({ "data": [] }))
    }
}

pub async fn get(req: Request<PgPool>) -> tide::Result<serde_json::value::Value> {
    let pool = req.state();

    let height: i64 = req.param("height").unwrap();

    let block = sqlx::query_as::<_, block::Block>(
        "select height, time, block_hash, transaction_count \
        from blocks \
        where height = $1")
        .bind(height)
        .fetch_optional(pool)
        .await;

    match block {
        Ok(b) =>
            match b {
                Some(blk) => Ok(json!({ "data": blk })),
                None => Ok(json!({ "data": "" })),
            }
        Err(_err) => Ok(json!({ "data": "" })),
    }
}

pub async fn current(req: Request<PgPool>) -> tide::Result<serde_json::value::Value> {
    let pool = req.state();

    let height = sqlx::query_as::<_, block::Block>(
        "select * from blocks order by height desc limit 1")
        .fetch_one(pool)
        .await;


    println!("height: {:?}", height);

    match height {
        Ok(h) => Ok(json!({ "data": h})),
        Err(_err) => Ok(json!({ "data": ""}))
    }
}

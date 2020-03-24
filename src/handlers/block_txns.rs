use tide::{Request, Response};
use sqlx::PgPool;
use crate::models::block_txns::BlockTxnsResponse;
use sqlx::postgres::PgQueryAs;

pub async fn list_block_txns(req: Request<PgPool>) -> Response {
    let mut pool = req.state();

    let height: i64 = req.param("height").unwrap();

    let block_txns = sqlx::query_as(
        "select b.height, b.timestamp, b.transaction_count, t.hash, t.type, t.fields \
        from blocks as b \
        inner join transactions as t \
        on (t.block = b.height) \
        where b.height = $1")
        .bind(height)
        .fetch_all(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&BlockTxnsResponse {data: block_txns})
        .unwrap()
}


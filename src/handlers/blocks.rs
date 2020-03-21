use tide::{Request, Response};
use sqlx::PgPool;
use crate::models::blocks::{Block, BlocksResponse, BlockResponse};

pub async fn list_blocks(req: Request<PgPool>) -> Response {
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

pub async fn get_block(req: Request<PgPool>) -> Response {
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


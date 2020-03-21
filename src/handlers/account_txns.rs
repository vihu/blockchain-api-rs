use tide::{Request, Response};
use sqlx::PgPool;
use crate::models::account_txns::AccountTxnsResponse;

pub async fn list_account_txns(req: Request<PgPool>) -> Response {
    let mut pool = req.state();

    let address: String = req.param("address").unwrap();

    let account_txns = sqlx::query_as(
        "select t.block, t.hash, t.type, t.fields from transactions as t \
        inner join transaction_actors as a on (t.hash = a.transaction_hash) \
        where a.actor = $1 order by t.block desc")
        .bind(address)
        .fetch_all(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&AccountTxnsResponse {data: account_txns})
        .unwrap()
}


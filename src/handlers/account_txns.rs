use tide::{Request, Response};
use sqlx::PgPool;
use crate::models::account_txns::{AccountTxnsResponse, filtered_account_txns};
use sqlx::postgres::PgQueryAs;

pub async fn list_account_txns(req: Request<PgPool>) -> Response {
    let mut pool = req.state();

    let address: String = req.param("address").unwrap();

    let account_txns = sqlx::query_as(
        "select distinct on (t.block, t.hash) t.block, t.hash, a.actor, t.type, t.fields \
        from transactions as t \
        inner join transaction_actors as a \
        on (t.hash = a.transaction_hash) \
        where a.actor = $1 \
        order by t.block desc")
        .bind(address.clone())
        .fetch_all(&mut pool)
        .await
        .unwrap();

    let filtered_account_txns = filtered_account_txns(account_txns.clone(), &address);

    Response::new(200)
        .body_json(&AccountTxnsResponse {data: filtered_account_txns})
        .unwrap()
}


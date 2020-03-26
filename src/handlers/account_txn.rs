use tide::Request;
use sqlx::PgPool;
use crate::models::account_txn::{AccountTxnsResponse, filtered_account_txns};
use sqlx::postgres::PgQueryAs;

pub async fn list(req: Request<PgPool>) -> AccountTxnsResponse {
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
        .await;

    match account_txns {
        Ok(acc_txns) => {
            // TODO: We should be doing this in postgres and filter the json itself
            let filtered_account_txns = filtered_account_txns(acc_txns, &address);
            AccountTxnsResponse { data: Some(filtered_account_txns) }
        },
        Err(_err) => AccountTxnsResponse { data: None }
    }
}


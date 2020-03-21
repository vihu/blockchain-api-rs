use tide::{Request, Response};
use sqlx::PgPool;
use crate::models::accounts::{Account, AccountResponse, AccountsResponse};

pub async fn list_accounts(req: Request<PgPool>) -> Response {
    let mut pool = req.state();
    let accounts = sqlx::query_as!(Account,
        "select * from accounts where block = (select max(block) from accounts)")
        .fetch_all(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&AccountsResponse {data: accounts})
        .unwrap()
}

pub async fn get_account(req: Request<PgPool>) -> Response {
    let mut pool = req.state();

    let address: String = req.param("address").unwrap();

    let account = sqlx::query_as!(Account,
        "select * from accounts where block = (select max(block) from accounts) and address = $1", address)
        .fetch_one(&mut pool)
        .await
        .unwrap();

    Response::new(200)
        .body_json(&AccountResponse {data: account})
        .unwrap()
}


use tide::Request;
use sqlx::PgPool;
use crate::models::accounts::{Account, AccountResponse, AccountsResponse};

pub async fn list_accounts(req: Request<PgPool>) -> AccountsResponse {
    let mut pool = req.state();

    let accounts = sqlx::query_as!(Account,
        "select * from accounts where block = (select max(block) from accounts)")
        .fetch_all(&mut pool)
        .await;

    match accounts {
        Ok(accs) => AccountsResponse { data: Some(accs) },
        Err(_err) => AccountsResponse { data: None }
    }
}

pub async fn get_account(req: Request<PgPool>) -> AccountResponse {
    let mut pool = req.state();

    let address: String = req.param("address").unwrap();

    let account = sqlx::query_as!(Account,
        "select * from accounts where block = (select max(block) from accounts) and address = $1", address)
        .fetch_optional(&mut pool)
        .await;

    match account {
        Ok(a) => AccountResponse { data: a },
        Err(_err) => AccountResponse { data: None }
    }
}


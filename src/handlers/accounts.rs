use tide::Request;
use sqlx::PgPool;
use crate::models::account_ledger::{AccountLedger, AccountLedgerResponse};

pub async fn get_account(req: Request<PgPool>) -> AccountLedgerResponse {
    let mut pool = req.state();

    // Blow up if you can't handle the address in request
    let address: String = req.param("address").unwrap();

    let account = sqlx::query_as!(AccountLedger,
        "select address, dc_balance, dc_nonce, security_balance, security_nonce, balance, nonce \
        from account_ledger \
        where address = $1", address.clone())
        .fetch_optional(&mut pool)
        .await;

    match account {
        Ok(a) => {
            match a {
                // Found an account
                Some(acc) => AccountLedgerResponse { data: Some(acc) },
                // No account found, Return a blank account
                None => AccountLedgerResponse { data: Some(AccountLedger::with_zeros(address)) }
            }
        },
        Err(_err) => {
            // query errored out, return null
            AccountLedgerResponse { data: None }
        }
    }
}

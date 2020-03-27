use tide::Request;
use sqlx::{PgPool, postgres::PgQueryAs};
use crate::models::account_ledger::{AccountLedger, AccountLedgerResponse};
use crate::models::account::AccountHotspotResponse;

pub async fn get(req: Request<PgPool>) -> AccountLedgerResponse {
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
            // TODO: query errored out, this should be a 404 error resp
            AccountLedgerResponse { data: None }
        }
    }
}

pub async fn hotspots(req: Request<PgPool>) -> AccountHotspotResponse {
    let mut pool = req.state();

    // Blow up if you can't handle the address in request
    let address: String = req.param("address").unwrap();

    let account_hotspots = sqlx::query_as(
        "select g.block, g.address, g.owner, g.location, g.score, \
        l.short_street, l.long_street, l.short_city, l.long_city, \
        l.short_state, l.long_state, l.short_country, l.long_country \
        from gateway_ledger g \
        left join locations l \
        on g.location = l.location \
        where owner = $1 \
        order by first_block desc, address")
        .bind(address)
        .fetch_all(&mut pool)
        .await;

    match account_hotspots {
        Ok(ags) => AccountHotspotResponse { data: Some(ags) },
        Err(_err) => AccountHotspotResponse { data: None}
    }
}
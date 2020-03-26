use serde::{Serialize, Deserialize};
use tide::{Response, IntoResponse};

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountLedger {
    pub address: String,
    pub dc_balance: i64,
    pub dc_nonce: i64,
    pub security_balance: i64,
    pub security_nonce: i64,
    pub balance: i64,
    pub nonce: i64
}

impl AccountLedger {
    pub fn with_zeros(address: String) -> Self {
        AccountLedger {
            address: address,
            dc_balance: 0,
            dc_nonce: 0,
            security_balance: 0,
            security_nonce: 0,
            balance: 0,
            nonce: 0
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountLedgerResponse {
    pub data: Option<AccountLedger>
}

impl IntoResponse for AccountLedgerResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}


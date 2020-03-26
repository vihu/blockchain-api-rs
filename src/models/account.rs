use chrono::prelude::*;
use serde::{Serialize, Deserialize};
use tide::{Response, IntoResponse};

#[derive(Serialize, Deserialize, Debug)]
pub struct Account {
    pub block: i64,
    pub timestamp: DateTime<Utc>,
    pub address: String,
    pub dc_balance: i64,
    pub dc_nonce: i64,
    pub security_balance: i64,
    pub security_nonce: i64,
    pub balance: i64,
    pub nonce: i64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountsResponse {
    pub data: Option<Vec<Account>>
}

impl IntoResponse for AccountsResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountResponse {
    pub data: Option<Account>
}

impl IntoResponse for AccountResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

use chrono::prelude::*;
use serde::{Serialize, Deserialize};

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
    pub data: Vec<Account>
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountResponse {
    pub data: Account
}

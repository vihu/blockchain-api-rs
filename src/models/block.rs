use chrono::prelude::*;
use serde::{Serialize, Deserialize};
use tide::{Response, IntoResponse};

#[derive(Serialize, Deserialize, Debug)]
pub struct Block {
    pub height: i64,
    pub time: i64,
    pub timestamp: DateTime<Utc>,
    pub prev_hash: Option<String>,
    pub block_hash: String,
    pub transaction_count: i32,
    pub hbbft_round: i64,
    pub election_epoch: i64,
    pub epoch_start: i64,
    pub rescue_signature: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BlocksResponse {
    pub data: Option<Vec<Block>>
}

impl IntoResponse for BlocksResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockResponse {
    pub data: Option<Block>
}

impl IntoResponse for BlockResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

use sqlx::{Row, FromRow, error::Error, postgres::{PgRow, Postgres}};
use serde::{Serialize, Deserialize};
use tide::{Response, IntoResponse};

#[derive(Serialize, Deserialize, Debug)]
pub struct Block {
    pub height: i64,
    pub time: i64,
    pub hash: String,
    pub transaction_count: i32
}

impl<'a> FromRow<'a, PgRow<'a>> for Block {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<Block, Error<Postgres>> {
        Ok(Self {
            height: Row::get(&row, "height"),
            hash: Row::get(&row, "block_hash"),
            time: Row::get(&row, "time"),
            transaction_count: Row::get(&row, "transaction_count")
        })
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
pub struct BlockHeightResponse {
    pub data: Option<i64>
}

impl BlockHeightResponse {
    pub fn from_block(block: Block) -> Self {
        BlockHeightResponse {
            data: Some(block.height)
        }
    }
}

impl IntoResponse for BlockHeightResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

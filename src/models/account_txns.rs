use serde::{Serialize, Deserialize};
use sqlx::{Row, error::Error, FromRow};
use sqlx::postgres::{PgRow, Postgres};
use serde_json::{Value as JsonValue};
use serde_json::json;

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct AccountTxn {
    pub block: i64,
    pub txn_type: String,
    pub hash: String,
    pub fields: JsonValue
}

type AccountTxns = Vec<AccountTxn>;

impl<'a> FromRow<'a, PgRow<'a>> for AccountTxn {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<AccountTxn, Error<Postgres>> {
        Ok(Self {
            block: Row::get(&row, "block"),
            txn_type: Row::get(&row, "type"),
            hash: Row::get(&row, "hash"),
            fields: Row::get(&row, "fields")
        })
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountTxnsResponse {
    pub data: AccountTxns
}

pub fn filtered_account_txns(account_txns: AccountTxns, address: &String) -> AccountTxns {
    let mut filtered: AccountTxns = vec![];
    for a in account_txns.clone() {
        let rewards = &a.fields["rewards"].as_array();

        match rewards {
            Some(r) => {
                let mut x: Vec<JsonValue> =  vec![];
                for reward in *r {
                    let account = reward.get("account");
                    match account {
                        Some(a) => {
                            if a.as_str() == Some(address) {
                                x.push(reward.clone());
                            } else {
                                ()
                            }
                        },
                        None => ()
                    }
                }
                let mutilated_account_reward = AccountTxn{fields: json!({"rewards": x}), ..a};
                filtered.push(mutilated_account_reward);
            },
            None => filtered.push(a)
        }
    }

    filtered
}

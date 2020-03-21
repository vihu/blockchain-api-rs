mod db;
mod handlers;
mod models;

use crate::handlers::{blocks, accounts};

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = crate::db::db_pool().await?;
    let mut server = tide::with_state(pool);

    server.at("/api/blocks").get(blocks::list_blocks);
    server.at("/api/blocks/:height").get(blocks::get_block);
    server.at("/api/accounts").get(accounts::list_accounts);
    server.at("/api/accounts/:address").get(accounts::get_account);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


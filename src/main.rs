mod db;
mod handlers;
mod models;

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = db::db_pool().await?;
    let mut server = tide::with_state(pool);

    server.at("/api/blocks").get(handlers::blocks::list_blocks);
    server.at("/api/blocks/:height").get(handlers::blocks::get_block);
    server.at("/api/blocks/:height/txns").get(handlers::block_txns::list_block_txns);
    server.at("/api/accounts").get(handlers::accounts::list_accounts);
    server.at("/api/accounts/:address").get(handlers::accounts::get_account);
    server.at("/api/accounts/:address/txns").get(handlers::account_txns::list_account_txns);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


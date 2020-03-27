mod db;
mod handlers;
mod models;

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = db::db_pool().await?;
    let mut server = tide::with_state(pool);

    // block routes
    server.at("/api/v1/blocks").get(handlers::block::list);
    server.at("/api/v1/blocks/:height").get(handlers::block::get);
    server.at("/api/v1/blocks/height").get(handlers::block::height);
    server.at("/api/v1/blocks/hash/:hash").get(handlers::block::hash);
    server.at("/api/v1/blocks/:height/txns").get(handlers::block_txn::list);

    // account routes
    server.at("/api/v1/accounts/:address").get(handlers::account::get);
    server.at("/api/v1/accounts/:address/hotspots").get(handlers::account::hotspots);
    server.at("/api/v1/accounts/:address/txns").get(handlers::account_txn::list);

    // hotspot routes
    server.at("/api/v1/hotspots").get(handlers::hotspot::list);
    server.at("/api/v1/hotspots/:address").get(handlers::hotspot::get);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


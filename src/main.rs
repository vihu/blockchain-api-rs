mod db;
mod routes;
mod models;

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = db::db_pool().await?;

    let mut server = tide::with_state(pool);

    // block routes
    server.at("/api/v1/blocks").get(routes::block::list);
    server.at("/api/v1/blocks/:height").get(routes::block::get);
    server.at("/api/v1/blocks/current").get(routes::block::current);

    // account routes
    // server.at("/api/v1/accounts/:address").get(routes::account::get);
    // server.at("/api/v1/accounts/:address/hotspots").get(routes::account::hotspots);
    // server.at("/api/v1/accounts/:address/txns").get(routes::account_txn::list);

    // hotspot routes
    // server.at("/api/v1/hotspots").get(routes::hotspot::list);
    // server.at("/api/v1/hotspots/:address").get(routes::hotspot::get);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


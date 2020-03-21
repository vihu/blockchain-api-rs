mod db;
mod handlers;
mod models;

#[async_std::main]
async fn main() -> anyhow::Result<()> {
    let pool = crate::db::db_pool().await?;
    let mut server = tide::with_state(pool);

    server.at("/api/blocks").get(crate::handlers::blocks::list_blocks);
    server.at("/api/blocks/:height").get(crate::handlers::blocks::get_block);

    server.listen("127.0.0.1:8000").await?;

    Ok(())
}


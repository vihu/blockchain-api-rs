use std::env;
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;
use dotenv::dotenv;

pub async fn db_pool() -> anyhow::Result<PgPool> {
    dotenv().ok();
    let pool = PgPoolOptions::new().connect(&env::var("DATABASE_URL")?).await?;
    Ok(pool)
}

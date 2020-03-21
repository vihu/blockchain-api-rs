use std::env;
use sqlx::PgPool;
use dotenv::dotenv;

pub async fn db_pool() -> anyhow::Result<PgPool> {
    dotenv().ok();
    let pool = PgPool::new(&env::var("DATABASE_URL")?).await?;
    Ok(pool)
}

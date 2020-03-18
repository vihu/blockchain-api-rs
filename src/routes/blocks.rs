use crate::models::block::Block;
use crate::db::connection::DbConn;
use crate::schema::blocks::dsl::*;
use rocket_contrib::json::JsonValue;
use diesel::prelude::*;

#[get("/blocks", format = "application/json")]
pub fn all(conn: DbConn) -> JsonValue {
    let results = blocks.order_by(height.desc())
        .limit(3)
        .load::<Block>(&*conn)
        .expect("Error loading blocks");

    json!({ "data": results })
}

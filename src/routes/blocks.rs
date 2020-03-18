use crate::models::block::Block;
use crate::db;
use crate::schema::blocks::dsl::*;
use rocket_contrib::json::JsonValue;
use diesel::prelude::*;

#[get("/blocks", format = "application/json")]
pub fn all() -> JsonValue {
    let connection = db::establish_connection();
    let results = blocks.order_by(height.desc())
        .limit(3)
        .load::<Block>(&connection)
        .expect("Error loading blocks");

    json!({ "data": results })
}

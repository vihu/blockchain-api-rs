use crate::models::account::Account;
use crate::db::connection::DbConn;
use crate::schema::accounts::dsl::*;
use rocket_contrib::json::JsonValue;
use diesel::prelude::*;

#[get("/accounts/<addr>", format = "application/json")]
pub fn get(conn: DbConn, addr: String) -> JsonValue {
    let result = accounts.filter(address.eq(addr))
        .order_by(block.desc())
        .limit(1)
        .load::<Account>(&*conn)
        .expect("Error loading accounts");

    json!({ "data": result })
}

#[get("/accounts", format = "application/json")]
pub fn all(conn: DbConn) -> JsonValue {
    let results = accounts.distinct_on(address)
        .load::<Account>(&*conn)
        .expect("Error loading accounts");

    json!({ "data": results })
}

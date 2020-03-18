use crate::models::block::Block;
use crate::db::connection::DbConn;
use crate::schema::blocks::dsl::*;
use rocket_contrib::json::JsonValue;
use diesel::prelude::*;

#[get("/blocks/<query_height>", format = "application/json")]
pub fn get(conn: DbConn, query_height: i64) -> JsonValue {
    let result = blocks.filter(height.eq(query_height))
        .load::<Block>(&*conn)
        .expect("Error loading blocks");

    json!({ "data": result })
}

#[get("/blocks?<limit>&<before>&<after>", format = "application/json")]
pub fn all(
    conn: DbConn,
    limit: Option<i64>,
    before: Option<i64>,
    after: Option<i64>) -> JsonValue {

    match (limit, before, after) {
        (Some(l), Some(b), None) => get_limit_before(conn, l, b),
        (Some(l), None, Some(a)) => get_limit_after(conn, l, a),
        (None, Some(b), Some(a)) => get_before_after(conn, b, a),
        (None, Some(b), None) => get_limit_before(conn, 5, b),
        (None, None, Some(a)) => get_limit_after(conn, 5, a),
        (Some(l), None, None) => get_limit(conn, l),
        _ => get_limit(conn, 5)
    }
}

fn get_before_after(conn: DbConn, before: i64, after: i64) -> JsonValue {
    let sql = blocks.filter(height.le(before)).filter(height.gt(after)).order_by(height.desc());
    let results = sql.load::<Block>(&*conn).expect("Error loading blocks");
    json!({ "data": results })
}

fn get_limit_before(conn: DbConn, limit: i64, before: i64) -> JsonValue {
    let sql = blocks.filter(height.lt(before)).limit(limit).order_by(height.desc());
    let results = sql.load::<Block>(&*conn).expect("Error loading blocks");
    json!({ "data": results })
}

fn get_limit_after(conn: DbConn, limit: i64, after: i64) -> JsonValue {
    let sql = blocks.filter(height.gt(after)).limit(limit);
    let results = sql.load::<Block>(&*conn).expect("Error loading blocks");
    json!({ "data": results })
}

fn get_limit(conn: DbConn, limit: i64) -> JsonValue {
    let sql = blocks.order_by(height.desc()).limit(limit);
    let results = sql.load::<Block>(&*conn).expect("Error loading blocks");
    json!({ "data": results })
}

// fn not_found() -> JsonValue {
//     json!({
//         "status": "error",
//         "reason": "not_found"
//     })
// }

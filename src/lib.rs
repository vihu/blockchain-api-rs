#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate diesel;
#[macro_use] extern crate diesel_derive_enum;
#[macro_use] extern crate rocket;
#[macro_use] extern crate rocket_contrib;

mod schema;
mod models;
mod routes;
mod db;

pub fn rocket() -> rocket::Rocket {
    rocket::ignite()
        .manage(db::connection::init_db())
        .mount("/api",
            routes![
            routes::blocks::all,
            routes::blocks::get,
            routes::accounts::all,
            routes::accounts::get
            ])
}

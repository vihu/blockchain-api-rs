use sqlx::{Row, error::Error, FromRow};
use sqlx::postgres::{PgRow, Postgres};
use tide::{Response, IntoResponse};
use serde::{Serialize, Deserialize};
// use serde_json::{Value as JsonValue};

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountGateway {
    pub address: String,
    pub owner: String,
    pub location: String,
    pub score: f64,
    pub score_update_height: i64,
    // TODO: pub name: String,
    pub geocode: Geocode
    // pub lat: String,
    // pub lng: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Geocode {
    pub long_city: String,
    pub long_country: String,
    pub long_state: String,
    pub long_street: String,
    pub short_city: String,
    pub short_country: String,
    pub short_state: String,
    pub short_street: String
}

type AccountGateways = Vec<AccountGateway>;

impl<'a> FromRow<'a, PgRow<'a>> for AccountGateway {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<AccountGateway, Error<Postgres>> {

        let geocode: Geocode = Geocode {
            long_city: Row::get(&row, "long_city"),
            long_country: Row::get(&row, "long_country"),
            long_state: Row::get(&row, "long_state"),
            long_street: Row::get(&row, "long_street"),
            short_city: Row::get(&row, "short_city"),
            short_country:Row::get(&row, "short_country"),
            short_state: Row::get(&row, "short_state"),
            short_street: Row::get(&row, "short_street"),
        };

        Ok(Self {
            address: Row::get(&row, "address"),
            owner: Row::get(&row, "owner"),
            location: Row::get(&row, "location"),
            score: Row::get(&row, "score"),
            score_update_height: Row::get(&row, "block"),
            geocode: geocode
        })
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct AccountGatewayResponse {
    pub data: Option<AccountGateways>
}

impl IntoResponse for AccountGatewayResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

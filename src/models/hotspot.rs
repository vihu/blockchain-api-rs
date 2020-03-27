use sqlx::{Row, error::Error, FromRow};
use sqlx::postgres::{PgRow, Postgres};
use tide::{Response, IntoResponse};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct Hotspot {
    pub address: String,
    pub owner: String,
    pub location: Option<String>,
    pub score: f64,
    pub score_update_height: i64,
    // TODO: pub name: String,
    pub geocode: Option<Geocode>
    // pub lat: String,
    // pub lng: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Geocode {
    pub long_city: Option<String>,
    pub long_country: Option<String>,
    pub long_state: Option<String>,
    pub long_street: Option<String>,
    pub short_city: Option<String>,
    pub short_country: Option<String>,
    pub short_state: Option<String>,
    pub short_street: Option<String>,
}

pub type Hotspots = Vec<Hotspot>;

impl<'a> FromRow<'a, PgRow<'a>> for Hotspot {
    fn from_row(row: PgRow<'a>) -> anyhow::Result<Hotspot, Error<Postgres>> {

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
            geocode: Some(geocode)
        })
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct HotspotsResponse {
    pub data: Option<Hotspots>
}

impl IntoResponse for HotspotsResponse {
    fn into_response(self) -> Response {
        Response::new(200).body_json(&self).unwrap()
    }
}

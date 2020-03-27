use tide::Request;
use sqlx::{postgres::PgQueryAs, PgPool};
use crate::models::hotspot::HotspotsResponse;

pub async fn list(req: Request<PgPool>) -> HotspotsResponse {
    let mut pool = req.state();

    let hotspots = sqlx::query_as(
        "select g.block, g.address, g.owner, g.location, g.score, \
        l.short_street, l.long_street, l.short_city, l.long_city, \
        l.short_state, l.long_state, l.short_country, l.long_country \
        from gateway_ledger g \
        left join locations l \
        on g.location = l.location ")
        .fetch_all(&mut pool)
        .await;

    match hotspots {
        Ok(hs) => HotspotsResponse { data: Some(hs) },
        Err(_err) => HotspotsResponse { data: None }
    }
}

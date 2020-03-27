### blockchain-api-rs

Rust rest api for helium blockchain backed by sqlx + tide.

### Steps to run:

* Move `.envsample` to `.env` and edit accordingly
* Use [blockchain-etl](https://github.com/helium/blockchain-etl) to synchronize database locally

```
cargo build
cargo run
```

### Supported routes (WIP):

```
/api/v1/blocks
/api/v1/blocks/height
/api/v1/blocks/:height
/api/v1/blocks/:height/txns
/api/v1/accounts
/api/v1/accounts/:address
/api/v1/accounts/:address/hotspots
/api/v1/accounts/:address/txns
/api/v1/hotspots
/api/v1/hotspots/:address
```

### Disclaimer:

Expect dragons

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
/api/blocks
/api/blocks/height
/api/blocks/:height
/api/blocks/:height/txns
/api/accounts
/api/accounts/:address
/api/accounts/:address/hotspots
/api/accounts/:address/txns
/api/hotspots
/api/hotspots/:address
```

### Disclaimer:

Expect dragons

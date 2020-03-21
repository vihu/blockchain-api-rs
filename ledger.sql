--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: pending_transaction_nonce_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pending_transaction_nonce_type AS ENUM (
    'balance',
    'security',
    'dc'
);


ALTER TYPE public.pending_transaction_nonce_type OWNER TO postgres;

--
-- Name: pending_transaction_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pending_transaction_status AS ENUM (
    'received',
    'pending',
    'failed'
);


ALTER TYPE public.pending_transaction_status OWNER TO postgres;

--
-- Name: transaction_actor_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_actor_role AS ENUM (
    'payee',
    'payer',
    'owner',
    'gateway',
    'reward_gateway',
    'challenger',
    'challengee',
    'witness',
    'consensus_member',
    'escrow',
    'sc_opener',
    'sc_closer'
);


ALTER TYPE public.transaction_actor_role OWNER TO postgres;

--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_type AS ENUM (
    'coinbase_v1',
    'security_coinbase_v1',
    'oui_v1',
    'gen_gateway_v1',
    'routing_v1',
    'payment_v1',
    'security_exchange_v1',
    'consensus_group_v1',
    'add_gateway_v1',
    'assert_location_v1',
    'create_htlc_v1',
    'redeem_htlc_v1',
    'poc_request_v1',
    'poc_receipts_v1',
    'vars_v1',
    'rewards_v1',
    'token_burn_v1',
    'dc_coinbase_v1',
    'token_burn_exchange_rate_v1',
    'payment_v2',
    'blockchain_txn_state_channel_open_v1',
    'blockchain_txn_state_channel_close_v1'
);


ALTER TYPE public.transaction_type OWNER TO postgres;

--
-- Name: diesel_manage_updated_at(regclass); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diesel_manage_updated_at(_tbl regclass) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE PROCEDURE diesel_set_updated_at()', _tbl);
END;
$$;


ALTER FUNCTION public.diesel_manage_updated_at(_tbl regclass) OWNER TO postgres;

--
-- Name: diesel_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diesel_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        NEW IS DISTINCT FROM OLD AND
        NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at
    ) THEN
        NEW.updated_at := current_timestamp;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.diesel_set_updated_at() OWNER TO postgres;

--
-- Name: trigger_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN   NEW.updated_at = NOW();   RETURN NEW; END; $$;


ALTER FUNCTION public.trigger_set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO postgres;

--
-- Name: __migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.__migrations (
    id character varying(255) NOT NULL,
    datetime timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.__migrations OWNER TO postgres;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts (
    block bigint NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    address text NOT NULL,
    dc_balance bigint DEFAULT 0 NOT NULL,
    dc_nonce bigint DEFAULT 0 NOT NULL,
    security_balance bigint DEFAULT 0 NOT NULL,
    security_nonce bigint DEFAULT 0 NOT NULL,
    balance bigint DEFAULT 0 NOT NULL,
    nonce bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: account_ledger; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.account_ledger AS
 SELECT accounts.block,
    accounts."timestamp",
    accounts.address,
    accounts.dc_balance,
    accounts.dc_nonce,
    accounts.security_balance,
    accounts.security_nonce,
    accounts.balance,
    accounts.nonce
   FROM public.accounts
  WHERE ((accounts.block, accounts.address) IN ( SELECT max(accounts_1.block) AS block,
            accounts_1.address
           FROM public.accounts accounts_1
          GROUP BY accounts_1.address))
  WITH NO DATA;


ALTER TABLE public.account_ledger OWNER TO postgres;

--
-- Name: block_signatures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.block_signatures (
    block bigint NOT NULL,
    signer text NOT NULL,
    signature text NOT NULL
);


ALTER TABLE public.block_signatures OWNER TO postgres;

--
-- Name: blocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blocks (
    height bigint NOT NULL,
    "time" bigint NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    prev_hash text,
    block_hash text NOT NULL,
    transaction_count integer NOT NULL,
    hbbft_round bigint NOT NULL,
    election_epoch bigint NOT NULL,
    epoch_start bigint NOT NULL,
    rescue_signature text NOT NULL
);


ALTER TABLE public.blocks OWNER TO postgres;

--
-- Name: gateways; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gateways (
    block bigint NOT NULL,
    address text NOT NULL,
    owner text NOT NULL,
    location text,
    alpha double precision NOT NULL,
    beta double precision NOT NULL,
    delta integer NOT NULL,
    score double precision NOT NULL,
    last_poc_challenge bigint,
    last_poc_onion_key_hash text,
    witnesses jsonb NOT NULL
);


ALTER TABLE public.gateways OWNER TO postgres;

--
-- Name: gateway_ledger; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.gateway_ledger AS
 SELECT gateways.block,
    gateways.address,
    gateways.owner,
    gateways.location,
    gateways.alpha,
    gateways.beta,
    gateways.delta,
    gateways.score,
    gateways.last_poc_challenge,
    gateways.last_poc_onion_key_hash,
    gateways.witnesses
   FROM public.gateways
  WHERE ((gateways.block, gateways.address) IN ( SELECT max(gateways_1.block) AS block,
            gateways_1.address
           FROM public.gateways gateways_1
          GROUP BY gateways_1.address))
  WITH NO DATA;


ALTER TABLE public.gateway_ledger OWNER TO postgres;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    location text NOT NULL,
    long_street text,
    short_street text,
    long_city text,
    short_city text,
    long_state text,
    short_state text,
    long_country text,
    short_country text
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: pending_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_transactions (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    hash text NOT NULL,
    type public.transaction_type NOT NULL,
    address text NOT NULL,
    nonce bigint NOT NULL,
    nonce_type public.pending_transaction_nonce_type NOT NULL,
    status public.pending_transaction_status NOT NULL,
    failed_reason text,
    data bytea NOT NULL
);


ALTER TABLE public.pending_transactions OWNER TO postgres;

--
-- Name: transaction_actors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_actors (
    actor text NOT NULL,
    actor_role public.transaction_actor_role NOT NULL,
    transaction_hash text NOT NULL
);


ALTER TABLE public.transaction_actors OWNER TO postgres;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    block bigint NOT NULL,
    hash text NOT NULL,
    type public.transaction_type NOT NULL,
    fields jsonb NOT NULL
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Data for Name: __diesel_schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.__diesel_schema_migrations (version, run_on) FROM stdin;
00000000000000	2020-03-17 19:09:54.762508
\.


--
-- Data for Name: __migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.__migrations (id, datetime) FROM stdin;
migrations/1576305004-create-block	2020-03-11 15:58:51.00209
migrations/1577040141-create-account	2020-03-11 15:58:51.075742
migrations/1577890272-create-gateway	2020-03-11 15:58:51.188844
migrations/1580305069-pending-transactions	2020-03-11 15:58:51.277664
migrations/1582467907-gateway_account_idx	2020-03-11 15:58:51.358366
migrations/1582900136-locations	2020-03-11 15:58:51.407661
migrations/1583473459-payment_v2	2020-03-11 15:58:51.428377
migrations/1583860178-state_channel	2020-03-11 15:58:51.451339
migrations/1583860255-state_channel_role	2020-03-11 15:58:51.471819
\.


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts (block, "timestamp", address, dc_balance, dc_nonce, security_balance, security_nonce, balance, nonce) FROM stdin;
1	1969-12-31 16:00:00-08	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	500000000	0
1	1969-12-31 16:00:00-08	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500000000	0
1	1969-12-31 16:00:00-08	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500000000	0
1	1969-12-31 16:00:00-08	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500000000	0
1	1969-12-31 16:00:00-08	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500000000	0
1	1969-12-31 16:00:00-08	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500000000	0
1	1969-12-31 16:00:00-08	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	10000000	0	5000000	0	500000000	0
1	1969-12-31 16:00:00-08	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500000000	0
16	2020-03-11 15:47:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	500273851	0
16	2020-03-11 15:47:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500020668	0
16	2020-03-11 15:47:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500020668	0
16	2020-03-11 15:47:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500020668	0
16	2020-03-11 15:47:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500020668	0
16	2020-03-11 15:47:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500020668	0
16	2020-03-11 15:47:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	10000000	0	5000000	0	500273851	0
32	2020-03-11 15:48:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	500527034	0
32	2020-03-11 15:48:26-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500041336	0
32	2020-03-11 15:48:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500041336	0
32	2020-03-11 15:48:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500041336	0
32	2020-03-11 15:48:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500041336	0
32	2020-03-11 15:48:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500041336	0
32	2020-03-11 15:48:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	10000000	0	5000000	0	500547702	0
32	2020-03-11 15:48:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500020668	0
48	2020-03-11 15:49:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	500800885	0
48	2020-03-11 15:49:46-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500062004	0
48	2020-03-11 15:49:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500062004	0
48	2020-03-11 15:49:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500062004	0
48	2020-03-11 15:49:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500062004	0
48	2020-03-11 15:49:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999989	1	5000000	0	500821553	0
48	2020-03-11 15:49:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500041336	0
64	2020-03-11 15:51:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	501054068	0
64	2020-03-11 15:51:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500062004	0
64	2020-03-11 15:51:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500082672	0
64	2020-03-11 15:51:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500082672	0
64	2020-03-11 15:51:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500082672	0
64	2020-03-11 15:51:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500082672	0
64	2020-03-11 15:51:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	501095404	0
64	2020-03-11 15:51:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500062004	0
80	2020-03-11 15:52:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	501327919	0
80	2020-03-11 15:52:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500103340	0
80	2020-03-11 15:52:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500103340	0
80	2020-03-11 15:52:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500103340	0
80	2020-03-11 15:52:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500103340	0
80	2020-03-11 15:52:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	501369255	0
80	2020-03-11 15:52:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500082672	0
96	2020-03-11 15:53:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	501601770	0
96	2020-03-11 15:53:46-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500082672	0
96	2020-03-11 15:53:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500124008	0
96	2020-03-11 15:53:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500124008	0
96	2020-03-11 15:53:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500124008	0
96	2020-03-11 15:53:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	501643106	0
96	2020-03-11 15:53:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500103340	0
112	2020-03-11 15:55:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	501854953	0
112	2020-03-11 15:55:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500103340	0
112	2020-03-11 15:55:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500124008	0
112	2020-03-11 15:55:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500144676	0
112	2020-03-11 15:55:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500144676	0
112	2020-03-11 15:55:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500144676	0
112	2020-03-11 15:55:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	501916957	0
112	2020-03-11 15:55:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500124008	0
128	2020-03-11 15:56:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	502128804	0
128	2020-03-11 15:56:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500144676	0
128	2020-03-11 15:56:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500165344	0
128	2020-03-11 15:56:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500165344	0
128	2020-03-11 15:56:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500165344	0
128	2020-03-11 15:56:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	502190808	0
128	2020-03-11 15:56:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500144676	0
144	2020-03-11 15:57:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	502402655	0
144	2020-03-11 15:57:46-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500124008	0
144	2020-03-11 15:57:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500186012	0
144	2020-03-11 15:57:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500186012	0
144	2020-03-11 15:57:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500186012	0
144	2020-03-11 15:57:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	502464659	0
144	2020-03-11 15:57:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500165344	0
160	2020-03-11 15:59:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	502655838	0
160	2020-03-11 15:59:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500144676	0
160	2020-03-11 15:59:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500165344	0
160	2020-03-11 15:59:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500206680	0
160	2020-03-11 15:59:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500206680	0
160	2020-03-11 15:59:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500206680	0
160	2020-03-11 15:59:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	502738510	0
160	2020-03-11 15:59:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500186012	0
176	2020-03-11 16:00:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	502929689	0
176	2020-03-11 16:00:26-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500165344	0
176	2020-03-11 16:00:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500227348	0
176	2020-03-11 16:00:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500227348	0
176	2020-03-11 16:00:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500227348	0
176	2020-03-11 16:00:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	503012361	0
176	2020-03-11 16:00:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500206680	0
192	2020-03-11 16:01:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	503182872	0
192	2020-03-11 16:01:46-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500186012	0
192	2020-03-11 16:01:46-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500186012	0
192	2020-03-11 16:01:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500248016	0
192	2020-03-11 16:01:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500248016	0
192	2020-03-11 16:01:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500248016	0
192	2020-03-11 16:01:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	503286212	0
192	2020-03-11 16:01:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500227348	0
208	2020-03-11 16:03:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	503456723	0
208	2020-03-11 16:03:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500206680	0
208	2020-03-11 16:03:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500268684	0
208	2020-03-11 16:03:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500268684	0
208	2020-03-11 16:03:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500268684	0
208	2020-03-11 16:03:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	503560063	0
208	2020-03-11 16:03:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500248016	0
224	2020-03-11 16:04:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	503709906	0
224	2020-03-11 16:04:26-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500206680	0
224	2020-03-11 16:04:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500227348	0
224	2020-03-11 16:04:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500289352	0
224	2020-03-11 16:04:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500289352	0
224	2020-03-11 16:04:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500289352	0
224	2020-03-11 16:04:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	503833914	0
224	2020-03-11 16:04:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500268684	0
240	2020-03-11 16:05:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	503983757	0
240	2020-03-11 16:05:46-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500227348	0
240	2020-03-11 16:05:46-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500248016	0
240	2020-03-11 16:05:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500310020	0
240	2020-03-11 16:05:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500310020	0
240	2020-03-11 16:05:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	504107765	0
240	2020-03-11 16:05:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500289352	0
256	2020-03-11 16:07:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	504236940	0
256	2020-03-11 16:07:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500248016	0
256	2020-03-11 16:07:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500268684	0
256	2020-03-11 16:07:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500310020	0
256	2020-03-11 16:07:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500330688	0
256	2020-03-11 16:07:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500330688	0
256	2020-03-11 16:07:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	504381616	0
256	2020-03-11 16:07:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500310020	0
272	2020-03-11 16:08:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	504510791	0
272	2020-03-11 16:08:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500289352	0
272	2020-03-11 16:08:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500330688	0
272	2020-03-11 16:08:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500351356	0
272	2020-03-11 16:08:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500351356	0
272	2020-03-11 16:08:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	504655467	0
272	2020-03-11 16:08:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500330688	0
288	2020-03-11 16:09:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	504763974	0
288	2020-03-11 16:09:46-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500268684	0
288	2020-03-11 16:09:46-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500310020	0
288	2020-03-11 16:09:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500351356	0
288	2020-03-11 16:09:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500372024	0
288	2020-03-11 16:09:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500372024	0
288	2020-03-11 16:09:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	504929318	0
288	2020-03-11 16:09:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500351356	0
304	2020-03-11 16:11:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	505037825	0
304	2020-03-11 16:11:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500330688	0
304	2020-03-11 16:11:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500372024	0
304	2020-03-11 16:11:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500392692	0
304	2020-03-11 16:11:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500392692	0
304	2020-03-11 16:11:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	505203169	0
304	2020-03-11 16:11:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500372024	0
320	2020-03-11 16:12:26-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	505291008	0
320	2020-03-11 16:12:26-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500289352	0
320	2020-03-11 16:12:26-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500351356	0
320	2020-03-11 16:12:26-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500392692	0
320	2020-03-11 16:12:26-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500413360	0
320	2020-03-11 16:12:26-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500413360	0
320	2020-03-11 16:12:26-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	505477020	0
320	2020-03-11 16:12:26-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500392692	0
336	2020-03-11 16:13:46-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	505564859	0
336	2020-03-11 16:13:46-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500372024	0
336	2020-03-11 16:13:46-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500413360	0
336	2020-03-11 16:13:46-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500434028	0
336	2020-03-11 16:13:46-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500434028	0
336	2020-03-11 16:13:46-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	505750871	0
336	2020-03-11 16:13:46-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500413360	0
352	2020-03-11 16:15:06-07	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	10000000	0	5000000	0	505818042	0
352	2020-03-11 16:15:06-07	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	0	0	0	0	500310020	0
352	2020-03-11 16:15:06-07	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	0	0	0	0	500392692	0
352	2020-03-11 16:15:06-07	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	0	0	0	0	500434028	0
352	2020-03-11 16:15:06-07	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	0	0	0	0	500454696	0
352	2020-03-11 16:15:06-07	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	0	0	0	0	500454696	0
352	2020-03-11 16:15:06-07	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	9999997	1	5000000	0	506024722	0
352	2020-03-11 16:15:06-07	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	0	0	0	0	500434028	0
\.


--
-- Data for Name: block_signatures; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.block_signatures (block, signer, signature) FROM stdin;
1	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCpmhUw9dZtXz70SVQinC4_rnSQDHt_UGw4hLvqlbkZKAIgWpgRIY2-L7g0PBRANF1lAQBdFlK20QM1zatqvigdAhM
1	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCICQFkBIwcSDNfrRwshxZvkuQjTJyQzdtiwnGMKfkTH50AiAFSf_UfIJBpa5OUAycRQMXWebzG818R2iWF1dI79b-vA
1	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIA7mNNZOGXXoxZx0bAD4l46OAcZzzzpf72zSMbRA0BQqAiEAsAVg0ga3iY5V4c3_GqKYMpkAZNCshyQckQd7jPVWm8w
1	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIC6VZthKg2_Lq65AKAfzCyEv7xqFTUDN2vu0CoMWH2yZAiBl2UWEFn_FYuDgkg_EwG_p3dNAW-9U6GfnowCGbQOAwQ
1	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDuPMjB3xuBhyDwwMRx1fFGQojr1KIp44iCWBFVMhmQRAIhALtQ8d0kPQk_0axeV5TwoC0CW57yyJ6IceshMPzuAFsC
1	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD1AQMl3sv6a3rR6HqfvrxK_N-M0vW7M2QgBZ7qxKfIOQIhAJoI85hXJthhmLzgFL8iCLkjqnNIACYwMn1wts5kko-1
1	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCpnXlPQlnoM3JA4fVO3Ofgfi5cmXxVTJd26yAxVWfewQIgKkEnxfu0NFLFOqiOvTLnrXf5Xa2fSAUCW9dt383L5b4
2	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCFJrLemSMHrB08DHOdVcodVnoAsLia7ATS7nsOowifTgIhAJ8ieEfti0GgBCuuh9576tdM9WFC-nW6Epvwlac00S4w
2	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCsAQxp7AnooqCmYPUxyHinN0tyLn8wC7L8LMk_469J_gIgQsPD3ZHomMIM631ViMf6yTGm2HhizgL0TWMXSfVVFgQ
2	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCLZDw_ctrn7hbEy4n_sozCxgIHBPUz21k0PCPLEmKvQgIhAOMoe6dkS0m8esWE7_aXYlP-Z4j6MPx3aSaJvwnInB9J
2	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIErmsnOEhmTG_mFcLEFxfubwpg-W4GUwuTgUzy7khf66AiBjYvshcFYdY9fIeM7wXKwpJauah9SEMW9gQPZtdSBwFQ
2	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQD7eX3bCp_F8RYdUO8l7IwYBbz87_HA86MWf5HB_aRLYgIhAOQ1eP_eIxOL6nKeMAj42qPJA5Tokxvyac5aHqPjaP8v
3	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCJ5utck_tUjTT1Q49q91Kyh156DUfzizAkPNwUKaDrawIhAJsWd3eeYW_SPbQubEqj9U9ZbG6YTPEjaAecU_SVj4l8
3	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDsa3YDaodYQw4Pn6ORW2AwL4ilCecca32ryIemMJI2KQIgCZs8mkzuV0-ELn92qYwFaRKWT6jdHevcvUm7pOg64us
3	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDc3aqz8DEXX4NSxye55GZxPURE7D7_UNvVUurJ4vjEgAiEA2Z3xQ2gFdxnLXT3WN9ECo9TiDYQXluKwAgrDxbxYn7Y
3	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDvMQvVun-4_L8GKT95BaeReCqgxGuOigHSc046TUuA_gIgGkgLGY7y_-6MCtHbYFVjrv9Qn6w7rvVx5p5ZT92OaNQ
3	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQC_JUcv4QlffDiEdRInZGXyJ6E9LaRqkNv2ZBB31zLuBAIhAIMpP2nUK5hVjisXBP1KEl1RSGS33KrmTC-1zO_eFpTp
4	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGZYzUuXpr9pI36ETXlIfe-HxLCJ7w_jfutUgMZZcL4JAiEA8ks6d6L641n8Tcq3IJCyoeCUaMK1qLOhegzv5mKN4K8
4	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIHdjimlPzdvBmR-gBSYOsnUuvIbozDGc623eJgmpb498AiAHRV48OJ3YkmG4UD6cUn6EXUzCRTyjbrA8I7lPNQR2mg
4	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCICnVOtFUhxMa4-YJZ7LNMs1RkmZzTFo6TAJcr3NNfFQvAiEA4gPFdt7y5RvwuH8bKEGe2sJ2tmCAm72KLDmYLC2L4mE
4	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCOnOGvOPrbaA9dpWr1gOANGqQ_Hve2USLxhQ3HSZU9mAIgZeScUdhqRvbyNhXMjr2xb20Oqg-qETwpwEhgyUb3Kb4
4	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCL-MLepNWvQ1ooocNBvUvrpPugizDh46pr9wnpxOIiAwIgRDo2fouplUiU_2LmD_b23r0GDNOulYK983GRc076C8o
5	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIAHXMgQs74IC0J5Ij2k7RxuWKq27UgifHZUQLtY3q4KgAiA-lQp8xL-2NqsNXu3AZbJ9Rd3klA6l6_fO9FkcS6oOQw
5	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIGryeTZECcHSmN1gdZVT9ag3Myk1L6yAQ4PQsAebIoMsAiEAi4jVAAs3PKVx5X6J2L1XvhN8yotneJHV-CqdcJ21SLY
5	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCJbUecHjyv6J1TauiEcipDu8Hq8p2I3i279Ylzo9_80gIhANT5Xc8cJuMyQc0c4zsmGNXSgnreewF7IyvrFClaS8jA
5	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCl5lnXUyimzkgFoV6P2XCyNVChIYh0rfBhBGjl7Ze_dwIhAN7PxbamHaM-22M6piIDW2ijI81fPkLkd-ZwkB8wzkEF
5	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDOHxDO8p4UIEQZ3-7ilf2_Y1OzHNZBaU4Dh3uM2l0PfgIhAL3fggdu3U2Vuvjzl1cVTPoH7EHBVc-Wbymdz_SMyXf_
6	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIH0tjtk56kX2cEZXKUpG94pxGby1XXHSECr6p-YtI07VAiBxabffVx0stmQKS0vv5ETovDMVEtdCW7P2b7Mymp1xyg
6	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIH_YR7biO_yy3POuftbevhZnCmxER-cxuKosjaY4erq7AiEAsvRlpQdZ8MqYqwHOgNrjispehBVyZ7F8VahAvNzFtpQ
6	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDuTdaQ9dHG1jEL2T0lQafk48YmH9d347EQgLgyzTPdoAiBFRk66JxYFlS6-4MGSWzKNJuqiGZ2DBWi7e5RqjxSM6Q
6	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDUbl54pmZjbbXjENu8zeeLZtlRVQedM42UiQ8ZIIjUCQIgfLuLWDtgtZ0f9uMh8VNhCwTgzA5HqsRUalVDAtQLlcU
6	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDYvn8fGe4yidp69nhiGWEaKyboE7UN5jfuC2F5eXXAtAiAwFst7XgHUGmILwbl2F2oiJSqNqSYEx0suXvlHa6MW5g
7	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDFKxmkgJE1jdNTPImXpfBtnhVNHspWjjG_BNFg2CYssAiEA2bBFcGq5eWTB7dkzF0zmG8owyrb11WJ9ahsCPoDdGDg
7	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDennTkQ0lFocaDetPIZ4RCbl0imwvUsH6I6fbX2kFQgAIgJBV2YmheXvx_ngP6Plwyt-fY3DrQclsWkmKV5n_-sA4
7	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFjtvl9-5dkU1yGUOzbiA6NGd5LuSPJXHsDzocBgkAOFAiA_0eEB6sXEuQZHfWzpO7ojf2L3Hbw5piYy6akGlsGGLw
7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD7ojAQEtlW_pb8bEnuB06d8Lo8bybIgZp0NW7bVQyGmQIhANpvK6osbIvrvRBD046kIxrvU_jkJHNrZkoxEudKFe80
7	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGOjKPMSxabEAGl8m-K-0vGuNFeYk-ORYgyvvQGrwJhUAiEAlzVJf7JN0geXc65NJG3lKEflcsDcICzDGdcWf1dHMBA
8	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIGyVNoFo8dvkAjUGXYieMaWuVdhHl5Cs_hjv_7_55vQEAiEA7_iclCUwOlEBBZWAiuOvfsAAUFskuvBSKilyFLtKkcI
8	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIER8cZl6lpHvY6jDdue70vsxzwm3IVh4NNgw9NLwb7AqAiA0rXkwv2MCoK_jsrqAl927tyfKbwDvSy92iT-WJgiExw
8	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIBTW0WjTxC2WzMfnxt0IgI1pn-PS8kTe4CD5712nC9E3AiBrb74OFJnSfhjoJP9dKE6Fv4mmubipjtL96nsRDUxD0Q
8	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDCuXdM694f32VKFsPxkLg70ya_1MM2UE2Wrb-4p0zvKQIhAPUzpjLiVlWelLUW2gCCCVgn7AIh8l1N6Ksbpi8_woaI
8	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFrw01N3zndE98-aCxF0svqcy7luMeSgvxkvwZgbWpliAiBy3mPdYl2k-eJjFxWdj0yuE-cQccp8sCkLWHvPjdMiGw
9	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDgGuEd0iXP078E0o7nV2GeI5IkSjx-pIoY9ioqtTUl-AiEA4ooWCHR_2ORShN7KBywbA-UZZY0Az4iar-XrE-5tiK4
9	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIG1fMOuth_kaTPT8wiNx9ccVbty5gMOuRInoEbB85jC5AiAvcO9xB-YCvLHl6fQVym6ummoSJ91eKaSRj7ox1uGAWA
9	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEn6ZLn9mQedvuWwVr2pn-GhTuXsAtJb2Y-SAFkGslhoAiBKieW0WaKAQC-yvrwR-1YO-FRV5s62OOFql_1E3chrRA
9	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDIePGxp7vGy8Y8ApbYA6fNhWPjG0E7ENL0QLHEgYhrsAiARbTMxxToPoFxO7udhxlnl2mtQeaEJBbcjISSEF23EvA
9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCGzXRz1m6xZyvgCKOjyFsKaFwoUnUYE6wdX7MvKufOPwIhANu1Kp7D3DOL4OEKN9MkNNkqau336ZYjoZ3_3JQmKqeT
10	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICEATJbRm-TMGk28S6tQkudMBGXrYY4xMuUINLJmZD1RAiAc4mhyF6fcbVVTXvM3ScgcxqQxdeHJh1ufd6wpuoC74A
10	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD9MKLMfibmHo0xJz_iJuAlAZ7M2jGml4oNtKSyafvqxwIhAM_HB986W717KKnYsS4bTLdYrl24NtWvwLylZX_n9zET
10	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDvc4CcoilBGnd39UCTUA-nPrCWyPogSr8eO9i10t_e6AIgdJCQKF01Ukfbv2gnfbFGsf3dUWgz4nZgBYODcBlJW64
10	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEp0WU7V3af-nTYCf3vfIXcpxLwAU48G1rrw-PKHLi0CAiEA4CRkBcbYfGleXkqbwlecS8GQF_i7D9z3Q7ddaBLURYw
10	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCgnCWkzvjAtknm_RVXImGzrJHobpNlWsR8kvUaaLw5-wIhAIJuoYPnfgla9shmCTG4SJ9HmpNC_g21PJL7TvFV5v-F
11	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDdWe4vMQZxnqQf6wJLEMo_lU98iTTMAFZ_kPnFxHRP1gIhAJFPYORzydojdxdVeo9bUeEdDgbMuVi1l3mHb5q6vZeI
11	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICZBPnnOpDbwYoy3JpR6QA0QxnSncHmbLHx9HYnyJGX_AiBATvkIKryPH3MNrM5PsM57QGINNVD7UMNwNXOLmgXoaQ
11	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDjlTte1bUZ9nJ80Jh3izV-_l1rk2cdqm3pCpJ7ZXK2uAiEAmp4SzqEzyxIpnImEUdJYvMJy0RmxsCwbqtQ6qucg1Hk
11	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIH9jcD4DSTYbJNwhnMp61-AjtZyCdWMl9C9hEI1ev_myAiEAsfnPptoeaIvAIvUysNDMC_39PHLDYWLlZgnX1lLNzxM
11	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCICLj-b6qGT_QuSS_sMmW1e1S1RmVo4Ii5wY1gE5JI1ESAiEAnjlFYRPIi0g0lgcr_xYe00-K8J5lxzeDSkKAtr_KujM
12	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDRQKkYBMwKBPlFeWNQZo9GoZOpqkvUi-2W9shnCCoMlAiB3E7sROE1Pju5pHfqnh9358XE1VWTeuGojxkL8lWdX5w
12	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCICvQiZs9vchb9KXI8W2G0AZtLldZ98OoHXjsVp2xGU0TAiBRU77CZ2GT_0b0pB8wNP3P0qEqgbw20h7m5zrTGUBp8w
12	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIETkoIF4GQUyQwlefxdikWR8kvLpeWnyUW7RYWV-rddZAiEAuIDfnp8017YJkpcN-6m9_fB4DW6rd9mNkSF4aGyNIJc
12	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCxn9ySs5d4tTh-vhP-U2l_ecRHQjbmg3X_YNxn5XcGzAIhAOlcZhuXk9-G9YcAnooOMIhiSfKCtbMdl0kvk7SJZOy2
12	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIFzC-B8Rv-XWqqA701VXIVKhiNY9dWTKRom6IthFACgdAiAGvUxRJhm8RWpaJfCvi_RSegWfhgF__ixCFr5qrnKoxA
13	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDPoRrQ_k33P6fC731754KD5ZHp1DavfgDYqRprkLf_4QIgCKaoEmkXvFAzN8wOX5SgBsVwUpl6T0f9w_ZiBGra5uw
13	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD9G2quOoa1k9aaafhsTuqLXJIr98tg0CRFmxn_2b8EswIhANcuOTNCY9wDr4s7WAPHm_pj7T6f8Z8H_1pkmT5oew7i
13	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD-CYv1AeUOf02S-dy16s0R1ahAd38d29n2fuHSgQcUFAIhAIY5Lu-HTs0b04NtRSesHujgf_4qCeBHpHFZ2dSKlfGA
13	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFAS1qi5JTekAVakdVrlAe54gDPOLNw4UOqLUiZTP5tHAiAl2y09W0YbYzkzVsMZ-r5F7Grbi7PChCOuJLUC_vwQew
13	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCOTZxscx_AabGmmE-61rgUk5A0NQhwg4UUxbdpfA6POwIgZcNA6X6D9bel5XQ2B7600MRp2fRBUUToALe-Terx9LM
14	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCtgSAxlcJT_WvQCl3d2ZZdYrvynsxn5tXbKvKilRf4YgIhAJOtWzPUVMNJVpLz09OKGlkiaAM_h_jsVHOYt-dLjhfM
14	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDS4WkeKILQg0mmuVYNQN1DOvIQi8CXoUMg3RwjRNbNIgIhAOQNA9TEquFAvqbgdjO2ej9e6CRLF0ha0gRkPiyphyvA
14	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCvXGE_A3lpsCqW1n3_59VTIhkkutXzZuisXG358hI8jQIgU0-J2rxv8wxdkcMIiow7gFEL8oTq5Blm_CGl9Z_UZ1o
14	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCa_oFhsV9U_ayNT_KIkMWmRvxfL9MX3is-GQ1zLB2DiwIgUarYIMk1ufTovNfn1hhOg2uU4uyC1f1XCdeewTueH_M
14	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIAYPDLJC8I5jiaO6wP1dyNiFVR2iiJiUgep6GPH88TGvAiEAkBzVdaFEob1qun9AQpb2mk9M3Bt8nl1XdWMYuIubdiQ
15	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHrNQvDtMl5MgwfpHrcy1cKboYrUOfVpw3HhxdNqX2YZAiEArJXOXq-2_kNYuE6MyjyEg8ixLRzHOM-tqbC86l3zIGA
15	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBxq1H8-_QZH6ptjiz_FncCkQwNIBiF-f8pQ5EyQTginAiAvUXg0aLmW7nwfFwFErBkGZJJ2WqhTnD03HFx2MEHSZQ
15	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFXrxGYJGB0KQFGFdWTD9-iFRuPtCrXGVFQLqPf8ZMmHAiAqfKZWge9ao0HBPHUYNf07IlkSpUgJJ30uFCZr6uc4rQ
15	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICgDNJLeP390V-h4JCFXuhP0ITot5IXVqF88dOB7IXVVAiBZ1JXJ3E2wfl86ppBYvT1lnoRsyrtya4W5sXPGSy3GxA
15	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDGMm2rIbu_aF4OvuNsmur10x8wkkKGTlvUhdyO-VSH7QIhAOqXs3gfMQetzToWrJiIbiOeVJYG5D87IwSCrUFY9A4l
16	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD2FIMrPXqwFx7DJ5jzbrmG0B-rdJ68RnP62DiXkQxC-AIgH-1D4KJ_beoETwlJpojv7xd3XiYiSkJmgkdixF__E4w
16	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDM-xUcK3VvwnSRCMBGX5QakTL4C8fkCOGEQiPNRamYsAiEApcW6MmBudUxC8oVEJv6TT4bvP-TkYl5mmiGk7kNtgcw
16	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDl78LT81GrYd73UeOuVgDoOHuk77SimlDS5zkn2Ev6LAiEA069pZ9VtOMFqMi2s4AZLvF9-QwJh96f0LgRWxpA8XwY
16	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIDEL1mEMVv8Zie5kF6uX3grVLYqWaAlo6XawYq1ZTXAlAiEA3Xm7P8-JMy20jM3cnyHbjvEIPJVD3owElwam5gqAl1c
16	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIHi01Ib6sd0toW10X4beVIfkjTRf-0UaICiyW2v9lk0GAiB8aIMYfw9OZeztxqo45Q9VeoIKk23l4bHWqNqPIZRQwQ
17	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCbsr-mwK11qRk5II6xkjLal0g0Jlam7EmyMy3kM7QW9wIhAKAf54XTFaH90I6TIKvcKvJLxWfs-W8Op1wwbQQ475v7
17	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCAHK13eYcXYXWOpTogg_nQJ5V2Eyphohyh28S_nPtwdgIhAJpZwVAz5I77OwAYLMnuEFBeJE1RO14wWe4F7gcjMXrO
17	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDWH1yEhbTkFoSScHol9CUIHg2jumtnx0cRtKbkbYVchAiBqpYCuQITeG7ytcVF8Ymrq4sLvcpcHjIM2j9jgbETC9Q
17	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIGtzceZRisljMNKhT2JknXiUxCZg377gidHCnflQDhWNAiA3BK9Y0NPc6BRasshyQwXAJ8zj_Zkjf15UEGO3u9tp6Q
17	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIFe6cj11EA4MpMh7nynozlp-fth2_oJPL0QwttsPthVlAiA_vP7ZnyhbcLYsvhX49PyQ3YdBwA_HJth2SoL-WvaKjQ
18	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIG8kxeabsmP7yqc8j67jxwJjYelw2eXV_e2NATVlOIESAiEAiAV7ru5xkErUwEhI7R2KPAv_5TwI5weoS0uUBh-Y6wI
18	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIETAeMKXIXYk6TmNyHRDqTER0VdIp8R7JmyudgeLjgUzAiEAhzY08I6dtaK99zlk2PaY0DdQwfC6zLDbAajggAxkHLM
18	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEnc5CwuvLOhYcjQcoAlClxXfK5HUSHunkDxsyXjkV3JAiEAy3cs3Xi9SiiNy6u4xsY-PunrFDhPLVo0_2bB6hlnBao
18	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDjqMBLHibJx3KSXYNRqrlLvwCGeT2SdSHSpjedkP5HJAiEAmx0jsQVHgVzsmFGFCZCni2almoyF7Fn2CaA70wF14ig
18	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIH3sHHyUXxlk2fT0_70v-E1kat_2PR8VYUa_3R3iy3dUAiEA3H9UeRHHq7WdCmy9x9OozJI5mSJ_ebTyFSjmlDZ3K5Q
19	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIHql8BViMllPyQ3kHKJktaHHh5iG2Kfe9lykQFIQXuRTAiBijVuS8uTnYKawGYFr3cSDPXk8z8mtkeHn5mrQqBdKVg
19	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCJ6LHlKscvNCujlwljDzLVBoDu8M6Kobo_Sw4mldQ1IQIgPnLlbLIIRPotvmw5qRG2zFdexLxvoG98C0i9vZcrM2E
19	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEHUagK8bQae6ZZFCwrr53XuC5366yFE8bj4O6LoO0wmAiEA0iYlUTUZ5RM7u3Sr1GsfT2YVtx_SOt41sxos4rudvrI
19	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD-8m0fZNca5M0p3Q5ulXzw7l3WmnvC48wMnkpfU4X-PwIgNCffhDEz8-jIbGKYhXlR77MKRAiVwXjmNElJ_w55BDI
19	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC-xU2AKVuCKd8C4Yu6AZgUBz3clc0yPxnPv5jUaqNDlAIhAJQDJ83JuU13WOTfH7pVheR3fOeMii7t608Te6LIxA1H
20	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIAvtIxQ9ThaxHt5rotr2oMMGBZNSTCoboewxo7ic51VPAiEAllmqfTda8_JY9M3m2H4Mtj0U0vOlJlK34pxHrjM4wgc
20	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQC9FdKeTihYTOgA8HHg1JND4nAQ1f1Hp-dgKqagidc-jQIhANazMkWitiOfi7Y0o1mTJ-r6imaUE8g3p7cNem-BJL16
20	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCCr0qkml1tC3D2pKktVVT7NhMME2mxsCsI1Qtfkj7tMAIgIiQRPeSi4BAK2RiFX-SZnK7dmVtTphfAEp3rOGmiL2c
20	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIHU8UM49GfhzGWCmzmUmCwDsY52bzBQlBJJ_F9Avr5J1AiEAycNty4MsmVed64gDCqztSomS0sQnQB2btByUopH0AEs
20	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBFncm0x-q_Z4p6KWpO1CWGDH_SgGye4JaOkn-4SPRMlAiBY5cpQEOB6Wj6s9PON9GFV_e6rPrH_ulvI_kHUG7_7VA
21	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICItinIu6BGaxn0rGZpmeQEFZpXGUlLEmvn-RjpEQUnJAiAdVtitOsLxGVZ1MS81lSbRmsVBr54xmBCFU0dY6r1Acw
21	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD3Tx_uoDoElAJPr239iqyRj5z8wQ9iO0npsE5Rm5nXQgIhAPkP2AFFk-uU_xak3Ap8eztvvzRiWB20XWMpfPO7w7Sk
21	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEKh25x-tNE3WgJ7yZ23yM5jrydj6N0D-KNYcNNcjTHQAiBWOug9JT7wVjvHzrN0iv_ENIrwjyLurK3s3gbMPkQJ-A
21	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIH2VYrVNEnKweW7yocyHQ6hRNRSsGphpFfwLl3FIiACPAiEAgAXAYt-43fZDwwbvbnxTYG4_yVhp22ilUfhaLeK7hJc
21	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDlNfbIq0aHJAq48juNS1FqRWoiUrPDzCrFz0PdQ-zDHgIgbOYhNzm1LgLE3w0tews8bHQiqG6KLptqj9vtiuFZup4
22	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD4U52T6SX0rGSlubI2CCnXaWw6j80p1raYQ38pF9eWcwIhANZaetX2WVpuGuS43Zub98vHKL34BFRHAXk7r-KpIaoZ
22	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDwstv1eP-mNOJDJ7XPzDwrDmnK7hBhDSpT1xJ5MD1u6gIgTDwQoE6HJuVZGPydFTiVMYmg0UAp5_nAlZV5qn7ky3A
22	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDTeXtXjsNWXALdI6sR-3N2QSb6HqRjB0gCOYQtiJTlBgIgareFpB4z8U8l2ppQR24rMoPgCgG3qZuohjMrIMVte0o
22	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQC6n9v4UoErWqWbyygGvQGOBPDvwd1242uwIS0zqLjeywIgcYqZHiclxlm1YR8s6w1JHjhpFvvKi5uK_qRXWsH6DO4
22	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCdXR1JXtBnrWfuBuQdomCy9sSrPyYdxHY9VLr5wml1mgIgaeuvpR6X5zvw235i1jx1VaRzd_oT7B_xqjPHKce99vI
23	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQD-6fF0UtIunelfB8lUgGZ2Ao6ARGyhj__GUG44Qwmh5gIgVDpQZvmbFMelkMbIxhOB1QyijPWFnlQMiBty5jGqflA
23	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIBNRuBTrUOvsnCnJmL-8O0gotxXvqY_Zpo4Xph4x62xkAiEArW5-OzRjfcjp908HZ5SpiAoKeAZucsTUHzYJ_56dSAA
23	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD3j_yFPlXz0sLP6jPt6fycOMEZ6At3i4a6RSXk6SI7QgIgMOGwDhXBnK9uRT346jtiTw1u57uRTs5fQGy-8adyM6c
23	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCESbHsXy8RPphsDIbfPM597Hg11fO-UpwuaxTjPhBaHQIhAPBqOKIK11tlPk1Hsq4ipSMR9B6FURkLgteQQxRzWdQ5
23	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQC0hKugn1F4-JTQHIgOlf8ll9J-4VVCJernJr8q6JUO5gIhAKo2J9BawGe7He1wD1ufngAoIc_GGWOGKo0IbzGxIfNW
24	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDAGkUk_AZz7UUm_RHIASgRZ2cf1s2zEWQdoUWIKB4X4wIhAKaSUe_U1oQuS-Oca4pTUWwGdq5MfaSD--3CkptpMPa5
24	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHQyfefpFUuC8QF5PB6XPL6u5iX1_uuw-Gc1-co1OAaeAiEA6QVdLnB9SxF3dt1AdCSE0J6Bma2SU2lpesER6mxjIDw
24	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIADiy4br32v8AZNGMgNu4DkepJSLVAl0jQaDnFx1teLYAiEAybIF8AxKB_OVio8hV8iroiTFGcj6OV3H1YscKhBnzLs
24	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC586qUuwCUScvBLVCeuymi_PJpeAjVepwbcOyH1wMz4AIgUw_Nn4T35rnxxYO3ITvPD5z24OJwD7MJYZ0Gca1a_ag
24	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIERT0uFiBHSOLi-wR6W9GwU8lJby-586M0bWZczYqy8nAiEA90irMzpYPZJpG9shDSC6uzYbHi-UE9m-9lsJXfdEiDk
25	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCuXuPQHerBsjHYgtqhRqgH8M-vnHShVz-6XxSGpkTS-QIgFd6c74nhhmamjBxp5SqvzliPZ5hu41Oc-VCgPdatcfY
25	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIH-4Tz2mBaHHK7U6jnFfg5WQ5FuLbx77NsscshsbwU98AiEAmfM_wLqGO6wQ4NbKj7hqTv5E2rrxthaePSl_csES2zI
25	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGrmegZLLuc7eoHKxAiIZ7HzZLG9RjnNStx60_kzgcgEAiBNxu5Mwbxc2S9ViVCBrTcG0YSwv2x3ntEu4LOa8GCZ5w
25	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIAWWsLVoxjM5zylqTJZHbfwPJL6XcxYa8xDONPBtlEwCAiEA6DVQHT2rLivEXzrAJ7oe6XazEQmEViXlkDecMYcNiJQ
25	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBPTS-L4OPySPbv05-jXIPu9y6dJXC0HTMhqY-O3NG6eAiBdb92Co89NrBbiLUpEhyPyhDODGw5YnUSC3yIW9NFiJA
26	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCb-7xKA9TnyeYlhINqrLP6qFavQtk_WX122c32HBfduwIhAO5YFdgbLIBLZTIx4hcfmzswVAJbE7Zp5AD4MJheb-Ap
26	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDJ8vR1l1muK35hvw5XEMEi9pQFkdBnCj90vIBok19kqAiEA4REh8LmwRyJmt_JhJwWo9mh_lWCpdQaxvYWJmfqXYXU
26	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCjfQUqkv6-mCVefMd7qgOePPWYcimZ3_J3OLtSmG1d2QIgTuoaArvPHppTw_y_Qhg8MWy6W5htUpUkya0mKEOD9gc
26	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIE2JZ7jxFUqIC4h_w292_JcuFLgAOpIOvT7TFL-uWH1zAiEAygunPx7VSYE3Hm2F4lbh21zwYSzlw4LFyy1UykO0fdU
26	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHU-ut_uixH-NKgNAlyXduM8Qs5P6fy_Lz6l_pgR4RekAiBgezvSxLMO13071ZpA9qXP4iVv9wr269cAFZtP5TfT6w
27	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBOmgC8mkQBmQZiYUd9ObCkqHK8FigTzDVXcVLzAMrmLAiALK2j-YvL5e8w9oow1mWg9poUcDoBti5CaFsXhunlHjw
27	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIExpTpQk1J4r4rYBjinNVTGMqwjgVrENonStzpVz7Y3-AiA0nOERuLtdpFDscRmKiinAxrHS_o2aLFlqDriS_IxIKw
27	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDLxuinjYUAQ-O9osJXkSulelmZk5keEqolxk-mq0NO4gIgW10WMfUtPI9dpCWYex4ZZHsQ0xeC0efx4U_vlM2iSl0
27	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDxFarIi3EDYeqR7OenzNichqZh6I4ZPxgDNabyy_-uEQIgc0veChVCnF6khpyzdTWnuEG8pGgiNK97agJ0LjtqsMc
27	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCHdNHQJ68kDZwTejLnXo5XMoFQXQo3Ths61pQW35aZCQIhAPY-Fqp3sF3XvLJzyn-vM1FKhsOPqiaJU-p19y_mVZCf
28	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBMUcvwuExtyQJO45IdDJmtM1qVBLY_auJehOcVtMzoEAiAKtqB5Vg5p8hFIc2DzRL1EdRIrnaYTuG17iM9lPTvPfw
28	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBXbCgLC8E28ZDZpSVfH_muqH3R9QxcqemAGaUsXV6O5AiAx32XOENtToC2YllJrZ5RYXzwH8rTlIfHxiablpBk_PQ
28	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDmHQAPccqWRyuDJB4_0vB_UzWMkwYdj-ulGaJk4TtQwQIhAKfip9zTs1KU8kJWZure0i10tgUzvUzGTd2Kk52sKrMR
28	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGPSrwnPQeUI7tzvn6GCYLkFDHRNBKJ6Ss6MvwnS8Z7KAiEAk8YWELRTErwfZiCAhY1KnEtkO5XlGEbqCEKYwo4V1A4
28	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIEYeNc5ui3ypWnX0Hkh_o5Sw6YBvzq3dIhcfVYoA1R7nAiAsBQ33plwgdpubKz3_EzjBBrTkRKSh-EDrFpBBHwArMQ
29	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBOlBGNzAaph2b53OfAoCtPkszdDI4TkP2Si-baltYAvAiEA8HAAJ0Y95ocNldKxOPukfpHnmnKsfVAWWVEApY0acMw
29	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIHNjVyglRGa-Gpf0SBqJJV0S4dAtmZ09LU5Vn21RqYytAiANayZGtZ7_k_5jfSfReGvoNRj4BO1BjFyuR876TGSROA
29	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDpXAplGHec92H9_p1jkiZpHdlmHuWoj7It56HNl1C-wQIhANugP9R7TLsd7hJICkiidSYmzwJfonUkKyJvyVC_b7Lh
29	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCID3eWESGMSub8rAovWuXjZgO_ANkl8jlRH2kePqaA3vwAiBb28yRgBgk2QgGyzLadujcxCXm0gwoGUOKcaV8jLmfdw
29	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBkpOV7O2wT-bZVqKHSCpFPHrEIwrH9CZpwh1zx-Vl5gAiEA6AFKdAWoioi9eYtADCUlYNpW28we19SP-kbUKfDHyuM
30	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEcGhD2fSfhI_POYSHcuKzvrMm2V2ZwQRxTTZDIpLPh7AiEApswYIFUS6tcpHPqLJ_lwXv01hd2TO1FKDZ2w1teaWhA
30	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDcp4FGkvfKq7KawF36vtuFUi0RhkoigT4VB4AAUPNnHAiEAjIGWNy4AgDhzF3ag8ukrj0R497Eo4yFGjgGwol0elN8
30	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGWrbgPtel5s6YLZ-tVLueyFkSRnZrV31Z8gFR1BmFKmAiBBWnx5URiy4IABGuvhdWZCrZxZrNVcyY4sIiWBPNyKLA
30	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCidyh5_FRcN2idxGWUXNNxj8jJ-BiInYV7bCcwgrgWVQIhAKN9SICSU7MC7rbSjezNvAR-bFQgMVVFQOayDLl55evw
30	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHMNtO63crx2pwwe6rgYsCzJzD7ImsFEr_c2vhjITd_1AiB6yYRrCeV56DxjP9M2vkPx8PVnYi-4dBjJCAEwn5ofmg
31	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFa04M5IGXvXgzAzouuYYcW5MvyInborbC5_8lSl9Px4AiAFPWiRqEai9KNEHokEyRUpkNVkvF3SVcxXuul3ttZcgA
31	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIBTghC3eDXiSzU2_Cu-GJiALbAYsMG0PPu43C-vonOqbAiEAxlD_xRyoq8d0hfOLEEPAKTh3xnLp2cqZ7l4Gcl6Xx8I
31	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDz4JqOEJTM7cakfKn-uAAohhnPrTWvC8TJn9GtC0cvhAiAXOND7nsXBHH0Pj3htavqTHPPRg3ceIHOes9hmu7HxgA
31	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDjo8_6uHD85x9WmdU_wg76jv0usjAyylx_KwZIBnBAaQIgdBwY7uEMgbmjNFG1HSJZEDB1irmNbzEl5aXCIn60HV4
31	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQClwHEuG_8ohY1jm_CgYFb34a26qZ7OLXqobj6rXAoWzgIhAMV2ZXyaK2Q9pdoeLGZfMDX2XyYwRVppjrgD81Lyb_z5
32	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIA-dTWG2dZGiR0jiOkDQwKuzfATDQbJWoOc4Ow3SvHM5AiEAgEK_tJMEd208ihZwF0490x989RyuwT9uV2XgJUsYL9k
32	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGH7bJ_I8Z-o-R_vwQ2XLbp4rLt1yMnYyDYtj9oUp2ESAiA3q6QqQ3Wo4CtKUtEijEBWdkT6Y14LhfTXsAReataj0w
32	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBMkmzDjRqjEHe3wyd6vJJABoRNnv5FnsySTdqIG3bldAiEA2xUT3qq_5K2_OUv5ncbOk6Hn_BYlDE56SNjG9_U2Flg
32	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIC8J5yi_0t6jaHW2sgpp4ddJCOqRj3oS_4xeM4zESC9eAiBJXrmmn1_xHrenC5eN7Ew-WPJBhvC_zpjqf_2yydn8Lw
32	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIDu7psY7HDCUTTH91vghVwpy2kqCsRvaT-tJbIdL-TvyAiAtNlfASitzfSiYhEaBVJVSldgjkl2AWrBFNmVppY81-g
33	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIAgY9fbkWSmMy9OPrsI0jPbe35vXjZ9ZEi2EbYVCq5vzAiEA34_VvrT3HmLRgVUjy9-cPzex_ftktfM23BxNfout0O8
33	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEbfKGn1bP0YKSNmnvugu4PHsmQkWwpOjt3h0peALcLnAiEA08Q9vtWz5c9Y03JLFKxA9JcB9cHM3Mi3X3NQv_-Q85I
33	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGbNreA-z0ozIknptALxvAh4n_MGu4Z1IyXUadYOBCLzAiAKQ6OZtbNQvGUaRkos5vMJHIkVXKJXl60L0UyERRx3mA
33	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDddwrp5oYLFsqb_S3C9P-BpCufy_-aYyEvRVuW0zIxWwIhAO4bfuGrSy9Yg4IQREHarNML5OBcRXdA2JJRqZuvIbBp
33	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDEbCo0ym2ZnrmZHIdbnjDcmA5u0KdiJLiHWVPRF0lA7QIhALZEfWiSltTwOXSljR2XlzIxerBSsnAAELKHb_PARtrs
34	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC8GccfezqIhbxt3FsJGKXnDTC2VIMQ8cg-Evffz83tLAIhALrY3MNcKxhniiyFEpw0OhNYr3_rvO93YsIj6MEfCyRn
34	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQClg67BNLzNlVfit0TVMbS57LYiVvDTmquqLJUBTE_KcQIgOypPXId5lcw-vAfCNCDRyrDeh8Slh0PzKB0oaniiiYE
34	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAVkkafwoAVkJQjQ6uCafhLApS3_ivIoqKYc6mgYaP2GAiEAuONWF9s0WpjhIRnkbRPuCdAP0vvHjc-lBRfk1SQlJgo
34	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCjF0x-afJVsWfk2Dlk-9tiQ9zEqnfqrpDJsyCnWLrz-wIgemLO-0DW-513bwHz-s7jIfFG0MZImRCyXtnDD0nSVbU
34	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCJZrq2D1kTsBq1QsEzRJJ5Qnv08KYESVQ8FIZemzsfUgIhAMmOJSvRO7RDdqJ3xM_k87xEnAxQf6r4pTeRcB2Tgn8N
35	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFCT1Oy0aFAA36vgNiQj2vFEc6NP9QEQUeXz8BoCtsQ6AiBKPitUiHw3Y8K9SVDdGGYLSkGCouF38ljTfyjutb2VwQ
35	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFo938BaQLZuWw-oItxSxdD4CbClLnxPaHMaWv_oCRfIAiEAlhz0tT05GWBMG5QjtY95OsTjJKiQsEuQCLb6PXwqmLA
35	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCbQbqcgGr_0dD1necpryv3mBGnACpnq_digw4k4rFEEwIhAMFbvPOORM5i4p-OJTeG4hoZoVpGGW2TtHCn74_nzHe2
35	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDhFO-r3CI8WIKW5jwiFblG0Q0LRSdq4_ZfEDMQTzgJxwIhAP_ysi2bWhJ34_WlAHgh2SiaFhnwLXAMNUvjURqNb5CD
35	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQChrp_eMlTAYGb-bHdOBMhobryx1qY3VzDYAq7LbhUCtQIgJiF5-y_dJr1YGGa8CKBqf6vnFIxa9Zm2kf7NLLjI_dw
36	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIESQjCcOTzHqB7obwM0fG3maVC3s_uh4xtmQLKmcXc-VAiA3PY0hzpaCzAavVW4XBq2KbHtuVq1HFDAkdC6T-OGGKw
36	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC-OfDOquL2yVMgW50xt203FW1Gfc0hl2l0AvAVLwDzPAIhALYG53sEKCyqcEBwjvAQa8bzw70tik3ze3sE7JWw0KR2
36	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFGc7pfUWs9WrwPLFpP7kULEQzbAAhqsz6tNH2FE4QY7AiBs1qgxKokLH469Y6DNua0Cg0O99K7172x-U6gmbxF67g
36	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDkBn__LWjPVPD9WXbjyhdIzeX3e_a3C018mMW51hnWMAIhAKSTood7A3AiktOqrXh6Pbt8QcriRlIn61tO0ztqLc47
36	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCSRRlOnHUFjuNrpoKOK3vBmNsR0Zxsyo_5Ed57mgY97QIhANltOJta3gQhqZP4WyK1DwZSeIYh1BuuUHyaP88l7b4j
37	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFYeP42G-thYcabdmBTamP8YYG2F_Zzsur6FhdvgjNsPAiEA7l7UV8uYXRDQO3I81oj_bCV5OsvaYd_V96-xuit4a4E
37	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCKVc9M4bcdzFj7T6kpjLiRIBrBTEcKvjNPP6i_H4WQTgIhAOwFsKs1RaxzFlTX59371uK9NR52q0Rui-bYQsuvcCVh
37	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDo85Ki5IKbBlJ0F_0NdnOyM5KjZV3Q9D8WgNn3iomvAwIgQOIOl_y8LgCmdzqXAjHhgGmSuw6pqtbAsCXQz72AL2E
37	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDwBuVy-g09asw-7pm2AaHGAfhpAPdYgnNBPr3ihw1FYwIhAO1EW0vPtmPa57G3FqnnRJsbD3-3SKXhpjHRNrOmyI-A
37	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIAZT26jWP4b8yIf25gCskctHJ_1Qx7mvCu8u1rU09mpzAiEA3EwGWZ96rsvOn6XpyadwJ1OYk5kl1qbeMQ2PXxRkKqY
38	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDBr4rW4JvxjmzbmPqoI4iWPw49pD5vO5VadMguoNQc0AiAEf1N_4XccD_Zj7gS6xVmKvdIRThP7kySKRUu2yRG3IA
38	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIG2-yrvFq7lLWyV_7YOERWB4ckodkxE4etmzxo0PgnCpAiEAja1RwqR4tLaVc18ZOLutyPBkrOZ253tXaQ4w5pZF-hU
38	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCICT_PsaQf5dFRhtkuh69psDylfEecRVkkDcaF3sahR-LAiByMTHhKoaSJHc_zfRYPzxIWAo3kCRsq_DqDYjpM2wpUg
38	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDTzAjW2K2_JKOjbbHDe5KzsdqTFiSABX7Vp5Hq6KbeVAiEAsr0c3TFIGmXXa-I51CM6UjUMmvfJOpgBGdnwq8Ayccw
38	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCID2esId-81-KWR62kiYjpmD1KbdCrymC5JdqfoqeiWMrAiEAlnGF2PqmPK_7oycU2awSdAwZsP0g69dMZO4AA2I4e7o
39	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCID7cJ36HF9_awxr1RuAjjoJM-pLTV-yyilKU_ik5DsuWAiEA6dE1DkpDJ3sz3rTxYolQBvJf7K0G3i-v9TAUvoiT_EQ
39	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCLN0HswypkG_gIqq1M6RV7MYTGP8yGhacMNFNtKjnYoQIhAKhYeHDBE-_7eHh8UCUgvFYcoSz9MgfqnVSLsx_64oRA
39	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCBYIss_OmhhfF3hMCqQ-eJ5_rFomiDtZ86GTsw9WAXYAIgVoro2UV8KYxvhYHsS0Zf0x57tJrHhkVodzWShg2J4v0
39	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCBk8VmG5KL7Ef52i3xq1uiJLqvxHz5h4INFpJ6Gln0DgIgFTHzVDvLBkIm0kS_kzyQd5kdD7zxcJkueYNpBic9Qy4
39	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIBW62zyRBAz62q43MM4mRucyLzRJy0GF9n_5gKRoMmf3AiA_mcd7DB3li5QWVGIyBkoyj0q1eGT-db9S3EU5afpZyg
40	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDronOBMAoFyob7pHqY1OuAvcYgcx3JIPGRUbMjNO3HxAiEA-m-2mZDCxTi1TB3SuS8d9lZK3Qdgw7gvlD9nJRhJ_-8
40	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFkVvi0m4WpiaAmZFIvaLevKaW_VtglKIOYWyeTr1qgBAiARXrnaT3iw4S5_QTMOt9ViTEBd431QFCcUO2OAPLwqqw
40	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIC1KSFaUEHOUTAkY7omVT1q7-NGoK1AvX1wDgI7c1J8CAiEA8k_uamhht-haV61Cu88aMHREU-wr00JQM5qznj0Izwk
40	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAjedOf0lVqwE9LOETmpPbB3U1zd8RsliAGSvDP4ngzuAiEAyqp-9vVC3SiewJgjmEJg5nLhMZCSicd3l7l610Jq4GU
40	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDm1M-zcHHyAczlFc0NxgVpEGnb4JPXn6Yv22qtRsIq7QIhALYxBO-cKh31BAlYz8pZjWjWeQkasNwZXf4VbIne9IZw
41	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD7GTqMBLQVw9R7Y1c-UwrST-5Vro9JkkDCmTh3oMPZhQIhANuY0ock7KoJFARSe5uOd1FTM1yvtMW_vjSZSw5pOQ-k
41	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC0zw7TQy8cVpd-HRCTDW_DVTNG6qnz3UgcCieqWbOWKgIgIR5wjM3s89k6grU9FDNpTuxPeMjrLZ5ODpG9ZySjMpQ
41	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDd96C4T3BnxJ8c-qCJEMGedVwd-GL72VDePm_ZrC1iIwIhAKwJWR2wut6t1xhdR0eaLyFdHAyDtv0UtNWeiQvh_2EF
41	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCMo5lXRTPhgFycssLNWWi2sbyrLIg9agV1ALhYSERbaAIgBdBVxDNu37GMerPFcQk8qYsAJfe65-boNQI3U0D7z6U
41	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIGRji_BuCCm66mvSWH16XE0Hu10wskuLSChgS3p7dl7RAiEAtyKUHdtM2xKL9u_EjK-BSVYUkEQWE_4YMsTAkfwQRyg
42	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD5aVukesdyvdtlM4kqmLiCJxDBIm0r5rj1pWkYAROoLgIhAO_qOTaya8ya13wvXYurOPE0f1tfcEEaz5CeP5wK5bb6
42	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCfvKwZaEJ48M8PP9YH-ZKETiBFPuXZpFjakAA4FWpwnQIgW5n-iITkjY7JjL8WhLeLpOH-9JuzOtZ1ns_MdCtK7lA
42	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAltzQd2-Qy9JSUWJM-Z6lW0Au4_6Ls_scxx4Ls9kr9xAiEAiMdssJBrKQbKY0Cj0HQlwCdNee-WwSatSYGzPrfKSxE
42	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIGzQl5eRVtQyDXqUrrI_AnHpl69XLwu7ohwz_-wkpee5AiAy5TW5Guv3Uka4NFXcPaMvWmHaUTk9YgLoyTZPvLnIsg
42	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCICKQDx_5Ur93OqL7AteY4zEEc03BlikKcG7WxeYxNV85AiB5D0uQstZvqjsC-ytJ6cZHayeqGOy9P9KyYENiXOjX_g
43	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAYZWghKFxKmwHNBJwcJNdagTWZOcaCOZqr4Jf7EbEuUAiBaIBzRNayUD-PRogjzG_95QlUTCv23frBVzEzFiGcnyA
43	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCEDKIF7-WYaHNOy1Jahrf256GHQsbMyzn_spJYXuaRCgIgK5OZ5k6Ix1lRIJ6R4R6iPsF7KqS1vlbxCRq8FvrouoU
43	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIHBABurGY51XxuKpim8h3X2ngwADU0ehZmlwIVfZEPM6AiBjXOjhgo668v_Y_d7IOfRn4yOnbtkG3rgZWdyMemOfYQ
43	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCUj8m0u1mS-pER1eZP365xv6i-yB-h3TREQo7rXFV42wIgBOH6lW4N_15pblk6kMmghDXXvS16aoRtTHm_bq_83sc
43	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC_7Mw-cZcdW-fxmDQGpz_Kqs_5fcFyzFC5dXosKh1h6gIhAPy8lZLtXjWoglbyb1CEtz1lkxb40yDlv-PUBgFpXyij
44	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDy4NfpaMxFWXyLOAQZ45VBCo_I5xaKDl_i5i2Lo-praAIhANY2m_0pky058YBjyLZq6o1UyzXksPDing9B6bBGWRIN
44	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHPdzcCosKXazHsGRNxzErmikgKD8XwBpmrmkIu_58hjAiEAuhdV-SHBjIKQdbiQfvYLkjdKS9SKSiRVHFlWV2qMg2c
44	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCuU98LolZ_jJSWQUtUZmGjMNoZsNpWY6EgLN9-UOI8IAIgA6BizklUb7f5LiioTBbjx4Xl6-WKZ-qMc9HunifF9AY
44	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGENQVunklv4V5yiHTE0RNpcxk7Nwu9lXsCbScQ5bYZvAiEAp3AaHydTGzx9NqIeW-rCesoze3rEB-8MoRgNjRknaiA
44	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDwPq3W200E_fC-FAT47io_dwsq-Fqyp9bSelMItH00PAIgXL0Vq6oynYwmWdhFEZUOWKb8hACtDJ0dCXOxHD3rNgI
45	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDs94Boqv7_4n9xd9KVUUON_qR4ez1zu8Nsg1E2XlcR0AiEAniNH0_sSGiaUxP2PPXTSfihZBwzEhLcTSp15U5theqY
45	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFGFiuMj3bH-j9grINK5_xS2Z563K0fZtINhVX2uLAchAiBaGR7b-yi6b7PY3DZ2b_ysdgGAROkKlMjPypUu54S-7Q
45	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCXHDtuj-p37pBm9UsGfs3rkWAyCMZTKNUlLLM7eixOYAIgLmXGRhtWUJSYFav380-3HAiYEe0zAzhfqh0fC-DO-qU
45	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD9LySeoLbbTfHhRbQokwE1C_bvmTjXmzeY-vWr6t0TMAIgeYcreELVPIDPo-a-oWLuJd_Bw0VLOskFkgZe2cC0EN4
45	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGACiaH43YvWcxM9RjGdWgSgSLajHJ-8BTfsqlU0ekMQAiA9knqqqRyGp7NrWIGp-gJF2Klub2IejsyoLgPXnAsHrA
46	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDPW6JO_vJ0u0gQWyFm9b5TgyGODVB-hn1pPHrGtcwA2AiEA2tTGqW8WSnod6dWmaykODRkbeUCqNbg-wvdaXtNfyFc
46	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDpJUJEDsIOiIodhzy6be2B27QWJh-nf_vBzysjh0dKogIgBJmLhpaPHRlA3cz7vqcjBbZuv0k-uCEJtGcbXdwZZFw
46	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC3TFH1Smt6FtdnuSiWqw-UsYi1IyIALwWk07WByLVWJgIgODz1akndH3cTRIvGnQdPzug6gbO6rxIFJRlM89np83E
46	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCICn-olSuSTIdrWQMt89sEJfHzUlWDJyPrjzVVz3q9LWsAiBvsnr78dv9Hr3lad_Yyh3SQ-cIssNJJ4kHOsCI5EkqrQ
46	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCtuU9KxSv_G9gCeLk9kUHCtk0ISx3LZdH5pUisEA3cIwIgG3Xk-4cqOTCtPkyArH5gFhZbj3-sVq3-xl9l7auOd9A
47	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDpG5UoViNpMo-jW2NTQ2WIUT06M_RPilh_2KkXwrD_RAiEAonTOAb440URRbU4NARjQKyX-2HE4KESrm4TeUL9-spU
47	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCGR8lXHP436_HKRvbJxQFb91tkxO_Cn70npvvMGGSMMwIgXh_bHizspeAsMi1rXOcvS1FobdAlZk6XSo-3qJ3aUfs
47	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIC4jE5G3a8nR8Q-24jpTyOau6dhjlIqRw0Pf1nbo2JKPAiEAnMBrpWKr3aJJYyvpqjMblcp5eGmAEzE64D-9YZ3ydsk
47	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCT4NGQuiyBavZYX3SkgIBlLEaXvPxyeMV12KEbeCg0RAIgTuKTOvxPQ1RodP7opNLGcH6OJpfqfFd40rg6PhVnSs8
47	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQD-I7G-8ZbR5m8ranwl3TEoq87ZnBBsBKJOkcc2fW2aEAIhALa7xZ3PdTVlQ5wccI8TlLFSEVjbIwYqr1Z4xPY2aox1
48	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCUbILU7qeBfjkYISQfOSmz3IFckQvS24QbPajyRA_9VQIgMYV9WKczicHJeRUGNFE0dcE_Fiv7aDfcM1xsu-wk7NY
48	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCJ9Z36X9dCdU-LcozulD0XXyEOHuRIf_7l3qO_O9mFpAIhAPaSge3KsmBY7_5R8XEijJcaQZI4DCKTsbXi0fStGMGd
48	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQD4nfzLiHFKRyPtTIFBS3-Wb6YIFJNM_81dgRR-yihjIAIgVPiNOZ2Bk-tghtrMyFMrVUstOKzxDTqjwdGbANt5IwI
48	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC9BbcTVuox2hJNvAgs_2d80j9WMOZnjqAIWahDqc20FQIhAN1y1a29rgxFLlSQx1bfRr0Dt8fHkxdPO60lvShAx_IY
48	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQD-Mc924qsu4pq4wqdiVEmQ8g21GhpEp_YCCybOTJHGbQIhAOPW-Frf3l3dFy44ngzxiqybzBp9lwTWHf-YEp_WRWpU
49	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDjoZLa7on12RErMbHNiU8c5BW0XMj--FL41GXiZLXdkwIgOhZulhgZ0VBfsE80dSDfdgmv8C6bYM9og6neM7-EIX8
49	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHrKdas68Svm3oPKswiohIElyOOCJmielTIOlqsnxNt2AiEAhE4A9DpcKyGBbB-COJJIj1FI2MPHAP7haa5xSJ5uOmk
49	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDjjLEQVlTuTfYHf7cJOFcIk8FrpDIBt8kX7oWKuOrgVQIgXBfwdKjqMgt_l4FFZ3kz2lUKO3LrJKjcSdDt_eTn_RY
49	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDpuBlaLirkhIAiI_m13n9VCBef86RYoVUs93kEvgXA9gIgWryzbxEywmfNCa8H5wVZG13JU3tHyqU6S_8bXQls_u0
49	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFuBdVipjsBJ8vRjVWPFx-6ZxDwDigV1ddsKzCbAT-HMAiBHG5sqK_qE8GcjuBjwbnMn31BVNZ6jwyPMGGliGSQXxQ
50	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC8ATW9yU7LDbBiFUk2Z3K62YG8wYuitjKg5qmugNKZ_AIgaQX_iQ86CtPnxM3jWt7HkaTWPON6t-3q8sT3HsxWd60
50	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAh2OghQYJ5Gvxh5eE4qOEfKoa9lEqOa01Moj7lOMN9IAiEA-yPHq0oWAncHq4a2WnFn2xUINNq7NItMK0Dco23sHRg
50	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCaY-khmWDoXyrXhWbPONpknpjp5Qm_D2PLz793_7U1wAIgD_CwznINxDnSBNdtdwP6qLREnlRniZnFpo1w-hn9VJU
50	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFsSV5GR4WfH04iM_Cx3Qqg5VZPptuXoWIGnGbL_nip5AiA58UAu31BxDdCdYJ-JjpoTgnGODSP5vm5ql_DgD3OoDA
50	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDeNVb2y9LD3d_soRuFTv-yvHolHRdkDfRyUvsqQxt6IQIhAIXlSp1L2qE9tO9TesWqvK8Ib31aYQlwi_k2Lgm83bHJ
51	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHhyX0IiKvd7NCuBvwXYXrEaKL17gzMlklOtSwUEA9eAAiEAzRQnEftMzV2nWw8BAtw4ugC8S9IbI21s2XqJj6TFUsM
51	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCwt-OkNaeXYJ66cnnQiTJJbBw0GrU9Q4KWOH4yUAxpAwIgZ6Uj3YEYCngw4LsnZ7sJCvVXTM8apVeUc2wr-YagRzQ
51	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD_fdstyNODVs7vofpoIwmxIJM0O0h6ALUgwd7UyMKMBgIgNDp1M-BdN1w2aUG4Mp0onGyuXJ5etgY0QFc88soXKJk
51	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGsSYIipTLn7p2Svi4n5irVvdFIHt8ZvWHd3o-ei0AU5AiEAypL4kGkVFfuTXbosoiYB32dHn9FyALj8VaSdJqDxybM
51	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIAfrZ5IH5C3l7PT1MttpQ5sBVZvs4dJ6DH_wmalCJOVOAiEApCmEKrnRBAV2p61eSnQICPT_t7ZXfetzTNQ4rACvGcQ
52	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBuR77SZ40stsaeksH3UIIoPP5JqIQ4tBpwEYx5V564xAiB1O3kJ1G8SrsGNiI_HWVZfl7aPek4rlims7Gl7coJqPQ
52	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD6kCdNEVD124zsIbD_-THweu5Lin6g5BMPJySfGw434QIhANe2B8hPBddfG41xg47xZLIFvgPxPpd7ZR80sf9Wyy-y
52	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDa_qhPMdHVJEoA-bBb8CPX1S4NwyT84KQIdLenv_kFGgIhAOesuZAAw21Dm22kwdG56rD52A4j_JBAgcXtEIQiQivy
52	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC21t7_JbE3kSM7l39Bcc30iiFCyZOgunD08tIa3wLD7AIhALo_FUm72LsJqLJRieR0xkSxqiNiTJiEUZCq4KpmTg1_
52	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD4iqD5s6fW1H_ef-k0plzMHSdth82VvDwCn5xF7g6BtQIgK0x7gcsLmFGt6qZMeZA9kUFHAw8JiNtI3LVnDnI8kqI
53	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBZ9yiYGnr8J4Hr_AHAYwIf2dmBES21VarNmdwf-hQeRAiBKoCO7W-Q1OIx7-LsVkjmLhOoeSz7fPopjB_KvZ-we2A
53	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIHbNBQYpJIbD2KpZCWqNEi5ClUXZApQ3G28u-d9hfDgnAiBJCIBW4F-GxYLMPEqwaBngAaRWkYFd-ylV7SBNl0lWSQ
53	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGslHRDi3PQpL7dgts9joZjdGsqCsmLWS3U4bFEL4aagAiAX60dliviDdGiw6hzremYLXBTj8kkLMlPFq3VX-53RLw
53	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQC9gbbgdc3arLpI8vaXGDhdl72DUMnDpttyLLx_l-cRkAIhAKt8sQoxSmfOqZYR1I0y4HZkJdAGq3zymwlkn2IASJHy
53	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDY3yNve52HYOjVH2A2Ghxp4bx47v4uClbhECvbfWPvWgIhAL_gfVsCVUSXb1My0fGjExIhDGAhjkWVe6nqnpDIclhi
54	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCNYB3P_qL0Xddj9oDoLtbnDKryyQw8TpyTrrwfUE84LAIhAIlx4DlVZjlrwxsLzq241esdaSi1HWbthdkAprvyz8en
54	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCesnZxD2oKfx_fH198P7qR1gDc8inxj25b0mfWFzIT3AIgO_DY2cBGfo5Io75bFlAWH4-ucPiyJ7v_wotu99qBc1E
54	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGRy_kUxjIB6wPppE7mG4AlmnC9M2Qv5h4_04F-XpCsNAiEAjQD8AwrucbiEhGaBQzPvKg3go2N50KBEHTBBffiYd64
54	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAhbcnhchfEAuFgDgKTSo1sIT-9FuSxd6puqmA40dZRNAiBIrKfFuH60uQA5a9mRVHljiJIzmn8H6MjZ-_ftkMvS6w
54	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCbF05tfQfj1yfgkUrm1i2iDe19RXZKgjko7d9AKtUCGgIhAKfOvpguQul3AChKzWVW6w8h8HXzCmcQY3_vjbftLGQc
55	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIET4ndf1svJewEOjPW49Oo643CcNYA9SxMPigD6gCOcrAiBhISSKy97M7wdqvYGQ50xy-1kQWz9gOK_Q-uO1jnthGQ
55	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDZp9LJ-IDgrRWRlnH0j3wfrdKxELVL9yOfPxp-zT8NCwIgdgkxdYTtbx082ijlSWZigtpksREEid62uKRggFWiACk
55	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD5pgzcHkeltIkvATCnE1v1BSQOArSmeIjNWK8p6BK4KwIgOcX17QkPdzbKy2N2Jh9cqY3OisXuemh9aU6jibvnNNc
55	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCsZfFd1fjG_5tIjnOVx5xa8A7oFL1-5FyKj3ISl7KrjwIhAOn2kc7hl53bQVxmmUqCwuxZY0Vk5DfZpqo40aA6QgSK
55	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDskC_7z6Ky9m11FpNOaHTxtIdohglGK7uEg6L-QkNxDwIhAPN0cYqcZ8ETFl9vbqPmeDHBoKc01TA3WPOobvmZDOVF
56	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBpBwIzv9R0RJwX4aSpZ7576QlJYQrhb4QzvAZF7hmLCAiEAzRSiHY44YRbPZg8GxFeO69b4s7FP669LX6zMQHik2dc
56	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIE_reBmr77M9Y6hRT3d5NWQYqESl7NvFBJsWq9Cm7OQ7AiA-saiPzTMYo9nzsnqzlw4GL4X_Gv0x2tj3UAUrCoF-ww
56	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIFABrAM9spvrw2ceQ1zyMA4qOHZaA_n9rJTYcw5NTCFpAiEA4OLDdLK7XlqznkJtO9zaqNOzfV1syiLIR6CsSYZzx7I
56	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCp6UfPTsuJqUGuB2U0VOOYCLES7D0R7WFFht0IhHZFDQIgWR2CJyYIm-WxbjF-eKxJFPKbHhn9sY5fG3d41-PoGJ4
56	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDURe2IdR_03ykl4AB_Uf9ulRGiWD9_RBKeZ9wWieKDxwIgRLClenBVUE9fmTBLUgfM-XSXTa8wvdl12c7SG1e8FhQ
57	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICCPEkcKRdGOcZ5P4SmMvAVUavWjzPOUNjQ10W52G5-HAiB6ojKSLp1z66lkWskOLJPqH5bXdbHrxqaJM1J2S3BeUA
57	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDIGT8nopUbpnX_2TQfJwJmTnCPD_M6FatHXFTRSxwQSwIhAI956F32UFDxwy48tuvN-2o1F02mAaguXu6EaxQT4Nvo
57	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFb6qv7beTRP_szE6kbdfkAtk-y-ZJNXi1QJ3IhofyinAiEAjs8AO4yViOj5NzUqTRKk46-wZTPXBM40ymAF13c9D64
57	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDwN4GqGa7KF6huHdNb8k-IwKg-z2XIDdlpS_xuHisO1wIhAOVUGHMkFK6IX5VTcRcpQ8WcwgEC8zYKVeizmVwWxbzy
57	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIGf71g22bwaUH7fGIRY8ISJTJQAU4HPZgmJNVBtEX0mdAiEAt0NcRCU7M8lKBcp98xbtux_pRIS3hYPynwPmd4xreJ8
58	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCgYJI54YzAZUFBPXWodteXWngGeXAzBVtWCXX8o-lEoQIgStmgmaDwHoCnd878x0UtZ_Rr7YuketaLcVDgDh5KNmc
58	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCNGbnb06mf2Ptrd8QkVsAdVWuYKWSzNmQf-kKERmzPSQIgQO-Uhzg0JIpKju7wKm9yVhMj16seLuMfKBgcSzmpEjk
58	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD8kaMN8vSDNUiAheatU16T6QA4LpZbQ9KJdquJye7JtQIhAMXY_TxhWJTZhPzms9SuJ46hosyQBO1gsEn93ncW59O-
58	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDEWpsSFYQ9WvftcoIRcQ20XJW6kylzCO9cFZmkOAVSVAIhAIIbiJdctuaakcG9CxlNVo883FBAnAZdR0kyn7AvMOTv
58	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICYv5vH8hr7idfbUTVYrrU6uT5aox0HMRjFr3rLKndSxAiEA2kj-JjZvU5XkI-bX1dRfOXutsg50Rj6ybgOT8RmfVpw
59	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDiBGkkySHmPfC_AhxP0ckfbdbMlQf-rBX-fPXAOlBRlAiBUpFei29W99vEus3Fcv9_MPKLbfg__jGK-iHkQLPdGyg
59	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIHtbEt8iNHH9XzD4t1YhNpkfIE7pRKVg1FXZAPheQ8LQAiBS6s1BG0wHvLTin8yxKVPnMJSzxFaHW8KNZH54vXMKIw
59	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDHGTdO6-yn0tDoZS4rm-_C8b9BZ8qfFiM07prwc6LtyAIhANwSQLehaON8r1cWWFGUlOrdGm4mj5KyptsAPgGPkw-b
59	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCICD8jRToFqbb_wZY6lt61i71ZBfedRbhd0EyOIMFKfRSAiBItKaEWdhk-kdyHoJH7BxFmLd0kCHEx1N7qJ-zKhaJMQ
59	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICpk11n9BCdBh7fvTWN3eNVABiBwQdktMi5KTa9AHnjYAiEAkooMChszfUDYK3rRbX8qDJE2GY3ZC3urPq_yvovsyvE
60	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIF_YMFtTIVrQ1WXn3q9rMAuNuvaA5TuSFvwLq5k7mKfEAiEA7KelKIcfoARA7eWfUVUIcI2_2Q2qIhmi8dEzoJg-1JQ
60	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCvp08hDLQX2jtakTPQ9fu8s8QMQTkG8YUMVSvsGaGwIgIhAP2ouMJ0P9riQRdU7zy0FN1zQOKVyWubuhFZhmwgQdJg
60	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCxg-xvmCaChrd5eqesu9pYszQCYyh32FucLlcAGt4MtwIgeWfuvT1pjaKE2uIVAYicJBfNoLSmY0FoTqUh3Nl4XqU
60	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICPAu2YA90wtROD4w2PlUc2VYD2TNF0QLaZ2odILtLBzAiEA_Wc0UC9v1bcU79lbb2yZvltX2nvlMJeSsfMp8639750
60	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIAYFtATkWe_G5qzriv3_ZCUTKLX6l6zQJxjia5kfqCSuAiBuLSGXHbyZ5pfu9dPCFS3xT_2RaFjjOZRk5Bcff5L3jg
61	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDmNKAC7p_TBq0keo1wySiO4uMzgc8QaFDVQt2MiKjiHAIgK-mkvM5e-IG7nPrFn7U0m59wnmOft7BdDl83yl5BkZk
61	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHPhNA8Nxc86fSrfoh_Ju3kI_f5jCcGqxkweGUZiWcvqAiEAkaoMFG2xSv_RBT6_BzTEhpys-37fmAy-Kij4skNha5A
61	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD8OxJYan7xJIjmmw2T4lyz16BRB3UfSNgDzVCj-QWmfgIhALC0dWwUWLhIAv9Y9xYt29aB82PdegMy73ngLiFjcBKk
61	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCoC1BOdjgfPq0oJxHnf4bVTek3htKj3hkowJ3WRCPnqgIhAPKmQ3gQxsqLbM781Hc-Gvngd2XQ2PrtzTp-D1dV-heu
61	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCO37C5HGWn3p54avHkkJR3dooi7Zhwy32-UWEI4oBChwIgX-7DlmRmtvQkXgboA-EfoJEl3af5b-_k8QNW2BHo_Sc
62	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFPgB8u5XVjWForjR4ClnwaTNjIJTw51lfziIA0czoL7AiEAjeKP36wPfnI5CJdd3EjcRO0LbtkxI8oHQ6ltM5anCDs
62	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDFH5zs5ER-Y_gX-cvNbXwDjjXoNDPEX8pu-fCuXzV7QQIgO8GzsB_lKZEbAiDR225nbszvSTleXiiiJCufAxlpc9A
62	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDwjbFNb78IE8FeBRcxJOWHjTPWKreQpZOeZ8IVbe_oSwIhAPq17BmG3uIsaYo_WUXAY8J-cXMewVBr2UY8ymMc0XVD
62	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCICsz8d3OUmU51MX3rjpkeyDOhu3mlkZ4uCcMxM6kuyiSAiEApZvRF7Jtqa-cH7pLp4lluzX0mQ_RIDGwhMtRfFU656M
62	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIF0ocJ-TIQNLYQne9BS9dySXhugRT9pHi3Fcx86uz1_4AiBplXCFE-4Trq07ABD4v8yx_keF3pNM0adfE1s2XzQ24Q
63	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIAMMqcDO6gwq-Xlnd07HFgcIZS3JY3HrInjzu6evMKmAAiEA3kPUaljrT95G904hnxhPTT8TUyrlkOYntHpNkG5Q-SE
63	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFIGLcVuNxpqCcSBli7PwtauPVb8iSuxPk4fDy7qvFPsAiARbd_FuE2RfQyPRn0Rl_1RS9J9NwqQz6VmV1ppTR9ZOw
63	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCoqpXHoSUU3xquHuWkSLU8Byf1kKm34tFjLGd9d6L6zwIhAPPiH0YVTvl5JIpYAnFRUyT-voX7EhWS5o-N7jJpChND
63	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDhRkgqYIbtBqD8zGJmciTPS7FNb2xzypjSeZ_4N_x0lwIgcN8lT8dQwhD8BVSZ1AmqmkCPaB7607J7YdBfUXrElaE
63	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDSgmicwQrRweMIxLKZMsJXa7IhSfDUPVmv67pp3sGk1gIhAK_RqdIxICYDMKUzjaIeOuhh9X0AAdkyWZ1C_1f1KGq4
64	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD15i6SWN8a18AEC49ACkrZ3JG5DI0Qzj1ZEVDQF_PWuQIgOXXTanWQtvl1yx__w5DBnxrv2-NmmfolzDn0rlnrb7I
64	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDvGZ1XArzG3YGPrb_U8k5uosNRMh33a75I-31SZKOvxQIgdauk-GanlWH7TX1s9ZEOoBWLYVZ1BV6OfgL-bJppFlo
64	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDuhPz2cjBZcQzQk5SyoCq922VewG69ZQUfV2ZZ1exuvgIgf0JspoRgSjw1AsaMsGG72Mq9I8c3-lgOwPwsb1khj9A
64	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCBOIndx06hlG1bAZqf9o35cp0pDm6yh98ij0k11QThSQIgal5-Q2CyVZNxyD4jmA2h9N0ldknqVkWI3XF60LQjVyY
64	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDUiTHGLL_azyrNj01La0pKrHWjRM0Lf_t9Kj0GkYfMqAIhAK10ZiikcJbrXT1ylyl6U10FO8UQt86B9xyRtRkMe7tG
65	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD-6yGWK7ueAwucVRpIyCxp4xhqstMly0cXyr8UMC8_XQIgfY9GVvTGjX9_v0_2CUsUCpj41OnewWTDMBgzKFMnUo4
65	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDzeInJmgNIp8wZPOsKvYUzCCM7GwQN6oyXWkljU-uZbwIgDz_W4LmDnuDLp6IpBL6IJFtEQyPYWbPZpNQ0gDrfbwY
65	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDmENtdGnh0fOl35x7y9mi6VYXwwyyAqLUjU0E-c3m02AiEAjBUckczzbSxScc-iYxV1iaW0wz13CFJqzqxlQBplsGU
65	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDTmyoFTg96sfSEOt248d6mHT0SRrpPS7Ygj2vL2JlWZAiAxTXlssjh_20_377YcKBo6e5G0UFqVsVz2eSYOTbTH9g
65	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCnkWE-rj8zl5Mfu9ZydTIQtUPhianZda_vmLNsMknGIgIhAN78TotipL6v_az9GeHJXAqA-qmO2f6G2nTvSrxFEQpM
66	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGqNLqjBp8GCspQExvZiCBSW15eTb4dBAlcAwd0NcxjVAiBTR-CYf6_JmOZ8yL6TH1DFmuNLv4TGaWkoILXvX2z_PA
66	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGPjKRdDp0ps1mz4ITkIzmhajg97wxhM36dKcDvzdQ8iAiAH2uBS1q2ZbNLiQ8UxGvhrfWz9DDha10Fpyy-JV-RvMg
66	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDuxbQdX3w_DZsU8_g4HNcmfvucc5nAOuDUGNzuSThkRQIgOx5HW9iOPhMcSkuonn-g-auEStQAXWAPz1JHg0ju8iU
66	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDOMszMbRgbxrlKJEo7ZHDjRstp6daqrqFUZ1ernaj2oAIgeRIYWzuvCgTupZmVDryQRss7PoKoQeOH3TC1bWID3qE
66	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICRZ9Uh9HCQrjn8wMHy-X2UBrcRr1dgrTwNhcXgX-R-rAiBE9l5Z8sfFfOj2CsJoCrQpow77KO384dMrblDNg333rQ
67	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCsux5mEx_gAcS4vJ3KTkr7T2EIK_M9kH7SZTv9PQ-wdQIgGAAiNjMkWY4W5_6BUZA9YAT3VmX4MGTtHG6Vio-12O4
67	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEPog4LZE7MoDOX8vVXIREyZ1mmhYv7Ell03dQzuQ1huAiAw36U0BpClIrUvysp9OKAm0zWcSndti4pC-j8xFyxYUg
67	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD1OKkxJuUprCIMUWXrlRrxzlwaLqQqDSp50aPqsRAowwIhAJhqeIZF6rPclONWpsqXVw00SjcfUFa7QWZmVfodu3Bz
67	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIBRibG96i9zUs2jH_VX0JFfk-TVt5FjLC0kEH5O09AhQAiAz69uHYnCy-DupgCH00fMEUdnIBDwd7fWOK4svZwCE0w
67	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCMPy-8AsFH8WgiuQWeFudHB9nVRZ36dtspG_VskQ5WgQIgWxFm6MknNetqXPVAi0ihbGNeNIhANvEGhHR-8n2njQc
68	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCQzGFeVf3OBtysluxT98dBf921EipUHDX5PtsTIK74XQIhAIxy6P1CfP9-2i_4yQ_zJR7IGlMa8MWCIKafXDkysJ8Z
68	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDSVgzTymDzbw10foBlMMBUIhMQ6OlJwu7WS5cAvbleKAIhAJuBddCqxEGLckLOjQbIIcKxZTuyv6QQiD9X6oco7tXS
68	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDwV0d0pTKLTYpdRG7auxF7MNaomBAzu7wE3VuM1ZU2-gIhAOm6q_L9QxfrSsP6tMr779c0UPPO4ASmpVX5z0nHTtTQ
68	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD7dfAk2pyyc65GwHQZwI6eMDburvAgyPnWOU5gusoXAgIgARr7jxsoervhRBuIfOKbzaC5RWHWMU202m2H1-lKOfE
68	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCQxiUq25Rmzup1SAp6zGd-A__lyka9CL9UEhedYemjHgIgPKAb-h-ZXhTp0oFb4S_3Pm5D0Dri5U69o_N4lQ7jqUE
69	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIEGIBJQY3g8MNTKTzciNlXkCnK_blVlGE1lWTJZ83mYBAiAQ289nb2gB8vQc17atMBL0rxxlIs9oHt_nKj6hixFUcQ
69	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEm7zzmuog0yctOSLa9H6a38sCfYXy-N_8at4oiWNE2bAiEAugQmYviawh2UXMHkr6PT26aO0PPHIzmh0r9FJuGJAkM
69	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCV-cm1Bfb8VBN5OFtPkKQ3Je4e6_Ku3woorpO37k4vCQIgfUJKDb-afBlPiJrOzUeS3GIrs73W_X1K2XZbENsqqDM
69	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFpBh3I76SEmll_4OOWif8J0riw99c8HDcqWPPdeokziAiEAhINt4CzQhYLhy9qh3I-DoHwT_6E72QHL5vW3IPeu7x8
69	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD-euzU3oLZEAnPXnHElb2lQmo87ru6n44YvtPIualjTwIhAJo6ba6Fz7r_L86hwXYz1lCJjYm-0PCQGF0o4qSeMBXQ
70	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBZJPnb1c51DqzWPBRtE3Pqctf-YjoGU046fW_EzMYgjAiEA_Ujgo27wB2tDL-0RHxUSaEjrhrsiocd41TdQvh3Sldk
70	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCSSrocW34z0fPzqk32Z7t-UFW0_0qpPOubKE__TV4PMAIgTz2nmVJ5S2cT0JyKqYm33wfHuShV0RMoyTq6p2-mvtM
70	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCS5tqJGQyX0PHvMAaCjxn_fjTBmHLqy10QGL3aRsEWIgIgAa8v6FIDo1U8_5HMrsi8YtbCw7nKEjB-hVCYj-5511w
70	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDziGVmuyHZvm_RQKqpa5wCRECjrsaWvd1xeFBVz0-x_AIgCbxUluU5CLHa5Qs5XFTtNKK4FxMCPL-B9M8RnmfjTnc
70	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCN1HyenXCfrKo6kUyPuDQqeWfUWxGvDFK0oPv03HGoFwIgYoe6qtCuHBOAGIizjpgv63KNsu-UHtmf55F_ObIYau4
71	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQC96B0mZ2Q3uV1QEo1bgM17xTqA7Yu_vmrZtEQjiaf15AIhAJI2_qXZlYcsHbIET2rJ4P_P0fw_wL1HnS94O-fwT7Au
71	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCID76qZA8QVl57OxVwuHZKP1iV_iBgULpQmfXAHXKogEoAiBGejGbOrEUDoLDtDg_8CdV1pqpn9z3AwSzMASe2zaRZw
71	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCID5GXQkbE77eOGwhYXc3HPFfP6q3mrmqvhhpGFjEP5eFAiEA3lGL8Znj68nKttMGXiVXJ2_EzWLD2eCZ_C1YG0qLvp0
71	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIF7cWpWQm3jxhj-ZzFOF5kZT1Gy1CACW0D9fXQTTkcSxAiApPoG-goqE6rXLh2vKrVZnfkUjvlRdmvyoBTjGTOdeqQ
71	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCsMZ7NtTTkhHQd5dZfRUSbJNe-2mMWEOp2sdXb0yFZuwIhANeMQf4tzbPym227QjcaePwtaJlp7e9PI_tsAgV8R5rs
72	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFgG8m2kOdVWIa11PTTafCZsZeq0GiQEsr4Dt_xJKkeVAiBIiO5U2NvSTSWmHy364z_B_0e7dGcLt6zwvk61fRTz6g
72	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDdBX4KSc92vc54nEU_r_gXJHVbvlH3-dtwueK_BPr7rAiEA0synlC0bdAOm_-tOsfljV2cO7zwCPo21VLfN8l0dJuY
72	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFi9TR_BED_8sw27uKcIFs2ZhzbAemYJrJ9Gf79OrKs_AiBpvFK0AZQf4QiVs4UUkMHM54MkozWDVHEhUqHjnqR0Fw
72	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAWmWuy-Jph0NHZLQbkA2tlt6_KH3dizThrS-pj2E5CtAiEAwrUJc9ovRC4T_UFrX4KrRoKBEQwWWbntpCGlQRn--Q0
72	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCquslVZJdJhJkRaT71e7yiVyiFYIk2RqQH-5qO44I5igIhAO4gsXtY2PlTK_JxH4z0GEvhpiFlB9dbRVVUh_tudGb7
73	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIC_xvwfqIF6xdgZ8W9vRMXdLwKwX8ZTg_PM7O6PmxlcEAiBrrI0Ufh4k2OJLCXynaK60NpAPXrIvvf1tTreSnjIT8g
73	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHJFDpKglBTHmQUXCz4-UKNBwRIhpn88g2W34_INqYuWAiEA0UNSO0K3L7OzAQ_qk22P49y9MYVQqDCuQ837uKoEqFU
73	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDbaNp6uWGBI1XMrknyR4hrQ5wij0Nxu3ZSzM86dP427gIhAJF-C6XD2RIKZe0XLDpgcG7XAM5mo__tdsqH8BAPqY94
73	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDtXirCXI9JdhWQp8Oj9lLRVN8tkhFB7D4mymcF0_sDLwIgdLbTRdNZAyzsNkBAhQgittO2xuKW8q6Yo9vW56SCoco
73	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIFgKDoeWa3ZU7H_xeGGkQZkZk05PandwIDaEmAoozHZVAiEA-dYYXm2iL6llOdbfoxBnHwXZ9SmSLWe-6JDWp-I2mmM
74	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICOFMVT60eGpxbruXOQp495_gyD5OPMugldXA8dNm2vjAiAwCwReuoo6TmmBPyGWPeuv1uw0IEg6dd3La8OGE7TF1Q
74	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCICRWNDtdcJwdobMGlT8FNk2_oZ4grLJkbrWxzb82T_zwAiB8MvjOnD9XTLHCZpvL-YBeuB4vqdB6JzfFTIIVo0Ut1A
74	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDzkwwPgKaBKU_JpQWLO-8WzfC8fLe_npGZsSEwFl_8lgIgdanxrY8_YnljTHK1wc0ZZgLLauGWg5n-dMV3_T0KmYI
74	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC0IE6jNxNeW7o0mU3DVoeakwzUKj8Vo4oVFvklMGL0cgIgMAuuPdPo20JsQcAmEzkuEbeGX2eIEoFdJ_zkc6CuXdA
74	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIHIG18MFOy1bJYL6DNhTq_By9QBpa42Rb_GOH_Qe9sPvAiBSH2yqfoUeqeRaoMamK0UeCTH5kYlrHOCS7x8gz4Y5CA
75	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCmbzynpFujIevIjw9d_QEXNhQ8KStHPguPDY5iqy4o5wIgfyQmoxM5Fr711o2d6oR8j41mOs4P9XgjhEiiBDoEtYo
75	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD0vVjRu3CKre5eQulkv-UM1rQ3nJh9kV5XMthAf6uUdwIhAMihkCRlTSCrldnmYFbB1tw94XI0ixK2m8Cljx8dLaD-
75	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEuXxzFlRA58NqY8kxJGOXtK-nm7WJpXzJBjxnf_6HKxAiAw4p4ApxT1KlVcNHUeWFL5vZ7XwoWf3t1_Pa6LK_U07A
75	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDsrSigrzVYDQx52IdlSuIMboDV6DObsrl2GaYlxUjQCAiA9N8cXyBAhmWz9b55Z4OPEsxtsYDgccjd9rXgTlblI1A
75	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCGOXRUpp_4nQf4uZleNz8_-8VafeMEKbRI-MPB4FMl_QIgCMsLokaQosg3ALAAzhzXWxTaEWYAiYpQTvDg1HIpH4c
76	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICG5RnBPUuLL38d_3jBLuFwHaN7WxwW9fTe5encthoKdAiBu44kKdahkUk0jGIDERlNcOcjYRU0_cu_NjlUi4iWBcw
76	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBvU57w-QEYsybw_tXFuTvXRIcaeXIJi8rKeycJpOZXoAiEAlkfptPpTJ0NzRvZN1TxQDO3Eh56Obfv5mhTTouxNW3s
76	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCAy-xSfyzQEE-PnyQdvY8tlkb_amYkBppgtpU7dwxJkAIhALbKiA6U18HSfLPICbbgOV0-LIMPDbCqxmSBp5i03h6H
76	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDIAXBKeCLH2Q9th2IROTT7ZiZ9lrxvXN4TB3T94mrHKAiAjb0J9UaeGHd2XspVCKMeVOJGgzy1gFt5K1vhDPslQ4g
76	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCCJzUrGZIZcflt1JoSPFNj-JvF_5G_RAuNEz_v7sVqWwIgRuLWeMT8u-CekFmGZ5xfWFH9gMowAJfNsmajXkzj-es
77	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGW3vTMxA6LZPK8MaaAZqMDZSVFy7Qt7Rn_BrBzJAnyzAiEAhFCy8TraaDJj2m4m1NotDVzrJPtTz0OiJBELJJ-EJgs
77	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCtHLUrFHjyRYYADCNauqhmUCC3aX8EDcouEfL46fcregIgZNS2463DsN0h4iQe2bdXYjQibhhyqwHkO0xd4DomjCg
77	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQC3BTR45HrSYXB0ZoDXY4AVzG0zlM2OA-COfM18warNywIhANhhGk63PknZBxlZp8DkqpexPzJ_P1TEK6TFxxbs900N
77	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIHNfo5-PDpRYQ0PDhsr-by6j90SqyI80qvVpwapHCekaAiEAx5S_dNst6B9424QqNb5ChC37ohxwQLEXzkfNNN-RG1w
77	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCkjMzGtYzTqV_Nf8OMxPmDIEkzTsuoD4C_m1g_7PdFxQIhAI2sIWjWJBPZUBfSBqci0nrg2iTp67hh_W5jPZeBKZd0
78	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCC5n_-T6VjlDucmO3ALcHgSvLXVh7JV5ZACAhrEV07vwIge98RVk95Z53WTVt-0ZhXzP7C8MsJwhXz_5-Pof2tKD4
78	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCgVWrWQCe88z2TUIieYUnoOqreYuJkMl4lWjFN1P6HsAIgfoRt14bcmLXA6bqREo0C78hPWvaJw4RWEJs9Gn8M8LU
78	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDdnWE0xJYfd_8aDNqz5NJV_2_qflDAFY_zj6vo3f16AQIhAILkLd96rIvw2FIk9DT3n_6sVhmqgLbf4Rtp8pPM0HMj
78	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQClrCKXiKszSHIEg06ZjM0y3Q1UzbTpNsOQUawFSFK1qQIhAIaq_tK_4aKLT-k7_u_uzgduUXFHE4zjTZpGsUkXJvL3
78	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCXZR1m8BsdUyomxRL4j-qIxvdUZEDMLyXzq61zUMitlQIhALCFBt5jZdXdB3QDrhkSckqdglL_VkU0fs9v83Qwa3tQ
79	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFv2pckgkf0daq0AVtldtA0vHHAyoum0TnFfgkeM369PAiEA28ra0vHhKbYp-BhLiexHXrSYLEGepBrc_zjiXy0nXxc
79	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDlrNOoiTLzr_M1SNbq4i6b77fDJQr36MV0g25_PcjOgwIgccJKUjtcstI_XhKkiy5m4v9Z7wKKr_WwFJKFq5G8YLI
79	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCBC6xO10V_XjuBlsfffp72mhFruVYhvzpvvt5oGl_htAIgPxZoVa5d3uodacyn8v5mfkWZMPrFB8FPnRBEpLbHHLQ
79	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIHFTCaT8T2J6gt6R1lvpcPfWI-A-dr2JD16WPwVYB56lAiEA6Ma0_Cx76Elf7vmvGF8zufcTX-mDfXjMKi9nLCzY724
79	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDxrb0BHjIzuX-w2XbKtIonnvGTKyAifk9EfQbCNbcsIQIgKRBFPTeqPn7Te2cDC7DsJ6iRv_kvx_veMYHCGVvP-Ek
80	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCQ6-ooCiShYNvnPwJ7wt65H_eEvdBNmmBtGhBi5CgmGwIgXrCFRiNlSgeOhgPLexjNn2pL9dxVEkIjJjoihWXT26Y
80	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDVpcEPb6bVZOzdq8zb9OUP0Mweivdt6PowcyWMO1uPoAIhAKbJfxNKBNW61-UXxyooxKExPzaf-rVs-P0WKdQUmRXd
80	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDv_afBDruNBlVC4_jjpY4SHQQWGDvyO7cDva_WtA4JvgIgPKHFkIyThoKcZQrOCBK-hA_hHcSX5xll3fApYr9tm9o
80	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCicPFanoZEt9OG0wBurJAtUL6g1l1Jy81R7sxsXXl8XAIhALzOC69TH8zjCPiStX28TnokDOE3JRM5EbbMBXU2sXjI
80	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIF76S1mJLL-WraQvLZZa63qNDYhr4yr32DDY_ycscoX-AiAd9k7SKn7PrnvNQfusCe7nTg6-6qVme6_AikdfEiBy1w
81	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCoSEMSCZsaFU52u9OSwU-YlPcELkw7pTZEJJqJvkDSiAIhALFr8qVyyrHxmAOfjaKsGdIqzW-tIEbDXsUfRkbJuVdm
81	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDD3OaiT9Sr5H8NdRgS9SjpVqLOWD5TP1MfRs15V_Z1lAiBgigDtLobIFm-MVLbRyqSisa-xxEOUOeWB6CtNkmGpFQ
81	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAYoejedNY3hIH7GXwuI_TGsKgv17dHu8iS99976x3m6AiEA2ZDMaWzbieQlBp0ClpOMLK0spxXy3aeDLvuLpmbpqFk
81	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCMeiIiNd1S7mr5-tPmLgYtXIy-VFtfAHIutAWwMUyGNgIhAMahy5MLO5EkmntIActsIx3KE46kvsx6eYt24cJZGtx1
81	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDzl1ILA8rt0jCdk-SRN9FDbU9-luAlt6a0BLCa7FSL_wIhAKP7UPb8bg7Z_J7unOJyOYRJMsZUC0BfU_B6CMLDfqqW
82	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIF5vCsCHT6EpPXZzu6em3CTOtWCcsx1kJ2QxMueZbmZjAiAyUeP5Nk0am1Ry5ceA7sugtaZ20xUbuCtFDYdBuLDG9Q
82	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFRvRkKbxHAtX2hpzH7utNzJOcHCmDOLc3HEy-Wpeue3AiBMYa1cL3KKAkT8yjUVmlp0ugYwBSTZgArYmdu6AVdwHw
82	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCVHJrrrU5cK8FQati6k89RrcrzVA7eA-jc19GOucRDaAIgUHZU4iocfj5A6mVmYDEOaoJwLGlC-npeLlxSqHSuY2A
82	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHNnuoFA0DhbtXulVsGAWWsfQJbduE-y10YA-E3kD1HXAiB3aCCYRy9Mv594cHFQ3byWxqfIqoJ5myYF987F6SlITg
82	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFBGs5KltsdcqO2eAmtJWrgsvZpOndNrKOfZgEZUunmsAiAsh9FfVtGiJETZNpKQyBABv9lACglGnwGoUVpeTUFj8A
83	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIB3uEgBXXS7qHrMnmoWZik47YYTGgXJQ1XKtkTP6pHYLAiEA9yHsDqK_JJsFDtIPWODUqOO-rYtZLmly_rwmeks6xhk
83	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHlfkwSy3CvItBdjlJMxCs7sVcCGImkGzD2PFkVZcqicAiEA5adQgQWBG9XXXEdK5OWfe0GLWt1vuC44621qdU9bIsc
83	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDYzgssURIxHn1a-uR54yv7nm3narwYgWO7Kg-gtGJQmgIgQSu9YKOyhTRuYevuboE_n8nviYVDL48su-FIFWZB6pc
83	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIDGCsLc24-gaNxXiZl2lsrGg-qm5g5XPX3H1eWgBmvPyAiEA1tJhz8ZOuKdp46WJYDmzpNA6SOxTdBGlbWkK6_dOBZ4
83	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIEfinBR84z9Fd4AO0xLzb0MXJBuYxUr2XntJ1sCABneeAiB-qa14m1zxhmytE4nCWhZhPyasKxkYX6xJFxVeCcmxQg
84	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCID6w29L0a3y7GnOdy0iIj23exzZI5ts0uvb4Ooj8SWuuAiBOLQpsJWdi18IpuM_pzq0HWn1WccZHaXNENGIroMssGA
84	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC2fy7wMhJ2uizHRKo2F07EyGM4Sr8yQ7YGFEA9q4mdoAIhAJ2uXjqrkoyiNPzlayCX04zb6Qp4-KszDmBVZ5hcM18H
84	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIFeLY2m-OuFasZZAcC0i_C0IlRhsdsvH4UyscCuVPPQNAiEA4Y4wgjPF4ZRtg2luw7VXqXeL8QL9hdeqIzW6sc_n-O4
84	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDRS8OpeLlCoPN0hc4cU1IlOOlq-UcObaR4bb8dZUfy7AIgBnrQ81Goyu13CAGYqR346q8b60tHUXUDXjxJYQTql1w
84	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCHjHGHJG3eWHnyG8UawkhYnsSzU512wLTcKgUg8VzZlwIgf18C1RHhcv_nsMcdyyB3AwtRAyptwNi5YRp0gGqj8x8
85	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC1_sHG0GOOSPjaaau4AZS-SslM_GlDDiaFflgaTsFheAIgKtdOLuH7EjMrL1nsckC2yb4svEUFPTb5KYSTvjDp17I
85	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEF-ck5_1FGTmZ0FPhtmo6Pdcwl7PPi8RNTvuaHUM_aVAiEAw3Kn4UlAAFOaW8C8TBCuUNgxiQis4ADrZFeKhulIMoQ
85	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCh7jTarx5GDOKe-fAV7cb_jID_KH05vdRkZ9jN39ioUQIgCTDZRUWLAuv8qR55UQgZ22nh8vSRZ3DzWgKxoEm24RA
85	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIF8VtEajy3ylHVr2fK2XZFwbdKKxKRMqzerwkyXq1bdiAiB4XlgilpBpUbcBZZ6xsbjyZvMm0QiwwxasZmtgcGLJ2Q
85	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDgaCviga0j1ooLdIVgJ0BaaPqE3KQ-qK3gXWyZkO6lPwIhAOx7Yx1BYsSHK2nhAUBTObk4M-cHlubAyBUznrM8Tznn
86	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDLRSp9gcExrh6W3597ECTkQMC07MJtV35w8kHU4YEUNgIhAMYWDHM03QSW3pJebktjlLGVF960Np2Tiy8Jh7NChuEJ
86	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIEToTQnzorX7P9txyZ39CrsTnTO5yVX-gxOF3Xoe75ayAiBJ26pofn0CX9swGYB2KStgAkxrrd6FeZekLV_kz-2WvQ
86	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDczgbZfGTHBpIN6faR1LToYlRvO7ptKnkNQnsox1dI4AIhAN26ggR7XBQhJVt0g6NBImGlyByTAXAH70PYb5UdVNRk
86	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCdi0DKZ1L_0sFZZVvpwB_2TG4X21FuBgJHzZaFmTtd9wIgRnarMFdPcyCWFpFFWNgqM7xIXHT6djc1iBpSyV7g74c
86	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIBlhxORWZCzCtpgfa0a4WnJNw5_vIF15kVCnHhcl3HGAAiBb-G-LGRBR4-ksyEXPeI_GmrpaYidGgelVAT8DZhFWpg
87	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCBTX9C8qgUgyBNrf_5vPCdJWpLP8gil_jBlx_40HuuJwIhAKk1hal4_Q6mgDhu1c6TedENJoJWY9RYLRQVurvHQBov
87	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCAz-cHlOWY0LkOTYNVr6MkKUCn5MYHx-WtI0ou18LANgIhANEgbmzA-rPDP-BUVNpPadHx8ahG9UTAw0HSLfGy3Br1
87	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIA8jLSPhvZi0hAB9fPmr6-8sjaX3KFu25x3TeE2fev2WAiAiFIGfAJqVyp2GtftCRM1sd5oDGRPP4mfLMUUZtyFhng
87	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDyCt3S3DrbnwT4myuuTu_nnGKO74fwFZoVbd-cqp3PkAIgVUd1gioieFodPfxF83V7077be7ItjtxBfgXZCUjjKz8
87	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDSCT0zbmc0Vg8p-YDOtH06taqBG4fWtfNZAu6rKsgU6wIhAK9NIb5YuCsJnXkYCZgpPSS8WZXNcSg8GB2V7Zul128Z
88	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDoJ2PBqQzlA1-ZnbWu-o5JXJlX35CJimAlnpSgRNIs8AIhAIteOhuK9FlPmgzCy1GnFxWsECK5UleIoeQ_J_bak525
88	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFUdQJouXfqiSM3uj9etofFKN0WeYgYTSBYxSfm6KuTCAiEAo_54zLkAj3G4Prxv89B8OIZAUn09UIX6qykT8Zttgo0
88	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGYrk1YjGG0hbhHtaz5ULzLhaiwPBp7V6_jdaTlDxUuqAiBUCfYFDsvm8qHcD_vpLnBWa1z02F7jBkqTij2wKkeN8Q
88	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFiRXieCIAcnrzxoDe_AlwM6KE6Iy-eccwFhG0zvUYzFAiEAkHzSjMoehOAhCIAqxgEfZBgW4-BiojXL07CmbC3ChAg
88	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCo_3T6-5TIWrznKZQr3oCBd6IMOYOz7U2VwIKV6PMdrQIhALRSmFV71PzuGMjnFph0P6lo167CZsGnb2gNL-2Oc1hB
89	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDfntQkAFhjR4gjDrYOXHLbMy3CD3crx212G9C80cw4dwIhAMPZl2JFsM_OaSzrdumyj-FIbbWS8b0nA1LSJ_LZw3Wn
89	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIF5DAKHp6X1shE5igTFlqie6o00_cbTYeOoB7S_cdx9IAiArr_gtvi6vdfyUwdzOfLNas-n8dlAWozwZHdwOlJbItw
89	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBmaRnj4_qJxGYV5Itdzi_rio7cZzIGcO1UMiW79i4ATAiEA107o-uYuqrO7EI2AUNl_iW1CkjWWjs9XjhFdiXw9gn0
89	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIEics3bZTvKerA0MMahlbuoNaSQNuZYoaCLtN1vVgVaFAiEA0xKhWLBXG5_0pAK_zqbbGUQ9OH39BdCyVPUdFUfcn04
89	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCRr1MQirA6ULgye6QReBfdCdVtga-GTHsH8G1RnBO3lwIgfMEssOX9xfObHP-Hx0AUQOo8TfsN5nWHHDN6BnlHDDM
90	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQChDYMv6hrxdqPVFCRc8E5eWlhh4kKk1YieeaJz66TV8QIhAIChwTFL97TQduPN-Aanb6GFGziCbAy-g9th7A1EyEiv
90	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD6bKZviy-AItNQho-xi8PFpmf41LZWtTNHdGDEsWq9ZQIgQd1Q1xpdYqDbFKjD0ek01cy89Jy7WweAus1_a4ornLQ
90	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDE909fDd2mqPZmOsiGNL87Fpte3QF0zAj3gR5x8R8bpAiBTvLv3rPqtQgn-pXtC_9FFtb-F1-Nfk7tB6dnZSRqQVw
90	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDIxwmtEr5qAEhaRALMwP7rrPYikPD_IYf2Fp2_NQ2-vQIgYHv2xuhlmw-ynHUCstHokGqCiO2U80PEQzu83fwgIZQ
90	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCICNyzoYlTv_Y30Rh4bgx54WOhx9WJM_3rE4l_eg2OxdRAiBhRgV1zm_OdFR-gMBu-GlSB9EOq-5VVdzAXEB-QmRlKQ
91	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGLSb0mty-M4lZQ2JuXsZxAQxjggBT5_C06o1g5Fq74-AiEAteIDUB-_Os0gMwtesPH5N4-a0xHhAcwretgLp2AYx74
91	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFMAlLqFA-OXsa8xa9FrJx0PQ5Kinxq_4AZIleS4dI3JAiAwroQ-9vdGStZ5Xmwcn7FARoyEw2eMOmb4-sfBSv7eqA
91	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDFyNVWx-ayswDyCeunyup2Pyhgn6CPJbJ16a7iO5Y9tAIhAONdzQR5q-4BWCnR15HMtw32-bOKJIsQs-MKQnvrcba2
91	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIEdYhYiD-gHG6BUzpsiH1tiIv5Q0V69s-I0ILhNXTAK0AiAk-npVZ1T42HgDPt8LHrSpMxJs744xllkUgj-xHLNQPg
91	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIC5A0pW4IihKPfG2Gz9XGs6bPUaOK4H7d7G_c105vCT4AiEA8Xml5o8Mid_a4_5EcAcxO4sszyFt9DMT_Vwyg0KGWx0
92	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC4q7A7RXpntSdiyMzARNCsSTtd1gsI-KyLtc0w_fKGJQIhANifWL7eWnjYM5WRiFhZgZNox4_9xod65MHXHv8bocQB
92	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCpVgVY9-J4jkb_5_HeWNDe9-V5QdNiEDFycilUvjXwPQIgAaHIPYK-f6Km6QHYDFla1f-LSMjxHKp46__wl_c49mA
92	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD64tI-vdF6WkJMhXxQcN4T2TzulGPoQ4w-3ABiYdX22AIhAJEsymuVON13exnbYppUQMgWKqgcDq1HRv3XWeneYuDX
92	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDDYS8LG77UN6Kt-ydsA_fVLMNE9gUf5bc66pFKHDPCsAIhAOvwiVG3kNr71DHb2ZcblpYc2IUtYwXKz092l1yKOp4h
92	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIB0-NGMXCuAwVqnmazGjvFFXoFCkbVVYXENjAuHaiJxgAiBwRrtsL1Teaj3Z33OVXzdpFRQfsSEpLySK17QulglcJw
93	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCkBC4juDqxBuHVgug68ZZ_-B1YsokwRT4n5a14MVNSzAIhAIDym6LvA2tDRswReGJfIOlWWy7v7K7Rl7kkGHPXukEu
93	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCLVqx43TOTyZK2aZLJ9CAaZs8p64TeGG5xXdX7nkiA8gIgNkFj4ADuySU5wJEWkpabSQk0JrL85LIDh5sc5YTEQIw
93	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDZWMv-VbOdpReFo2jqQIVHKGLLWAUWCACUG_oVxRRpJgIhAM0NXQEw6gdIgjupofHAPg6EFASwYGN5aIUGwLKfSfeE
93	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIB1x19AdG3kdgZYdCLejhMfdLUgLWwwwHEIoJJKeq_PsAiAM2znzvnbVkGw3VdUvTI3A3gfUv3xeKjvqoa5LbuUJGA
93	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQC1pdlGNZIIfBwt2SjmkbsbrxNx52EcziVdcg0BJPMeQAIgSvjf5Dadwa4gG6qKovY1-3H4dBj2LF8ECehc9hpmlwc
94	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGBZLKqt9Tk82nySFs7gLBC0Tx0dL-jmkmGzNRnOssPdAiEAzMvqHr5vthkpwILgFM5e_klp-85zh1uf-ukakHW-CC4
94	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCM3-KPeXevhLFxeag8CU883KrhXv9Vm9uGDXzAKdRyewIhALg81IIobq5A1dtrjHmHjyVAsNrzWhSXTV7LDBqHLTZR
94	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBbdQqKqpoAa6RRU30mmXRV2_PjPvotG3-lnaILdDDKMAiAUf608OqbmdbDABJEGEbn2JhU4WtCDA2swAdR99Stzaw
94	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDlJkyLcGfM7lGigPabeCoLkt-9Dl04oyrhdeq7upl0bAiEA27vQIE0i8zBkcWPrJyyFpe07wyYCoVtU3ba6S5kT4UI
94	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCgaU4E9bUsKmvNVHvkxy0TVPQynhMKpcUjCD6EwXbGMwIhAOhbZMDybbjufybQMEigJlSJYthwgyVwkTPLewvA3S1w
95	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGFGlPRDGg_kW_UaYbgtu8Blon5Bwyex8M-cEu6Bo7LpAiEA5ns5BRO1j6GUca7xgxm3DOJ4DLsPhB5angpJxxNmKXA
95	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC_K1tyteI6muQiRzQltPRStkuiUy6-3ajpO2jeOOlTXwIgRRdNeFEu-DKQ64dCHGLhw-A3HIoE1N0x3Veg3u_QSc8
95	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDGkiSAjnc-cXFZJuMv7YiHYxQDqSbzKyBCeNj8gDkxcgIgNCTptT9ZdXGfYVPu6P07HKoL_ZEF5PDLrtvsg3kGK1s
95	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIAFvgWbKn1HLmIo1YLxxctNoivO9JyURfWXokWduhRVYAiB2oP-EI_BlyNPmEvz1ceyZR7lkGBlAFEB_UxAapqqgAA
95	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDZCOYEmHXdj4iilBlW5wv7Ql4m0WMCUmq23zkD_GimWQIgLijTfqL6zuPcSSw7AhXUiUy7RTVULskfY0g5VN5J3Tw
96	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDxAplVaNz6ifkXuR6dGHzsSi_XNmzgp_56-Rx02HJJKAiBRlkRkmeQosbQBy3uGcZSOWeg7yaAhpJcuzHBUOx_Kaw
96	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCHGE5eztriGOnWJjjtEwtLpeyD4PiViSWF3syEPl61OAIhAIDY-2nx3-UqPJZsc7LYeLzZWkS0njgG4EvOUB2OsM2F
96	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDiDU55d_-qRQRoENhmItxd1I0UAuW_gnEUsVispqPQDwIhAKaQQ4PmVXvRkw_apQOz3MtjT-FDxfCGwLUURkCV8E-7
96	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGHx84m8r58UMbB1OQB7ZR-TKLbmF_CVft0cQoDiqb2HAiAcrGnbvdW5JajZy0cc6I1jptgsR_fS6KyBkRg6ot9iEA
96	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIBnPdSfeWI5-Knz_N4PN-WVBLWrbAL7RfzsgIxpFW5MNAiBZJ5cguYor1PFp-7oqskv12OMakQ1zLsrXbpzxAWSrFA
97	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDuL1y_ZKI4A1zDfLstt-MzdQpEInQcO1Gg100bsYuBhgIgEBGy4t0nzsDaTDF2soGlscN4G-GOH76b4WsfbxpU__0
97	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDZgcw504k32hiVzRmAd1H9f-WsSBWfMiFlQiwIfJklVQIhAPSGZ2VLb6DKOEX7zrDOPptNxb77r7RdokmzSwa-skR8
97	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDClKD0-n5dXiDbHX_EfnsZQfII13Q4iRmvDjIKIGP1IwIgCnSOuQGczrIGp1tvCZzw-cla1p7EUwYArD8ipkKeFiI
97	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCICtJMgKyyYHQIpi3vKjnV1KiQAE5Yk0HmJnTHXB5-SIDAiEAgKxd63-fiA9A0D0AqIybjznDCLQZOiNfGD7bCxqLHPQ
97	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIElfVDsh0aYlcYTcd7q1sIqY3LcifKFB-54-m4Ilpn8iAiBml19zrvQi9ZJqCu2fRdppxA2MKk2kI7nSH_-cq3kYbA
98	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDKMtI9QvRAtGjrvs6H1aB3gFYFvQFew2L8a3JHoEsdDQIhAPhzxPUjQSmDUYGd-m3rYLSpPiboilx3XqrUVTjvJ4yI
98	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDc260JY3B9qCFxjtRp4FGnhXs_67GTHjEFEB4_4TGiigIgHWIM_ulSgGlTB7OK96XPz-HenMuuu6QzaRd7dtyXyH4
98	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIA8usqFJsLxKKqiH-Q8DdgK40DZTnvPN_FW2IFIUouZLAiEA_-dLIwIXbCGglekK7QNfw6RkHHyLEfCHoin7Kqwsr_o
98	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDY_Z4S1xSaokxu7XtYPM3EBi5QDPQbWBHnafdvR2W0AgIhALCuZsb9LdOLZbTqdGXgShF5yTD-aCGlpxCHlEyAArxH
98	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDBttWCrBr47KcmVs2P9SEIsxrRmDQ_Wlfe1fNCXvcw1wIhANvB34uRZS3QHLEpTBP1HbtfQrbo2l3txwSyPaKuDcMd
99	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIE89Dkybtn7hRadPEfYPwjHYK5oyXboDm04eJCziHTeMAiBCcSU6mi7JtZqKvUbST-zK3d4s-IldYov4fxhmdeM8uw
99	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCICqjyYPZ8_luKnHWAQoYz5nSXdLb4Td7i6sDe7iz17d4AiBmmEMN2yWr8UKlg9jziQ8NLKG6D0BTzKX1H7phFCrWxA
99	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC3i4nKOlL2JcqLzTSOkuzMpqhAU5duha1oZ8DyEagWzQIhAJFHxlnfH_UV9JRCz5lNPV40sKvNVQdU1RC_qYlMQDPe
99	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIF21B29KUWnMDWywPoPhWQf4BC8UhPPsRINFK09dl4TxAiBpWMZCvQQrWeLpKJsorEf0ySaclkDSohFw7OrTZ89VFQ
99	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDMhcvV8nxU_9gV6Sn-dxB0MmSmzn1HHg2yQqTWz6PzrgIhAOTC9iOlw9Ydv-S3MBRJaiJmKfzQCNfBe-0VBpc3wcrn
100	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBoIz7BCJw2W3iB1TQyzoH5BHVRHLer9Oi8zYoPdx2xXAiBmC3rjcDBQD4wt6D56JEcnPlzyh45i4WHDGoFEQKdQ8Q
100	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDnsvWntbJtt3Lr46TRXOKGTeN9SSiIwRiorSmlJM4y9gIgKC_25HoOAYqAcCGEs-S6O_VbwYhgK4jLEnS7R25jyos
100	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICVDqwjC2W83Bcd_cGqufN1bbxCWyl_d6FpcJCfrmy5bAiBSAZnVfRoFvMmwFUWCDd7fVNX2LQwIpZq2hjTvGAtjyQ
100	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIC-bVB7FVHVWSHHIiPKcKREWav7gRnlbLkCudoqnwlPBAiAitXIwtLYMLctGlV3w35Z0jI9aLguVg3Gln11AOWvZPQ
100	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQC2psj3Vc2C6unsm0v8pXltocoWqGirdyXE99VGHkTjmAIgTkRWtuv_9Nd6icpQ_SzSq6FtsnRajSqcOWk8qjEeBTk
101	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEg8LM8LJVmtEsqoSKiVqbFn11BGgKewncUKXaUZuIvDAiBZg9nKn-tBBIixqfV2jnNseUqJlOau6KKvA8KJSP9d0w
101	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIAGM9goetBlWZJMGDCvffogMzRrtYQ1gDFVNdOmIGqdPAiEA6_qiSyJDCl4sL8U2JJLt1IjdhrGJW1Vl0xF-t62dkMA
101	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIF4jvAm54wpJHqCjRB7UYFpcJ0zz-ia5mUzokbnZs1lEAiEA7GyYL9obQDdDOdeMdNx2OjryTMVerYZ7jRBWhfTFCNM
101	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDbM4mYM8lxBojHUaxp9KenRPU6zO4IcmyHUWzenzjNWAIgDsnuVjIF7PyC1RrNZG-QVPvelUAbFsGX2YS0yK_MP3M
101	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCjv0bdNH94nCUCDmREowGb3hX7cGUcC8Q8HEUtwnNawQIgMBwBK_bUCCiPWRvR5zroaMzPaCGou1fV0a7Ak1JkC4s
102	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCXQdn7MizGWJKNfUKmDzBaxAjO32llXB4OMK1Bs0m4EwIgdz0GWiLultAPXolBLqXHVSuAIke64zGgrVQIj1KeBPY
102	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDwawaIhsOzl45814eIq4utwiH9FQ_A_IH1T4ZM5MaQ3AIhAMuN_jdJNsRVkOUrDfe5_oWC6BgdslyTR4kO8GIePLFU
102	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIAOR-tnouRRqfEhaJ3XwNXD6UMB7GIkhD_3I1_j2ni7zAiEAxa6MMipAZFBjuaUZOLeRK3S3lS8bYS8anAwPJfdcmas
102	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFX2MrMGTHPAMRXbTwGJwT6QndU4gHMfp01cxQ5qN1GeAiA5mT27vrtFX2F2_SnHev77b6XvW3-SwDdJZd9Vnjj1_g
102	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIEJVdlTJU6LQsd9cR_nVv_Z9_lbP5axv6RLQPvqRYxsYAiAC7fGq0Vdb-4ptNtrdouzl8OKyJRIOxg2qJjzwX0hCYg
103	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDUmqyAhjipjZsCFO4E_ph-i8MUXXr_M_tdCGjJFc3tjAiBdUzW0VEuVqIG_dc1ULmTxGs3VZ9A3s_SpMH5wShkgcA
103	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEmPi2oF-LCA7e1yD6jcFCNtAzOFdRMSNWY7ftDE675nAiAuNaiFhEu_9qNgeVDR-u8p8xY7FqViYeGBzoVDgxn_Cw
103	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCTt7ApbSjxJMnynFOqXjMo7bg2DHAUgIJe6BnDDS3jGQIgJFRZfJJ7mxwj76Qq-7kF4UBoAAvxHASS613aWhx7jag
103	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDUuCVpq-ZGev24YA61dq27RPZZ335nlf6bdJ5jUWwkSQIhAIDIFIDYKUeJrde2gg8b0sqasTmC-3-5jkfSnNyiSRnn
103	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDkEPbh53SHqu58qGWfA_etF_5lCKqti3_inL69i-P23gIhALFdpkgw9Y3BBLQNYsdOIQjOHf9pAHpGadBnUOhrMdSz
104	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDokWa1zmXfSGillh1Somc2nD5ycwL7xdeWdxse2LpgKwIgNf8UDSeZOK7AbgHCXNai4CkR3eSLjYQxkDgZkYWKOg8
104	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDwLyxutZonhBdnmC9wmmwLqzzOg2Jk8ALeszVvtLg5VAiAOHHTJsa8dbDewT0Twi104_hbVEhcPRIsrHJCnxfrBBQ
104	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEidW0iCApKhRV9mdof1_62qUZKRpzbmocFd3fqLdtOpAiAtIsEZG7PJPCsaff2hv8HC_DYmO-sqz9L0tNyaWtQArQ
104	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCb28b9IZm1yImX6qwf5tWYVlirjd1JuBs9uJ7kBj8LLgIhAPVxUETXxoRlOIP3dFCCTiks6EADXfs_7hpCX_aAwiXO
104	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDfe5dQQovGFcziR1ICSnDCU-87YThkCC9-Pxq2xpyXZgIhAJK8uOOnGXvECXCcJCSzEmEPLh-F9P5p2zvaFXsSfufE
105	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIG6p3EuF2DygCzPpf8jfurMt1VzeTF0G1HbJDGDKlJZoAiB-6DHpD5tspm-39Ll7E4XsT3AQq80anxlpO878v5EpKA
105	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHICv-1sGDgpJh6WaO6K0ZCkfwnluBwnDML6GoKOYvpgAiEA0B6XQ5Q-VnrSCrAKQPao4xPm2V9VJRg381Mg2jmpRlY
105	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDYbuwNuGVIlzjjsRhhczCL-CAh8VVHa-4y8mF-zTokkAiEAwN1rLU-VK0y9veonySr8uuYedBzwMBVO19SPMlYaTQQ
105	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCsyN3E9Cf2r7GVWlblfpnnMZyM-lV5cLCcvGWk6vMFvgIhAKaDGO_gJi_EtVgzXvDhsEd8W5CXf1W4IbMMVh1YU_4z
105	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCGEWh1LCT-RGMe5nmcWB9uE4wTuPh9PiYqDlH1AOreFAIhAOHJ3ssZWnh0MqHA5Svy2dAuoBRGjuK73et9AedoldZR
106	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFm_O7vtYZoveHcpajch-GGUHhVFpkObfjTz2R_IClwlAiEAmf24Ylv70-R2uKwwWY7EmUb_s0wK5q4CcyZNSIbdKzU
106	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFCMQpa7Ku0cfeXaraq73x_bXogytZyiPMwVvx4oOnrRAiBnMtbbz4EpMeTFYxMsypF5HPSbc8B6shg7JmGVkH7eXQ
106	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDHFpgQ0cNSRvTT1wzAmsjHVz2fvPPsBXZoQqgISTTBPAiEAoBZa_F5r9mvSQSmvsXLuPIGU4pN1fv8_ZsiZ9zlDzRU
106	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD5DfVl8zoDYCnZ-rFWnrE9_8IqbbaXqlGzHixIHmAAzQIhAKMgfs8QM0pB2pe1vfB7PhzkBZC-hgBzhQTeB4vbgQjW
106	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDkcQSawXpLML7M-V7NbjBIFYd2fp0o1jyuvjvK2I-0PQIgEyFAXuL-tQC9D9BBLR4mYLw1Jeb5KIAT3QcdPpdtYPs
107	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCutELyPfHnUOcbyIlCMlZ1YHTGbQpMYaiO8a9rptBNvgIhAOoFI0Acq7q4mwgaKEfBQbNPmEvESkecL9_Afx8W9R0Z
107	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEo6blnzcV5cWr-kR3l4OS9WAK7OQWqjHVbHdWH0uH-9AiEA7eafGKpOKSXX4KQR4JwP07-dJwgI85kEdBIV_okH84Y
107	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIBZPy2PGBu3B3cambjOBqRAmidOWekXURw_dclELvnrVAiEAmj93U8IkdYQ_4w9wqurzRVEO5lYzzvP3RMF2NYLuF4g
107	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCve9HhQJ_fWEfL-sYH6DzYbcxm3kMaPD6rLND__4uyLQIgVxWhAG-646Vbtb1HGJf0qav-poxS7bDNWm7hgFHm-w8
107	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIED1sjHQd1IOXvq0PK59cefG0szYTEpOBlYiPVdlzQL4AiEAuBneECZPM-D_WQZUYmUJvAGq9za3RBaFduJTdEd56JI
108	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDduVGSu3jBzFRdtxHfjpYuxwBZBvIG8k0L23vrVRMDwQIgBlfv3kuBooQetT_QmI7limHD0hXLlWYDKisw_ChcOUM
108	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCu534yaiqDXtmMs_Ig3pIJafttNmHEbj16fhTCSkwM7gIhAIodSd569vRUOroNC4EmQdVBQuNLa3mCcQhDFfSGp8Uw
108	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD51mUO74NPRFhPdz7iwRVu0_O9nZHAg6kRq63d5qp-ugIhAN0aRlhyTtKo33mB_KSnWKMTOs320Xx-SszxgXkSxExZ
108	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDXY1ywdUgC6onPXePqPIZ43l7HBQ1azean2qA0BCmPxgIgWGfmemywGGgyWi-GbXPeqR7SuuxjwgOnBxGGOlv5a_M
108	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQD04byto72S4ihlKd-wh3nI2yEs4l_2kiCDrufQp4WYzQIhAPE9J51mpo5JHn9emXKvX0qhXgjq2WYFqYVAh4VjIvsw
109	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDWVy7crZgDpLW8zM7Rrbf1vBU6QarDRzIFD_gB2WPXnQIgV4Cozhr38fWaoBH59LiANTMeLk6RYSjNX21pFRVkf8Y
109	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDPgkzvYdeD3bK8SKk3MLjPj9ddg8clLUes-gNVE8R54AIhAOmtgAuZyh_1k7sMDBXgrc48YdSDVsnGHXXavzYVV2a7
109	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIAHf6i4oQx0UwpHk7Zlkl-qR293pd0IPiVdC_ROVM6KoAiEA4Acj3cUNxk5feRyME5WmuUDM99OGGX_FCoKBKfWG89c
109	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD0_DhM5cxqzh9FD4ys9G1b1R1yiVTD3C2uWhGCibf89AIhAIaasi8iL1Wrl0kEp-O9vyrEpQsw5nYf5XJVhAtsMCbA
109	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCA2uuWXActFi33R6bWzh1ofQqWB8glstUlLVRV4f6R0AIhAO33lQFsC0U44zX2JU2tYm1D2pU_B_7OqQjdMMMfcnYy
110	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGh-p_PHureatGO331rZvTKkogWBjnbCzStY2bcRemogAiBJrvGra3VoYkr6N2AjR4lFeT0E37WV5tGAMCAqvKAfoA
110	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDfZG3f0odOZJHx8SXVGD1n_IGcZilVuIp57LVy4IBbewIhAImvZN7PHTh9JSzAh50_oJMTD_GPBlSaNKfsEjjcyPKA
110	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDR61_Nd7oRtvG3gr84cligVHcOPP-jKfWBjj-wzm969AIgZep7Qpkf5SuLdQRW2rCYEMcSgxSFm9s2UAYFFtLg3Eo
110	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCg9wxsKjCcQi70bnIZDVwZYLmdponNxOxq-MHWzKUfHgIgJh_5qZ6LjNa215tT1cOO8ibDrbkuyr8O1VTKid_MTrs
110	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDfsXuharQVQCVX0XuCK_Mi78XjxvizaAKn5AfMakJf5wIgYVW_73uUA1Hy28BX2R7yKbOWi6OHWaqRv9XfS2Aacx0
111	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICK1BMrehzUXwy1oJAaSpZqRQSQynK_iaA8oxptE-tnTAiApiLVkrS_su9sbnxCWxQ8LP3QXW2jg2CGB6pFaddorPw
111	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCeLMX8RRBvY59bqnXwPnDU3--9fBF6_EY7lNilPwZZZQIhAMunnBP75ZJmVIE4PtGJ2N7cubqLskpW-QTssugDT7yp
111	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFqSRJPbY6WRiNsdk6ahWOrchlrwrtB-cCFUE_9A_RLVAiEAtgMiFoqvzkKnbiKZGye4KGYfF5quRDO-LTleWEsuEiQ
111	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDfX7EW2j_Y8FbIomqekFXnmX2jtIY3a-AF9EWdvZMJhQIgCeOYzj4VsZkzNbwZRcfq8IF8RRNn06en2dgVQ9nIgJQ
111	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHNegwqyNk68A0eDSHtevHFQ1H40OMLV483dGbJp5qIpAiBoBLge1z1LVplA1pNl-0tj5SaP_HMxP4NvkjXBJ4uavQ
112	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHtOtRm-cPqX0GJMaTW39peNAVBOJNi6Pr711mOSX2PFAiEAw0KPTTg1OUdQ6nHFE_59bNzzdscwWkhv8vy2_EdyMoA
112	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIAnC_wo2LBnbqXDtLIzO3xw4XpiBoHE0TfpQYII1ob64AiEApVLaECZVU-RR_ZM68KPA4RilS941sOjzOPUyT9jFD8A
112	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFEBv9huek995hWdo8HCz0Ee2flFid9ViLqAt5pPpC-TAiBr7WnxBT5gewNlzQd3agoBVbtuQ2HOuTgoc3A7gcGl_A
112	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIC38TCxNMlESpysGDeeraxG3ZZVow4ykJY-dwuhloyDEAiAPpNG7Mv66TeM3HiF8HCaodsfjwPZp9BFlJGch-2pwlg
112	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQC0LfvRUTd0IO5nEu87mvbjYWonDreoHcfexffhA7JHYQIgA58ODmnVLorrmdTdHqdKedlfRMKi35zSfMZws_L3dLo
113	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIAx_GSLuPcJ_RgZutXAhqU62l5iUWEKfrSy3F6TvlYHyAiAHok_pYlje3gRyFOZUY_CXYoLe9T4Q8x3z1vdpr4m-CQ
113	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD4oPcI6fKSYEUt7VfGAdxFOvo4ORYmAupP_iFxuaqDkwIhALbUZGssOm2llA_RyqWQak8jVGelmsySnNrNxturwNWc
113	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDaa46uVFUG-tFTZN7ZhANQ4HImUsK4KRABlLtIDixSPAiEAoVJEsJBNDFhGKKJHUZLJrW3eMAR3TpsByR8s84QHGEY
113	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIE_GX9IgIY3pNblaMSV4GIeeJBtWDLyVbxYI7HGgZs2jAiBNXEjMpTYQyyFlzCVMZQdEXDB5wJI3CMb2r7nGdHjkcQ
113	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDHNaKdTtc6LZJ2-XuF76ypeCnq6TK0SGvq3adPEdHG6gIgGWybCZOVNxEBpYbj-Z9dRyvspQuTuQbZ6TI2UCFuVsw
114	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC39nN4cynS1qpuda481wXLWCFo4xz_BExk60PkGVL7fgIgFj_JETQbklVpn-843lJ8ng9kO_OHxNNT0--qf1aFF7Q
114	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFhv8xVlA7izXPBOq7q5tUnxeBgaxVFXVH2NqeAt05EVAiBpl88kUt4K2iP5HRs6p59KV3F_9cwzH1okfistvEXjUQ
114	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEYl0Gk6Jqvw0UJQHX7961ZZpfjSQ44bHPA0S6CjjMFiAiEA_rQnAAWfbKN837qvtysBPZNtn2O-gAsZmJHZ06Vgogk
114	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAE4fe6g02jaPeEV9ZsBmBUEwi93pTmyQOplB-J2dpqzAiEAjh4S5Rw5kT-bBeKMzwTJfZFqM4_8VVbcyJ3xus4yU68
114	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCICpggpM7EKB8T5O9K27jrQoOheUgCYv9nB9tbON16JemAiAUi0ayWRhZ_At4q8VaLfhpaiTBs-_Bo5-AouTbt3gxtA
115	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGv1cMJbiVZdWz_75QE0hdZ9WDvTLDPsJON9vZ4pALPyAiBXIw52RobCpcObHKXcQSjAdby10EdalEktBlk7D-xHqw
115	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQD2LTWtyYDmBcnWX9t9-BRN_2VO4sgIiQPI1IDVeqXsQgIgKAa8uygh9g65yTgSyCaxvnbEF4tx2imaEJY9XwqUqK8
115	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDoEf9hS3OdAWSBxM0xLCsvSeJvYKwno_73KWURNcKuzQIhAKbfbhnAUlmAqgWCsWl49ug9rUcpbrULLPFeboAJFGIH
115	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDWUWYdWeOm6cj4S3iGZpWOpZSGoBjXvvkCmgY3uUms7gIgb_KnJIgPlD2j6-Qi3eg-hX9SEbtmmnpqOWeCuT36Ni8
115	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIDM_dEg85MnJzGkgtvLOi9K0XhRqRjgpVPfha1Vf64Z8AiEAl4KhHRfLQ3PbKJUskpCnBIjn7YCanny7vtaMTPHrwDI
116	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDAI1QZjmkOipBO6O9QiOjJ_2D6HbqlAd4LWEACJ97DygIhAPaahsu-IanSmHrL49vXYFe8LQPEPikLizx485hbkWl5
116	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDvg_GVvHDAY5cmai8xKwNL3kG7jz1lUr_QNw_XMUGyjQIgCXAdJE3G5AzEJbylq9XwdIxaJJ9gGN0eI5Sehwjg02o
116	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDwlhzuG9rcq27NxeQpCXUFpo3zD0K4DT_LQpj9mZxs1gIhANu7sJHP_eI5LTiwCBifVhQA3Uc4H70Z11QeP-rq7wU1
116	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD50rcdEJ6nBbjuBM_dEFIQoSvIVg5sYl5tJ6blfuBNLwIgVLGMbz-C1x-Aw2xW2AVPD0xzCJrnu_H8L0XmxMo7ZAg
116	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIGm7ta67f6EJQi8IX_kIgdgvQUbWoLEQfGmFsbYc4KSJAiBxTuPCOaA5qstjUHNn63Z6jON-zOat8jXb72l4WP2eDg
117	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD-r29kDv1afYdRynsEnKkrgMzk96X-o1omKR4eTCy2BwIgLRLJGmQazYVLM2uJ1ddxUXP49fh_8zG9ZF2QA7wqUUQ
117	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIE9lP6AqmeNv30F0fnKkDY8eO1jzwI2Z31Ca197LMHg9AiA4eZVpp1xttjTZ9ulVa3RDrYOSheOrZiMTBZWwjro5lg
117	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCzQBN3nDFTSp-w9l4ZtubCVhf69x29C5MEPfJAP9DzNAIhAKsJ741DzkWPY_UjIdAWxwToRXIGHaZHkCUupFDH0T6q
117	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCKlAjVR8qRmAIYKXZiQxqXkNjX_0_6HKd3l7_iczf-VQIgYso8vfEHKF9UpSm1BSxX9C_3K8Q_MrEO9K_BnDUydYk
117	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCJcq0VCMU5ybnrnKcNJHLBNCWJ7RpRYsjqS3tI5TJ0YQIgI96XJcW7bsCAGp3x-Ps7OKkn39YSkGJ3PsQirda_6UE
118	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDbCdvW9yzAxtzR4NKMttORxrC63yWYGRQSYRHp7U0N8gIhAOB9sRAmVChiSXfABQZ72vPJ9x-wdT25rfiHmF_zCbZj
118	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICrLLnQgYxo2YdnpngFJNVUfraEK5lZXqHWD0oyNneIzAiAoiOo1VVQMgNHLmaRd8-3RI52qJhxyeccXZi8WhQFVtg
118	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDksE3ujdlp_OiVuxanCRoETbICqRCtNkJx0SGhMNVb7gIgWT5sUBwoAwsldKbvDPId4hLMf2NXxQIGeUqxH4K-i5A
118	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCCTIuwyM-t4R-XjWR9C1A11pKLkXUcM7zwr8n0kHJUJwIhAJgZ0PsENohzZ8xbDLpaJg1vsNywrealpEX-kMMlG-B2
118	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQD36Xh3zjDNmEjIoqAHStsrttijtIyxfjW_PVqF2GOhlgIgWiMPoxdlIeVBGMWWHoUn-OyMEWSDF2v9K4KcCAQcRhk
119	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIHH7ZHldKfRuSRW4334NqwHjU8LC6cSqzjoOPusXNZ98AiB990JnIACeANqnM9uLEoe9ALYAF_461kC2Fa_lQ-ygWQ
119	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDAhspv1tS6Kzl3EYV3VNmXpS0TjEqd3YNA-jyQ6FLhRAIhAPlTXUlu0UuoEma00sqqOBRzm7x6CwGQJ4H__vMsRGX8
119	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIAVc_kA9-LXS3IoOyr9gXnBbT9-sjFKrFgCHuMexG-UXAiAHssXPW2OLDq69_rIgpsiRn1WGD_ynlDXLCvR1c-xvIg
119	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIAb4GXeyfhqd-jWimaqBsA0yFRUCGO4jxT6874L4Sn-DAiEAldIgnRuxtYfTjHE0U4IFFG01RGx0IsHgsYZDIlkHLgY
119	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIFUgEd2LN2dP_FzCvVrVviwar94gx11ydZsYZRj4XZDOAiEA0HnMcpIJTvD-OgKRZadY6npONLekV6zkKJ9yh2DrwkM
120	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDgBmwO0bayNne-3GRTCnZup9EgWlbidZdComSX3-53MgIgI8_iSJ0gufiWXTZrtn5X_4IzDsHc22W9YNaihY-vl-g
120	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCID3TDn178CSd8-Z-hk-i35EqSy41UT-kHa35uRQw4E8xAiEA94PKDQmFXJK7QglBk5W-XIKafySI1lw8zZh-1FE5TFA
120	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHX4j8OQQEsEhvZGKihUsA0icTruC0Z3uk04_9L-c6L7AiEA7f1AZYWQYHmeik3_PrKfI0vmRWfL0gNsJzVr8UgZTQ8
120	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDLBjEotep_I9BxTKpu-ASLibWJ_r7ar5x890_EYX6S-AIgAkY2bC7nDaA0pacyLD5Vk8b9NwkEjH8-Vhy1yNYAJbc
120	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIBRvJ0i7OTJXgl70hDe1C28Fr0GejmqT0Yg7BcRX0Ym1AiEAvTf45zzWO3j0uVmKeA4LD15VGnw6HssjHT0wcagFEhI
121	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDywSg96AKcYoqN6OM1l9bfSlglLAV-IBCLTLtOynZYhAiEAqX4RRDxykKdPLcKl34P-X3rRJIUsnI4lXXDeGxMOwfM
121	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDXQlbyZ61xWVgDu2LuzXraoygNA7llhnlUtvFEvZksyAiAf0Nwi6PVsyEHPprX_hYl4xZW-7rkZt9CaFvWQv6l3DA
121	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQClOPJNiL5o8l7rpZgE_qDNNfU2kycJiieIIVK8bJ6WXgIgE3FjZHx_rsT49Cu2EixjGLlM29bTxFiHVDD_QFD6ooo
121	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEIPljmYf7f76IcWxPupMIQImxrGKYKnZCy-gVxqYb-ZAiEA58U4zK2fNKBwjGy0wxVU7ZT0lf0TpbHFTkN2B_4sJRw
121	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIC3M1_2Q50Ze4kym5LvXwac78gOUY8HGY7N2D_tth8UjAiAscxwX61qgsB_uGcASahG3Aj-l7XW20lD4v42lH6i51w
122	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDMMuwTjhXdEYOT4-JLbB8VoeOStF6jGhDAUc4f5cntpwIgLqUowRtfshpVpn0oFH594BS-tPxl7gpT_qXogDfyXMc
122	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCbyeoKAPt6zP8itcbvRQeyHGpBp7sYWEyHZGtQ3h7aMwIgEnMWVJwX2FVhfGrEOdXTLPFdW-fZ7WjXNRBqu3eDAgM
122	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEt97V45POSQRJgyr1XeWlristQwb-uPdCTEKbU5sIUxAiAyDdTE2m_UYxDkCGZ9qMZFgWYjs8qEcoC4LwOLE5q9tA
122	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICqObotuzC64Me8i_UB7vH_v29rlIKNFBa6L78UgzemeAiEApkVygoCDNfBFw_xnE0a7_UpNspWRDYoBYV9Rz_xaNZo
122	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCkN4rIGGaPUmPKQ7FW6QiltW6pT4HO2v52qQbe3VRs9gIgQ6nZ9xuiKqZNYjI1-tTbX9Rz40_N_F6l7vtdQ3SGwo8
123	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDJrO4zm4oVVqKe3NO9Y4lAlJjcWndPQ_SgrmgLMe1trAiEAtEeo4IQl1p1-820rpx49HAregg7wNMgD4AVOisskngM
123	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDUQVi8ni3DTUlheyVngWXgo3sqUkKGfTzPtBzM2ruXpgIgeY1sYqM7nzrxGiY5eWQW8Jet9J-QmVaWzia2rBNkxDg
123	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAOq33GAASIWs6KmDiuiT7vcqp6KkeLAnulr-lqMf-y9AiBQ0T87MVNuyy6_ixgdv62mlMQ9u8quvvxlS64ApstFEQ
123	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD533EhUiKEedCtUBhkEe5r-HxykWxnX8-NGasXMAdJ8AIgWDZXyOmbxQwPYLUkBTj_DvsIOyXVWDliN9SJDGGzNvE
123	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCxqKaLDvMzfKkK4oDGGHG5tG_HTe6cJPh9i5dmJl4fHwIgVnrepPezXnAS-31_qQBktpypJGvC2pnKMH1Gsa2xmxo
124	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQClOtuv6HOjGIq93c6TBrH9DrZe_rBTEnh8kW5yF1U2HAIhAI75KkiI7ffPP_V4w-6k8zmVXnashDOtBBGzyExYBm1z
124	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEjttaZQPQnOcKya9Ve-n6hxAl1-HSBJUm5-WGrCr4d0AiAkDPqVs4gPKKzOTWbQkNTPQKwR_vqLmYR_sjVZvgS4TA
124	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCIiaeMuyMvXuVCN3SUkcfCylwsTKqbD_Fg5WjlUe8M-QIhAIh68riU4L5uXqG4iGDS3MXI9jgaaTqxYMzpFUkNDgp4
124	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDlklTaBSmDgK2WsuN8xoNg2_VPuNcXmUXxrO2j1HHEXAIgI3HErimvrhhK3LpoavllICpOPZK9EdOFyL7DS5_hhZ4
124	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDqf5MbR_9Qt1MeoEJgDQOKGQQmMorEU83eEcieLx3lrAiEA51XAv9lxMaFJ9Yg7KXq2UxqykpmRT9BOTgv-2tZS5Lk
125	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCgeqUOLZLTXqoGfCkK3iHD9hjBo6p1tauAS4-mmVoXmQIhAIUrN8ptrObdHf6OjaHDqnzTbZctBCdPVTbrasyVijQt
125	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDe6TBCMSjANlQgycYWTzeNXNRrc6iWshm2XfAPWCPBoAiB8UpCjmSbILAUv3QW-FdGhfnr0M5k9V56ZD1yTLAhlKg
125	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIF7sH_6pBhY881d0D5wApSoqU4LHDm9lzVoWbnXp2EjMAiBYK0eippzj10tmqzdQnvG2Df23mbmfksHpX_T3Oz1Zag
125	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDMTpJmeAIjJ1Pocz8BeFNGg2wmRolV2n1RZEbFw6LtEgIhANPBWYv3HA0A6iOozU1G1JxQ-Fq1IDMxhk7mMWV41-3l
125	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCLSWc7Cd38ycQKsvV-DJMMGOF5OOzMkLWpzahrYA7LsQIgQSPybudMahgmJ9lDERqyqckV6vGwyPHkx4dFtZPa2Ys
126	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIC_adKrus2KwhZ6WDN02fD4BQHdmTZ1MoTE7mM6WEOnnAiEA12aCkxMdEdKbbQ8D7Ckn8dRH13vYwcxex6LQmjjaDm8
126	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDx-1Rwj-G96fS-RshOv0FV5pciowg6AKXG4N87fgmkQwIgS7xnYHbj1B2QI6P2eYYDrETI9Cgann5lADWoVXpktmU
126	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIElCrtFMlQquwykeijmMyyYXFYsITy1RcZEeaZ2c7XB0AiEA5TyM4zurwLcPd_bdG7LqckThC1wwN_9Sq7RnVb8PpnE
126	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDEHQyST5UNJjjTIEA6Pg8aeSjaTqLGHlzN2zcozSkzpgIgNGIKuXuaojGV88ccX5lhIGG2aNdLoAkMC-JkrRjwAfM
126	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIHUt8leXO5XmftHvOYpjLI8ANQHPD7HbsdTrR6JyoohbAiB22LJV562FvhD8m3o0wgCb3QXz2bM1cuFiQ4UNBIKFKA
127	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIExzVh02BBlTEZdBhRVFsOvmygY4RsFTg7NWWbOoAMR8AiEAp9ZdPI16kfL2T40XhFO8NCGILCBv89xaO9RIv2egnc4
127	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHl-LGGS7r2g6zStCHVH21_1CEfFNzP819b6sG65X0tNAiEA-NucPj12NJYYXRGUBDAYCeTLeuuE7oKeaGWf9bVHhns
127	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIF4rvQPWfFXw3iTBfQnFR5fxXAP2GCLMhb4ubE1pZ-2uAiEA8XnzgTKqxdfsORO0rHCvMut38FpBktTpxLkDvTKfMbU
127	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBxSc2m1c9-dnDR5kscM_61iO0NDt7HKTO8m8zFHUhmCAiBCBxjwetBQka57REFKlmvnCD9cF8SuljMnIh7nTSx4bQ
127	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIHR2FwDVaE35MXPBXZfQ3SqUbhlz5-YhOONEL9eglrJKAiEAxFD3795viWBt_KZK49BFY3GciS_pjL4Q1j389ogFYPY
128	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGG8HiDbDgNROAeerD9BgHOmW9D4-MYjPMheTmgVNnpTAiEAjYypFQsbWldquSW_dL7SPHC3CUtMLkUYBvUZMf84NOY
128	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD9xxW_YLa7fku9DhP6E0fClONqj16L_SSRYhOsRgxs2AIhAJXXrcaUfIJ88Rl3m_FMo8ojA0N4YcHezVRj_Q2hs-iJ
128	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCUP70wqzRf-VoTxbW_0hGYRuyXWbJNMamkIgBeadgLbAIhAOHgrDCIk9GiE2Cs4yxkgPKW23P9sfqtGtT4CtCJZcn2
128	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIE3xDqUtuw4QOZw-EYuo4z17ffpQPFsTYQtV-Rvj4TVRAiA2Ctiw7fsep1rMl5FUT-qzaVJII_akVuxS_Q5X8TserA
128	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCXsLI97R69SBl8gS_OjfPQtOUjjqpkMQ-d0OWOXQIKqQIgRnqSwuYIHWi21vAGUdzr923H9PtLBWdUiw2k9GjYPXE
129	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGfK7Bae1SbUFz_oYg-3-UFWaUPbmvyZ2TaRzJcO6YO-AiB8B6lamRvlY_gbJDNWlOWlCvvNF7APg2_Us8v7MxZp3Q
129	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCa51-WHRdmX-WLD2eZ_0ZhqPYDqvOLHmRDlK3n-nqC0wIgCKUniHzm1Rw0k6rNA3kfltS4sIwx55Z7Rpwjrtv_75A
129	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIBMDggs11mc6xcJVQHAaAoNUCZhElfYeGwnAk4qheeuTAiAcSpxLrWxJYaGyO31TDlNUB5NxiFI4bSe2fPXZ6bGp9g
129	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIEbOGRHK2RR15suaUMDI_xSXTNkmpaWJKKOcQWiR4VYXAiB3PSenjOeTdn6_eE1gRErPrBwmREvcxuIyOr4rJim9GA
129	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFv9znMDgGvES8Fdkiz0oxYvEtRVSrKqA2iOxCztKjXoAiBnzxCXBGC54PVRhJ_2A3uA8YcKcb9xwFnpSRDJuQc4LQ
130	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIC8Xvr5COJEP9eAruYn6O-gthhe9iWQkjTwFmmXzNYueAiARwFDKG-ER7cesRKuToZ6LM766CLOoxo07cwBOURI6YA
130	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIG04Lps30fIILRt12CERbLkYWbrxFayU4yM7DJkwxUCQAiAmitHezoc_H4fTCKwP17LlDL3hDi-Mq7vI6hL7JXC4qw
130	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDjT5xUeJiRZpbfOFxXPBNRhp_IIeAMfPYT1C4H0fwpxQIgYNqRe-HQIoqbWCfGr5tDtrwwe1XQC-DHiMu243k3e4U
130	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDuGCgt6a-JaIqrkONxl9G1xc9mMRaJRTVColpjcD1EAAIgA868oSxEP6qdGuKJyCKHHzporiVyeWx6traxzbUJ7kg
130	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDqeyhJjNL1IveolOaq5OyTxJ6XvnuuMdEl_yrLNAzmIgIgAqcZqKtXSMJUjJ0tRNB15_S5aXgNrf2zVMXqscnX5HI
131	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC7FjJK3mC3RcKxu2vLRDBztxRnFDrhJw1Gi1P5fPeXaAIgDVMrmUSdDOXPgSsugUonAXnIp2Wb5WwQB6IDESr7cDU
131	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCqlwmFzlmXgI4wb-7ruGcYomnngITIwBlEXx-JqWXYlwIhAKKASkq-5LV_vLnGmiM19kWrCBsDuMYLh7PB_B5gVu3p
131	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCw8IqG3TEy8tD9PfKleOS5SYkFJ1Kmnbo4bysQB-Wz_AIhAKsRHIKOFMIG4rlXBuRuR5jT0tyECLV8EJM8fDbS2972
131	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFVDATL8jtAcs1I0YmW5_yScPN53zShus0SkwzzeyHaBAiEAj3bfUgRAsZQ7gFjABvTWE20ATZq3PjIC99ptg02CPLg
131	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCUyeAh0FvDszWbVJzbW7w3yMRoEPCqztjVu27yRO-JbwIgLuc__gKDPKA97_Or30oDShbB0d-pKCeIrqIC6kin0ik
132	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCICHViq0nZiQmj96ULxgPpv0zSUQuHf4DMRqnD3sk1Ae6AiEAp56iyst67TxfLw2_KvCq6fXdP3rREMzzGkbWvUf4e04
132	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD99teL1mVUyjyUlYSRiO5mw94lMcEgAjjjyixzOSGK3wIgDWMK3STs89cnihVbxP8OWVTG_UUrmiVgzC5FB0eLreg
132	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDPB7UdjSLaVzZ0JErU-I0iDUqpqcCVWOzuKVIFLHHpQAiAueKw4s9SqdK4-uCK-J_kZSI7TgV_y8zLUnX-_k8bIYw
132	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQChBue6VfVWD-7BptZC5uIu1oEpLLRXwOHwp705N2bVzQIgAZ6kuIYwVO1PAjhdRX-RDGVM9Re1MNZE5wqQsqcy4-8
132	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDBkSqNdPpL7zvvJIjbf63wCx_qoPrWsOpcukzDM4oAGwIgGfrLqG7PpX3aLiIHLR-re9ibi3TkqfG4YE8zmR1_EzU
133	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDHgYV8uMXAgsjgTY8wIQBMdcqlFP1_Nve3GxHH5eMXrAiB1rQWnhbe5uDlhX1nUO6RZdG4Lxd5Rppiha_sKQxKzxw
133	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCie_5Fz-kiClJWqEwkGJC7_o5Q04CtjcNIbAwNq0HNAwIgWarU70TlkENtmPzf0W6K_0ufp8Fonv1K2C2yuAIk-lA
133	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHFXq5dqQC5jhtaWT2Xw8cgP2a6PFYppnGzfdM5DYsUuAiEAgM4lsT4cnwA4h7R4on4W3I9KQPfNI4KWFwnSaGpr0hs
133	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGxMY0jbvkYbbTJNL3yp4DBEja-TuSK8ArxfpDsze9beAiAKIqj-8Rs7k6-WcG-dn2qsrMWa59nniCPxpWCQyJD8gQ
133	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDRllZ9OkXOmNS6YCWeY03hCKGMTARK23c0ca-I65J5XwIgBXJNnXTf42enqYDReV5oe6Ic9-Ut-jRZf2hhiHqK_Zg
134	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDOzoFj8W7edgmkGUvGPJX5IgaB2UAAWmf32ElJprAvSwIhAKizOpAmP0w5RPG4s2H5aFrUGoyIDQQMTLNe0YXnHKkB
134	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIBguWvdxH3XvaBuTDR_2XJ5Nds7ROjPLw_QE_ilVyQmiAiEAklkMwcyF2n8oOy8J7LldpGZBnqJW53OPjSBgQzOXKU0
134	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHFqZQ_fDMs5Vi-y8GPyAo9xOnWjtcpsxmhlqyrd8ycDAiEAmFDzLsrUuJwP4-6h2vUxUa2u-3hirN7Bw__rzxBQPiw
134	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDi2fC0YgwzPiuGYpY1acHoEUWhonCKsEi0_8AF79OHqgIhAIhimvUIdK1dzLdmKTHPZylwYVu-cPZy-djq51htIKBR
134	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDVh-atSQwIboHBAULD0wGvkkbVM1_alceTYlZRsWkMAwIhAPwAHgRzenSiD1VHHTSkA0iD-vt1vAXwyb7SJjfvvq5g
135	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC1ZqOjKG7_bvguMDI73ewbVHdca45LJSoCK_ZrF9echQIgEqQLSg0uYkb9olxCi4nwrKWH2agsrV7TdSLmh9mI2Lk
135	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCxb2ix6xcF-WkUWB0AMXsuQtui4MxFheb8l9ge-n7ESAIgEtBMKeaqveq8RH_bKWP5EsVJ3leBVhQ_iYcvLSwI3uo
135	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIEIBG5u46VzeJ1NcHLjtu4K2okE1wAeK1znpKgkn_qVdAiBvQhnOWAiSD2xWmJasCvMS-vFfVv0YWZ1pFIp0BYZRjQ
135	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIATtTJXEDt1x_vY9IDSRCnXTa3zAxlB0hzUGlCVsFvmpAiEAjCjslsp6CsGoKx5-N7CYhlBqdgm19585LityU6UnjJw
135	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQC1c5AYLKHZvua3KZWUthjVaMEkVApCekuW5YF-RRTsfAIgMTjzy1572p6HHPJ3nNi4yT-2uQuOUoStcl-hOV5QdEM
136	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBJ0CbHV35WfRo-F307jKvQc5m50vTBHEjhK95CzGyQeAiEAwTEFbOJoTDQVkxZJha-h-XLldD6Ml_SQ0MJRLRppSXM
136	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDsgrEqTbLHw_1jrQe3dqEDOPOdhi-YO8L0GvLIicrVSAIhAOVXcxXVsz-5XzsYTFICeNUlXWFEQBsQc3ft4voad66B
136	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIHkcIGLYXHv1hnN1ER1vRX4UOJ_uzgEvFZ2wBVbYV9Q-AiAk2AVkKZFR6XplA8NBYdyjjNdzIvoJiZ0lI1AI6fnKew
136	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAy588BgJQ0f7lkBaCZIfCXk97fFIi_PVoEmni2YLOviAiEA8V_m0_CgmGH84HTlxiXyS1h4cycqeUkAxzVz1qap4m0
136	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBZ23jvhrpDhTCfkub5vz507ozshR5dgdAnExxvC3G2gAiAsvU6SQG9L0vsFm0cmvo0saYjhOB8uFy3Hg6LCwCxPSA
137	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDHkD9oybaxU-w0swIP4sRTMbwsvgBAc-k0QkZ_bj7gAAiAwc_WtIwRDUd3WoCB7L7YB0Q0omcxRDixxvvdnqvQxCw
137	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEZq5j1nY_JT9ooqp5TnmAA1X8uEc2gDMFFAf5WxO0gUAiABR-scpF-RX6awEreFjB8k6CoN9tnoeJW91KlpgSlLMA
137	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCL6B_GrPU4HczmNaF-IwGS7_JCznqbKsethFiKKE1jXQIhAJQJ8sFBTHuginIABUmGth8NFEeBNLCJN2f60t2hQ9Pk
137	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCjKhdumNVSF-IO2Wn0c3eK5J5P9659Tt8ikCdDCygffgIgfAdpnZQFMtkeIEakDv4KbHF0B5WwDxLNFPYs0g-mQjM
137	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCAKy-qH42N0DD6TtYnaEqdZJRi94MrogGSUn8xAMu5egIgTT0CIx5BhnijJGKfzAHppn4ZnK0PC3Bk71Ck474_jog
138	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFw8L-QF38YxMGy_rZOxUCOL5E3nALhHPVFW4eSdnzqvAiBPEUZiHywImDTRzttOQbYS3wTdGL3PK1NZkyHsQlf_ww
138	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIBjPu3-aw42DuD5DKsNFy84ANpfUr7aCVyNptjvzNpjlAiEAhXaVCsP3FfDn9KVRDn19tJaUBTD3NOwVA3yUBa3BxI8
138	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIEsiRZhaQnqUl2THMhKLl_lVZkpfN3m7Dd7Y3o2gPIcWAiAg39xQUTbhEGsb5uAqCJpwgwcrYjez25SByIrpO-jzVQ
138	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEIrWG_Mg6dc7UDk8PZU5DEwL7CarhduoiFSBR2RgpaVAiBxUWDEgfC4wcoKA64nMYAsDzmDzhqiLauxNwaDCMgWhQ
138	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDg2XN7U0CatFY2jp2XFcOmcO0o00-8XPJw7ekewvftYAIhANFyJqBknzu0QVa0Yp5i627LQexPSZQ0hdIzk77EOVcl
139	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGHiO7rdWGzmY0t1ID4ylKNqAeM9xwgGoXJJMuCNLFlmAiEA_l3bgpYKWVKhG5hp1VE9YNiN-K_UIPlZR1IKvOtD7x0
139	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCOl4KrBWM5T-hTQeCjuIWU_zqHvMN5LoaeKqBRxUw5ZgIhANQOMexngth9B3g1NpKn-TLGZ4pPcGxNJL_VeBergWiN
139	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGfaDZlrhfq8XXija_klIk40RtXsZ-JnKFwJbL3ym73zAiA2enXyO6JYAtvJJ82aLXePkrhspr7VTlUjFUcSxl5B-A
139	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIFjrn7LSTPIGdNyXNi1djn24Z4mzYzDJpvzVdGkHNdKHAiEA6XciP8RihjSHiG40qiqd8K_JO0iVJSDshOr25eNjnFE
139	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDNDRJfHW76G3idbWr6sBeq_03luJ-6SPO34IZ5X0qfigIgVhN1kT9y6AsiA0-uVdx7W8ZgI8yyZj8n9YHyNbAH0Rc
140	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDu5OJw8pKB4yef-UqRhlRIzH1dK_l4-rkIWhBJvbkawQIgLTDoT0cmr90gfgpPeF5VZRsCbz-PapVWnx2NnXdxkkk
140	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDavrmrGJgRvamcdo9orqqunM0lj-vL8AdUUTp-sW8oQAIhAPaVA77-Zs0fBzvTZqXJiF6MzCal1jDbfDYWZcBXYkJv
140	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC_U6mmllXqpbli_4Mw7a0KRPo942cyiVLGoqUmI91oCgIgXI8HMTLLXl_DEt6Kl1dRK3Ze4pacJeJE4GLuKWtAVsI
140	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIEEA4piq98vKDzSycI0jGqj0Ddq63IsMB28tRLF8J3ZCAiEA130xUwoz7v0QrCaXx_RK9Ad5vcfakclNRAcik2-JwDU
140	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDVT8--5Dy0I9GMp07RXIbLi9B76G9XluCMetj2xGyM9AIgSs0s8NnUYJwfkGbGEEDGzVDn3wGiTyYDSk7IpBNG6hY
141	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQC-a8LVXuNkUdQ9t29vtquFAgvfsPo2VQBjOe0If112TgIhALjmAofIrDFdgh96KHtOvlDPfbYmGCdzATjUi9cT5t1b
141	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC-GiGvKU-hI3owioqTKHPB8e6sRIVs3FEcb-mJun1dWAIgM86FF1nPqcUeHBnwpJ5ahMQeKpyAteu3rrVEWtTG8mc
141	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBNhX600Zl4jU6St85QJQ9OO_nHMeqtl402F1to7BUgkAiBP4mUolbfJx08Xa_F2GopspdOlmD7bKgLzrgASkt8M3A
141	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBBDMef8JKkpN6tAzLMKI1haNHvbeNQa8RPssWHKbMABAiEAwBVO6t4xfTB0Sm_nSmqqPXbhcUt_T67r059zJ7jiqnE
141	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCuPKbIVCx3sSNoMR6gXyrpshkOLt0k-Dp2AK4e0u7VTgIgElmogp3UMMxWWrARryXMrlJZPhpCKw4xTOdBbXZMVyM
142	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDmQ3gImXQ6mE9j11GNxfEbwfhTn9uxgdl_xX-pdAj1-AIhAPz0SaZ6azTuxMjeMCMTV6U0mMvJEpA95KYgZ6xXeIar
142	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIA1E5HmrdYbnZidVnR1EVvnZ7xl_fm-rCbG9ZjUevl0nAiAf8aMaXD9j3Y61cpOk3AxB12pxL53p-s7ebARpqQBdpg
142	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCM5JraMQLT-wdPIolNm8w8FuPQKCZGxo1FubI-A2AuLwIhAMCDdlfHYjRPPdhFqXpaICaaFrAP_cbierOKsZMU9jtw
142	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDlXZlT8LvOyhqkZQ_Zqg2rmREsMGtL28D-eUHb3pvtuwIgWYJWGVrN32HtCFamW33rlhaob5Wl1Y_msxoXoi6B91U
142	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCy-j-0vQqPpTfTGNmFKv6y5On8IBvJlBPrT2V1tY8dNQIhAPc86OSLLIRLHsgyR2K0gM4u0rLa-HcTdRwbwFMAX19p
143	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCICGDTmRFj_CzvQ6okn21JPcdFWbvATZxh8xxnIOTsX9aAiEA32tM2IsbwJtmua0JpAc__FaVrLbiiUDxjq_oibex7S8
143	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDQtFNhEW6YtLHi0Km9GF_yocB2gU7TPLcMri5I4MMvmAiBPySFhJM3A8r1IeXJjqGoU5CoX03OqkpRBrHiHRT7Qrg
143	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCwYnLknr5b7LkM3bQAip8-lI_J8IogZ3dTZVxqOZRKgQIhAI1pWmdXSeaCO_4BL7bOQuzR-0JImZYmTbo7k1zpJfr3
143	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGoVO7VNdMQ5B8SiHbR5VFR9t2Ch07Wg5l76zl2PnaVLAiBinh7KXUogdidVWMhXiJyHTcQ5qiTvn5orwiIJwQQX1A
143	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIEM9mS-2XRX06FKSCrlTo8Cz4bVLrsNegQ10ggrkGJsEAiBMVP_z6mCPrulabFhxTr-mEa_I-BL08i3S38ctfrMHCg
144	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCfbfxYE_QWinEgtMe8-g9s3Xg1N1FEmRHDbtn2hjmRIgIgLYGRHwaULrsMJOAqoKfNAR7Fh30iIY2cqcZJhl1_SYo
144	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBIYn4l6XrBIR3aLZLX3dXJroiakhNSYe4mRDhgoBYWtAiAHQr0XgPBoFH7jnULvCb5tLx6lJWPD164KHgUG0xUn-A
144	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQC9suP061RCnBqPVxWueWhidOSn54FMnlpVVR8KEG-QKQIhAPObTzaiNOBbQorgdxHE2kGVi5TpjwRE1TP5F2g8WQgT
144	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIA9lUiY2-zVwps_X6fO9zJ1UAO6i_68RKpYlUEY_pMg8AiEAh2AY_6-Lu311r8U2goJkhzcCYt7qJ2HEF93SfgJX0MI
144	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCICtS89efXgcKNi1ZEJAhXYfAl5h2ZxnpczM2pPwmepOGAiB-C_m8mEzb1zAgd7QflypYG4rnpToRCrpRND05Fi3FUw
145	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDd__luj_ACJ019EfZPx3Zi_pylekKTC7eeaq1mC1vuFAiEAiHYw1GAyQF6IFHz6ykzUH-ilBVAGz7cB8SOHeNbCK2M
145	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDlgtRQ1uwyv6k6uNkahGTbMlyPoAd3cCYhGt04eP39HQIhAKACGM22hjoo51V1u1boshwg6EknL-DaWWddwUnlmjR7
145	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDqMSw2qxvKXN5Lv-JiXcGd5aiE0kdMtWYAjJfZ5p3yrwIgDYj7T2Li-AbD42U4CBXGSVW2JJb9TVevdXZ1m08U6Sw
145	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDR87xA183kLasGd3a_iXiwsSXba6ZxLQhGUiZSTAMHIQIhAJMJfzFfmZyfQN5JdhVhZJkzSk86vMBIAGch46KlMZFR
145	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGqXO3xfhvxBSwVg6d07lZCDBgPNzzYD85cFmdNZpWbUAiBtB5Sne5hxxiRdoFpqCoRcMGKtd4RGkJDSO9Owt_XVBg
146	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCdFI_1WoNR_iTcOdwkTkoLfejhs0vHlIUT7cXLJZGS8QIgDDBGSLHzbyS0MlpLKObfoBVsA4Xon-dhaPn-B4Ny7kg
146	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGAUMqZ4j1T41T3qEsooI5vxsFqCfCO1IRAuDZmKeFvOAiEAsYfNDKIYyN3ZZ0Wvt05Bj7_0xM73l1ZktGZTlOv-VIU
146	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIE9TWLqSEuKJL5o8J62cjP5t61MwfLfQKL0vqzzso42jAiEAw7R9dRZ_v_jMrkqCpDP4atg8PwxCnc3LHnrOZDA2KuM
146	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIHKVqQVMRET7wlMy7TCxaePk10tJJT94_61Zoa0eePpHAiEAnxm_vnzROvTy5TGXAac_paPPIR8lJeUR0_JvTjKQkF4
146	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDWi_p6WchEc9ODeMZ6gIn3MAP96jjsm9WyoakE_SJ-NgIgUSAQlPJj0F7nfoZH1NHLr77huSK5-ffEPRTFLIDW_mk
147	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEH0HHSfpxarn6iVROGNj1tPrFTml9tq2fbLUQ6xXeO_AiEAvtuXN90tgejz3Q1h0OvY7NsNXooiNK0sI-wjEMv5VMk
147	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDX-tkRaf4tlvpeIBbCc4Kx4BjJ8fsGCU4jUQS5BtrlegIhALbZK7mDzbEf21EObcX3g9zBNV32pk7EtouSmXD5AUjB
147	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFpZOqmq9ySs1dDRKMzSjSjrzIZz_Feydwt0lb1LrcT6AiAFpA_o4wCTWgn1QwGuES6m6lReJKTOm-AsVReAWqVUEg
147	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQC5Ba8KA-ohBdQaSHS8D4qFf01u827J1LNhTQe7sv2v0gIgPfGm-V-oZEVbjypJRV5c9Aie-mSdHBTec9QqH58iHTA
147	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDCaf1YqvIG81N0WUGXKA44zf8BE8l6xfvdffxlC5gtgwIhALmbWS3idUncbc8DOv7NEAqAQ_oUqNhw60uUssqO4TM3
148	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC1T0z4MekKA5xsAe5TxGtubYZjnOATx_qP7SOKqOwHvAIga6wRk9Ek3fMsCAG5KGqjJf5HeXY4kmbmnEN9di0OP3w
148	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCtbLj8pq3GRDPuY-mxPekgcPihdvJg9U3XA62ZOANULgIhAKD0pAShNuhpKpr_4omPu-PCyQiWf-ghVlrV19-AxpIL
148	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDn8UI0qYLpc1hF7jB5mgh8hMOnwwjA30SojD6H0Xk21AIhAJO90MC4SxOL0Q3wB0coNz4j007iEIiKXOboW-OwD2BJ
148	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGBuXO-HexNgd7ye7hL8LOZX0Jt5p94yBU92xLrGgtTqAiEAlghUG3UHGxiJRMPt_-vzfAy8aFUG-6_CD40G95IT2PE
148	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCbY_Vgm1C2HTq_hZptzUsEAvWo_pAbAP028AjSPAWz0QIgaU01HUtwEN_W4UdrGLHO7JE_K8hD4DXeVcLoyLbUPHw
149	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDPI-Mpz38-XFZ9nn_AKo_IAPf48u1tOfv2LFj1UUpUPwIgZgm2Wc6X120pBdARvD1BM7YNJFOHaYcm_eFpFr38QVM
149	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCS7TVHBXQtiEGZc3eEOzcywtlzw43YOopfCcTIoV4E-QIgBd9NDeCW1Taw-izOU3fB_x1O8WdUziJyrXcMLsdxiZg
149	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIHY_wTYceQ4iRC37vgKoPT9dBtaoEFMyfhf_SwjqdoadAiB--md7IxBomTkW10ZTCYuGHbO1fQktyRa5renehApimQ
149	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDXYNiB5mEKNU8oSGnCiSg-Oh8-WwRR1T7fTfzcwZiBQgIhAL2jKrLfTHDXkzcqLAAERlnymAjbgHO28EMJmCIE6G7A
149	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIHoYarZy9jytW4_icJqW0pPtzRySe9s_dUmenHO7zojrAiEA6T6UUiqT5Ca_kZkmAJ_7uxqngqq5zo4m2QYGw5vycyg
150	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDwZ5o3eJZiggZ5LrMFN_qME5Ig9AbK1FFu6qbTvTWQmAiEAmSoShIAo-WYIRMl0fx5_syzknMJLfmWbyxebMnS-lj0
150	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCfoc6cqgIccOB14hpmaeNYa0ZCFmEONLMZvC6TUMTxTwIhANJ7_hFrY_H5PURpavBTCr2vdEa9x9LWtl0-ZKGSbmz2
150	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGVm8UE-22dfwd5lTtKVjqqIEA7I89_YVw1VLvWHk_C7AiA9ElfSJ2hDL84xp5IN81e9d2qhaJyQdqf7qVCJaT2KFA
150	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDIfcVhJxXkpdBJHLVcM5MYBzdH_jMDSRObD2ZQ1OZavAiBqiuNM9HskqPspTvFHpH9tiY1o3rdwmBjgZ3nXUF9KCA
150	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIEZrljN8Uh_3VOTakk76mSnMVHBsRBdhUiB8EeriJb36AiAGGjBY62vh4DFLTuA7MRUFZDecb8yfrK1uTFfQ_qriog
151	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEkoKdqMS5QyPZrM3Ok2R2CeKlFxIqeWpa2I7Dt7ZkyCAiEA0O0gbqFhjZlLYh2D9eFXajxIhmwTcCWEAecgdGlXfnA
151	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIE-acV-_V2qQnIHJMaBOsttWET5fEo2_xhdHpHoNXZK6AiEA7HodVbYTwnHxUMPnm6q_q4RAcYHJkcaY26jShDIbj9w
151	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQC8W3CTrzpZl0_hLnP1siTnZjyFnghf_T1BBpAAweUz-QIhAICH6_cX39-F49QPbVzr-rzoFYvy3delvsj8SfTer_zf
151	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDmP9z5JrHaEEAVos1O0DQfzfVgiOGcY1ULmwRbgcq2EAiEAhgekb9uc4bDL-FSbs2BPWPIVFVfdL-5w-zPK5rkkMxg
151	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQC4xqfDtsXqYj9EIELCaKBZhrbauggKc6spwKhkbpTJXgIgQKnXk2p-GHNDMj-DvG3_ax2BNL20_dzmVwfDnRhhnQU
152	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHyNsATrV63gsojg_J6qW6xFCa4xPfGUYUvF87p5QiRvAiEA67MaFKYfrCVzdjG2B8tyVNjEJLJv54OP0CCLvgOuPV4
152	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCLym0Hqo8oeFEqoS4Fk2v2XB5F_bDOBz3UJUMBYHMR4AIhAOdfmG91jTjyw9msTwj82f-fnDD5JyUeZWDXsTTRMUSK
152	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDJXdi_nJDdBr_2YF2_cRDF2zAF17Fx6Th7wo6glYV0vgIhAJ1SYUU-2Sg24Bosad83nK4ufxpcbWLPxxdCCBOcKSyC
152	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIG1rfy1J9I6R3tU_jbPUx6-eYjQro9FudDqO2tCXTB-EAiAjpTvb7NK8zO9KHH32HKnMc7T31HPUQrICPhtQBl9N7g
152	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCY_dVqPqoQi1nIwmdG_f_4I0UjfdvHXG_xda9pW67amQIhANiP4DutTI3KPP2KzoJFWAMikQkMzQuoiYJ5NFjSBgAX
153	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIE2QyNa1qLTd8zUe_XZVOdr-H4C2pcas_zoYA6ltBqxyAiB0g0HQpwB8uWiSa4pxxULKCeD0J20hVze2Dw_ScUSaEw
153	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIGrS0oofrpO3NxdT1QhABCOaaR_vS9QAF11T4cQr7FTnAiEAhM3ziRCpzmn_ayoY015SPt-5YzJs9RK5tA0fVVV4yzo
153	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFwijpA3AR1ngX-xchpP9fQvO0F4voNejM4XXM8cSjqzAiAFrewzFyinNL6UVFInhJeqr0klpcqjON6sBB3OPhUphg
153	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIBiLdWSIS1Obaysvbcs7acFlV_L6sq15lMszMBpuNAXeAiAF3V-M1adeQDc3WEjQ6OtEUMoEerHm8kX-c5dXJPT5kA
153	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICyo_rGW7VXasvzJ9J5dgVKMsZozkG0c4qiIrzX8S30MAiEAq9F-z5GMXN7St5rv2_J3tTLf6kXe5UDX9qfy-h_p_-A
154	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFfWzQijB4quItPZWHg4Vgc_RAVknNbWKi2QqIkgNsSaAiEA0Om8b7J32Hawwi2chdwBNdW8dOSqY1lfVN5_jp4cIpI
154	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCICHK6pgBnFBnb0C-rL06w0JWoi0-qMNNXnGRaW-Rf5s0AiEA0R8k59ujHm_DV5EuFTcqBjkIiEbnPfuHN5m0Q-XnT04
154	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIBq7AWU8t-uUpmHYk21nZxAA_mf956mYjUlFUUqL9OR6AiBfFz0G6EwP-AxUqov2fj0hMKfpbEGAHww_dxwQxxDXXQ
154	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIEUFC_2DgVcL0sxRL8zxrrKLNny3gTY5iu0SboA9RYF8AiEA_YAlCaAGUv2a4LpYXJKfPHlvnDslCaHT4IyqZchaS-I
154	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDHd6Om3k786KoA6iynE2b01cKQCuuVRI8D0GtYBO-LMQIhANDoR019yfdLyoahijq1p4woTDwTGlxEee6eDbPBuXoB
155	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFo-mJ6a-P-p5LFRw70NmJPJ1wQjzS8pbGvSVJe8Dp94AiBH4d7PK40DgVCtPW2KlXBnC2aM0OQMlbd1iwjmwsIMog
155	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC_btSMa4fk0D45Aj1Qfco48m8YqjH_pxy27FG1PtykogIgI3QOCkHThx27L_l7x0UTxSnLtmUEI-BH0xrii7qxkrI
155	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDAc7UEwwJFsjuOTa1cVQqBoHXGk4UwRjnbNM7YcQrWtQIhAIOZJCmxDLqoKL95I1Q_jKl5lWg7OcF9x39zf0b51VYV
155	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIHxkBUfrmtmlARY22vM12KmIshtBnQW5CNxF9nDHmBerAiAHjpVHVytCpbpSmurnG7dnSlpfTyPmOpJeyUO3-JvzUg
155	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDkP7UyyYbaF-CQCZ2K_8jvLP2SQmWdMnFInk2fFUzGxQIgMBFanF6p2KPI3mAiUPxVmoFcg9NY0cbmG9Gj20pxugY
156	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC_VKvwwmg7rQgSUzbQYID7yhWfNrEkf39J1PEUi-aHlgIgc08YIAr0v_CXpk4--upRqg1q-_qwM0p6O8fSsc4iKWQ
156	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDmEWa-Qs48XPA4rrAzKyylTcUnHo8-1C9LD5QCbySKhwIhAJKtvGXD92aXQA70YUSG8JFW9YggB9vjZBQ34S4_TWeW
156	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGMs6nLBrL9VYBleahcM4eF1hiYY-8XElHyr8_e-5DYfAiEA9363UCYd2FDelwvxJGF7tQkcc2y89_xLL3f9Ni3ilSg
156	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCICypwMgK0WK-qF_32HEDLw1eEpJhsyWTzNWOhI5u0KzrAiEAxPK0MTnu9r6PpjkDKDMS-z442oAQrfP_bUBU0zJgFzU
156	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDLdn2bXdFLhPozl4gTWc4Z2mrfGlay02VXqmHhT4xqXQIhAPgxHxXzEEdh8g_5iHDiFMwf11HsRsPHFvPaQZcXXsmI
157	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDA1nZEGwNdAvdDJE-CFtPaj6Tv-H_S1ilOs-zOvCXLfwIhAI7lFNAXyI8D3Sda-yLkc7aZdWRueWXUC-N9CMU8dJgU
157	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDF0nJC9eP7pqcS12WSvlpoATHCUtuTdW0tqp5FJvyPwQIgLLBAYjduR1eq0yp08HBM330koQFLTcUoVKO9ku0cVzQ
157	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDSHP8GVurFXp56WlpjR2EtdXqLF8npowxo_HJthZS64AIgGSZW2mmvT0AGV8mMdJz84DWUsdXRo2HuVY74LS3Pa9Y
157	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDs_P1A_JssXmfioAe6lU-CwdLNFAszdFoCFKznbCpNqAiBlBldMntjMbir87h7sj-SmIo9M2K4H-fixHVnpC4UiNQ
157	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIAuSr9ttkLvBz5sqcqPa3ASrQiVTjRl3rMQOWV4xyskhAiEAlFTR9T5eq_g8NLggNWmfbqoGqbz6PUT_3M-A-elfQ4w
158	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDVliQtsyqkje9tBiX_tUga5Fz5Qw-bsR3bG_1r7IWjuwIga9OVs9rmF-ltfTUYdIK9u4bAcDs0OdXqebX13vjixKw
158	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFQYJE_uefxygyM4YuG6xgu7-QFsLkBSMTCiNzC-dUQiAiEA8QlSqwAT23GL6bB2P-8YkXsImbfDJEePPm-c2qpiwJI
158	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQD2Y7u_NEhnIRV6N6Qij14xmtVsK4cV6kZY292HSVr8bwIgJaFtB1_Lw6FGdBQFPUJ5_1b7kzeOpVF3erlQeqbS6wg
158	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDEzklB25GDf3ZUMlL7Vj7lRbfRPp1Pv1BsWcnFOWOCxAiADsKY3pSP2V3pt6ISL_TOFQLhyli5FTz0OjU-DeVIerQ
158	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDhuA9CFZVdtGpKT43EpQcY7DsWyGbq-gOYcfi9dF0MjAIhAKv3HjWcRcmQSaKpfqEVXAVLSzvJB-H7EsqtOdNi1wHZ
159	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDVCnjFkHrgADeNflthvSJlrgueDWTncMvWvnPHgkFWsgIhAJ8nH721W2xHkfXNKjVWg4umgSJH853YnUpRgWMKWmoq
159	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFL7pL6kuj7lB6zSmUu7p1J8t5v98RGCAHrHG8ROIL33AiACUfI3ZIOPOorNd7MPVQAl7NXccbmG5ubEOnzklrxLUg
159	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCID8cMdFHy6FnZ54UlexB4K2G9SQsAYoqaxJIpQZG7x17AiEAy4Duwz7JpfCUYe-Boov-5AqMpVqMn4a0HDFLH-05Oc0
159	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCVBcG8u7hPa63DfJy-5GLnNy0LTsiwOVKDcUx6tvtYNQIhAKjqXvEYzvB-5xsvbYWyp3zml_1ZNOciANn6-tDoWF0f
159	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBopxeSAatuU5OUkglbIqdr0zEkiULr1jtmVCr6PFnp-AiEAsz8GVTlOzwp0CBvF_Bb40lO380zMmEntQSLdeprtUpw
160	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEHgSOaP5TSvhXI72gpLZt6OiLn0CDr_QstZ6l8riEoSAiEAiALsqpqUs1qoWCRIDF1hFq8EH7SClksqbszzuNPBUU4
160	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEvYrq6h9SR1b5urMzh4RaHdQstpnIZVkTFWTZ2YoY0HAiBFV-CbpxldVPTNHns-H0vo6X98WKSuP8QOtYRH-OR0_g
160	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCvikea_nbFiGgEX0Trorc1canOyiutRnvJOYGpnvDQhgIgA4eAl17Jq9_1tW_Hfevbj5lxRSz3F48RsgI7co9Hn4Y
160	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDhPnbTCtM1UhTi-IPK9aXztCCR1-cE6c5CfZcGXvqSswIgJu_CQem3EztmEj9NpdYZPqaygMb8Jh7AFdnBz8gbLIs
160	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGOa_BEE9AXoLwh25CEEweihMy2cpXZklHP7xN9yYqXpAiEAgbpAvpz5ai1B4afqSkqe20eN7i2wimWyDdNVCE-ht_I
161	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDO6H-O9Bs83pm3dATL-1VX1XHsJc4ZT0RltCa4M0USaAIhALrT533XgzkDE0KBE2KBHZ6zd9s3NOnIDtLUkwYUtIjL
161	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCwEu6PmQmD1UlgINAp10dhMcAhl_6W6hNo9-itDaDsQwIgHynFO18LRmNhtqJsdw1Oo-cDfAWLxCEljc6z0q6PM5c
161	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAzptncPkEwrBqo69NFN8HFUT0TriPqL5L5phlwBC3oHAiAaL3RkygJokKnJSsO31UMhW35x9edRPGcxO5eoK5oqtw
161	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIDux_f9esaaL6vycg-_ecqlPpYYhkEEiuxFxdA_NEExiAiEAkVJgFAK2d7iBgS8Vhn0EhgbcSs-6uGhMZxKa9u8f-2I
161	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDjIl2VDgYCGDzsxPfPjUnDoj6Rj6PqTqTHzHBWeTXReQIgf5c2KyrKipF7y_3lhhmE-tvyly_1ZEezNNyUvOWEBHs
162	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIHVHhs3rsrb9L03W7mAg6I-9-3bMKjssacGLagbCte-EAiBPBddI_keIazDuxdaID8VaYbT6d5PgF1uydV6J1IMPow
162	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCx2p0MM_70XUup6cD8bimar0USWi6hZPBD2ykU3REVMwIhAMieSshKcgZQ48xMF7Y-IGUczqw5066C7ZFOb0DZn7jX
162	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGD9COv2WhMk5naqCF6IfgDhgEPbsqp4M_3g1_JhFKNbAiAIIxwBR3U_Av9vXdwuI_S2Ia3NAyeswSlg0nnXAbpqtQ
162	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCD3TBLkJXlyb7r5nb043IcJb8zGcx4l7DWteZWmu_L4wIgQwePEvLMu9dpjyK_T_IhneptU3opedyfd8gUjLtH1CY
162	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIDC9gfVfJRHvfZ6AaeljwepUBCJe3qSIWbfzBRKRvhDAAiBaKaWtIctcv32yBE86wV9Y4Jnz37szqC_dLXyTRIFm5w
163	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEl_wK4raud_D0h-02sd1QNoTXDJmQN8r75i5ufKubcSAiEA-cs-csaOx1ulYQTSKzwTNEuw0LE1jplSZGAkb-W9wmU
163	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCyxO5IdGXRRIgHIGwE0lVJG2SEE7y9ARBVSTwtsAc-uwIgQ2kac91W6hUE4uYvtRJ2nJB6NabWovQkltppC22oJYI
163	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIE6pMBLFLg2VhpONRAEl6NXqr-33U0o87x639P5lfePjAiBo8Aydisj1I8sFFO3vfDn-NUFnlt0sfrpGusRpt-JPaw
163	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDJz3qfgvtL4RL7UV1ct7OX5sgNJ-5hL7suTX4NeunhgwIhALVVxpoWbaS6_yb2pvgqGb8DkQgcWjI-X8O-eTCrSnOi
163	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDQAoJU_nwrfGndmBcCRk3gHA9CNxfG_XPNqYX7Qzv5tAiA1iTTIGSEpSH4EtcbZjVexQ_y_pp88b6v1ypm031cRCg
164	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBwRGls079PjRTt2H2VeUp5Q1y6hw0e96qVN0POGbFdQAiEA6XIpj3SrqgeEpTmYTe53mHXQxQ6FahZEhqfenHKiAdk
164	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD_YCrp7KvtGOMc6yasg0xhsMlhOS97WQ12AkdhKXWC7QIhAMTrDOWlWkq_fuToK9K5QZiL09MuN-IfKjsqegPkSZGH
164	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCrBZfcIn8wlOq3YqwgRWM_OxbHAgI-WRF-sj8uJyOzawIhALBBCiAURByGT3mqgIqouZBoVdpOR-Uw-okwuGVJ6-Ez
164	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDyk4inq915r6B8rMI_tIXb4w3B19loWT9L1tfxcbFVUAIgVpwPFRevlchZXSNMxzo2_zWS7TiP3Xt6Ga0qA2zm5ps
164	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDjBECcyvRxcCuKyNI0sO8TKUuqM606enEyaZAPEfNo5QIgMjesDgmv8aSuPO3HKtu1KygDD_Epb99ErI6aEaY6PKA
165	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCICAgJqPR6NeTXE5s2BRuceF9F5wlpsslmCHbSnt9VlsGAiEAtBcqaidLcOHYRNIwpeBOVWKsix79vyvxYJOCw7_TpZ0
165	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCbl3wbWwB5Ar-ZapaBUeM4OvbR9sWZqIy-ijiUMhWIQgIgPL52cebv2zubOmpvgH1Xi0R1Z1gN7PSXjDKdBOnNJag
165	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDVdC_qc8UOh0xIVPo9SIPVvsn6UpkEltHe66dm1RkeEAIhAIDtWlAFBAlx5_EvnaZACZXMy5EmbTXWmp1kBNKmd9eg
165	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCnio5_7izRwawRncgaY-wwUsMLucTYs7cH4uoMkKz4lAIgAk0V2GaYBFSWSiUsRqZGhbYvZsxe7F4955yBS1WZFEY
165	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQC9h7b7E_4_Sgg9ZHxxoHr8kW-4nlL0pKBNMkyI3-F5FAIgFm4c2fTZQ8TSczFhCNynQfZpBsJYol4cCgBzq77Oy3k
166	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDDGChE5KWcV8b5q-T2CVXR51aCIt7zYNSCvJd9oLxLhQIgH604-QEKTtzYLrgGsJtdXUTW-cro12SXnfHgftDc1G4
166	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC5eV6dZ0XaCneVTPsRRB3FXNFe_lUsUHnborVF7WczXgIgQ0tr0YdZdjDBbvRkkPLae7-ZzeqwlL2AK86jNApDVfc
166	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDoSESmTYNWVZCqMKiVEgcp-TmProxL0dEDs6G809RvtAIhAPVAe_HjKWrAmNMNLJhLArP72llq4qbBhSDJ2izpe6DN
166	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIC2ImeDP9bEf0ghLkzb9uWsLHvcgiCWawficPD7XE_kOAiEAkHPgIO1py9sPqf3ulc1wVseuIYMKiA2RLXxt_j-3BDs
166	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIFlmHL6Khb_BMmxoxWILA-u8L58fnR_8slb9Ta6N6QoZAiEAuEj3gRj5gPCh-Mkj46oosqZynPdOM8O-buxJjpVHZDI
167	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD_xtc4Sqv0paUqhdpRXLpQ3PQZOmERV30-N6MWv4HjqgIgU175A1fmW9Hnenz_v3-0THq2kBHVgzM6Cf0FlAb-3lQ
167	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIC7WPiR0E4ZceMaL_IeJ81eKzWJasAsSccHnoFFugCxSAiEAvJGfz2kRnBYRL5E-vLMpuN8J3rz1ukFB0B8VyIFz92Q
167	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAz8cHSwRuCz_mPt87LcoBZLP-boGMSSpn20w_zFCodLAiAD-2sI1Y_tYYQS8ps0MflYbkSfJJmDB3-jvUGASmYQ6g
167	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDyGLGHN5nKYzXnXqsO3BAtuU9eMwelgxbbk5rsSSuxmwIgE8QIICXLcGq1ol82SCK3GqLwmzxQfRwLFxAD8hFKNlw
167	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCICuJMHbLWogLAwTeZ434uXMQIUtHmd_Af1lMvQeJPgCoAiBULyOte7BU66quD27tGdNVQ7UnsO_Rm-WjsBGk7GCe_w
168	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBBSJCNgKlQABPMFdJWZd1FVAN0zfK7qqoOoRMIqF9ihAiEAzcU-YhZFdGtjduWVOHOl_qdgqmhSMpMgDlGibe3tq7s
168	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCSkMOHkUW-HPmc4u5nqLuCpizjILb8pG2mJQjUS0L8qAIhAMu_CONCv-FUrlurbVkd2mZbc1FNZX4AmcpADotv5LT7
168	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCKz1U91afD7mRJE0vNBbltOIq9W15DcLSAuLWF8hFdnQIgDZt0QoiEF4A_3VzTOlL6XhxK9XEihAhKuJT8yqWsftQ
168	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDboAW2O4GbsZYR6ZTLfdeRGLi2i7Gty-yY9GzqxOkjRwIhAOJiavHmLGhmrG2769IVQk-MEBFihEgszY2w7h4nj-p9
168	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICVuub-oGnhmYvpKw6UAkua511TyJBxHuISSzWv2EQ9nAiEAi8eoOJTTbGiImq_FQk5w50dFvjCjZrzYIdD6OXMku-A
169	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDRB2gzwfgQ8i7y4Pd1xBN2xPe5T5xlUD5JFqC1wJBFSgIgDJIj_uF6j-Un9YHjWGhk1mHxybZBImaZgirlbgJcyq8
169	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIAx3T-oc_GB1TdO9JwfV4UKQs-JRsuQGsw9uAJfo3FSgAiBF004HwYWcTEcUYsEVt-yIx8l12esgrTFsT7Zo-c7yog
169	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCbXdw0ST0Y1O7GFb54OdohpZuAjHchp0QWGjjVo2ywJQIhANq0WtwCTpfPMxJr6KH9lq0acVOUbe1JQq9W1m_JwNjM
169	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCICYK6u03jUP348GS3k3Yz6ph_zRe2xm2GE7jetR1wKwUAiBcMqOyO4DXetPNz2ctsuC4MbxqqAAmmnReoDQ5uT1_Ng
169	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFxO6vPLUzgUx9zejEw_RhCVSDXq147B41Z4zdxZdYMEAiAYwBPcV1LT0Z4XBlJSEZm4ZMaTAwiX3jhu1wz0xXbyDw
170	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGQRsOtM0kZVCnRjRz7nRorz4ld5ttyNv3QrH81gUT3pAiBKsL-dkcCykBfvL0xKfATL0w4J-yExeVGVaFo-vL1rnw
170	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDqij-eF6nT8vsxnUpTZJCBjfWdsU73_GH-v-qch_QRmgIhAOfCOxy4Vcd3pVOYIoAbLIdJjmFQ6d8pfijrx9Yz9KJO
170	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICy65lz40ePFhMcw67UJxi7CAZiLtXRQi3fmhgtVj8mTAiBS98v4e04Z7qTdNupl-DI44kZfv9hJP9zqU_k8HWyYHQ
170	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBTUOfm2300XtgrOu_5oPEnQERTQ0ebPPfk1b8iQlvHfAiEAvuOQIx025RcdL5TU_3n79soMAbeZ2F4ZfTa6CkHOTyA
170	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCuo1N1xGHXQsX3TqeVOI_m4wOYZpkbVS7trZFrAjC4uAIhAIGzeVtUmo1nwbwePEOEYucywVmI0lkZi_1vpWV-sJ82
171	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBiVxFer44iHX0XM-hT3b2xHdkFxQ6g47RjzEs-yOHl5AiBytE9kLTYY8B97vNEWi5e8QFRzSEdpKIFXBTtuBjPFzg
171	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEbV1rK5nPHzyH6cq4J91F9LRCPJZz482cmeV9fRRJCQAiEA9T7TXX7989ER49UHwqdYXwo4im2boTv4MEWWC023d1Y
171	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCICpBqbklcX15LW8nv7xZdmYSByW_e3icgSBoZKU1-WIRAiEA4ereQOwOsv86QnhgVhr_bah2KET-qqEUpLGyzBj0HBE
171	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIGiyoSjDejPFMI4iKU9pLvLwueWeQM_fkqlcIGeTAR7LAiEA1PFXtG2p0iQOqy6GVZ_Mk0EmXvbmQGa9tt2E9ZC1fxU
171	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCYW40poT8aTgSB12KWzIqBSWqXy81K4CmwetSHTugh_gIhAJXRoQlAHRZBQgPp4hGzp6kBFn9l7mtyXykCg4yviF-O
172	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD4F5WFN_-88zXobBjqv_fYbjlVMz3RGr4yjmv6XfcemAIgf3vzUHxNoL2d02xbIF3dNR-4hZV_hFKTPVVuEJv1fps
172	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEa-g1BI7AMrVo9pLdVs_S3LKR92Jcb_krTLDn4TnE14AiEAm00GuPwY-3GW6T--17e_wh_ElxtzfZd_3vZaaHuKw2E
172	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGzl7SyBWXHNiNSlBjLNbKXgf0dnprA6rh6xu2tI-tP-AiEAtYkiewU69-8c3oubq0pd0L_9HITchn1aUoRUQKO58KQ
172	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDxfML8m4Wk8Mz8fRDD2fXhVTXXCtb6jyqkRBhlwF-riAIgZSdgdBcXmV9fvApLBsbdtxf-ILJ4WNMZeGl6GAVakWc
172	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCJzYUuKHipfu3iXRc45HGXXM9OBweAgFxb5Htj7Qe2MgIgS9WvAwQlr2odHLh3vbJOtbqZNFP1ja3D_-Cd-ILIRbY
173	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCVtM5-ka6CAJEh7-1ojyR1mP_NVuDl6EiHxi1-1VLYwQIhAP4C_6fpwvYSe8Ork2cArdmM-NOWu5lZxMOvubJEzOyv
173	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCICyybY9qwPpm_Z_Wojx2qPZIRBw8PSUDbVz3_2XL2vAdAiEAg-MVhS_QxDjwJtOmMo0EMZbNzox7fD70h3wIxF1MTrg
173	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIH8_aSOGcR80KNhRQ23d2rozw4mA6um4U9fXwdm7RtgZAiEAsm8KODQ6y4us3xR08Cn_CvFgSEGWs73WBPqAA92-1PE
173	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDcTN9cgIA_-EXMiYFVbg5redrTGk-1Vay25f00r-Qd3AIhAINASoFGy81JjcOgOsHokvmZf8rlykqTwrzcL17YhdJv
173	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIB0br-0N6MpiChr-OdxPgZlNmZbZvZaFlSLs2SvhYb2nAiB7aMvNL0byuoTzzA07BsLBIR3YYc4K5GmcDDdy31WcPw
174	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFAbpCp71KDBb0JeKAze1fz56YWJ5tYhs1x98dtQAvmVAiEAzMNJuhwmb51OtUA-Q2FXIYORbErXpQN1VtvY-vWXXWQ
174	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCOUH4ghF1trJU07Mics_K8pXzDK1cLLvZqXAvTpOTlAAIgaoR-pIh0P0sMT9PTtIyjsAK8M5bKz0zECXuS1__Vd5Q
174	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQC53anjHMZja_aAcIxFGSA9qH8SNVhQNUv8lL1Pl_lgigIhAISXJPXgv5kKi57oD5i3DIj_mQ8Va8wRcNDGAtbdz95Y
174	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCVDC17v7SWT30z3Pzudj8ivnq7uGCLOPsjC900gYg-MgIhAPJsPal1fcECSxMj9VyGssOiT983f56au2GxpTu_j9nU
174	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDhrYmZdvN9MLqXkCiIQHrF30ntlYlRq35KdXfiAZvA-AiACR43IGm9THQmwAXl3oUBxU5voipwhRxss8dc-fU2b1A
175	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBxEmULBFArSBM39LOSIA4a7LWI9yqo_fVhi3ZgY3nMzAiEAx-EX50_XgIGIJrSSwf5nbs-T1wi-nN0aXDyDjqYkw04
175	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGFEJBOEkCnV8LtqdnhsSrz4lPBWSmKjxvotQ4BDwsfWAiAzdWPqU4OZzcktwp6_spFOhAy9aTVrprLEuuFYcDoL3A
175	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIHu_Da_05Za1T6wFANXtVcXpoFvzn7cbo38QNnd2WIkkAiEA31nnCg6Vls2-dLUnNBGcBaaSp9zdkiTBCIHIURcA6xo
175	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCbLuagsn-Y__tleM99wcHcpCfqTpt5FJq3DP2wVn3DpQIhAIhqYZ5bnWE8CPGXKFjKP8chOH8jf_LDQjCjSDhwLb5l
175	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBtZfwV1J-4jQznXd_fVTuIoTkQjkjs98Xul7UtZM6tRAiBFoPVMjrdTFUzndPLhskRTlvnBeSS6lJQNXzy9aT-ZIA
176	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDgrgYULhQU5aThi_879MpkxM55uA5MkzuT0HXiOBQ07wIhAPd9PYbAoCc9L8XWru-ysFZrFXon-WJDG-rK5T9TRLUi
176	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEm_lZUPWnH_eaYH-TsVGFoB5Yy57tpVFlcR-2USGY5sAiAdaSc6E42MASk1ls4yc8_ANI4J4peP_3E8FI7ZtvG-hQ
176	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIBT1kCsY7QAFx6DhmsWo0HhOL2_JRgoQvQNpmKj5LOk_AiEAnBcS1ZBob01LzXM8HGGZlGnVKyWr_odHlm7E01Bj4fQ
176	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIETsnEchzo9cNci0saNgucfjOlDzBmdq_jZGOyZSRq4oAiAxCmYZcTZ4l8nRW4ursLv8MtuhserfUD0av2ZN8KUfrw
176	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIBVchKsDKCVQ_SdzDsYmKkG_pjbZ6EgmKE5yJy69tdtdAiAlFtgHa3LjH0JeMUwGk5OY_KQzpx01iDyXMzxCn-UsZQ
177	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDEUb6lO7BJoYO_vrzx1TP5MYYk0MClWVv6_KZe51hAkAIhALzhUW5hfyTeGrHe5aY5G0nyTkouBP5mGE6-wC7mEV-J
177	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGM5dwfQQuYrv0NyB9CN7EfBThxqEtZDzxpCw6pSO1IHAiAdyMby-yrIOYWOwenOcnSU-KosSu6o8oNe6reLgP7cXQ
177	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCUEWfDEz9V6rvObxusSpEArSr3vWfZQWEzaqyWLkV7swIhAKC5JuSVuLbBcp7A9AjpDCq4Kg9WPzGXqOs9hW838Z-K
177	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD1OeBpQy2ZQo-J9Z4MUmBmAlrJRC_PpyPjUcZRe8LU0gIgCL6OfpznbEzjUUYVsjvFc_p_RFajuNN2kL1tvBy7r2U
177	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGxE9__TNpAa-cIHBiuj8fYdjWl07iTAsgOlsv7Iglw0AiAp6dlbb6DnvLuFM686xm8QXDhOU43e0Pep1LsDZA5YLw
178	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICvJkQKQrb9ywt-xamsiWZaCwx4JCPU19pPNtUjuh75gAiA1XL9G7OJyvBJWOgF-MQeD8lwIaaLsRNaVlFyVECNlrA
178	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDip5C5V5AROA73nJOOf8CesAXPcblKAKWiMv-GB8M99AiEAww3R50sOCu_8ndVVS98yKNNzGpHrh_mu8_Fqu37m5Lg
178	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDCoc7NCe0WU09CXjEYxGeeZF0PdwiaY8ufkGhXT355TAiEAqCuK_Bv4RQebf98dGpltfmcCyh9dV9012g7-VgjlWJM
178	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDt5f043Mo4bHvc_E2eqIS_35RDLBtXbBicICPcZ43IVQIhAIvslBGEJt1bxP7LPTePv9tdtV95XdFUxrhbv8bslMs5
178	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGfM55yovrzPrI4KSRlipkqTEVl6sOMcq1n34E1iqYE5AiA9F8zUSNwyJQGkbW0Nni-MrivLmW-xHQEO6M2H7JfOSw
179	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIAQtCawGPnILDHeB10mvZJcg07h-fGZB3wGkj7DS5i1BAiEAny4k1nKR0Phm-EHL88FsyOGnP1Ql3NrXvBnquRMi3H4
179	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCIUFpeQvE6TtTY-NNklk9IZsv0ioR2ynD34NqXhv7nXgIgE9_AHXfSoZpH-e2xOGyNEFR8OW4361yuYhc3sVOURiY
179	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD-ZEwxLND6N7yGpsGuMpSebi6yGqN0BPstGmW4wsmmNAIhANk0lEh8cU-A41OvQUnNd_ShS6lbnEulbHz8pltZR1o1
179	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCHfg-6RyPVvk47pZziaRjBSP98u4qpnWYhDqo41Sdc6AIgO5RjUhnG1nk5NXQG7JpKsrKnxZJdobRxWckaF8U7Z0o
179	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCtRVu-Xogtdft2Iuv4YNl0a0zrKiD15_EgcohTdMlNTgIhAMJ2E2vIIPgbZZLRDv9XnRwQInmJsRAX2_XeTv7_Dqqg
180	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDq1xrIHczagD665sty5uRhw6ay0oK_NPRjAGzoxFp-CwIgAY7Ltay_ClH48CpH1KVvT4-VoR_hy0vpJCvzz_uuHcI
180	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCibTaoOjTXQ85bh-cW_rWJScfUX7hJkfITBVamQDszVQIgAxcXCclHrsLOd4D-MaRNiyZ1FllaUQz0j9_AmOrGkQs
180	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAHOhLi_DthUO-izcIgtyNTk85rzIEYrAHJ6IrCwzXZSAiEAiFxJX8YmRC-tbQUVWecbmiC1qfj6hwz1ugKMpY-tE88
180	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIAKQXqs7lFe0TwyUIaWRWngzWVrshSyISKP01f-f4NgJAiAP2BM3FcHXEBplXTiCDyRIw8b6pO0aplplEVmWcklXBQ
180	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD_qYD-hP8e9Vo7Y8nZsqtg4yRQBHZsEQ39fKoZQs-DSgIgWWT33cGcf68sTNjbqV3tGCwEA-eNlk8260TqP2X5SB0
181	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEXFpxZI40u8kmiQ8fNhQ2Vane8jl75kQ8p3yvdmDsmhAiEAzgBxo4i-HwrEtlYDyfz2ckcctpA7qosAB2H_VqAxoPQ
181	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEb1sOUEZ52PPCnjMDlgQiSA7qR28uKGRNOxmhv3hz_zAiEAmeIWg23euSAu3UErmake2OUWrovMvLAyJQehyeRoy9A
181	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDslFrSzqM7U1kDTcFi3VXk0s9YWZCM1exk_BuIWm3LTAiBoGAS0YBX-doa4d6bunZaDGzIOWJI6lLT1ii9boGexuw
181	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD2vK__2lV--8NUfUalJuI8LIiYtFCUDhv6jsMo6xBV_QIgXrdieCw-AAq4RaNQFsy60APpBP-DE160c9e6MoxZCo0
181	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIByicX86L9bfBHlfntBwWe0w-y2MdjdKH_ydCXrjlk0qAiEAuyiIEHLuChbD9sGHWlVVIxuvk73BZ72vQNhQYiwyOJw
182	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCthpTaQ1HatOlWSnmVgStDg4gGX1c3WwcPcoPQ1rRptwIgcA2kSuLjK27-FTQI3Ge2Q0xNyYje5bpaJWJb79C21tM
182	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIAwkGkxuylHvT_GdPLCWgVCRYTLZdUf5YZXN-AOF6HszAiBFCaHDeG7Z-b27gfXsARqswqF4_xecrzdsyKQFb_3y9g
182	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICtEDou8nq2p5u9xHoWBS_ZtzROnW_FERuhymmXl5OmkAiAAzIlaFCjIDD47v5ndJ4VIvKKcz188CHtcazOEAfrQHw
182	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDgn55cHYdf2ZU29SfwKvEiJmfvGg0t-2A_KfR5znZJSgIgMJz1jv-yyDCIBN-kdJsP-ZAZ4Z-t4BYllekIvFbjWAM
182	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIEBRGHfkEn_TTD87vfarlh0EIyS8Xi1LdMEkPIETU-ZXAiEAy1l0uJE4KeBAUJnAYPmnGkwxYNJQCMFz_rsP0YxAPmY
183	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD25DsouTUPlBv-prRZ6fNlouhjiCklJT4uOvpSYjOl1gIgLHJK6e2wRSVS_qYdiEeZmNMgEHKy_JeruLP3sl3S0QI
183	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEaeV7hS8zNTBR-YQDo9eeaauZOnED8xvtt1DXzXPgYcAiEAvsacWYOgtxRKxGcV3aKid_UasEAkJshWkbHkygYxCfo
183	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIHAeJs6nocYiKIFe1AEfxmuuYi0iY8ENi1mDQZqpNkbFAiEA755F4FVUKaGGfXTfS8JINMavRI2rAvuOyrrnq_m1_KY
183	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIAYoqiUdqyRXJ8624FbH3bJwpOxytP-ppxk50_u6hJH-AiEAu6CcdEfp_wqqbHOvZwTawr2JWI0_r3ttezL4EudAGDE
183	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIDOxN0pO1D55X2lD9ZZ8EDTwno9s1rfwPcBDuu99U2nfAiEAy41YZj_b6oiTXEipMs2IahE8D0oSfavVVlojScAZkiE
184	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDl6bcP3Nw3QLeEmiAYbe_tZIkM5DBmiqhBq7wOlOdrrQIgKji7maPowzacdZeIGUF6u8_mN1n-GRGA-ehBCkvyzuk
184	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCID7TYkLZl_UTJKbNdJuQK5OyF08Y1MJt02l3cPbzQZiZAiEAxcax6TnUAxvGo6e7XauON3EHlBtS8HNAuDBY3x-IFZY
184	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCFld8aE6MwqkltRJO8idLCNetA3oUzFtYnt-cjfmu6NwIhAIeFoHj_E6Wkz0NXsODPbZtXePOellzOmpW9I8gD8NLH
184	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEAINCT1RruZFlsyw5NL9w47DggLs43deMIFdgHiq79yAiEAw3hhNkLy9fXv4Bhi8UBD-J7YSLVZpzsYIaUx7YMROfg
184	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCQ7oPKMzB3wBYF8L7TiYNKgWL0F2Y1KDG_UAHmrL-rqQIhAJ5cyc0dOZXFybUWC5tnO0OYRgcmv3STGj_j8jpWGq91
185	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDyVPhwYeOq7LnJ1NORatmFM0OgU_RdiIkCH1a3MT9QEAiB0rWzAtYnPC9RpuwpOiQ-09uo4TlJSgbIFY4P9hEJ-_A
185	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCXihodoOe9e3U_UeiYk-5IW0IZxc4gP6pol2XvZAsvowIhAMMkrrtnEPjeTd1gtGntHvyiYs4p6jbPat7TQe1d8Srs
185	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDC8Uy0WdtrUwR1G0ikSNG8jg5OwsTKkuqZ7ICxifDUjgIhAM2Lca0KaEiTMmo82IhAbeFFMbV6Q0qDRLwQg4L7DKNN
185	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCmR6kyi3dBv0OxZKp-N06M3KLyAQHS3gOcRZyOuB6pZwIgU9FiAmaQd2mSFd1pY4E7R7RHxXAwdkPnXPfTWMOPGaY
185	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHZPooxVNfeQTTj0lYOFN5UZtuOWCTFIVnrumpon2bfMAiBbg2FIzTMPKoBdK8-rERtJKeg4aXLKZQhZJhCidZM3xw
186	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIEntpTna1FjjRZJGvz2vfGKYeIsHm2GuPCBOQvkDaOIUAiA4_xsHo2tpAae83Pg24nteaujLZq8WMIVrs-JQafwNlg
186	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC9jg7wLphNLwH3Vw-Aye11fdjueYiFwrWJ2TA1RxUHGwIgdS8TOA_BMeVSPIQmxoUc0lJYnkgv0Ma5mhC3CkxNs50
186	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD9PwKGZr5ZLTb-Zfhh1e_zkwswF32VnETgswKxLW56bwIhAPNeNXpfEDcyNcNUG3hXyH1_RbcE7-_h2Q6SbT7n8deq
186	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDE9dKzQzsR3oFOs_QM9LeJH75npBSjD8srmu3kc359YwIgQGDP-oYfbyj9EYgtp-22YL3_4-aJnHEGSE4shfNR8Fs
186	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQD4ZPEQJRxQPLL-CeOJFPVCyKxL8JfmvXyoQ84ZFniIbwIhANOk--2IlVdWQgWVs3xduI0WAXZFJKXeP3p-d6cF1wjo
187	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIENW2FozfCWynWnmprzixLiXG3CwXhWou68qTjdNMh96AiEAzBoAPtPsxnmzXwmQKr2-DMrIr7z7aZ5q2e9YvcBONg4
187	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCID7wNCsSS-qwYLe0oapK-jZ8CbGdPzhtooSEghq_uvZHAiEA-crA559OVqd0hFitaHE427II9xvlWsoEWHIh8i1BxTY
187	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDOXP5iK_0hVvna-_zqyJ95NIY2_itnTd5ZCQtgLY0QDAIgd557vIzF_CdGAURtixBl4_K1-eL5s6Gz6kf6a_5eATQ
187	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDUFfzIOqNdYVwvtRle4uOx7jZFvYtSXY0CCeLfBG8u6wIgTnDZIOtQstwtRAaAvPDkB7jOpjI4FDFxPESKWZSpTNE
187	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIHYxLtSfiK_6X-ua20iM0iNdqtW-rRvKELKuo4LPiauwAiA2gjyt5rtdePD5duTULPdLgwCZDlLXop54B9dQLcWceg
188	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDUGM8SDhx1YwxfKSiaDSdR61g4Jg5JMewaAAkaueMOegIgRiDGRNHzYZqBTdbKWaZSxlXUR_5S_9E2LvCm73zdXAc
188	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIH-TfuUMs9g6BAiGxFAx7Q7lg9VN_OHc6eTl1f7MCjHcAiBlXbVjt3RwD3I7pCJGTah2qXBu2xjHugVGvKyACrciYw
188	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDr3c4SMxWUu-4kKGFCAOfaHaE5bkTo7YdhtKzypj9ojgIhAKAA0xqpnFMpjMK3IXzv_zpD70InqO9_22vVW98VYzAo
188	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIE_I7KhT2Lb6YBp23Wl62EZGmiAJFZTFFdBu2LEKt2LMAiEA9UGa9DaL38yFfOberMz9Agenli_EPmgu6_JzSUU8oeI
188	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDllXObd82jzqWac22L5NjM14KhmqVOJb2weeCNyFeqFwIgDP6xYns9osLLNVFQgP-MPod_mB-Z_CBJUud7f7iki8s
189	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQClhb1y5zrrsv56vmhUxmu7zuQaJ9q76VEU8LxcZr5ZFAIhAMWiy8vmPqXY99_DtDmjczEJiFeiCaERoCFGx9rHIWns
189	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIAyMYDlmONc6pUKsyZA-s1YEe5hfFhEwPrGg_8PNGRbeAiEA1GjyykCZNaEWMe7BcdXNhGFjCLTAWjVMzLoOEujmGOc
189	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCID0YcCPcovOY1QalJ4K5anwzaQlM07X2W7aoXaxUJKwOAiBoK4C0OYd8I0k9hVAgSjDZ8ljiupaj-NBJExRAu7OAvg
189	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGUzYIV4jhFDlVoABQBYuLB_DcQdSCMCgTNbj72SExx2AiEA6u_d4XLE_b8x333ZG5NVP9SBU_eOB-aGYwoe8UhkK9U
189	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHw6VgnoGDnxlRoYVH9aSemAV-20a8gyuVXKcoiBnA1fAiBVl2-LBBTyG6m98SAj8P22VUUoD2LPMBSmQKio9Zn8sw
190	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCZh7Y1Dd-NAANbOfTPesdq7lyGCWmF_MIpSCfv-9uR2gIhANTmeG7GF1CtavSHPOKREyKvGI04sdC-OvdZ8LyTyFHv
190	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFL0s4AdLQrn9WeZKU1aliZ-10uw6U4g3sZafIsAvLUPAiAaU6dvq1xmftLmWDSEJ3SMYpoGpyh-m0Ly3J43U5Wj8g
190	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDbD618xgSeJZCFj9gqFQuUKBjATO2H5VPVsztfab_k1gIhAMLVRQNhzw8rva9tbJGdFV424G0O4ohcwgUdcYpTs75Z
190	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAuKZqcUqKIktAwlQ-lZk6Xdm5wzVkUdfOXSsQgTxI9GAiEA2FeaX2JeHUr7iKyw_2RH_Z2yWlm2JxIDV1Or06V7PQ0
190	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCzyC5NjeadMMIN_m2pMhO1YkoA3560MSkE4mMOW8KsDgIgKqVP3_4nKqO21a85dbYagilBOPunUfQ5PlAt5DsxOfE
191	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHX7-ldg7IciSsrrZuU0QuINdgqozgWYW5dUYsSDU6xfAiEAnp3mTRmx90Wo1GNNm4nTP9exMIrMifdk9nEcboxRe_Q
191	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDBre5NC-PPTaSV6mk9lN0DbTE3ECMFRB77AHmD68tI4wIgK0lxQVNj4uM1nj78QYcJpPpg-NSxRhGmk_h2RfhU6PE
191	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDPj_4IsPs2-L1Qr5aS4B36Cs52DJe8SttNvOA7T7fGRgIgbTcpe5xKhcPKOuKUmAeuSg37_aAYKbAUX5kmGRdNnog
191	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDZFABmPdhZj4rOJ9W54SuSgTKgj51AHzkBMWGBeSxF0gIhALohnMH_4kbQ0V_JsnXYCUZiKDivdzvk59RBnkrbUByI
191	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIAT8JGmbn2uk7TXY1BsxaxYoLMxLgx6BBA_oI25bMcWuAiA5ePc5xNh8AtOOKnHBpCTv2byHm-pa6wEQz3Ic0GR8dg
192	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICtpC2G91ahm7zqn-_lRD1IQwQinNKw1_BGFRhIHLJCMAiB0NeJJDrsFEyrngo3FTrymEbj90bvA0qD6nNleGSwO_Q
192	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIARlqRomSiJwRR4MWbg-fNIdvwkZ67_5wVCOwCdtp2Q5AiEA92DgGjJGHf8fMuTUwcKFy92CQeP2gyuk7PRm3xklsl4
192	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIC-nhvdKwIo9R4AOmNGUketBk-rvTTdSSwmA4oVlmB5zAiB4YqOZ7ZBL-urHBUEiuCd9STVJa58kpEbzDSvbf1Qn9g
192	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCiLCA3Ikk5dqkKVs3iEkyECyG8KdtCxn3TjpCNgIusgwIhAPscSExXb01CUGP4RQN1rWfQoEm24dWqxksCKOUzQclC
192	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCEPxBf5_29x5pL4ZE14U2JSSsd0CErqD0T9P9qBQYbZgIgHOTSDmWw4kYPXc3bB9MhloCIjiEEu0jN_vXfJAGE_9M
193	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCvVjsQH704BqkxygnNynO9O6YDz9o16Uiqw8w66DIMoAIhAKgYBCiJ55i8EKslCFpnHebJU1H6K48jUjkyenc4XbAv
193	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCoWHI2_t719sRSg42Y0JXed73SvtWbZtcGtiTO45-u6AIgVY3ADFv4SFoP16Vn3yeAlzh-CHoO2s4UwkusSar-z0w
193	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDNoMUlybpoG45yBbhIyxEfx5sq4LcIsG1SA0KxOEYl1gIgZDFM_OOxXqqBe3Z6J6A3TWZTmkhFKehD6CmjV_gk6hY
193	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQC5TaTKDdOjnd-et4eYfs-npzQ43Gp0ayh1ZuVe9qG-6QIgMejD1qu2vezTT6Xvhrmc8hEl3Xw06vmPAegRftnn160
193	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDlc2Mtgrr-tuz2OFNCSHn7CyYcCKXQZq6-PXL0_hICRAiBpO17sh2DA8KquyQhG-U61R9Rxo1wraqX-QPIBLzDzog
194	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDuJhbBAf7n6s5sxkTQZrm0Jvwd7XlfNK6m4rEpxyGvDgIhAKq4BmFwSkVUoLFUUEPmryuveNXPsPQZKn8CbXy5pKnx
194	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCGKONZn88kQlrtZPwK9EMNkA4lGnWQDkNBDEXbfhErwgIgW05RrVb9mnF0mBxwiErYYdAevlB5G2Kna81Py-Rqvdk
194	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIELgZeITWjRq1HlAPcFicmg6M8TNpUS8DNl80Pn27nODAiEAxN3R2pqlVbznW0D_XsflUm2yi64QKkscMGqS8hBJNLY
194	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD3eopQHlZdIRzP39f7zeOgkeCLvun3U4nBWNO--4V8EgIhAM5rOMuydu3EaMv71nwcdKgW4m0mJJAZ7HIferytZUOp
194	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIEchJCs9q72NZnJ03wMXVQLCHWO0QAD9gNvWOBq2DgrzAiAaOQ_g3vv1-hLNfsYaeW-Tp0xQ9REJK1NFXenYUVos1A
195	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC5VOACYLkQKJXQrxvWOtXcjyb2h97No14bSDxWpuehUgIhAL4uWsfYN1rve8EK2dUVc7SyZKR0auDErPFYCbXC2JVH
195	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDIu1OSe-QEzJRFffQaOX6hrYOEkFri8f77ZGYidpFtIQIhAOCSqmAsnwYGS9mM5oQPCfru5LrTSOguRFlQTIioB1TO
195	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEWEtaQeTCpqw84o5BdAMfypWFMgXsofSfPFNXMRu9x7AiBRIiFgjh_WYnF7SSjwe7_OGsT8ZSGd9hOCDa2y61x-tw
195	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIHUTvhPpfikHKMO9k7ve1bcjItdZ8jrBrID-UwGsGAtdAiEA1lunFx9UB9hj4v-zF7rfLzgU6xnm8fdTru-nS4IIw88
195	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIDU2Uf9Nxd27M0hQlZGyTdPDE2MJclh-xm_erhAJBfBBAiEAqC8aTedfT_3fstyEX7jg5okjG5WdujhIarf-l-bGg0I
196	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQC0z7c5xpHxsUeus0kZM-RNylwRvsHjsfEk-MY9Uv4K2gIhALL7Lb6CsUlad098INvwhrRKUqlnLbUxsJznkxnKUMea
196	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC41kQgVpNLCxTwiyKCdUH2cZANVRuS7S3ZykkPrN7hXAIhAKpE479yM7HnNULRHEr6pTx6R7PRB26biCTGBFQIfttF
196	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGoF8JQutW0dw30QjbSMTlbHGrNTF9qFVMvGX-y3p940AiAWTWK5Ayy3T4ygCzgvRQ7saAwoS-GXJ1nOcduGTf6BKg
196	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCgGCOZDhPXXefKCtvkSBtQuFkRaXs6OTD2lb6pvInpJAIhAJ7wOjgXDKl6HoooP9Ex5jNqk5rXeQdy2RGFxd7Z3Jy9
196	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIF0AFy1diXmqdQMHSa33rKMSD-KCcSEYlN8aTOUalHxpAiEA-Zvhqa0HwOxlzlpi4RahGbjMOCIdg8dKSAGd6nyJZfg
197	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICaMQQ3wEbhfpMIU5ibv1mXsIQsmPOBVBBAAvni3qZl0AiBsAJG9LyvVD7oxw9tewa-pYMtEbySvRb5V6U-pzNhXKw
197	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDJ5xig4sYV6ZiCuuMH3xd2tEe1FSyDfBeVlcNHUt37ywIgEj2IKIrKxiHRkmJYIv6tVMH4x9f0O-Dmtf0eyoHoQVw
197	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCbWZyFD7pEghFiw3_VG7AGwClJA6ToEWT6a-Z7zwpMGgIgU6I0a_DroZvVJi9yX_OtgiEt4ZH0irQqPR0JDV-EBTk
197	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICtvjQqRZyfBBa75DkEdWb58JM-czwhDaqJS-Bj5gCArAiAvxusES2ExEkDFL9zarPS9ZJ_1nrL7ce110Ntxwhf-DQ
197	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIAxoXvkf1Kc0HlOS9zwbmYIcxxQ9aJlMTYsMRDwSz4d-AiBw5sQTLD2ZR00hAHl7bPb5wQ-HWKLd6LVd3QxgAyLsHg
198	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIB0bLDNpPQ2CZ5yXV9qHP7B59hPyWT_XpZiVY1O_eLm6AiBvJMnoMKsAIkDSaTmOJohS2LZRpAdRQZ7oziyHANtUWQ
198	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCLUflmnhE7OPCm1XGUcj1fD6cv6cFZl1I3VrrHEWPIgAIhAO61-2t8NaPCjXsnNZGsIBM32aBgoI2YyrcXF_DdG5tw
198	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIASsZ3GjU_9oTiio0y4NSKN3Yc0TCJ2RTZA0DGKxDjScAiEA61civVcGLKGr8gVg3ihtONtQW4YJzQeTEiyh-NC_WRU
198	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDfekokDxGbCcl5qOMCAWSjPB1xsTUFOb1tsYxpYNL6UwIgCNFNJNrx1Xky86hQTcRBYAdSFk6KQJTVv3ZSi-Inn3E
198	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIE--iQNnWRp_tbDAC4tm_X-_zoquCQlqqdh-EZMUwT_ZAiEAgcGT4DCYOuo_Y1Ox7x2OtHv3_9emqWUYt0TdfCKARxM
199	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCsJY5lbI7T4bqxQBML4ESHul9T5lDDjORQEDoPJJ14DAIhAO6fyLgMgSBCiANN5FCIlxY5YL5DyNs6L1uxtuqlJ29o
199	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBy9MwxwkXgqsF30PJFo41KMJOlnUZy-oGsYzGzX3OjnAiEA3P1kOx7w0_NEvohEHDSGYMcHx2WKMEzRkpcbCyulUNs
199	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDPuiWRO3VH-LdMVcPCwPyR0JIQa3gSo3aDhhy3pvZFpAiEAio6xhLNmKSOz3S21RSMTGGjqre6L_XYpQy5SpYBnPIY
199	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCBvf13nm2XCIzEQoej8HevAOJw3esmj7mdnm1kMABKNwIgO8gFj1_5TmNLHkZ3f8zGwWvQ6_cv5BbSekK4CTC2E4s
199	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIAC300TOWgK0gtCn06-NhH1_G23TiPjUlhdZU0cOEbzKAiAjG1BXhtl1E6xTgGqUNTZ8IDC3HJHoDk70ZuMHgB8QXg
200	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDkA5o1F3U0F6WCNNzLfFuOqkCWon5ZeoZQYplMYTIGgQIgOluj_W4K3-8b0P-9oPUAThTcGEChbgT_LAgIMPZrdDQ
200	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIG9eXVI92b_tfa4hNq2iQOSpouvMRVMeSCA3lyNWAtJ3AiEA-hrOs6hSYOwNDbOBV81vzeo154Iut1NROLhuwrR2yGE
200	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQD9VyyiAibWmppv2_UISmsdqcq2BoigOucd5Rco5QyNfgIgXnKKGJ3CMHAYj0g-3wkrynKDgZ0IudagWDKe76R5F-I
200	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIHD6ON5LwLzhadhruaBN9oYx6XexRJaQhcAoffHB2NeUAiEAxBc1ZUy3h10h09iV9tGS5rhC3kSzRfXty5eIIPOjarA
200	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIDWrte6yj89g9qEgdTcs6xhfjbu9qwwM2rGqLTG3rCHJAiEAg9QluY_XuE0-GFMn5bWbSx-xIJz0DvtHmKraCLvnT8c
201	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIG_rcjlYNh2ZQ6IxPcsYcI6jAmoroOEcSYumYUQMT9dkAiEAoqVsBHNl-19kRbiSE-suw_uS5haBFlR56fPBpD9G54A
201	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDvZNWN7WRQCWN8EbjFIH_MIwtJhbY0XRQXLZErAGoF2AiAlOTsmpWOdg9osdI_cVFxPsyasrekfJXctf03n2voVdg
201	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCGKpYD16Q3_Os8uJ9ZPkx6utAbKSgTc4Ca55iQ7xZpEQIgeuKOWRqlPb4Cdi-fG6V_4bRW32bn0rzSfWeFvHdoZZQ
201	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIHqQ0A2y-fCg12AAtptsNEzOEYJDg5zXKe6Yb69WdyrJAiEAzLFr8VZ8aanzaenH9sa8zVAJmbv7S310MbieBqiigfI
201	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDYwSlYmjKkcPM5JaZtf1VHO6_odbrd_xd1yCD5gfAmHAIgfPAVW8BLpu9HjJ4EFW-uyJkURAHuuOfYmENzNCZBfzc
202	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCSFZoAUEio8VyDK2hsydMsRvtseSkgTlOIgdu0gsD2ewIhAIhkMqtAfNuMjlidK9oGgGpXEgSTr8Q8Zp6ljn36tZW9
202	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC3vJCvDuUX8HnvARh1TOuDdpUF26LstIvpsAxHo2cydgIgLN9G-7JAOn_pa-i5UZj4mCjxtfQXrgtH7AdA7VaOVCE
202	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFbBsapjUxbhZzTkoWYsa8GtjOf15s59A9S1zPEAFWkgAiBXqhAmau5zwOnS1He05rDdfS-UVUhHY9pAabMqTsANGw
202	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGJT4fgfhxWdpzQ2kieC89xvlaKZZqxPW69XcamepPXIAiEA077eVGn3pyQCy6f1mwm82lRPC90Mld92KoxkK_xZQow
202	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDi2s-2BdyGRh_t8bi6QIMjomDTHmD9_LxFEMhnV_VIJgIgHPio7ns3WdFljxiGsGj4zJQLJiLIH-xhkXl7jwRcslA
203	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD6bg0j4LILgX3tvq1txC4u0KQsz_sDBCIKENWyjX0gWAIhAOOXrYTWKT55OnJ-Vz9Ltg6afPVeIEvIkH7xcG5JTJ6s
203	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBhmC2NLeQc48p76XbyFg5l2R_q6dcFy1adcDqAnu8NIAiEAzZjWr4173YtPatsKWW68VBlTwG2SwIrxKGnjWIa8EWQ
203	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD3Jz04RO4wMdPRYSDNaAd4e8vgih-mJrTPzEjZoEus5AIhAIiSckXurwmpylF3nZueD_PfWmD94j0kaCMZEhoByaAh
203	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICYaotjOMCX-261jEnO4mQFV3X41IcloMpWW69eOxosFAiEAqmfs8LFPQIKDi7Ec5BPGZfgGPJ7w1fRkE5pz0t1giS4
203	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCJGsQ4Y30LcWCOwAruEGerpPR9LooV2I61G3PmWo59DQIgYllE-ZMEd1Wdot7bR-S20YqPpPcEm_bQSfKd_okc4HU
204	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCOAT1-33fL71UU52i2gXOv7pj9z0RZPQaRWvN7V2qv4wIhAJERc3bwDUuOGCIzMfEQVUslRyN4SG8YN6duEUKGNnp5
204	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQC2Klh2w3CgtxjjEqRa6ZjOn7SkZ9oMEXGEkhXle7M-HQIhAN1zwtdSMa4ohkbp73XnKqgLFbnZrBlZ8YvhEeKA9295
204	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIA4m0HbixtZrX-xPPVI9MsqejMfOS0cg6Dmh6hLOlFrgAiBM0X4SyBiZHz0EtOsuRNVZ5mkTBi2o87d1SH-evHZ9Hg
204	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDIXsEiFYMZPPhUsL6y-BRSqBZz3Dd_oD6kRhPZbbBlngIhAO4DVZU7Gy12YtQZmYcS1AmBOJOm6evV905BXtUCCZTz
204	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIFaFw9f-jpQM8ptQsJyywGf1RJ4CAl8x-0UnqWUi6fE-AiEAyWP2ebxggPDkntQYgJQuwaoI9TJghvpeSdi72R2-EBA
205	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDtMxi4E9j_3oIRdvmAjysW4nljkQq4crkiXyyhHRiYIwIgWVnRvf2hw094UKIBy97SG3pdiwY6zB5aWSUcZsxnbgw
205	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEGiEuG_0XDtwpBZJ4lOjNh0X8pYnBe7JH6P_rDQIh7bAiB5lJ_-IsxYe8Ci9qm9MH1LvS3q9SfOXQiTmCxDMxnw9g
205	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCIsgzNu64kd6LEHa1DzknSfDnwSIZ7yH0w1VLDc5RCkgIgZ2w4E5Di6M0PFgt-Xdn6b6lBtzYJn1WNcMTknle7twQ
205	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD2y3Xm_mQuzEfZrMtxx1_M5895JA94cxi353PT0VPSdwIhAIg6Nj-w8p4FLWJAxZgnyYflXJvzZW--jDKtoNIyozZN
205	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCOYvOiUFasjmEci1ITWI8_rQA-mjd6X0wcVyGVORrCQAIgAXtrDjqQ7oXM4Y-fu9Cp6Chbkl_s33CJSP31s0KUt1M
206	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDzhHwBjtHGmTMYk0Fm0XnbATNpbtRT1LeF56Mg6fSsNgIgPvkfYsUuyJ8qyr2iOr178jh2WNz-bdzUHcGzlstlzw8
206	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDVRGmQU3Xnf_hrzAVas93Tvu_XI3guaiUilXIj4roHBwIhAOFoJrcvZIoB46QP8wVVRNu3nPWa7kolSF4wtkNO3qzi
206	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGNtGC_HDzPxiZFW061MCl9W1gOkoYInIqoJnaqf7jfbAiBzczikJacy1YkZ-RdZqR8Tj9hNW23Yd3TJO2-wenVF3A
206	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIHT0PyP9whDOivzS3xk7iJqL3w7-FOsylnESOyZpaxiQAiBuEsLwmuuJHgAs5EEf662Jw-4Yr1rd9Gie24wagyuRbw
206	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIAquRQ0T-mzoFz7cky0YSl3Y0xodqfR-kfUKogBZoqsbAiEAmFTy3fjPO2Q3AEf9-idlkbCeB0MjDscDYVjuex6j3kM
207	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCu_DwUVE7Vz-Ro4qIgtjyl9zU_sEvbAOXMlwJLNJnLLwIhAIw-x-wU0tJvoo7z4ctTkbj-LcvjMjT7gmi7HVyFtbIN
207	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDSpAS9vJ0nvaMpJIflchsKsEUbIyZ11OhxqUwhQsCBwQIgJkOPylwO0r6rVniYZmdDfngfuVQGkcn_wHcV2bkckj4
207	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGjML_gMXfnJgnCSrMOrcl9dTHYkLQz3Y0bSQx7aiIoHAiADT4Xa3Pda-p-YB0fKoM--yTgvj9VVgFW9v-WETBEFsg
207	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDNyj_hE8LPnJJL-FyhyzOcNjVMr2rVwioZLmVtWSe_RAIgUpNlitdQazjpCdJCcC28ffGW_tudkkU_TK-8mypMVKM
207	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIAqNv9d96KwSzqOa3-7t3r1E4y4CgU9MB4Fb_WY68QcCAiEAg5pDOBwkQb0zRXtE4aOaYMlQIZWOqK4CuHkAaY9993Q
208	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD0l7RiPHUnjrhR2q6Efr0YPs7kAbBPNSBHJgpXU_wqWAIgSnqmoydvrmyzhfBqfCvPPdv2GuAfac72lNTjgdETIM0
208	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDo_skpjwQnRbCsPhZsyV2LSHMwUCJfLGNA0IDVAhmFnQIgSVphsIg5yPaMgH6CvMf565nWiyW0StyQvvTip_eb-jM
208	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEFr5SgsHHdsnoq0WY8l3deuWN9YQHeeF3_VokTdaj2UAiA8typwY2qd7zvfG3amWQ3qJhdZUqHiBFE4M-P4K54PQA
208	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCgTu9pXrwtp2KQ3GGU9mja_4XEQwtPZKYUFSkWQBmxLwIhAKhSkuzhJ2MnlreXQAupWF1O6LuUVc87l3YEK0hcMIgo
208	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFSYnH5u73aI4zo8jXuZKbz2WvQWOG9Q7lqoq0fPfvd1AiAzFZw6irrESY0HWyl9GoSWVTfijZIRNO83Jb_3vGasQw
209	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD1JKfCAMyJw8ojRU2_414k_ooDUNbVrY9VS94E8z6aOgIgeoUkIIbXellzqpeagpdL3Pita-UOA3m7X-A0N0LgSnU
209	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDS13Nq05ATPxgma1x0UrhH3f4INezMwoGLh3u1QdvBUQIgYKNAZGspaDYr8uvAa39HsQBjJKnEe5lYZrY_L-OOwgI
209	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGDi6CqhIB2z8xoj8aDrjJy8GL8k8pzPZZu6sbcl9jy0AiEAy8qlqfjC8WuDPVg33IxT3r_skFefG0UVu21pT8TJxp4
209	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIH5_ylsNvg86Q-pbm-hsUaxGaDgMfzNO4sgSplLYt6IrAiEAnuo6ftcFR0WszBnA6nUQXJI-kkcGCrrKwlYub5Gksp4
209	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGQGeLQInX3hXUssVrs-jClzihohQz1xjdaJo8Kl3_bwAiEAj5v4E_7P4LqGjnfTs_zPPLWZ2GoMRlmQFZO8j7tzX2o
210	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIF74iGG5N1yTAD3YR-yKwkQIz1Yjgfk_NGsNKg4_8bnwAiEAqZv9BdTPRYW5TdYgh64GsG0tsmY2UWmjF55lAugf9dc
210	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCO4F8kV_Estwgfw3uXMxYB8gF2VxwxWjZQJi0i-sD5TAIhAOYOfUdmNBMRRqnyqdnAhtXoqoVZkX2RReovYZaJZ44d
210	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIFOf2E026avxE1u8OU1A7C45_xJM_4TRv1LpetadFKq6AiEAsxdgqV6K0pSzkEtJWPYYgKbZDxEeg6Z7pu3i-9RTw4Y
210	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDSq1yXt85RH49xPV8DbKPYDx6Dmpg89DKkenBVtxdyTAIgPrnnhdsYykIhyy3CUKLd_2oNrYt6Wo0uioDJ8n2i2Rg
210	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDI_Z9PdydbUjMFofcuHFMbSt1HgXQ8o6qjA29AsL6i1wIgcvigZY3iMxgjO1mPirYlxycEzLMglAKXoArnbfpTzQU
211	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICeGDgl5Ceh4JEaBinwzoCnDBms3OX3eVqDXNaruzQoeAiB6CI-kkUSWAwCrj036v6yqyte00OJA9doQ-lPw36T3sg
211	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCuXbq5em9oPpcEGK394IUk79iss_x4q_EzbuHQ_FG8RgIhAOq-HYa928JtFHhqzFZFA8lTXejf8hyO6uzcsekrhsWz
211	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCID8yr7U6XWzNd3zNCUCX0mhARX67GE_pyGvSokmdwBkdAiEArrhoyq2LGZU_5rSWiyC5edz7XNxdOQQo2_GDyph92Jk
211	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICL5TpgGzecs_HoPgStdyEJOMWUBmTRpg_YyovZ0qybRAiBvGKj-krBtwpSuW92DxC5oHt0z_yP8Nrjw3aeLTrlKEQ
211	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIElwUWkZbhdjm_VbWzWzErv0knG96qJKCitCR7f7Yw4GAiEA4MNSHp73QZzZccEd-7YzTBz3cnEQ07klSF3F1IkHdcs
212	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDGBP5gLaT872DVBGGgGskJ-unVph5A463bORhnNN4J8QIhAOIizhbxvx-3PcsuXfY8ZnilWwlf4-nY7zC1AhjOHpUP
212	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDeMULbyhBiyWkBhM0YIABi3FqOB_qMXMZmv0KAyhsFjwIgZHOd1RgmUudNuynQ_PuaQy7uwhJUz-_PVxF6_mHOdgs
212	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDdI0J3r-KXctPPOzKv86fmD1o3ON_HfgpNJB4dUCMUsQIgM0dEqeUhdNiU3rIcRWPNLoILXvEn8e5uyjItSfBKnys
212	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICYRnrFODMDxM3dIlQ1MgO3X1a6lpZi4fSbOyKx_0j3EAiArgki6-zqWFuN7pAiJFPzzq3ba6abMJVk644U0iwHmQQ
212	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDmzL9pFjtRB_i8ZcAI29WNv4F1Cp6NImwP2WQTVgIcwQIgHFdABgHXUhsCfWAySXDnwU1EmT5-VOLOit4MtvINWUw
213	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIB1PnJE0qPJA5HeBC0buYfAOfZ2fXB3GqpO8EzzZeJ5VAiEA5zSWXLTfEaItIZsuNUe669OqoDhcw31aTcnb21RFoQk
213	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCBBmVCapDJLBlSRNCa7qETPrC6WHk5XvZaheBVEHtl2gIhAL4U-ailJMciqBwbSJn3BmikgUncBBY1zq9t_uds-mqo
213	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQChYT0C01YaMRQy6eACV5jxK9xyLxpkQQn1h8imPVO7MQIhAPuil4gbk62Vzsoyf9e95l_w3agSHl9aeqQnd2r6GQ9s
213	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDpYXJpX5BgMbeYlr0v5x2GWalo50oAEJmB-u5bL5sY4QIgUaUrCXvvF9i7U77vC5hG5NMyZ_MZoxJ0CcqJAl0wIC0
213	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCZzl7njqJT359479HYphN707YsGRtp7_8nDOXr6CB-CAIhAL1iXniTWu--fhG0Z0vk-sD6d_bnfOAyqkDmRSKcGLrA
214	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDOwIispLVDCF2zsDmx6HEzM3kDG9VnRtqmpc9VGqJdUgIhAIuXmtsXKkXbI3atUw5vBJBy_upt8Exp10krYwpPfiUb
214	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIF0Ly0vEsBxs4pfH2g5yJD8PFtcWOuSDkARt2sTM2u_tAiA6oveAmWJRCzkPU6ahEM_32QulTkdajm5fwmO2PsvkVA
214	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCfUb9bZQQme12iKYHXXactUOQG8dWXbCZriTBSW3_6kwIgKEQ-RK6l9eB-Y50XG3m4Z8DU5BRMtDy1idsv70RluWI
214	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIA2ygt-JwfrwFACLdVv18PSchniDKP8fVoI3Io_RPzaRAiB9MoYlPgDJEeRgsvf1SzmhuutMPxNHledisAL1ezfb_Q
214	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCr6ngy78O-Gg75E9C8WK8X9rdBx0myh8kPcup0AVdt4QIhAP9oYInlAtyaPvRLfWh_2DIrhJlD1Tph9iDbyNEIWiRy
215	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDe4WNrwxuJ6ea6a0SJ9enxWwwVEEEUMwJd9ZTEn0znlwIhAMzQkbeC3oZH22bZwJ_ngmn-FlZYEl1jN35yVjnMeSy1
215	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBi5a4Gj8qSogWg0Ps1FIJ0gBBqSozyISdW4-AWqtLAeAiEAq5AozykA2M4Ky_g6UHmn-VjPiMbkm4ecRvqY2brdofc
215	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEq07WmeovsmInSbKRrp4la8PXDOppvFAfwt-fhPFtz5AiAmRw1N4cOFxi3EFgm_jwAxOmoxQUy0gcwEgO9ESwPO6w
215	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDCE1mEmmY4HIdTSf5Y1ac1a3c3CmYK1PDESSDzrHYeTwIhAMIqIxVmD_xLIxsfPYnPlKtMmoTd7-i4g2DeUHmsKdgf
215	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD2ZodcPgTky35sJ6lK4o_UoiKjmc1Za8-2kPpPAFlITAIgP8CQo1buLyo0N8iz_najQDvcT3QC7mEg5Inz54wORXo
216	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAscUbsL-flu1TsXPW1nd3d1fPDt3b5LLk2o6ogCr3sSAiBy1tRrJz3i546AQCvJLPeH8iHSxyCFlwUCijwgehYY8Q
216	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIE9uVwoq3j_Db1Nkw1TzSys4af0VZyxogj2rRiTOERSUAiAbrsqBOgwomUEPmjG038ygzPylYwusE-ySbKzobwTTcQ
216	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD2i7l-pR-0SfwSz1fXIxq_VhTRmMTs6c0yqGDsKKh8ugIhAPU133-utT4GGL_FDaHIdowXyarCcRmloAdDnPNuQ7-h
216	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIAZqmh8ZqUMZCarqmB4A6WPDahuEuY5h-_-CN7WrZBEjAiAmbg_8O1mjfq-l9pqS9QNEyhm4uptYGXd5v_JNDUTMbA
216	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIHrb9ioBeIcIThk54_Q19z2M1MMqpthA-ul7oaspAZ5xAiBPJDngW4OFfOrUONr8HRau1bLaBVMXGUm0g-MMl9Y6tg
217	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFmZKX-leZ705iu2c1KPS1FbkJfm0MaU67FAsQVAtHwXAiEAyc2RVjbJhrLzf7HUvP75xdqqg7zvyQ6In2TPUPoBOxI
217	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD-28ZLsQD-2foxykwrZJ0KIaahwx_fUEUvx4rVSRTiCAIhAKpWfLOBGxrpXWrkbTY766BCC-7rzI6Z6otiOFyE-UFU
217	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFBGCIIFDZwgxm90Nubch2O14i9zg8vBTakxPCzxR-t9AiAu2ArVuyGaGAZOz6XvkImO7Ydl6n4hohPZCGRvmkC6lw
217	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFjYT3XfzrytznuimyDdkI5NgR0aw09zwPL1mEjjvG89AiEAwLLAEDGo-ST1rRldgZS0e8boAVjVU7SvdVrcQs22K_0
217	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBdWtFAOcvEd8gS1Bb5UIjYgCHxNiUiH5VtUBOOT9V02AiB2EWslxKqH-vQVKOw-S-43QRg8uYU9jgmF8jj9_73Cgg
218	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFMGjN-IP0nKjnmvmDwJtc1LSPqk1lj2hcfM7pzMirQZAiAIlnI94KH1oQkNFFBghdbixKM3ixDYecKpmKdciuvzdw
218	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIB2Mhn0x_CgmYWEPqt0WS7Epp0LYN7hfFYuq02sPor4SAiEAsc7uoLDEbbXjPY6XMBpgcs4ppFgFDxqPILGFmptwUD8
218	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD5aKJqvnsW73cjPQzJ9uHJUtHY5uv2eMNPWB6w8mwEBQIhAJojDN7H9nGKAU9KF_XyzuXlXm_WXGlPrpuOGrRm9s3B
218	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIGO99CmwgpiqbHvds353PrcIayYwxVeKmAhRFWQayI2YAiBmPncVqoc53AjHiBkNPvZOZb9oFExYWEcLY5OnKWlEbg
218	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDYywpGI6AQX09vzm76TEOsuuHupJD2Qcr7JdkQmZdnvQIhAJ-F4xZTT-_BAXQl4cWDmuv58Q3r9Fmjvbq6uSCe8_3l
219	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHRN3344CGQH_fiMHhOgXBadCo0tci0jvHVfx3RyGh13AiEAydkk1Jgx0fadUhO95kqnyyKgN_bxrgFK9qf43QKKbPs
219	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDEBmnjD1JCzzDTEgnE07hC9bOff3tdJpRhftSSrbbvxAIgC17sZB1hO8wToew31Mo1UVzvOBcKK8BsMx4N03e9PpA
219	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCT4FvWnGbRyqeGKJXBUOPwNWNw7QMsiON93JehWJpyLgIgJPFLINSfwtzhfdGRQUTkMofm-TTb5W8kqhUZo_XjrEc
219	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDDBxmFfZuTUC7OYsAfPnzPt1ZTGrMVnFqt0VlyAGIvfAIhAIyFFWA2SJN7d7GbTi6XIxVSidNcOp97CfjLr4nTgmaV
219	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIC3HQ6Y2jUzKTKL9UdFGXDHNbOvpWxgZVsW39ZyFGtRpAiBJhUniXu-O5Cr5NRkTRRhUYFNmRF_KtBD3ddCkejnMpw
220	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFXpNQLj9QdDvGUBV5rjitt0vp5XvwRDBztmYJBygovnAiA7pGS0XKaELjNtR32kqUZmcU_-x-tSJWg-EAjgxJjPYg
220	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDJjkrvFCB-WKcR-kfdcbjBvlFma32Nt9cnnr9SkdOzfAiAEsEkmT1bu2kRf_twvaK_AFxnf1LtO7Mrhjv3NfrUJmA
220	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDl8eUjRvG3m1K_QtOocLFAZ2q8uZHBq94IKBBTUoOQbAIhAN0EQl_3UwIuEnNiSNgVceHWTz-pNORZyRW3iPYcCBUe
220	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFaDTNrW-pgg9pcTuNqm8Vah6tpSXYpcj8_g-DwwKFNQAiBXFHglJK7PgkfVnDjHvoW1bCn7H7bJG1V30W8dZc5rpQ
220	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDdZgqfiCHRv8zz3QiyssLENYIpEViOFUk8jaEJg8NiQgIhAIDATNoDvc3GwEO_3uYbHhztPxD8NInLcgJCHfSXkpih
221	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFsaaTiQPgoyt-cseifC4tJGri39e1pPp9BhKzri2qo_AiAhyecFZaxddxn7bMH7OjEF6Kff-Es_vK-mklf5wPUZsQ
221	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEMCHwnRVB_Roy4y1BgHLGr3bC82H_L2UhCnZ5xt_IDqV0cCIGmVBX-fkeedL4311fl5U6V1NGZzcBSs2Ey-RXnqROaU
221	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDDlU_IEw5A8Oyxso4EDBIuwbtrJ1xcKZMRU4Xvzp07RQIhAI0hD_Uhwe0BNh-gtPAOQOc_-ZaX2rPAE2DSKrni-xdN
221	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCEozvGnk8exRdGR9mj8HYrnmJlInUjxo560MslsmNdqgIhAPxe-3csSPUvv7hmSLZyaGg46aSzYksEThAA_BCWlVrU
221	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD_wc8VFmnpypcpcQF0gauBR8O_A7DA43bnxJTKIO7nBwIgC8mmHOrSstN_8o5hImabWKDh7z-fCq9VogsnZiuSVVg
222	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCa5z2Knh6z1DwNXcsa8CogBSoRn1rMfzdVdxKSVD9xMwIhAJxKBWvwinmtFPNCK4k4SCvIDC6RJplJquUFtMjYUE8B
222	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDmEHpS-Bxp7ITX_QeGtcQVYiBJNf_Yl9fX-xMZ9MD3YQIgfXpAO554Jhml6Nb27fh0jA8wmKDTTnaXibXtOtJeOe8
222	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCiC3hZ1sO5QtPN1BvKq1Yobx5RpFWrFLm9YrwDoFJy0gIhAJQ3RUZsJQiHifq-36N-fg6rSPzz0mvQo8oTOrFkbiz4
222	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDFzqQVlid54KTCTLsHR8T7wtAugPdTnwWc1VT9V2MoKAiBZFXqNKj2RcLoX8xwESiDb3Az72WcHJgfvDL8d7Y7yRQ
222	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQC5sXplsED6jfBqrrjhhOTo9dsBDffUsVFURUzIxGho1QIhALNUz_pl3NB10Oz2ZZaPquG3jQysodUCu33hnA9Cg5ZO
223	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIG7d48bysVkBaUL4t00LxlObo1jFsslIWwRrbAYkmz_iAiAE9TwpbSI8W8wZeZpKWTSksMKXRRd-deJpjYPD4M7QLw
223	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIE5zDtK8CRPeCZQanJJoRilDABp0GAfT_qaCJSPn1LjSAiBTGgduTT7KHoT2w_Q2du0FPEGxUu2PLDXQrlEpI1496w
223	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC4M_v8ej0avznvcMPjlcYlbw3yfKRCV57F_gswU9zSFAIhALDkEviSncLXBOIZi_t7LJ5QdwkDafhgrwSYE_LMdp0q
223	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQChdYIVMXNlvKbjq2MB-BFAToRNcmpNkHiCbuwQBl8hTAIhAIdyxxzK2nWEFD7DdXFemLrB2uiboMHMyd7s8kj5syBN
223	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIF1xJC_Lf32Sa6vRn2VCR6ODoFY6U3ClPr_iESMnR5__AiEA89h8OwjTGGiiIXh5n-_ox0ydPolKQbcmGKtm92PQgh4
224	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQC_vRwq6JGvw9BizBvJZjvz7iwyhQY0jAJ2ljol5VqmtQIhALbuIt4IZBh4nzID9LnssZbZiYaT73jUDD7Tqi0JxV0e
224	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIAXGTMEJG-o23SRhmFtmHm39tFIlvaCjRHnqs3HmNX-BAiEAgy4lGtCOGM76e6TPOUt615PkGBeAkfX5K_dKRPMis5g
224	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIE7kbYMlAFm-_Hy-Jc9OfBeuZUs77eJzQ1dbLvop1x-ZAiEA_gLUa2sgwvOXY5pTKCKqmRO0VnYaPZZi-67MVKUZaN0
224	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIEOwTVZXpx6Ui7PS2Y1Kwk6P1NEFtwCaXg-jIb1yDxJ8AiBndQDEl2jIwhtM2ITXTPTOIh9FyZrq51TKhg7DteBTHw
224	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHdCA-MF_iU88roVmOiNuL402sCsPj4DBnwEG5DibadHAiBHMw09BrQ-2VPpqBNvna2MMrWK2qQunnw2dGK0uKWN0A
225	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIQC0nNgUcoFL51wjpyQKoOZf67E78H9CJBDjWFM0dZB__AIfX-Lx149QgNwziHPSbRGt03UpeHHNMQ3c0zn3iD50GA
225	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDPou0Pcut_-PVPS0RWAgWrN3UX_DAM3adrXjJKzEcZGAiA07WWC2HTuT4GMBT1mbh5PP85NcD3eQpjzKVGJbC0wgw
225	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQC2PoKHiOP0ByNymeXwIzz8wxYsxS_yDwFIjno2IN5BjgIgZRhf1TJuTR6j9Tyh5ymyrmKNIuh1nwxMAQXaoxnnJLM
225	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCbxSlIYV-VDeA1UY9Pj_I21Y-RCzpXUL-22ovdtP7iKAIhAN1YNw2Mf5fS_H_AqvPpKkl56VwGSLo0rwYfRxkv_UvG
225	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDdij59M-chJXsGPZTJpKnZpj64ktdbhiA3Eg7CKzdPVgIhALj81wumBUYJ4A9gVFK8xII2w5wmt-tSkbtpWFclbZiP
226	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCFRh3FetJYy3_Ywsfb_1cZzBBPcEfCxvA_i_krKcEd6QIhAO85OgprBFgI5mrPSVebX6HDdn45_hNFNwYD8NFUpHoP
226	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFmfb9rTNCahNZvN9tzt4q6iwslyU3l2V52twO5tuJWeAiEA-Vg4icnpPgDkuqIyoDkEuq3mAmrGOP9F5g_UjvS_uJw
226	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDbRHyVazm6jH-K307A2RKW7vSlm9p7BMJ7PrbSa7cKIAIhAObKR1pDNEiTevcJrcy0N8fE2B-oEPoAKUJqik9NwWyL
226	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD3kFnAFDceu4u567ofSEedNTY5OLaiQN5dJX64xd8qigIgJo2eO0MhAhStjnT4wBao4Q0ssRDLYzepHx60Thmcgmg
226	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCP9dyJ33p7qRyBNKNcdtyoyhZin7c3CfIUkk89CL6ucAIgeuZ-tGUWzRe5PnYiIeWoSSXSZpuV-fkL0L0NjTMNUFg
227	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIHekg1b80Zf29jYLmkuYSLykhBA8VqpkH1XTBjnDJ2tAAiA5axqP0E7WdFrLpPzGQ-rxXwFlTioU32-fEExOF4opTw
227	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCUcufAs4v6ZaeTjQ2qP1UF5eaUOJ7Sz1592wxRHmj8jAIgKJUm2YTyBhTXhh3L--lBiKWpQAgXbF5AKQ7JWoq2szU
227	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFH31MTPgFCbxMaRwFBNcQ9HkwpPfHotZwbVdzUuEq1yAiEAuBi-bBRzffvwDFkLD1AmpFIqCVvtZdw5Ssok4kBcxdE
227	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD44m1hcl3gnsZMb-wsVbTpf5y-VsdAiCTUyf_AhVd8IAIgJQzjK-WEnPf1AQhRP4ViwvzRj-ImZoFoTTpfijYRJ-0
227	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCdnpKYPvh3jmDmO9IElnBc1fmZD-Tmlpgod4dZKMg1iAIhAOe1hQ1Kox1ep-y0ub9xxT0Zm53gPvCdvqkSNbYiWk2v
228	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCEKr6BoZT2Ez3xAf-5-4sPjOPx9rYwIwSZ4HwXV1HeeQIhAL0mWatLc13HGX9PeaR8sHeqBgW9q7v6NuTBGjavNUeC
228	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC_cihQITDP0PstbOCzsOZVrQt2W9y6QNNPSYrqjudmYAIgLSpUyxjDfBAV-pbKokL-AfKenKGO43KWlOXy_lk-TSA
228	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDXAXi91B0XFFVOE9UJc-KALZCDsSr1y2RSJXjIapiwogIhAMtbuxSrcKW2RwpN69NW4Vn7paspEvW99D2GIlZzOxf3
228	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDJ5-NuMFdHw7umtdc5XvPEAHb-4nmxREDzcYwgTYRjjwIhALgdxTZnOFdw1g5ztKPywqSDg6q-FsfO8l0qfO0WrcqJ
228	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIAhhCz_snU3B-Ycw5USZyUrNCz2bzRf03lvikwLHJse2AiBCFYZgdNOpLarDR6gLhLmm2a_8ef5dnBWTJD9ps6Gktg
229	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIE053iuBu22wjY6enLnu3-qsGfLtHybqfxOO2IfS2lQOAiAdZkRJUWV8I9muZxUrp6ZdUTRA4_L9h4G28IV3hUl1Gg
229	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIH-kwVwMumbyi45DgtODvd3GBPk0-7R45XBcFOymdjoOAiEA4srK8zOQS1laacB8UucTm-bTz9Mzs9fTZNgb-yFMvZI
229	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDJVjZAka81uMzecMyjKTrG9G7jKH8IJNQZZIJIEQoqfgIhAIttsdplB0BP1Ma9SqD3wy_dQUrXQywMhPOEf3PQMvHu
229	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCBKW3LwbVKMXLUJ_vkkk1MmkXcdLmNhDYYdV4dYhjAmgIgfNKF-XQJGp9KHxqUYjWgDy7jc4IHunIekXthMdgnLrk
229	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIAfpLYuKHHra8qZ5Y_Gb_8StvOatA_rszIRBebNlyQszAiBvalJTYF3kLW6_RD8xGWRbUdmfkAg61Br3C-yCNKBJng
230	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCqANHs9xhx6jgpWZf3S9JgtmucBC6V6-HnILa-BbDe6gIhAO64Po-rg806olTZnV2dGxG1aMdbcBbGatuQvzrKMZcv
230	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDELBopZ3nPiKlSjD9eNYb0NZ3FgWaOrie3mHqEdvyxDAiEAktEgvWjrljDPgmGke7xVEUe4nXCIUoNJqup-jUYicDY
230	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCyvCMRTngTabceYqt9_rW3bj3pv1nVXKHXzkFzlGTXPAIgPNG0WXvZyfOxQFNFa5ZlXgO9zFAzz1lJYUI4X4bLSjw
230	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIHdoUJ7Inp99xXYrFEydm1n21lnxiNPvco6qQOZVu7P4AiEA6evpVjf0XSR7d9ZP-9AjnqUwsqy09v8BUW4tAb4PIGw
230	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIF8cjnOPVla2JEB41qG6c6mN4U_6BhDBeMO-dzv0Qo2PAiA0uR_qQ_mdfN-FsAVR2WeJhC4pNz7EEVr388LNrvP_fQ
231	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFCRjC4skZtBcdZDVTWMhrtZIIejsIgskGCreRoKWDQzAiEAyNy1ZgOWp7FuDIopYkt188ez-YBzt-RPaGgIa655zYc
231	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBvjL_4G-NoaCjL31lsYYu7IWcs7ygE6EUO6y6TwNGLZAiEA2SRbVtTGMVWTOiDJfmXVV1SzoOgEtAao7-tNq3dhdxM
231	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIB68wuji9UtUkhPy0DJTTRpGGm8GwImPVGStp1KCl1HCAiBo72H-3hR5ft28rCDZRdGGPCWfX0ugHfPol2bpvCbFLg
231	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIAklQaynSaT38A7UXUfpE7rWolABbjLZM0dpPPp-D_KbAiA_ETXhXAcAT5FZYXfbkOZa5kV1_GBGhpDhGR0NWyOmrw
231	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIGWOVI5FCcmnEmuAeunJEpSAsMMz5WkPNu9X32tbkvkQAiEA7uTAuMWiFkNN5HtbZms5Mm0GxQrk36t_1PnmJtZJ2Tw
232	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQC-kxA7LtCsIUgLI5CvQnXGfpKru4bBZcMarzSujUfmcgIgcDJNN1BMrQEvdYAoA7nYALeDTYAGUlOhzjQTkXE7xFc
232	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEopWXd7hnGL8qZB4FKgDmwfF11jsthDltL1VGQ8Py8vAiEA6U-rPBHh1LxZxD-PC6lLgP-NHjD7TQGlmWlYoGTQsXo
232	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAt73I5NGxp6YWAV0mZrIhjsxQnDvSi4p6o_ynkZSLNMAiB-Uip4khIvq95K5SL3vxioxopg9G2IJ3Qyz-e6SghKNQ
232	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIC8YkaMj8oDNX7-xBoybYI_EQlYguuXEuQUfk9kyZkpdAiAWuY61M_aIU9D0lMqkAKbCmzyb_N3ELCY2i2oqqXsFLA
232	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIGyIXX4102spsUUbNwdGWD-YC-GxpcqxlrBPfsYM0hdyAiEA2QHWchDTxEgYm0437OuTalB28gWPFPqwXitYE7sWU5U
233	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCTOXtStJUJFtm1OZ8jvwp7xRXDMWNCrJ0DjPhFTMVn9AIhAKWBOEVQp91EsdrCZ8VyXpQVwqGNnSq9pJQAqz2SR9qo
233	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCU5h6na19y9lD8JYsqfYVpwV2WPWJfHFvPl31x2VPV4gIhAP10lJCxXSDnYMz7feVoaOj4fbv5O7OPYHxEl1j29UCX
233	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGKUPIO2og0sVi9zyXy6rnratzwui9mWJRh-kt1mNlBGAiEA9uwXSZ0sV6XADKVYdxRi4y14R3q37svVWjP-VMFw3mY
233	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDgohVrSi5-vg3EO3ePCfYPlPAh_ZZDM9rhkWFYF4GGAAiEAvt4Dvu-QJNy-wZbF3j-2hFOPGvnBwA8a2vPWGSP5mv0
233	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDyyKdyWVC1XIIdumLxyoe2Kh4RZvTR41pJql25n_JPtAiBGHkeCB9jbZ8Kqgq8XSv5krPQQUG5Uw653SwpHZUKgMQ
234	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFy-dGh87g3vP5YlFr2mMSpgs9oepZ3m5nLYVMqoDJLPAiBI8ntgN5nShhcMiJ9wYD1F4WyiJqX3IzHWLEsZkJoLwA
234	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIHq-MS_R_pTx8oGYqTUleyutsb7J4VhS_IZUJyu2iqa9AiAf37OellAQn47DQ_lIa-8WCtIU6vpZ73DXPfG1vZaJ7Q
234	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD7fvFj21cDJNTWY0faiD75ywjjD0nzcNO3LrWomV1zDAIgEDP05LdJLK-u168V-Zx7d-KI08oRrtuBUvxWLkx4FYw
234	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIG9FfRVHAkQXWdSD6kdNjD6xnnDyiaR01ZagdNkNEwiNAiEAvyJaI5NZzMBkqIYGpGpQYAxN2P-s-CYCUc8PVxu7hMk
234	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCtCKr59o_-kOJMedrA26k0Bexwxr0RHhxJnbGNCG6IwwIgeDNy2oGW94yeBG5tAKR9zL9wdEJwWjhZOU49j85uQuw
235	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBdJVrKvssn8_wxE-pkPw5Ho5vKvEdy_tRXCXdB-V0sxAiBIUb-fC5nALyXl09nH2w6XEfc_PcmMgHgaoLgD9J6WwA
235	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIC3ZLHerC1Y4RMTaYvpN4d9NLkERgnruF6k2xg1DVGB8AiEAjqd2clQ69EwRN-UsSb22MTbCJMpknEe9oyx_Q8c5K1s
235	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDk63x-W_SxRfvjI8GhS25ubh2A8YoUorVlBqshyOXN1gIgSmHyyMpO_WZ1Sy_x4elmkzHHhMhgaS6YGvsTNw7nF54
235	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD7WrN6sJN0YFrjKriI4BV0hZtqK33Q_ZBqZxuhFJFo5AIhANgG2xF6KeG6XDsRvLoR8sx-Vzz7ID7X-Thr84G9fP7T
235	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCyYLnUtXHOi4jvbyWX7NVVSLSMbvBVyouJaNaZWN2o2wIgZ9B5cPOfobkmwSuUfT1M2C2yv51DI7vLE2zoAnzzUCw
236	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIG-eEp7239zXIo2XFHjCAWSHJ7csN5ptywKe0Hpf0c8TAiAEt1af3JfChXL-rWSdZOdoYg22d8oukangeHuaheaPSA
236	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIFQpT0Ca1sIYkbNP-rUINGeBw9R0pIaOwOGotpkBvC9QAiEAvVl_Pb-7oIVdfNA4wYm4Ab75T-vtYU1iRAURRSusBwc
236	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCID0EGp91FV0uaHZNqsqbMYmdhIXkOpZfw9uDSwKP2G-mAiEA-3PEYNHC-kQ7lVqOjPUmPN56pjWAj2NLTgTxddl0Z08
236	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIFmSbAi8Sqo2qQ2P6_hRZ7Xli2b9q-_AMsVSuBxyfQfNAiEA4zpberilMEYMShu-SPpIP2D_qVCRG-lT_zh8RedHtms
236	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHQJRfCSB55LylAt4fEv-qs3AYwXM_Qii-e53BBQuZ6vAiAuZJmz9WnAhVzN4nY9dCTp6hvU-MX4n73UJ--Rx61vcg
237	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIElvfu5qeHmSLAsJY_BKqjq5amFhIOEybX9QPjqhEkKpAiA7cr-2pWG6C6WojfKlSkH4KLcPdlde0BCwybiK6Lec6A
237	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIFkrwqPzGdJ1L3_tADumB5uiVLrDjH7kY8s754vZ1_LZAiBnfppmMLCFIIfd_ubiPBrgdtt916zz-2_QD0ZOBq_irg
237	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCX2aGQqk3bHVAWpDveSiZcO4z17il_KQYChn1nLq0wHAIgQGmApfN6JgSOfkt6p37gbJM8zxDfUHeP4ns7rkoQn9c
237	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIA_ZhJsViLek5-HKRcfgkZWsQOCaBn8R594TcRMyWJIkAiEAr_4TTiqZUbvaRKF5O_ZAM1bV4ctxVvDongWOyYhPzAk
237	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDxKjCMG6G-6AgYGAfHECMVAlQPtT_ESQsEtqD5l6gvtgIhAIABXMaOXTxrhIrLQpWseqbC72p-G7AoktzUf6n-aybS
238	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDoO6JusEk_wwVX0by5TUuwDZx4f4G7sTZFqPIK2D6dRQIgOFil2ExugPfWc-hD2fci0jBGoe9kGtgefmNR-mahnc0
238	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGWET4Qm81FsMvtG8aJIDRec8CDEp2RBThP43LTHjfagAiAZPPC2JUoMU1OCGS_IkmczykcTz2MWUWkt-93LgLnDCg
238	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCw0AqnB2v4uY2iSJ-CkElg3AdjsaNrCdPb78KVQpm7ggIgHrWiG3qV55uyC-xK6OjRMXzP5uOpYxT1LhJ2GiA9MI8
238	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIAO31sbLK0KIeKi4U81wgZ2rg6pP0LdHUfmzj-iFgemUAiEAgtAQhILRgHJ4f8TEAbpo3-VV8NE5KetSLMrZu7YdgGk
238	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIEq7AZ9sEbm1gNCa3qfypDvnJfZmMTht8mcNMCXyzx36AiEApa3Yf62jU8j4lvvrbo-AG_Yz-gm58sdmqBaxP_LWGK4
239	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIF4vlV35y0m1j22-B-O5LiNJnYYglcU6VRJtZn86HRc5AiBxpzvLncAJkjZUT7pRWeFgx6NBLHoDHLm6rBDR04Jicw
239	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCe_Tx7L45ocESVcK8XLlqcpeh_68v3wsVczMJNuwa7fgIgcu4-RK27Gz6GBldcWQiTk13linOb6No0ftHwYHQ1B-U
239	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICx1hxVtuKpCDQcHPdTqNbH0CeAsZ6oAwI6WVlGXGEkwAiBu2bS7amMMsQaJWtCPu8Z-TGpFo9uY3x10BkaupMjmTg
239	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIAc7kiQhzTnwt9MttJoqEH4iKyZNXab_tkQnp6UxCoc8AiB-Hu0Qu54rIKoQQtkI-INTue4y-UMf5SyZUDN7WmwfyA
239	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCJflFyeN83sZbYRfSm972mnF1s4kTHbIU4mJ-amWtYEQIhAP8kgOQi-_Q-rT0zABLtzhFG0Ei-SjYjPyyOrVpaNmrU
240	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQD-b_AAOXvoV8UKj7mpMRx3jgmQn80CJUT0e_dXFV0mjAIgTaCeJ0hkw7FD5GxmQn58Qj_WxsGN2AhvBLMWdMyZiIc
240	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD0jxyrxs5UKdDz-CDcOdmLhZpuQULB4LHAWdENW2gG2gIhAOjjstBokXjncuj6pGJy-cwdQOvIaAjnfnY0Ikvr_4mf
240	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFMzh_kq14hTMZToo-jc9tJ8HEohmupk0aVn9dzgOWLYAiEA7tZg0of2YDvBQRGUPS3-v12CFJTyfnv9RXIDHspiuMg
240	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCr0G4BxVFJiZhzJYF_mSbVRrvTFYxntQCh-BzEPDQ2dgIgczEUWplXW39aQDGKeo0OGKWKvyvjsqwjdAXRQGhq4Tc
240	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIApGFq7gxvnElgWUC0HhChGf7K_62ZFU7rU7Z9Wstwy9AiEAsy4w2Goq9EX28GETUOtWNCEbyrS1pcn9V-59Xx4MS3s
241	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCICx152Ujc0-RElY1lkBEwlvKsiAYQEtqRU0l2IbnAKOkAiEAnArvE63voCweLAGUSM-SrYBYffFtAiLNxMgL7SWlxfA
241	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCQmC7lPZTh63JeWFuwt1k6Gl3yIZus6okJ0JScN-X2KAIhAMKlBdiaRMKry96kCa7bfCvfnHWiB4wXjPhQMzI8uMSi
241	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCgWKHvJRHXBuuXskKSZU9Jfuc-CYpUDlKMDqCNcxy_6gIhAOpUMwVz7qyIU4Mfcotjxk9HjNgKhSeVqqCr0mRZmEVB
241	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCIN2wRjZcnLixOG-RbUYq3U1Z4B1KCwJO6XpFOl7pF6AIgOak-eC4dNx_GjEUYOCWGwPID1xXOligNLQKp67YIUx4
241	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIAMMxVPMqgdKZjjwvkqAfbiA74kGAjLaxuF_sxAkrOJSAiEApw2qltr_1YmGwJ4x78o4W3LqQyQd8AHI1St59MW9nR4
242	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDzCTHL5PgDX52GSQVmIhCGg7a5sfTINXkhquDu5N7xmAiAyqqLGrWxcpUBU07VWGGHgq4ETacfISOYJ_0Up6IX_YQ
242	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICZop7jpwJ7A24g_pnSonXaUFrSkmdADOqnp1HQunVnQAiABifMkP2Wf3NpNG_LUucc-s9OPreMsQ1aYzt0N7E5kWA
242	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD2VRno7p8k-A0tHpS8WXQFg0QC5tD9Gljs9n1kdirYUQIhAI1_mgDaE2cvYQyLvxWgoukYIMkSiKjT0_nuWWKhjsjL
242	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD2sOwdYMuzWWmzQ0oXzt6pTY1jtYmMS2hUfGXmG7KdmAIhAJrP_nuW0b43XcKbW1brWpJvh_kKzgyFUTXQ0td8cggs
242	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDn7Pl8sL8JpRRCiVSNQ98enhOs914r0JctApFGMlVOlAiEAwu-O0olXjISBqwLy3mH4kafAy1XvQcZv068WtG0rQwI
243	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDY5_6efD-Ex7ZHF5k1AvHDSC5StzAvn2tp6q6ZXia_hgIgFeSIug3CycApXFttYzjcyW4_Tc_rFuLAUCR8v1jR2DM
243	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIC9B50sts0m-svC98bXO8EhhiWhhBOg7lJDegD1d9OY3AiEAk34lkxw3yb-m8edznZ2FJ7VvqWN2cRUdSlJ_TkaTPF4
243	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIHprNCFCMzQ7c-Q6zc2Hei1wXcYwf7qHBnIillWE4Bc_AiBOcgqV9D5MXYsUO9zKfv-6GIHzF2P_dKQRKszOvTQvwQ
243	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD2pZxRCZEvd6IrIz--EnZTcMqn7fM0CHj8T01khQYfggIhAP_dMvyzI5fyPvq6CCNaKBsSg0Q-eKflBUXxiZY9zqFF
243	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIEbp0cU88chBt7brWRu7YU9Dx4_reUe1QfI9tFGU8MlsAiEA6GDmzWsei7hhWBKmLs64Kot8v9QjVYzcd3SiQ05t9bA
244	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIE1eM1u_xqpz6jtet0ndV_T3hiV-FgXAM3MUdjov9GumAiEAsuZHn_kD71n3gnA3suaJMj6ZCOYMDdLYZgKbbRp-6_w
244	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCUyKCeCmgIY5JxwPZl4JBo1UrdcLZrae94_CJAmNLTXQIgW6OD0L5kbn8plLp27FaKTWcGxMYQBN7XSR2fBwAOI7k
244	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDXinO3-2UQuP7vv_lisOchtRKf8tUcxxFR42tGYpCDUwIhAJ5pMXr4JQLBamps2sIgP_wYA8zPZUJVK_wEZamAfhAY
244	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDOoTjy25Z_OHddhwDmb1jKYfAwPSJs0hPwb6MOb16w3gIgSwoU0tQTHE0crp48ilY_bKTfd1Kj5EIHCLg3Wj_Cx4U
244	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD7LTaah3j8q-eyR3Xvn05FyHHS9o09zxEi6W291F1G6AIhAPXSXonAHKKuQf02Gwb7VzaOWmzy7ZV07h9KZUFcIWeN
245	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCRlbCMJRqwOISDJRcAPRJ91hSA7sYVgj3cwZB6dOnjgAIgeitwxxPHYNJmqpUGYYHNtRaX9gcHOr7Up_i3radKJEs
245	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBHjzRgUUbqnrk5QiVKS36WjRPaL9kwrtKJ5CsBFe5f2AiAtynjavbbp1ohlJaEPpZn8YwWgowcj45cbha8LqsCrqQ
245	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDkeJShT6ZRNm7tGrjuIrmcDqJEHeiYFnm6S3c9wDqtywIhALNnQGIhLZkmCCD0stmFaXKLR32i_ZZ-OebTnDCa1mFT
245	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGAruwzuiitV9L9OOeUV6BunaMh-vm8LGG2tXKwcBjOzAiBD15iyO2EFe7q4LwXkLGjGuxqI4gQAvLeJC6aI4XxKGw
245	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDnpMVwN5o3i-zagXDyVRSe67oc7VJXSiIOVS5lxMNFdQIge98FENZrWnZxgVVRj_EcvaUoOfjLTzONCmuBovY7xLg
246	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDNmhRgCvlipPxDL5mfp5iNpdA2giCrQ3zec1eQGcQirgIgBWMDJCrV_b7W4lcADRP2TrKH9QGchEOTvC_DF73mYdU
246	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDpa7AdfIRr2irRSwjOvyDPly6lbOo70eyLgmH1S-C24AiApaSxbC1a4U3N2VKyqGr5gzXtw_Itl8vWltjWNKWMqWg
246	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCvJFb6WuaiDGn955oP-F9mjh4L_JvGZsH2XzlObCu1rQIhAPkSXKeG8FZ80YB06BsRiIT3ROC7ppWvCx8VH4z1p-Zh
246	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFZMU4_Ov7SP6ILyX9xsPlpGy1v3AwxbyQtslq40yO1AAiEAmgWKZiz0t6IwlF7nD4Zk95VKgwFGgNE0obyBo83m8Q8
246	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDAiQdG9JRDqn2z3_MNwr2qqqXTZT0IWh-HR1Gk030WXQIgV_psAQmyuI5wWUsZ6xCIGMGcam0OoFWu3eYOa-cualk
247	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD_CE27vfesJBBhoutL0jXWcM8H9zBmu1GNVCM81Y50GQIhAOM9B694_sgHHFjAFto9UxOmwKs8phdcCRnEDXRUJTfT
247	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCONTsl-npXgg2j8L0g5mK-lhX3AYXqpCcZ3F6-1YvhPwIhAM3mG7cSNlZIvrzH-xKET5FWegZhzwkBvYxaBDmdim-d
247	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDU5JCcgxtJJMJlU5UWkUih5z_Q7vV77xkIr6qmTo1VhwIhAOb5Cl35_skQ3jE3JcVUBfptysptPL_Qk0cwY55MTTgo
247	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCZNj207ZpQx84TvTbxm4xV6PqbRVtmz_yvzl8UHxb11gIhAIGNY-n3D3xgOdSvLqwyZTKdBOnr73slvU2fDKgXPfRz
247	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQC95Vuwq_7jzoFruMETcosY8voMp5APoLKQ47B7G5Hb7gIhANbF3fVBF1r38tfg5gUujVodUGsJ6ITeQMepxmLg6zxX
248	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDNlUPcBA_fkFT3hYin_Q1VaPPWhcgurf65t1LjAYZu0wIhAK1dXz85GqFwrKJh-OWWueEAWIktCQJdrrEsedDTx2aR
248	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDGSjoY-fd1IxBX9TLToVV62ycgA5GuQ2vAUR85JqAt-AiEA2sEcybcn2zzrRiWTqbZ9MUamA1RjxayjXSqEKjVgaX8
248	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIDpq-n9rY0yRIOfhbp4yQKU1gG2CTXx1-vM-CFn1ENJvAiEAi3H2LnBs2AK1ewVnZelLDkewsNn3pKS5VAYQS85m9IU
248	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCCcqGeEU_dThMHY-hMACpo1ZNU57L7KJEbncyffNo4JwIhANvg6PBQaSo9RddTtf5bP-FbvbbBuykyqZhoLg_q7J56
248	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCVj-uajfaXhTcEg6ugIsWA8e5qT3iozyiObzDUKqgSPQIgNsaqTG5MDYJR63LiFWEN9CYBlxZGhoVrUqbdi5rIwdw
249	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDZrudln650Cdn2RRo8wPuI9SgLfEfJLRHQrfIo-Jn66AIhAPihazSBqWsfu-go9zkgvHsFbGiEcahpOLPrakZFpBKD
249	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDM6lDcKVbwKrEeiMapWfM6oAb28V17dfBYDgl767kNbgIhAJ4DobE0v5TvrIjy25Q-jyxZo9QFVYeCK7fq6htx2Vc2
249	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAY7NYpJKldui90Fi0sy7ce7hbWy49J8WefYVM_UxWroAiEAqFmSY1BaCeyKSPsP0hCcd9UZn8OOOfnGhgc-o6PsvtY
249	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFOO444jSvmjdJTSh7eM800Xw9cNP2Gs_KysEVd5ra_IAiAYN6iB5cqX1NLf4PcZ2zzvI3vvi6unAv1P9Qz6blXw3Q
249	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCm23FcthKFYR8kL_IvO48SH2jGKTIsodexEFtK2EIJwAIgR14Rt6cNKoRR1rgIVXPkW7wC2f9Ost6pnX9nKcKSkuI
250	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEnGb0q4fC9FhDnYAPWcVCMAY2V0q-yzl0GECpnfarrMAiEA7hwa6V06AMyku4BxLdmgS9ljImvp5TDvpd7BAjrlTeg
250	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIEYjf3s7yyfggH3D98eO40LarSEPPgPKlch4KlvFx-_RAiBdfzuKsLKfcO3UU7mR2jmmcf_lbaHK-fcpmvuPrxqRQQ
250	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDAX23aZR-FWraktSajYLK0-RBltN-PNFGAI6ecii51kwIhAPpq3b9oIDtJhqXi6lm3JQkvJ3xNSjGTWWYTUH9FghFY
250	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDIXGHgVxVTD8Jebeymr7HMUgK-KCHXNaM1YAaOtBzTvgIgFOkukHs3pajp8vfG21m9w7MTQ0GPOo62cLCFVHjp8oU
250	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCH2VqmReWA0CmTLyH5QTuCB2wzjpMHOq09pnSdVnD4-wIgW9vqk4IAyxIsybQZPjFArqnMoSKUSprjIwK0Ocy2MH4
251	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEtSdEUuzGZ8qrAZwt48DVzoq-Jyr79wYvVIQGiIPBa8AiEAlryEi8DHo_rEIkMa0OR87Mdi1yWt9EC23kBEBWBFUb4
251	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCZfM_8rQhdOrpKH6ST8FImhAxwupWkxPTKFRnZxR98JwIgCoNhTQzB-Okip43SLqabENkGmcRxepy3gqhb89ieWTQ
251	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCICUE7s6yqVMSC85v3G9DWSnrLmQVtGAybvqbCOBz3yLPAiANsniOsaqah9ntkd-fDCBJh3JnIp6yv8vl0JbhZjd6DA
251	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCUSt52eotppi4QWLbZ7As_6jBM6lj71QwNIYeCK9q_9QIgdtWqXb-ndMczbvY5jmLvJsKoI9t5YCFjY_LwJCXmHSM
251	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIGBDk4Tl5kyUQUzVsD-jzAHaNp2SvkZwsR3HFwE7ec3-AiEAn3dXgSz5LEKvNOt86ynVQbhIq6AorNRepayZHkxAYXY
252	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCA-cybJSNCY57PrJrC7FCTbqkgIYWrFKBzG7bSaBGbOAIhAOs1gsKd_raJGqzJbcjCSX7fZ7NPNfSBHf95wKQCvv7O
252	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEMa_hKdAdXDOhnFHnqBaPX3YqFCBXl7A6E14-IUPd22AiEAxoE1LJTvFhnmPTWCjxLSSb1EUUe_hPUN-9CyAwEW8TY
252	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCID7xIXJi3rBZ5xrfIcrBZDRibXo1WMiQxCzknG2bgzlrAiAwZ23L9rxDhTbX4q0uvshTVWNm470QILHlxGMAQl9axA
252	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIAcfjZzAN4CWHJFVzUkwAeJCqx-VOQNuX_YRGj3sc1FpAiBl56t1OzSxPkGbY6XMZWUfjRoUxakevYf9MpFrKT7__g
252	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDJVGVesWx4hbJg1WRUA0oFYCpmzcl50azonK1t8okqIQIhAKGWdv1I1Xz7VZN1BL1LLj0S17LMlIWlU_jPBMfgTfJQ
253	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCXon6LWpvGwDaaq-BEiOoVXh8lAHB9ZT3KRdsvEp5YGAIhAMfjrtBtZNp-IvSXvliIHBBo2KXLtdVUfd3v0HUomZtt
253	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIF32s5PUQZ8MelWcXxy301xqj9p8wrQonNTCndDwbYDoAiBv4uQOppeOs_IhrZjVCL20ha3F5epcKe-xA9UHGSogzA
253	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCvLsTQO_u9hU3uS5FR3kO_WPHTWBmb5WoFZqGgyR3SPgIgKrw3mSBxKgEGgY8BiDSVGGrfoRbQAzK4JLxt8Z6w8wQ
253	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEKWXXd9nvEsUF990qM0RXbVj-XEGQYOGW6Yv4WCT55_AiBfJKUHtyGCk_u7rzgvglpY5TYfTG-5btn__9reu96sIg
253	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIH62bIpoKNzWrLeltzWAvduwXGPo2nA_QzUWeabK_00dAiEAsUERROGAyJOiwG_eoJ9m1LH128FHYvHE_DF_5H6B58Y
254	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCsm248qmNFF4CavymxwNi7_s0DruM2ewgusxOblxTBCgIhANK3_iluEhLoXp8oRg39ATqf1Gadxzd4Z7hyWow1nuch
254	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCbIJl94vKjvVjrSXCLlA7WzYlcUA79MVIXrhl1eZcdFAIgF3ofPV1jOU6jESB9DoEOHdECWC_EEWoD2enjEHOUEPo
254	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDW9jO7gYMDEzpwIFKpSlgaHR0rq-RcYtq52F4-jjl3TAIhAI-wGuLiP_9Cq46hYybRojwKKgoXQXvVmIsPgHTEFA2Z
254	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQC2DC_UzDlLEuK3TILPO1PR_Hy4_spXlpO1ZZbZCv1q4wIhALytEh-hCsmFsOjlbDXpyMoGcR6WrkyBoEVBsygzgq51
254	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIA8s_J-CGsnvUIfYSglleSLjqUjsS-zHKF6UmiXjVG7aAiEA1L_SfORy429Nncn9PFQsea0rBC6GoPvyZNgYVWGfz34
255	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDUJd58FgEP9qhJ98vQsNC6ppEG7kIjI8R--aOk1YVJKgIhAMDU6mycpZLmVJBqzunfW9hqSTXT7zJhoT-Hd6XYuIrp
255	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIB22Ni_1G8v9yvnI7T8PP0ZylaSeRVA2W1BR3ZOB4OdGAiBcLIXolI826fFxvBDbHjMN7JIiH9YIrbaH85vd2W-L2A
255	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGJWXI5x6iJs_y7mO6F0rZQbRkZYi2OV-HUqbA4VezxlAiEAqz5oyb79FlqO8H4ewwWMoMwyfM7d4UGI0QMLo79HcVE
255	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIFyfz1TyIM_wNEtSTnrkA-bYgySP33AOI2L-0WZtERy1AiEArgzL1kcN-WS2f9Jyv1kPCvkJgVZvg-QKlR3zPU4wxfs
255	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIHiq7-3vp8WsaOq6NuTd1BY_r79obTAbkvfg_MsGj0KYAiANOOno4Ii3kgN18Yv2hYV93RBveN_mKAQpVqGORxGt2A
256	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIHB-wp7ywOzPNvOXtyLtcbZLZs_47f_dn4BGx5tXWYDTAiAcLNeWHkyyXFed4IZTUCfG71mb-vnkC1LNekUw1Fhx3w
256	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCGRpZhAe04yoBDCb0Brqvj8l403x2gewB-tc0o0UXojwIgGz1qwatM5sKBeGGszUKOJ3DiQsIK_fViM2f70q4vrs0
256	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQD4TKyjxBFDv7OCkKK-R3hsn_x4tJyTxf7LyCRlEdgQFQIhANvlFtkNA29MHRmFCi9yv1jaro73uBZ7SYvRKf-xQdUW
256	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCewcA5GMyw2iX-Pq0_IwbgNe-6uO3DfWjL4WJduh0kcAIgUn8fumTeHAaf_CiqqfTjU3npu65EZGsR9ER2wGrwg5k
256	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIHxW9bB9ji45fm1vlp1JAldeyn-Osel7IMqCQFGNodw4AiEAjTURaLuGvmfDpq_O0cGQBV4zowYhs5pffX8zZCf_ICQ
257	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHUZS2B2via2uq-5SKBrWAS6cM4lWNQQ9hRaj8s4bd94AiEAy51ZZjNgyN7lxK2fUULoqyM9umnPnxpcp77_nMaeeJk
257	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQDuzoFf1QUVEica2d3a3LKljcYb5Vq_9ChdMMQZLOp0-AIgeV6Ynn7rCnYtFldSog5bCd8c3VKpI0QzWyit4369TTw
257	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDMVQrQmvkuw3zc_lFaSi4c4w_GlfIQGoyl4ipOy9qyfQIhAJsB4BIu4BmB0pxJVtkyfZ8MwJ59VvZ78MyG_VJfzgyT
257	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFR1hRAYXNAI3XcmGaO3WQnvP63HBzMkSXZlB57ZZ5j7AiAP7Av9z4UQaoAmkz-HqB4dIrVsZVX7mxaGfVz5w4cjZA
257	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQD2ivD2LQJudTWlmvkbhc1nxAC_QL-QtOw_0G553gWVvQIgHGQ2MRsTjwHaa97xL1Doo7rFa9VHnG39KthSTt4nypQ
258	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCICKVBrmMt60XrfCKGOjj5vxTlordTqUouBKgRIs_mhf0AiEAjzFMzXwZiPdXwVM1MnTAPJ_ab1bZA3qtnDtVUrIf4f0
258	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIATdQSPu98tlNWNKdV_5h-0B0nKOMBB5S3po9kSyq69AAiEAji1tI7ZwAn5iXniznx81jZGsr0Z19BcxITqZR8VnhzQ
258	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCmFpNK3O5YBIg2DYkY8Fa05fjpp8MA8fv1THr16kf0XAIgb7cjqDV0-VZLW1V9P5w86zG3cGO77wYtxrDnIvgKHT8
258	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCfLYN65cjy-4vAoRahJcbsh5LNeBSR9a19ErM3Ia0Y5wIhAJOo1VmoDS4fo38JN_M8a8FD0Hv_msmawUyzjMcs-IzH
258	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQD3OnqKXSotZqo6EFomlVbmCEmH1kT7vB_tc6xpzPJVlQIhAOuGMbuzjj9lZJsNlMGzN2R1Qhid5wX1It5T30a6T8tS
259	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDO1V12OeSct1oPBiZSGWswj7AfrUjHoRKYzpWkUVtCcgIgIIfe0_qwW0UgNPt-6ilNkCnJvUQxS7iyb3jZhneH5bM
259	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDayfxhWP2Q3WBJ48A4EaYdnlptpkW7OWi_zPjKWehpXAIhAMBlArH9-y54Xts05EpGBODYDCURVTUB_YQ7NsqLfJTM
259	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFJN1gjPPgCftmkuhg3t4eXsl8VuC5xT4dK18PylwZiCAiEAxsi9HT3Rb8sUsE9JVxYFcA_mBtGOInRXmOGXriUQeFI
259	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGJh5p8agk-ttM7XeVr67VPQqrfy_nCqy0mful6db9-NAiEA75GD92pdBfgS8-dWiPgr45nFkqmdlc4DHTl6bJWysVM
259	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCCeTyMeP40CtYTGBtIrB5NEXON3LVE92dwh0LCYSP_QQIgOuDmyqUKuO0kal5USfBnsqdWI6LXarsnbjtg8TD3Ez4
260	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGP1pOOkiBdtzluXXT0Y7D7bJUbpImn4sfM7MPhmH2MTAiEA0QWXsmua1yJgjqlXOa0Q2tmx2IkFY8mDxWYDrOrsA2g
260	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHMqsODHfL7CVKM9Ojph7tVBu-pvdslOvp_9CUGHitzNAiEA9hXNIEdDXD8XPO5QcElvZt0DkU1stezBl0Y4L3BSbk8
260	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCM1oi6iBUpNsmxZGOHGQgwUOo1HF4pQ481IAnU_GtH-QIgL484vxT4xOgaDq4AYGHKgYF8RaN9yrN_Z6z1Q9Hftgw
260	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICTADRr4FWP8A0i0GZST365bME938ZXQKv5Hlcv8CWN6AiAraH_6ejY1qrIYy8w3TgbMDIB4MMr1tW_NsuHEWA3Elw
260	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICYQtAbMIcmOM-luDBNwLtcJaZr5WRl8xjbxzO7k92P8AiBrXgtzQrk7rBjEiYcqPM0298f-bsoYFR5uc-rycwV-_Q
261	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGkN9RjsMlE6ZODY2YF3UPiZi-0MT6DGYQ4RoJOyklLIAiAWXNS5-xMYqz8kn2n1XvxCf0Ct5GjM2axVMS242mp8ww
261	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIAParN6dW8vOndNNRsXsnllNIByuyxsMBy-yNuo-QaXbAiAZGPc7WSauJxymVW_tNwyauCPy0tLPdyIkqWa4vddA2Q
261	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIByE5NFCWFWDcLXa9zqoAYsX-CHb9N0MdFGFAIGbRIejAiA5vxFf2U1rOAMxCqG_k2TfflyY-uk6rIMH-EFmwcy5Ug
261	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGVIWSkzjprWG7gJAAZp7W3eIfmRyveazbxYnWghCZ6lAiEAyscvZzRMLpEloUOBmBC0G2X5QT_mE59OVKRDSs9LHXY
261	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFB_NV5moB37wDkcUjZEuM8vHIGOqm1JNR4quiIWdx3uAiBUSGkCUATw_hT3V1NgRkZiMoC8yjpp_bEKVw7-xsDYaA
262	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDtK75W_Af8uskYxAbJwoEViDA32_cGEg26MTeWf4aosQIhAO5E9LhrPgGYQtoWNGJiuPvfjYISb2fdpwyIFjnUQkPU
262	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIFRqj8Tb4kFQzzE9jA-8ly3_4XzjTZOJRRHtu8gTie7_AiEAyGmDc2PUxNct0WsT-XH1N63I-rwld-_EtEnaGK9jxgA
262	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBRjxoPLu2D2FqkIcpFNQHlw690yLih5ZO-uIBi_7Y-sAiEA7MHaZ7TBe2lvGGgrZXstKPOHHiW7gMDAqMMyF95jmlc
262	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGGmVmfD1Zqd2w5-B7Szadykl4G7Zig3ea3FbXLSH79EAiAj9SvSrIbrpZnwoUHSGD1F58Km1Nm8IvVRVOL-eczu_g
262	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIHdCD488rm4wLJkeFo4O4vh96T5nEWpI67PWO3lUq9rwAiEAzkRKQmPC03x2-Ws7kmm3NWz5rS47m6KDQ285VyMzBWU
263	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAM091AFOha5iUk3jmcd9xU88aG9_e-QwCTb8uZQFkcCAiB6Ici-UMBHEGBVFjIxjv7YJT6B69e1MYB-pZDSVZXO-Q
263	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGs5ueYbCWHnwgUVC0xFC-6v59UN4qfSQGRV4_kOVXHsAiAf24Qp7p4D3ZNhmb-9whVcORLEV-LgBar7ZthwguilKQ
263	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDm0cVNudPfZ2OTfEIi0UH8YDzm9Cz11ioCo-J0iO89FQIgRnfr1T-BXNFyBCL43LZ2EtAoGwAyeZ3dh552k_lsYGU
263	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC4h43np9PQ6VZVd_4oLi-46d8vWYwR_gqXlVlCquooRAIgeKs_muPc13JRw9EmM_6rDmiM1yw9MIJ8FLC7OosqctA
263	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDvqkMv5dsaoqY2eKlGxjvYAdOzDClNjcUxwFxSs28rzQIgVasQfoouTRcCP-fGPwbbQeB_jj2ChtqzOKIRgClf038
264	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDb-wsK2itBxL6tn5Eq29oNLs-0GmZHJuCFIuAXJAMSDwIgGnTSdCen4k9rSptbt1Rt_GMWXEvklhwH_9II_we4XLs
264	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIC_BvmoUt8ObwSXYsRwBXR9NbwulTMFKtuYVr-ka_y0tAiBGT1R9iwH6Std4w-xh8xPfj2da6keD8HSSTtZ91PbMHw
264	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIBAs_kVOGvrx2-JvuiTrKL8xPB6zENF7LLbHked8YxUTAiEAxI4oxjzkHjWNIT0iYumJbZn2QBMaZ57xSz5ATtpx3kU
264	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIHyW5fJVDIHzkcb2WKce160VTOdvz8Ojilr4pKWYiT3MAiEA6hESQ4SAMhVlpejj2-Qxfp71W0zJ297NBz7ASfdxXUY
264	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQC32pvQLpKD4qyuWCColol4fV4uabX5X_oQjn_-MMhsRgIhAK154-rVohGZHjds-sTAXnxpw973I62I7RQW2LfQcfnu
265	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDQ5x3TKJOimhnM-QVD2CV4QGslOegqhK96LlmP7Zy7TAIgTLrZkoS1CeL9I-x_9PKtXgkA0-9evT9q6b67d0uYjGg
265	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGJPdrpiBy6PofIayf-VohseWYAIuNMZ01QSfyNXOmxdAiBQd9N-s5wv1CDZjEKxeRzF2koQx-9ZpD0DGSmEueQxDw
265	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCmtkuJVArsMmMI3Jctqg_Cp-PRz7mNN6S0ExJ1ucBR7wIgFmOfKViikAJkWl_PkOE8W83Mx81BHCTXXFIRNOn3QUA
265	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD8bxbG6BepyA67iJEStB73cL6qk_LTk7cXj8jxreTX1gIgJFHq68t9hvZc9lY9UMHiGH7PbtnTn7BpGCKk9a7Z8V4
265	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDUFOqDluH7xkE4J0X1DT5Ab2wPngPogizDMZJkNAnhTAIgG5EXvzOUvRWZ48u6hiOQoEGgI7KiEPKOtX9gqI64llg
266	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEMCIG5xpR9FfMKYy_otD4gbJOc-zQ4iUuRRWUFA8L04qzsjAh97yNZF8Dl-XBUxgF5Y1mSj4Uylx-QmP6Jw2odEhdoo
266	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDpRfS7TvHXn1Ni9yPdW8hZg1MXDbVKhfs9XfAjWchVsQIhALy4cH_z8uH0R6Zx7nmevPlVo97OTJE_kNf2KpZ4vYdu
266	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIBes66FD_KcNkwDmTJlAv2UlA32g3T6pMOsF7aCQSqI-AiEA0bWkjRb71pES2eLKIIli2m7Tg9YUPcRCOM999CbYXJw
266	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIEBWerluH1PpdyEVV1GjGApDrNO1yZXVhI3G1UYnWdQUAiEAudghggr77HfHYmaL7R776aiS4BUacs2oRl8DXz5KoSE
266	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCDqr6N5HJVzuMnLg3BUrr8_j0Tjk2O7ZOZGTAc3CaVHQIhALPxCi0Uu4DjBS4VUbyDx4f7r9HEdRCuyOVIOAvWw8ih
267	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCrpRnX47NaddKUTavGiIQ0bE2hbm-hh_Qla-JsvSiVCgIhAI0bGPykfizkLHDNuu5mskGBEXZ4GHFAOlzl6kNYBF66
267	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIE6dfOKVMmsvUj6Mxi7iOlm8E3fEb6bB-rvztATB7x7cAiEAkU3uKIRB5gFoaoyzbEOdCI8P6D_bTolMasqetjPw6kA
267	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIDVwnf2rlXJzC1DL_20_O3xpIKrgQgZvbcoYRkn9pod_AiB-BeLvVBL5Afpe7vG9OF5fX_DfaGERExPGB8aRP6OBhw
267	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDPsxv5uO27iJvZ16WgDlRdbVv5v5OfNpNL60mdWmi0-AiBmnRmH54jP9AHEwXHR_WQqIj0_LycUEKlMgCHT-5C8CQ
267	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQCshwBp_mxsQSpstbM_P4xXOuraB0p3FimPXTmMv9b7AgIgPJuJXc6QYq2QZslxUx2N1KR9avP97ba0juPcCzqZN74
268	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIHQG668KnyTbZXV44hLwhNcIkrxZNNhJZjXMYCpiF2xQAiAC0pfl10qqlNiTZ43No1Jvokb66MPfQgSzoV1X-aHUjA
268	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD78MelrVnhcbDEnrSEHsw30YFdhCg8iWVrnB9tdXxRfAIhALvNpih_yxtXCXkPTIQAQ8qXbSOy2BpH3sQvkWc97uTJ
268	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDbVYfavU5xjPIU9hMpg4QZYZQpn5j0vv5G5BNQCRzGGQIhANa5Ksoj8-_VOlx-m58BJYIlX--YH7bR-tS8ZQZaD8DN
268	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFRqPesEqVEhB1D9IS6z4R7Xn9tknIjaCmmJ8suRHmL0AiBFU2FciDUVxf5vDb0ffYjQxFha95GU1y6C_ImRiLWwOA
268	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQD17zlc7mUQAqCu1IxwgsmhvjqoFxiEKlDIhbhI0uDRfAIgcWtXwJrF04m_2oHoIySGN3naay9nnV0N5RxGcq9Ptlw
269	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDR60qnYt7avrnaaLovFWlMmxtkFX96SPa5iovFI-TsfAIgZ44GZOEe8cPjPsaGc6olxLRlOtNn_3XKOKyPD07kRpw
269	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEx9OD58fLrVrrKMHl5EwG1mULhWGw3SHaxoVTjVPGNrAiAMeTf5Zh-1Z3P2uaOfIZgAcyzS5BOFdMDQbqSyy7N4rQ
269	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCMp-uTBFF6bvNqxYoRTy9xAsPkkOCsDcu6ETNr4oeVkAIgQcM709tffYshodzkpBH-PwTLSjFO4Bj1s6cRxuVbvGA
269	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDHcEs55mkQ3uzFj4W89IJ5LNGZMGZEPgMUAZkQjh7NJQIgY8FZwyLudFMByWlgt08n9_OUdHq9iHezYEjzoNVUV0E
269	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDrQHnz1Nvpna19TdPAhyYA9GQyTp4u3a3juPhxQ8IqlwIhAI0Q8qx6mNMcKYAA3UFc1XtuzV8eW-PiOEjh2T9FmO1T
270	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDrIRZPvgiOFHchBMRbkRpPu5WbEl4SI6GlgrEorrPiegIgUwG6GDuq-iWL0nfxb4EYkMNznAqSn9tS6lvQiA56q8c
270	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCGjkrSvpJsNphpFFlSeA64oMEzHEEekqKQNzNsEQ6H1gIhAOCjagkCcFAxZtY3LxRDVONmqkAP6jxqNMhcsuurj4nU
270	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGDy-iKOHlkBL0UXKYrTvfr3wTrt3bKUMQZGhHGKEazsAiEAw75WqU-pSIh1W4xBZgFfJScOiQiyXBg1euFqTI5ihtg
270	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEMCIBAcQWAZaxUqBQUn0zBv5RoqTwapNDH9ZM7cUIXdGHNKAh9DcIccBI_685Tyu0iU4mnP4nGTflfEDDp1vk45qPmx
270	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIC64Zh0nrmKBeicP5haPRLw6nY3wqBlMn9_Nttko73BvAiEAg1SgXxaiVZK7yxjOSBXlUt1Q-BFf08mE6YPCiabJEjY
271	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDO0ucYk9XTMiiRuXbKw_Y36XgAfoaJBhx9gcUi3agAhwIhALGAsEhR6vtQh44cN-V3nqeBIKY56b1fRzSSfrPyYjNb
271	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCuCr9SrNvvz78zJ_0Bj_S_pOVCK3-YenJYFhaCFEP-SQIgVOLNCqguHTyFG7wrXfsVCpttYuteVFqrvQ7WidMp2-A
271	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEjh0I8ZCz1sF-a-i10soscE7jhYdlD-f2ZXSRuw1YnRAiEAg_aHoNdvLo80DS-MfN1xsE43fkzeNoCcSa5h6_94EA0
271	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDdOROzETmzUM_1VLn1oXvTPifLQwtVHjmBn9Srcpp-BAiEArCcXTP6MdaWpE6mytrxRyHikSfBmgr335TeQ0sKOQaQ
271	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCSffMcXlj0sb1e-K65bSoZRpCx5jCj4m2LsK68bGXFcgIhAPhDX6nEUpaG-t_j14eJ17_PsSAYQNnEvLckDzNHxEC-
272	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBLi7JmzbU-cppl9ATJYGf10wNyJ-PK3s_d2u_xPzCFaAiA6z9SZ7W_mBWM_fAJa0KsUDbtljKD9Z1uBg65vRAtQgg
272	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCjUN5rohB9VTag3E4icZRF5DJGa5ATtCXHqeb3iFv_YAIhALmlQEn6ZhwnSMCDwT2kmwzShylrhG9l-CM4C9reNhH-
272	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCKMRTOeRl2Dd7Q9GHkLvMJMsiwcgMdDJHaqYwgS-6i-QIhANXlhCoskKnA-bZZGUR5-_kgdg3hCYd-4jL5a4PTqWTr
272	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD87Yaux3VKBkBTwZKckG-W66G87D4AR6rH3PJYjnUGmwIgdZpLISpqs2dvxXOTJjTkSgfNhhRMVosV7J9Hgoez7Dw
272	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIHbdJ3wpdDFYjLxxkLHzfyXiYLDyFuZYpvBmfNcXwwT0AiBnb37Y7IQR8iAnK5xZARdRpomis6scK7w3S_0Q9sWJXg
273	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIHA33LTFYIbzRHu__nPhyC1AOwLPUa-c9vR7lUkO2PisAiAuoQ3oUAxYQI98Dt6Hu8JwAX2twcp1Av_BP94tJEMEOQ
273	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIH_OansIZuD9AhsePKeDN2_5dWdx0dFBoFbOPXJUBlEiAiAVeBzN6QVeRoyD-Fb5f3o0PpdzagzrWrsvkLhRdhX1Og
273	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCRHy5lZo6Dk37PtaJKgG9EhyTglT9kGm8Tlcbj55OCfgIhAP8ZSRxREiM8pBONZJ8hHhJAxd9J7AHtAB_3YHi1Itq2
273	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD0Q7bu-o56yvQBQRjDJ_OZPtMESi804MHBzYEf3s2h2AIgHIg7dcN3wZLQheKdP0IDz30jH4HoZoxLFAgMk56P-0k
273	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBK2zow0q-cJA616KosLr0HtZZrCh1uGCmC1bawome6OAiBi30YuH-ev4inxjwZWaXRTP4r5JyN6scD61fyvDqWAZA
274	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIGA3Uyt8yD1Kt_N7v4ZaUBGXy25fXrg90KKp5K_aVLthAiEAjBMymGeABTAYBpXJdFVHR_J-NuFV8wXeuL9SNBMIPDY
274	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIG6IJ322nnI3zXGbKoFgC3QL8Ly5AknCFuco2uUM9t2sAiEAwu4VgAj0CQg-ihHmwgg7EuvJEzU2RICltB19p1Dy1LE
274	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCUdzpWg4VN0Z77ai9yBqiWwf69l9vzhKnRFYmPh0v59AIgbCwLA3fHRgmN7GtG01u0wSthE_GHsF6ANRTZ5o1WHg0
274	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDNHmOMu4aBQw4YEzXPRRhXkNImoQpcWsqTRzDVczv69QIhAPklugg_T5ckTVC5F5x2N-1N3sdhv5XVaUoIqXgRqSlB
274	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIAFbZVYq5uQ0CiRus3UEFPDyaYuHL5PeqbhV5pj4q9KRAiBYzzgKHFd9EcPZavaPKSRpXYcFyu-7OgUAdXk1pkvkyA
275	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCiJOsboONM475YxPnV4loYl67ZlJ_h-IztwO4101uFKwIgP9B07vSocMOLNY4u1KzMKHpghAHNPFK5tT5dZpfkGuk
275	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCeeoARNQ6mmt4e4rCsEjMUulpAxePUvYmA8pNdPpG9fwIgKCaSBmXKIeQBnoWBkXFU_nHyJ4vpNcASp4s8jYHbgTc
275	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDqUa23K8kcnAnia6PAFUuBuRQr_o1TF2Pud18dIoZWggIgG2_ZSYej4c7P2Jr4iC_d8PqnoA4jrTKy6u0Q_VEytyA
275	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCepZlZXT34awm1iCb3g1RUXAzfoUiTlC41vgzkEXFrkQIhAIguSH35q36CdE0TmYM0fW3Wn-c1lea_X1X7c25KfXdF
275	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIHGQ7-sK0n2433rwfDjE0VPVFZOIF-3OczmrfuBuq6lNAiEAwW6OC5zvBgc2vgEfKMUmIa9z8g-OrEMqf2MdPl5pnyA
276	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBn8JeVtOOZjTmIZV89QsAfv6aoWOdOV3tqhC_CquH1mAiAVD5SRS3XKH7tkmqBNFgZyJoc61_bQjfjJqURexWhjJA
276	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIGnn5u5EXlyn4W8ioWkVuTN6COtjeWJPxERwj5FKyiFOAiEA3IXhTBVuJj1kV3TWU6oKfawfj-TBU1aAWSTENmrdffI
276	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDOcaL5ZVh6C_B3OnUUr42S3Eq8IaJq_OmcV1DASkp5FQIgbfoc22dR0IrvVvvxswotHEnyCGYEH3jTCm_EsTf_Zy4
276	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIBThTVaYkS0UD_kq7buQdDOjHWrTjp27iK7-rmfmYQk4AiEAq-Kw_wCv4Y1I2XBiwQXLLpfIlJ1R-wB5cEqp4fp834s
276	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCUGp0P2NHrwTMZtg7DaEU8vbKAaT4AGh37udSA0vXXoAIgB-2nfdTxwwhDXF6_eyU-W3G93LtMj_jzkF41GRikbrE
277	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCcF620TfGI7dSHZnLdu7cqi9UMHfs5rSY0uhOb1bOo3QIgWQJN6JxK6b5g7788cfjBd0IA_QUAy7JBPHwWDx880Rc
277	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIDE9q81CQdPkIU0rgn6nUu5czrqa2YKmKqYd_S3PFP2sAiEAgk95eZDIWUGjHJb2cEDtAOdPwm1ehvpnnQih0nox9mk
277	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDJlODt7a4A70W6ldDOm6T4rA20Akj9U14RgUCYIEncTgIhAIYGZAdL_gUB_LNQ9DB1Wb62YQuqbuX5NpyJDJOv9jGX
277	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCfHqU8w2ReY7orHQpWJB-oO7P8t_pskWqFoWpicG2UFgIgIv0EC-PgBsPnp55uCny8t8KgYyhiJneM3ZWfa8T8lng
277	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIDXAJin3llvZVMlZXJbvGpgladEn6_z9iNYwuJopEMcWAiBPLdDYTnG2bMAl1xbveCRwoqvl1Z11Otw869lRn4RGdw
278	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBSzdDDoBj68tBfvpHtgjfTDEWwtzTel3c0A8LpuJu4yAiAtys265OPJvD99lRB8DVT9b7DeD2qnhouIyiXZg_1wSw
278	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCICEEcY3jSIWCWwDAZJ1hSBjsUVBblB5gxWbAjJzQhP3BAiEA1SewgysU86Fzvr0mTUQeJMmtLcavO1YCKL8bamdfS3g
278	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIA1qWSn3FCPmvOXM2DryPl-MRAQkNb4EX1yL1sEIe9W5AiEAmESJog41ul-8S9jQ71mdLM1YU-hFiLYdafA--_z0HoA
278	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDQsJaNcSMIeO_Co6rTaOxbM2GSUuodN5Tawblo6LpssgIhANTifkmVj69dCtRYoGwCWDTZoxtTzvBdbstAAK0E595h
278	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIFqL296D056N-DqbiGla1ByP-1scgGjVTsI_Gk4Q5XbgAiB8TBa7RpT_hs0K1PrPLgJB86ZiM-NY3X82jZ-Xp8ycVQ
279	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDoEAp37Jrqc-APkBQn7TIPd_aTFa7ycgsY6eyhMVmZVwIhAOx58d4kxHjipAdYMFYOGl1-9gXqFrbDYygLzza2Nt5Q
279	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDSw6JzPaki9mzNRGL-u_mA4vT9LB_W4z0QPkh3i5l05QIhAKTCF6-nu5PM1-Ij9bHdnGFfgwhuxTJ51YKWmRNwjItu
279	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBgZpGxnCLD6qn9JscpLzrqtijCy-g83nETAroNxRO-0AiAD9lzWd3w_MZ-DZVDhIMB9sWL_vn7BZXZJcRFhNH_WRg
279	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCHotzbptE53xNum6ILRKuUmITbqmPJ08DyXN3wpE7RPgIhANp58-GveP_UF6CRIoEFHkeHDYCug_TGgvg3v_3sXt4W
279	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCICy7eaU1vKsxk9btE0GYivy4jryVZyQOSX8P1_IpPotRAiA-YVgbq_HJssJDslhJV0Z7cM6Vv-tyfvPnuRezlEP2Bw
280	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCp3KOvEPLlxf_LcXC0kzvbzRu3yHRlooozf03VoJYYbQIhANglg8PsgkmREweB4nhFO0ap-RQM1Kmfn2DORn7IimFP
280	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFtlR4ewx-8A2hlTO93vrye0N8SnyGeCoQ7wMCDMUjk-AiEAlueexr7l_KgrqP6KkBlhUr379nza1SEUFKbAivp651E
280	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFBkV1dUcANtkzdOdlttQxJff1oI3OcdRlUnaYVZsJymAiEA3OOdEG3KUmOngGEwJO515QpOB-GYCrQMeyKbjIUXhdI
280	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCQz-x_aTNcpQHZBDIXA3vs2kDB_EVRU51QfwP2yak_jAIgakN0gH5hgFbzIaTVXnbnfsu9YUmh68OsD7d8DldLvp0
280	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDNmrEZBkCSMqzAP61WlcQYkgKHB2IB6NqOtpO202j3_QIhAIaGzswb0EcVbrjKAC17qdwKgg1vjfmPPnrX_-3rMYHP
281	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIG3CyPeYtaZIh2j0ROZrMWkuoG4PjvLy_oQZmMixecvfAiAgJe8zHI4BjAAHudE5-QVO-bpamCw2hhDboj9L-XWBPA
281	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIDjBAvuSIVaxJAAle6cBeM9mVKquhs3JscE7RHH2VfWPAiEA_B_hav9d1h-z2C50FE2xNBO5ScfTnuxpHqHaagKUT30
281	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIHxNFEO2UExvfrQuSe--pOVbYH0p_EmYRgHW9s_sYCYPAiEA1B5pYKokYzcty1DBY00_m4wIyR2Oz_N_epCEI_qr5zE
281	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCavlHeNZlmGpkJX02cSenGq4v96R1N8X1yMldAQugd8QIgL2l7kQpU3aZpJ22oKMpfAZzOqkdX7kHlYXZDU-PkblY
281	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIChPcXBfvrHnglOL45AxiYjILWwjzxbcqQz4fwIUja1EAiEA8XgAMOqy9HrnV9fHnH_cuHfFSyuWNz3TCBDQ87xI3Po
282	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIDIkyq8V3-ZXgYhw62jfiSCCxch01HHOulh3yYKtsk2nAiBZKkNPS1FMHx9ykSOK_dDpzu2Gpn7OSyOhLj5neAmSuA
282	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDUjoSDXHUNsH9vRKWWfrSh5xG1paI1z9nUoH24rtnf3QIhAIvbVEmUBd96B68OeNPlWOcxwCWbVV2DIPsKmfme0g3i
282	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCR76jnZRXjW9ZVxtWoq70PKlboy4PoGdglUvTIOuMMigIhAO9igt52h02il5OmG49qvuT7ntoud33PwprdWsvwVeoW
282	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCu5bBWIAzbgKGjkeWvTAmu_xZZFzM-6N7OqVnolF-JhAIhAPJmEGBAIEF_vDJebUsx6HzR4E_kL1APJLVNIg1qMxy2
282	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDdtMXgJlRM7e4LZyxXeWwUkAHDYmmMuLx_Ju8q3T8BQwIgFj0I6HDVoYR8pB3nvV84QE3L1KzW5pXeph5LxGZChJY
283	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIBk3GxT0MixBSjU7LNN9ut1sIPDCnYiGQpixi8WcvHPBAiEAxd6HLJsUZxezreyz7blANG_rK4fhtW8DGZXg5QMEZi4
283	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD2bw-d0gPY0STdfK_RySUwVhJQ3O-l1CPUgWkh8grU8AIgWxCE08ctRxNFzdGDSTucII-IIVffkxIvuSHzBtuJO0Q
283	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDT5J9i0QlTW2S6dFRWKGXtg7CgUMb49O6UE2MrNVTzLAiAhCVi0DpiLa5Q1vO2Gv3PS91fJ8HQcJ_mMdIutvGBEmw
283	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCosPT5bB7_R110xFDPvQFC4wPlY_PLfeYSG9lvNpC8lAIhALQjoTnv7nDsXc-0CmpkhLJom6VUCNQ_d_d9pkSBU805
283	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIFi5fxGO_Fy8BEQaeyO3Wsk_YzsYE_yV6Tm2lR2n5KQvAiEA7z8GfL6yCPkVC8dYHMvBSfywK9ZsLXI2kF7CbrVur_k
284	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAHB6XNRCRKZPTmg4YEk_Or0CwW4AjtEfQQTg3ltE-_dAiAOyBTOz5fdamnbRv4oy3kGwJtkyuUvVHePvsNIH4rrOQ
284	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDCr_e0e9tlsJqeN_ZLWrnFysmVqt5QDxvrM4L5iVVJ2QIhAMm2E8HSh5JsFB-6JjduLaJv8S6TRrdlyk3S4_fs1qSy
284	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDDNtsolpYNn-cg8HK6aOpQDXVvzaeETPgWWlTlB5lDcAIgNppdogCJ8KWM4yP86ENXbCjRigPrSJKQVn3Aq2bW11Q
284	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIEBB-sMyMcSBquvF9Ln1ERygkAJeyyBjkov3vSK6CYhbAiAZ469RvqtJggCnoNc6FQZW_bvge0CdkPMLtSnaKsJg_Q
284	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCxfl7gbI-5JKHG1ecqqELVCTwC6XwP1oAUOWZpGK3vwAIgbq2ECbkTJxOkmY3OEhQLAQd3QAOQyhx-nsJWpFr1Rxc
285	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIHWBu60DU2Vh6FLW9YDvYGr4yWbbVPhSzLNhVrVZaKCfAiAJpMxKh2E9J8omc9TcJjwsYCR7G5ykHMs9NMhr73h5EA
285	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDpdXzmop5z-r8Fle74kVtRO7PQO3387n-AofXryWswVwIgNMyyqNlHv58QfMHs9dSfk_j0tv6F1qWTOh6XntquBxg
285	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCf2xdAgDST66XQ02nej3KdRHWA_0epD0mNytWiWWOauAIhANQO23SZ7JgoRmGX89C_ircSpd7eB3HxiC_wri4DbF4N
285	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEczIb44lE9cg2npeReUHPZTDSma-CnuSMPAAcCKCh03AiEAjlt0VUMmkkOhHpYHJOETBZx7hWM7ezxrFYnVZAoc308
285	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQDv8swk4RBAtkafaEZR0-x4YFsrsvf_ZWcqDbXi0MmhawIga8psicMNS0OBhuPje3EUPVp1CLaKSFBSLO59H4WFtP4
286	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCtOf6Wbeq6HlkupB4Zr9FV5jet8vuRAoCA-0c7e0IbswIhAPjHGrYhkwqspY0DDuIid-TgfOMnEHmhTOksRT2UhzV3
286	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIG-ICWEiBSJny8lws6g7CHn3zCYR9X5FxecJf_xKxuleAiBOfVPUwfq-mXMRi4xrq3ZQX7ySsrX06Q0MoJhWetwKVw
286	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDlkyU1_McQF28aOvr8NXm_YKP_SxY1tm7QVbkniZuIPAIgTBddx_ceiSGEvcF379KSjCn29pYtuwfFr-0ZCErI508
286	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIC_1buH-elnZlcMoxQWHhqKIgdEgSwmq9VTmtifkAsRpAiA6bBW7yiwSpPlDR8yJibOkB8UYLZgkGrzJalBIwlSPfA
286	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCICdllcO6GH36pPee5GFf8KM3Lw9BnmL8VbTgiqAoYGXhAiAI4MZfLguSl2z2cAPPRK4KcMryGPKfPEgn2Pe_3sRooQ
287	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIELwPe3UioI3fCe6cF5L9jrH-8Ziu0hReNepjQiHpD-3AiEAxlIEKMS9ywpCH5u6LBaMcHfmXS2o4ILOEb1uSjhI5fg
287	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDW8qlxKjAtwHPf8ePK38A3YpVo_oVV8skm3b8fRlxutwIhAPc9_DGdElGbQUGuPWbW4M44ybL8eDF07I2n1kkyOXGt
287	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBBl6iVvCTNpuq8HD2fGPVV4oZdeJ8okpyuwraLQEztfAiEAgbX1IQkrOnYk2cOkahJ8yEd05joPYfyjF2MiN4AHlao
287	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDZjsFf6Dx-QRvxiyPa0QDXhvWz-D4er67i6oGROVNSBQIgQ1CvN86g_nlUu0WyuZsxGg8vEVnuPxtaPnxC19yQ8Gs
287	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBuXGc_of-RzrK3t-p1kJ4kZeQxO2-vscaH7v259lt0dAiAHUJ4dv3cNOnJFW1io0euSWIvPuIWYRfOdmVg6Y3s82g
288	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD6JJnRFOQHPgrZpFoACBW9VJ7xIryarqFdNxDYy7GlqQIhAJgJ5eshm-rlyTI5_Dw_qz6oVVvWrVzU2EYaAnslzPnT
288	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCk4r33aK2FPnx-kb3pDtp94ULzsqcu7hAWsTbebjXFBwIgW3JNxJwtYBB1jTuqk_oNFvyVlUJrA7Y10OOB6wQ3yX4
288	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFa_EHtXmVX_97nO5cpmQG0gwNkrN9qXQNSEapvNL9bTAiBECutaZvop1f294RGXO4GvBOVhd3dfRx-x98qe3906KQ
288	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGc2quNyLFVc0wLKJfrC0zad3cgOZj_sqMxnnupPibccAiEA4ys1UsGrMo1RHIBjYSCM6jUwssNiLA9FqipUiRoy7kk
288	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICt5RrISzVn_gwwudqhZm_oIyhi4gd9hyJNMg3N8_V9sAiEA77awCaWViB6mUSYtLJgutfypnK-t6--YTPqjPC5RMr0
289	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDB3Qh5PbOnHbN-WRz_UtW-uq8R8XbATk7RIaoxsnZaewIhAMlFFRNuj-qAuwVueKGwMKGforJkCFH6Us61UFRRL0-Z
289	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDU3FgQgMsBclB7esCONrauy0BMeb4xv6xd5YLd0Wi79gIgfua5ZJpcpPtJqMa6QqLds_gWhrvUvhrx_8FSDi5trQg
289	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIHrkv8wbY9XaJr2VdKN-BZgHELHdAEZDPuytU8tVuZadAiBWsmNsOehX0jv3YUnoYTepBQ3Hke_Gjyp94uDHSIJL8g
289	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDB20jz2QWHrkIMa26SW0AHMBKvF649wfBGkEPmugKlhgIhAMBiGXHzztHpwRedOlqQUERRStI-bwmPc-JhmMSR7DoC
289	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIA1BgIoMH51z8e--Dz3gu2mQsjSCbqFTa3HypLVhFc_YAiAEB8ZxM0-CBjK11VmjPkwBJU93_OYktv3I03SrEyoLpg
290	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDVIcpUYXckD0NrBVpxFqDghr9jMFLofVjBHGDKJuDZQgIhAIGXh4AZfVkie_tRUNdMMRBga7TxS4-lUz4Dy49NWvN0
290	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCDKcJYQ-nEKXBfg5LkuzQBAsg2wSL5T84kqzGGiK8AsAIgEBkPKE2Cxy4sRVGd3T30cESys-ioImE1BC894MqmDHw
290	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDhRv_WjYWKKM4fUJ8cAY8LRuKjjXrXX94hHrzge8xdqAIgLxUhXvzfk644ZGLYb4vLZPx77-k2nSwoViJW_omOLfA
290	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCICn3GXQijoQHCYBcHd5FEGlniCvtiDXPgtCZjl5uK5RaAiEAh428_tcr659IEylA-hw5lpaPetIQqDzdTPOa3gmr6CA
290	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIAnHS15tGBhzwQpzh38A75mGtBJlz_SO2fhrMSsxDodFAiEAolKoO6HJWH5x_x2flXWx24r7NBok0oik-OABS959BBY
291	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIG1kaVS3ZSp-G5gKmfPxtvtyvXAb2cpHW3Kk7KWcQk0rAiEA5ylzia9bxiVfJsllwHIAciybbDp8zUJG6ETDtfu2gxM
291	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC9lzz9kCnsTo2HuAwGA9z1L0cOSBlJUDihKaGQehI9sAIgL9rfRNE7pBJy92BKOEO8zTkDoCq5sFCU9xI8L_VXqsg
291	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCK5KntAUNolRrHUBENb8qksfNbKVllXAlarpMKLxA6PgIhAIu15LEhh0yj8BIBvJVQgy0FbS15rdezIegZtVMq5WLO
291	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIGxTjlwlk8FiBSQsFWsubyX2PmudDPByLrV2LLa2H-2eAiAbunSRLDFYsZe5t9TRaGl-C2TNGT9G4pARMe7qO5GyPg
291	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIA8gcR6axAfKjPFUmw348S-oUEqj9oP7v1z2KxIJ75QpAiEAn4PLPhdEUZ3w3sPozVzL5iAsm413zakqpGb1CfaWk5E
292	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIQDVJE9A1C7GjGEaUIiamjKfss6TsPdywaRBQ6zFZDZIDQIfIjdJ2n67vNrZzCNOPu5vFWAiIsxRBGUhOEmf_aGqAQ
292	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIDCyBCk30hC2AWvMrfkj5VXwnyspra-vsMFRChMGw2XxAiBQ6qyu4h6ekRm6BjhUkU4LlbCZNwCLJYFnb8OGl2YoHA
292	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIDDzFQHJvwXX2LEOEpJl5N3B_sYoH-DYwIZezUA1_p38AiAxRyWVA6wEcfaZVKpfRN-zSI2jdrwWbiO2VQZ_TP-G3A
292	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCwD3qmbRPnM0tbfWNb2K-oSu9UJivf8ZMPk0dqYpUAQwIgEw0y1SuZi4BKHuE8jQZ4auJrfYeBPGDIBp97whhwy1Y
292	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCICCdddWL9oNo5kF8m3Vh4VFilAbNo82XHOV2Dd-3shNOAiEAx7bHeQHRmGew9Yb7vj5NNx1Kjg-vguyEWpkTm3D8qFQ
293	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIFydPpebnax9crygkVB23RFISjZEEzMgJOaSokWU9Ll8AiB-QD0KyDRwpWPqrzLoxzcsMu-ykhgfzRfx4E0i4VZ4Ig
293	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGNYOR0sinoqbYh49sirRddfM8kPKavPXw47-Thp8Mf-AiAaDaoj05qu1rTT5v2Pa4-FAegxMwnHD20L6NQc_KbdcA
293	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCDruuXpfRjelfSikJXYfPWpzqkfKVbN1BtFKZw1ijrtwIgP5YRL_18AksUEOaAOPCEmHZ8wST6aTNAM1AfrRFNnGc
293	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDENwxCG_0pCMVrIirHUV-2dZYJ-d4uHYh166gj03gt8QIgSeoM7ma6VDPMOn0fxb-TcLofUVLBrqRN96jgga-owe8
293	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDOnpnLIS2nmK5bTUDs87DMmCE_itQmkPpaZHkRzvfLCgIhAL4Y86V1ugojT-4rU7jI-Z1QYS_WRthWHPONnjtzYAbJ
294	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICid3nFtn16ecfWhuWtSiuEd2a2976__dJKAI1NpbOe1AiB1vVB6rHobBAPXA8LciPSgMj6saesWYHCn8bp49zgyAQ
294	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDzKOQHQwbdGwiPnH3N5wYzSJYm3HlD32v8kyGnJDxiggIhALCbo7QnZqp-L4KtIDw8japaoVcvy104AWRVnwiQQaww
294	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD6vgMr4IGdUtv7qajzaMiQwjPPZ0LzMqJIs_orZKYDZAIgfPNxgjTxNeoIZ8fAiR3ag3ILqTLF_lgiTuT8XNTDMdQ
294	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIC-RPlvRfx63F6bg2vstTsklX0G44Qj8MHxdVYup3-qlAiBpxK7KmWjLxPbfw2yKF2znRKy-VZN4kDYMrkmSFty-NA
294	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEU1ERUat-ma0RkW_Pa4GZOPORnd5yCenjwOsCx9IqDBAiEAt9v06-G97WOKY4xgOnxTcs_VaoOujd1ymCf2nSko_vk
295	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDanUA7No7t9l6QrSO-qtuqY_C9WG6VjzuzrOzPC921WgIhAO1uEpVwugrOh9fhX_Lloo9M3Zb-VF5h9z94BfPCiO3k
295	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCRI1rHYmpKi3QInY-5deOvjnMVKcyKpaI1L4TEkgGhOAIhAP3dwt9JA5oNPP8ZV6DevqEgjbZPCTdrZZzk7tt6q5Bu
295	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIEmQ1hAT1NrSttSWs5MM7T4srYcAqa6RkIBZO1gdjNdeAiAccjiyfd1egrMBlIIiRpss2EY6zn5elNR2C2bsvXffGg
295	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDfYvjGwrQ-cdeMkaGYni4AkxtTKFtrKPkGYKC7iC81YAiAbbvt-63DZZrh_rKkd4PEq3i_GEHI8tN8LUs8xamM4Mg
295	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQD2Np6dbcbyPi2vHbpk-Vfx87pSzxdaLXIMQ3GRsQISFgIgPB3zOSnP1teh0ynyvf3PjVN0-I-GF2YdZRKmbzc5sVE
296	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICBA9iPpi0XrEU_NbJp_e_eDJapCGTqsgvbF024t4cLoAiBwm3hNLuZlhU4le2Gq6vxsXgIYF3G-p-6E1-BPgzc4mg
296	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIF9oN5msjddUhKoVQfaWtQnB49e29pIWYmVbgjFhednAAiAHfnqmFckRURHL8QV2wBNo47zd1sRUF9Zcj-2QH3_NGg
296	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIFIqG_8F8-hDhWM4y2ViCK-onYzploDeoCfC-sBqtQ6yAiEAhA0hK1G-Kzc9C1uO-C_mCSEPwp70isvmfDR6A3TVpmk
296	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCvlURg119YDZlJrGfRfzJXKLge3ETHvgYES5vOl65VsQIgchQlGogxyb8ObTio7V_XDEhrrJIKB46KEJkR0GjmLXU
296	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICHyAXVEYWnfJmjMtYmdgbviHgLlUKVeU0yUNqWgvEqVAiEA5XvSdsois2n27pJZZ0JFdeFveN-5vjiuvMojOXGuyYg
297	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGR2nMsAQShCfOiqvCDszQtnSMTW7rd-AIuEEH7qT_YnAiAT0O0xVemrnF-hj1mmqX4AlHK9Fwqa3wXtBvBOZNRYsg
297	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCiZEbcxMAXE5jmZtkXpqIkbKngZ-pk1nZCP_plvh9rOwIhAKsghwHaNSxMGHL_Yrp9ZAQUoB1_Elx1sPDFtAQ8kFev
297	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDWOEp1V3Mdit8nF9agRMNr2bknfkcCAJcT0DRzSN5doAIhAKx3v2nmSRGOn0cLTAsnYct6CMn_9hlXGS2UQ7JcoBm3
297	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCs3LKZZWLDUVomPEZnrydCJPgifKTwXFePU2hnLEQ7LwIhAOrEJjnEx0vOVilkpwN7Ds4Cdhw1-0PlI5useaWB-wVa
297	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQC0cBuL496LpUarPLm_lrmbHzqkxDfU_JCyiONC9QAkAAIgQIinZPnKjlAmmIVX5FV0kemArAdewpoAgoR4Nqx-X_A
298	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD_LVdzFUR9JZmGwWiQv_fVYf2lZ62LW6xKrXJk66KgkgIgc0LqUNmMTi-P8RDogsr13c_KzXzfYDTKrhNMDQtbzS8
298	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC1Y-lXf9_ag_CGyDhgM-GJXVI1gbU3cjrXTM_KqW85uAIgM_HdFnQrqUmK2drhneUQTilNBSJHkvQl1KTTpGvTt9U
298	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDVq8dyptgcYZSvEZZsdXwfGidPEL46wLFqq6k56Lru6QIhAM0HZfGN55K-eTkaY4XoGrHnyjkzn7dqjQUWp7PWs7AF
298	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD0vPGS4FNiZ8vuQMQ1bpCRCqGeZdya8UT8pemiLY9irAIga_kHlkAAeUtEPi2Q0C1xK32iO9zd8iMg-sp1R6RcDbQ
298	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIH-OURronjMAogU3wfo69DAHvzerS1GMVryLU_wfaN85AiASYq0zVUNavPpJwaTQcKrf7fgWjnsclidUkEQ7VqVaQA
299	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDwzSPSJnUo8qMCQ8ModzF-ql8mOf25ICiUPf1wPMk2lQIgXEFnnt9I_Wn0GypHFZJqBALTdOmZuqQLePjOGhOzVwE
299	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDqEEoFEX_dM-ZgDEI2ttimZ6Ngw8HnUEFS3I9ciFHfcAiEAg05pqXiI-n6KfldoVxTXEo2BnqeutrlOOSiVU5JImOs
299	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD2GsWL9R6RZk79VpXyMWZVmPVJkjo0yh3JJFbHANvICwIhALgL8oG4ikhX9lLO0ScI7ixDVAwdLE76iL9z0zkddMgU
299	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD8erE6UCQweTSHFmpyiOHkQteNM-QMYIb1y8-xmqVtcQIgFw_OdSuFz4fUu-QChvC070dY2yxoTKiNxsx119NstrA
299	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQC3nBqXeDmF0rRGE6IDcDdpsPC08iG5i42FhrtflPmJKgIgeY3mGoI11_kO9SBnVEgk7bthYgCD49yYT6TkUtiobWI
300	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIGeo0914UPM-y3IgcpmO9J7NZ7b1PjFBHUC7P0SfoS1cAiEAyAv9jzYENhIfmdS0fUTjfPLD4_G3PUz_jU28fuhPGZw
300	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDITiJx_hKMj44P-XaHZcCLGiQ0p19FIhNAbZgfqVEtrAIhAL6eAq3g8Rm-a-YZp8gLLaF7l7MhSd-tBOKJaizRih_2
300	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCn4ZKllVIfN1VMwZmsUgIqqM6NmaV4iHeYYEl3tHYqTQIhALYsa2k8rOiUG5KqDgy0NhfnJPof7Jh3MrZNZOW3mXbT
300	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQC_nLBi8g5l81diyM54o-CNLz4TMr8NZ7gBO11OPpQuFwIhAIb46mZCUW1cuqZ4lyPgMtfYCLckjJv0eaRMBnEvRY15
300	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIH7jRbw48x3HiUz9RyldNKlGXHHz0y8MQTSn_p0mk_DJAiBqT8sCaoE33c7-45dLorg6ngFggEy5mr8Mqqj7zbXzUw
301	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIH4fym5TP1xOLMW11MV2LVGaz4btffjWM46GaKQjymZCAiA5qcMY9VLdCP02H1N9QKSNxXLEnlltm99-jXwGJPGn4w
301	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIBTqttfOx1G8R2cYi6IVvFGMriBQrI3TaCRmySNueanvAiEArroSBTw-i8QD5K8cvfpaNc6IODaeXZZNOBFw43O8gHM
301	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCID1ZGVhrHUX8G1hMUuro0HK9yCjmHMWL1dhNlp3GD0XzAiEA97PByNZAZU5F_nRnKxys4c9pRlOrNo_ax6ki-7HlhZc
301	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEZCgTmBNkRjKXoYRyva4auycM2hmL_inR025ZfBnDAGAiEAquHGFxa1C945yZsWrGlx6QpIAscPfLbF-ooQ7dL_cDk
301	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDDyRDxQmYUW0uF1mEWZk72CCtbnp8Jt3iop2pX4lTsAgIhAP2_eh31ok2j1hwga74LQY0zFYpfBdNeBdoNc2brlEFV
302	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIE8whlrxw3_balOvepb3pyVlja0tcquAhvGfMpAicCviAiBb94H___MZREGPtH8sfHlpSDzxK25tztyUkI5ra-HM-A
302	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDPdeELwvDHk20P4A0sfPe83zq8fGP_HOH_ONxu0rdxbgIhAIPxjMaq8PlwWuB_NrFn1xKC9znCasGDvzneix6Cc00w
302	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDk9sbvW_mB3EWbtdOKI5S9Hg6eo9Fg4XujFWRzI91pJwIhAKo1ckZVBC4_BK1gn_gLqFVb9A1QUioiAmHIsRGah24E
302	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDBu6tTZzeUSNzyiyOlhbpD4bycoQMINigZgFT9WhNrCwIhALjdMrQJ5p7J7Nn-cZIjiz4fxVYPAUgg5vBO8mv2GDiN
302	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCYD6WlWuF9KuwQgKmvU5nnLKwMB5kz-rRnMCXH2t54GgIhAMmrby5dVdLe7W7SxDRxabDrob_eZ_3bCB8Bo5WEYcI5
303	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCEGr3H1E5s9mxHUSMrwkoBRIRNcLp2END5lksRkDv2AgIhANnqoKBhwc_hUlpyT_k-xex14ZoEYImUdK9qbk_5Wzdp
303	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIAXTRh_MBcExjWF_rp_3iTWmWdjHEQXYy-kA-Rp02FXeAiEA-8beewfbZwxkmGwuhBDw5aryE8njdQB_JJosWQrcR-w
303	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIE6118-e0bujqvpaNzBaPp-iMyVwdLr6R5rrRP_uHnzHAiAy4P6q0NYUTrPN7GeFEhkD4tUnKNhL1GSBTyQdd5B7bw
303	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDwB_7nF1C4J3U9Y-MqJUlPHKwCJpwsTDAarvLIrb71QwIgH7nPRYvQYvWNs_4aMmwsWG4Vib-xrKbPsPd31CNnlqQ
303	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDvMOi3_G3zMPXGjM_pjGLoKOmHPJlqeS3JTi6qHet4VAiBqMXKA4XkDWex3kD460v-UOhz8SIgTudz1Kkp6jGtGpA
304	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIH5uHTC7QPOyOa7yuj4PVy__PQnNQyfk_BVhOGDgv46EAiAOkAMR56z2dLScXN3EbQwyLfA1oTdNTwtpoRC7zRk03Q
304	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCJI_mC9yPkxomM9muRsk5UjF5FzK6ls3AmD9d5m9iQFQIhAI769moW98rbrgiQnK392ZfI5pgmcq_s5kyXkLmBwaVc
304	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIF2iZOaP6XFE4f9C8z5RCy2-d2xmaoeA-M60794-fNGCAiEA8SZWVaq0EbaLyIDjN0AVBYsXH66eTCnDQ3zGixJV0vM
304	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDxUsdrDoBFYU0dIgtw4ukCR-wvNDCEZbmirFkdlFoB_AIgMDn-GE2wyB3m-6WSdkx3xeOJS81xBzgRU3DqVPcjiP8
304	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDGXY3pn0Fh1VzwJHh8FMsfEl5Oq-qL2cEW4YgAr_ORBAIgQm22KgywFzrszoWGkuMISa6uTsEHucRnWmt60IAmzIA
305	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDLJflZ1vGGNe1jGzvtfgJjZFsImljrluieRE3p0yHrEAIhAKQU8Gyw7nxWisNa6ojkl0Y0-ieTNGwiZWAWQ8UF_ZB2
305	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIE8hpfUcLZjWc7O95U23hWYS2gBJc2g0B6DFkAEdij61AiEA7CvVN5m3_Nt1mn6k54-gZMYFRrbHc-TSS0GH1FKo9a8
305	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCRMtjACvoRGMKXj3-i6d4oweDHc4ramPP3UGNfxwVNMAIhAJPJtVy1q7ALIWOE9arZxJJJ-bmr1f0onSdWV8HmcNho
305	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCZZFqtdURV8KVzr57B45cCT-aGfAOlXZOp4hf7r4afoAIgBBNbYvWARWyDJDUljoMGTtqHBuXhyYwi353kAJ9sPw4
305	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIC8Z-sIOXgMDl6KoYCwxr8k3vDJez83tPe2D8LuPNTybAiEAoK_yCCkilCSEU6mKfg-91DTNrIQIm8A-4-WTVKx6EU0
306	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFjFfuaXBXApSHLNnjsN0caRARxmJJLvcPRLXmgobOS1AiEA9T7POylYWmaQ58K9D0NDXePAlCUrTfrCYrdfKltJjOk
306	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIHuZybC6KDlZwI7g9SHBWjn6cFlnl_eDafzdu4t7IKvkAiBChjLoVThUu68OY8U0c3pmpoZTpS4mEak2GNTTz8l91w
306	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCmgS34O28KNOo1-np2hMHHWBvq13WbQTSifQsHe7kI7wIhAIlqJu_VZS060jQuv0h6aFq5PAWShv5CwVZNT9Vu60yc
306	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIB9VSDGC8Irpb1cY3Ku9WKebJDRNnBLExDDtEoOQwCqvAiEAsPlGoQrwbETa2nZov9ZzI7VXfhNGYTp2l7VPCHKJ-Jc
306	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDDM82XV39nNefYxKOjchlt6DutuSNbGAVNGv2HmJinKQIhALWHbZF-H-vzC8wX6A9pYGAYTbgBDPdAoxMAfByb00rU
307	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDB3q-F2zwGIPBX14c7olz1bswULRaI2T4cetYAw8qvYAIhANyrK-J7IlPpeF-oBzXQ1FKjl0O88tjCi2JPMq2w6LiK
307	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFNsq74V8gEO46QfLA0vSvmAjr5qrvWK6BH_pajsRcRhAiBr0V6NhCLvNbEcupfSG7met3h5h_wZLHMlmbpWcSI0-Q
307	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAwQXd5VICi0mYYq3fx7-3jYtUYtQrkrYHB586fmq0BfAiBuuODETArsq7nPbRZF7vrpKtaHsEcI05q9zo8dBC-__A
307	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCfKHlVSQqtS4-20SzGnnhP6fQoHaSIy1mm3EzHcNKxjwIhALtsd73EJyOyg2lDGkyX0Gkgibkiov6mY6okh931UCtD
307	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQCPvH939boHHbgyfsDB7FJgs8FnQ0TMbyUpGdwfpRqlhwIgTQfa8x530aYpXOa2pp-wYmCsoB0kZ1y9yn0hZyvP7HU
308	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCUJI4mZGrZu_o4mxePXPLg_8gpuwv0KU-ZKB2FeqpzAAIgUgIxoNSnjHyArppXDeaqcjcITxYMnJbnPvjCWvD8B4s
308	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIBF6vjcQHQBs9MZgHqwDLXh3vXvX2-Q0uPwoGjB7Gb-OAiEApUphlsQnvt9HRfi52abn5NqCvEuFi8CoMtvFZbzgxSk
308	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIEupKBvINhnrPZcU1pFK9M6jO1ePvnaZZxHyAOvnGP3zAiEA0zs73pmN6ZSYCmIN-c4S6IC_P4pS0UYjP5VbepBclS0
308	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCSY9xA6irKqalpyBwujzvCRPnJBK2EQJdhtuxbtPoCMAIgOHtry0mGJbbV7R1cC5IH-C1uRsZKLzHQgaPspRFmnD8
308	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICOtiD7zDadwQ14ce2KGdQCaNOa_nhDKuv6Uq3eM-hxOAiEA-JSKRUFbzpDYfpPisB5ocXtXjuvMs7r7abQPBwbpwF4
309	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDOyuOOOd4jOQVRwX2NktMG0ULu61M1p48oBOicSM9IQAiEAxO054okfdcURxoh6014EQqRlxHXVdGrlvfUwk5GhHxw
309	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIClJdeVpnD7SI9JibIZi9W-2GfnrVoTITDwX6eeKE5PIAiBq0yYnA5kzFtw1nl6El9kwsE-slFw7157YWGMHiFaobA
309	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIBhfgHSmB6FMMsOt-t7raxTi2JzJY_ADjFgy1n76JdaJAiEA1xYLDSR8_Xe8vBl_sAZCcDc7DkeTzhS2Gj27yE-QzLc
309	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICQG8iR2f5rqb07L1U3djuUROYRRCDPI14J5NQBSssYtAiA2qKivQDbaRM9QmVuKMJ8cUwPumqaAJKoEjnkFwtbjnw
309	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIBq5F4tMmVyEKCXwkmpei4aPoPJYPuQ4lle1IeRvjGSTAiB4-QZSvrECPfxbQXxHlCwGPI6y0eLk_zsJywK0wuhO-g
310	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCbtbTgORZeDvVUfpJhqcnhOFQeTACegvjaEZDL7TYujwIhAOZofW6YJ_laSoVdRoU1jHiY6o6mBP9aZz6k_SzdR-tL
310	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEG1pHgYRijGEkSxhw2JTh8e7XbAgH4fj9UXEjbLfV0SAiEAs9TiVBkv-PjUs4zO8YAjto-LV_IXx7sYpKJGgQejhJo
310	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICCDKE-etUtKc7P9swy-Osk6BT-xEUwq-YKWDE-eJd-eAiBpYzbkCq_s5z0X9qBIUoF5T8klM4SPLJhcgkfJW0TagQ
310	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIFrp_zyGhjvq7wM41v5jX6L6qtctSB4glb97VapS99ZGAiEA0EAWDYDmlJdeGNDcj3CsTN_IDO3ECu32q49pXIpShLM
310	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIFMZJKZEFvLZlJgVVdfT7Uy1JPv8vftBPBRh4FgpK109AiEAnqGpXM23kCQ-enG6w8aPtX0o8f6X6a5uS96ge0krD6c
311	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFR5_Oxiz8SAPdNECZbcQncMvjrzKAkzylrr_-i-2A7EAiEAzTa__WaqvgH8PPzPQneiZBSZ1-_MUQFJkGde0fQ7aiI
311	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCRNr3mzlcZ-Kg8Er2KivSixc9p_r_oOOXjFkJAWzLtzQIgJ2MgIFTfK_I9tL0onPcJ4aIa-TA8i7BE3B2-flt_vAU
311	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDJn-n7Nm1cQgFp9xJGjZXMs8TV8BvcU2_0u6AGhF68MgIgVXRqJKkMkdhHJBKu1K512P-i-v17kljbvWt09Unoezs
311	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDr_GtOUIbdhFXqeAuoZl42FvlzuUbTCAqSwXYhGUwfMAiAWTUS6fLxaU5PkC6cTE61f2uVsonMTPoZwiQDhrBIdng
311	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCyDBRPgYonWLTjPCSwbb0yMqOJwdhQCD8UMQQa4BDMHgIhAOlfJu4Fphm8ZYN8UUaG4Z7Cz8zIFTlYxR-XYPHNLS9G
312	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDGzvQb_D6Y5hITlHu3MC3NyKHDaYsuwEUcUruxoiYvbwIgewkW5tC2BrnGrXcwBg-hXiop-MsynrC1gjeAOCGoAFM
312	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCfLyo9YD8KIyP7ab37-hxObOvNH1o4ltbDry1vJIKNegIhAJcEJRFv10yCcEyjR2qjg2YYXclHbbguFTupduMwkeAn
312	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD9NyYJF9dhoor86woEzjv_ELd3rV3zwFwZmP42l9DrtQIhAPUBv-KJ9ikThzVx3O-VGpENuRuItctuzOQ1riEpuJo7
312	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIGcdL2pEf9DjR4Svi9M6yDa-KtQmw3N_yQ5i3SKtgCIaAiEAvGWt4aCOamqtquVMHsPqqSVmPbYiTOTvZCWdhibchp4
312	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIH3vmkE3Y-dF7zNAl_StD0IdlQOZ-ETBqPOpjoZqXAsRAiAMssvP9yYgGvRxFwlugehYtEOSTkyLUVACB_7Ihdq3rg
313	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDIAwgxV3m5coDag3iwpmjzLkeGinKwO-WzxnXfjmbSmgIgWOiT3z3Y3POcSHIzJW7wvu-2CDDFLw11V8WOTpeEGlQ
313	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBQkl5lbG4-UFX8TD1Q8LNW3cfA9wj-mvpl7xOAtc-xPAiB_FqeQbHqXUG8YA7YZnIM0LHMsjkB7XcUJ8IC5tjDYmw
313	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDkObj4Gb66hIUVfJxTU8XBRswCeFm-E0Lnj9mT_MIMnQIgMYURv87dRAAXalIwUWgRs1m_m_RRZHj-z1nhhPxZP8M
313	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCctsHk80wRswR3MvaEpPksFscomq-P9Z-69eS4wEAtjwIgdwgREUhWnjxnSS8twtoc2uTHB6fFkd_5306BQzPktm8
313	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGfmOAxt5mxC68ixhwnD4qTiluSQfPSS6mr5qJY4xKpxAiBNrlt2rBvaEmvPRfX79t0F9I5GKPx4q-TAB7Q-6Tcouw
314	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEHWQKFeZqFnor0u1xgqrFaB1yL10vAkYwaJYfzXurCRAiEApPn71ssGKdDvRyJ7K9P1JkfD38PPZDvcJ82vlAybwoE
314	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDV4doRjqWd8TC4kqbIwEOr8k1tSfNKFKr5FOh_dlNLgwIhAKyIeEXRTktIZhozcBQdzLAdJwTmowGa_QVkYPOB47Ua
314	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIAGRiBzYCwenLcDSXW-1Pf_60roaWehL8Wzd_4GLwEboAiAdYxTj40G2y6jmupQTKvqGMh_jPoa51p8Bvs3brAnI6A
314	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCKEIsAuVZai6qFp-ec00PfKIFtVX9cYGNcLN9z2Efl-AIhAJ4EPbLjXBcEHwGZ2k5gazE1C8odBN-OEOowB2KS-HlD
314	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIE3pcwV7_2ym0IjXhoHJD8Ho-PeuSffc56VxqSK2NtgFAiEAiv2cfG-eiv-9YfpPudQV4_X3q-I7TIrW4ysCB62V9HE
315	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCvMjbidl0NKMvEAIVy0pVOownT-LI6Kj2i6TgkxXq-VAIhAISgxZxR9n__lrF_m5GMiH0PjzR68erVxikg_qqZeeKA
315	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIChZt8XB_HEr9TOmKhZymbgZ9WD8q-dw_gRMzZlq6kpwAiEA_pWc6Vv_AvgFROLsv4sWUX3mlpsjgkuIpVmKltS2zSU
315	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDqTs3u7nec376Uo_FsBeis9951nHyUwQKDafSQVdMyWgIhAIPVNgvJc4_rrcWr0uNiM_GONF4Mf3-m9gIB3XFO-XMO
315	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIChEEwvZEMkT8-j2WakcyYJmtj3S7iroJxHBwDQfyxghAiEAkNYd81VXAJeThnQlaraaQb_5ZpOdKeEgkMAWUG24vGI
315	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQC2Mw2Ud9aAII-LRcpQzRP-KL-dv7WtpKF0gNacWPPgKAIgZ6j8GuJbSLk8oDlVpPXDf6CjsFE4mRbXSvtzcuP1slQ
316	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHQ8Ojz71zdGRJgN8yeV1B32nyABy08T4Rdz6ILAz3RzAiEA-hwPCOdTl_cKk-1dXET6u9lqpNR_TwQx-hetrZEiSng
316	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIA628U7OdXcO1Dau-4BJTxW2fOBxlFns5_J9QplCsQn-AiEA0mZm27cSL3qNMUSnX2xHojvwEh8is6cSUd14eYQwkN0
316	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDqjnNYin7PMC2mgh92MXO5CzrtM6bLl7zClnRLErZaDAIhAIU1LmBUi0Wnh8PoK6ghLyUU4m5bnQGEJkFTeDh4wx54
316	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFeIrIzcdH0qipXR3lj6aj_3_xbBUkK1nViweRo_9Y_hAiEAz3McIgv2Kvy59M7OSWhaMQAjqdpJaJrpo2ePNqReM14
316	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDCzF_jje7QcHjlKnK7uu48mQJquE-qZUQlp5aAfxA5gAIgdt7E905tYb-0jYYSZTKObVXrswmKWNU-Uy8roCTuV5Y
317	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDj9QV4lg7tL5L2n0yXVz094e7jib4aTtx7fpvcONShjAIgDhjps4fvbOO7jBPp9magN6Bb_-WPOeZnCIU1vKnZZWA
317	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIB6QqFVh4Bu7kcAR39liw64Eo7r7_hytJyaHqlcSLzU5AiBgwEkqrPfYdPBGco1QenRVguUZkJcalEFMhhqYvYC0Gw
317	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIDI7QZtdZM6tXsjZyc6OqhJIImQTAkMWsaSF12NET9FjAiA7hLlZQ-Nw24ERACj6B34h0i_GXmCEEcHOvBr2iYTx9Q
317	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEb66ft8vk4GnjWX-dh_sThURU0uZPX-Hjmi7Fk1ItrSAiBF6iB-OY6AqPcwaVPqtAURcH7Sdzl8Tte-95ryWskWkw
317	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICwLExR-5qYIRNNgyM7PXE3_sSaO_-l5U_Un3kVd1UZ3AiBXC8TZwOgNdtGD6YKaGtKH_sS0TktzrIEkoi0zK7LWaw
318	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDRxNStsgebaq967tzv0qna1N2QDqv0MVt8XJY_xnUJNQIhAKMk66A2RJMRvqDB1lT4Bf0seCEG90yepjaFX_-yCiF0
318	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIBJK6XDcOj8iJZ4284HdxVSq7YjGck49zLIRDbG8IPplAiA6TuIB8fpSaqQBG0zNCHwGR7WJF5heBmvRQSBGRCjcuw
318	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC4Gm_LH-oF2WLMWWiypORLMv3jM2udaKZSNN7-EYgj6gIgZCc8d3n5ArwKsWITSE8-4kqDqq1kIoNjqCxeDKG7XnU
318	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIG1psA8WudYFU2OwzGiXMdQ9YMo-BJpWEOteLXjoGlN1AiAZReq2sG5vLNsqvZYd95nQ6RQ3jBZoqToAAUQkopSIkQ
318	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD8jI7KDqwNkOgMKVPpKBmPduf14F_WLuW4yYPbAKOrSgIgEWkd5dARcQ5L-aqARyM_syvcXCJn4eu0yVq2Nzrj8RQ
319	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICT7kcNe6fbhpZ7Qfvz6Y7V0EGEPW8S1KBc_CqjOWV1UAiBsVe-iUa6DFHteCzMtQxiq1j8-Ta7nogfgLScWRO9YcQ
319	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAINSwRtjFsCnmj049W9N0j5cM6k-U51a1jJQIm7jK3iAiAEOFCN2RW7hS_grIFJuitodLoIcB3D4XbEGi6jpS_-EA
319	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIC72266QCixwknbkYh59SAa7JtOS-G8QVXEyPUn9sycCAiEAk7o1f1VzAgdStKb_JzGzG31CAW3Fys4NSBk5BI9tFrs
319	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIAC30IIgHAdPipCn_VadnCci2Nbr5yg8xFNoeG57XZm4AiBRxGp5jIP68pxoNxp0nkBVfLbHCXllENG7RUjZP6AI5w
319	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQD35NPRoc-KFd461I0CrLWbnAJOVmRVojwIZfPDrDfupgIhAMXnB1rsEV5yGd9VAsqljBr0UGXCa2JmJmmHlrf5wa3s
320	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCTugKvG3YUz8IhMC4VDntRNsOIgMo34JE4MfB5fUakkwIhANKKaIZVLMCg8LzO5aYhSWlDiT1tR5FGFgB7AFFhhaf0
320	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIGHet8Jmy8VDTxVRULnOq2ym6DMRVlluvZCc9IOOzy_pAiBC9jjKHI2LgujPcYvjyDcM5eIM0aeu7nDdBPefEeaeIQ
320	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDE9SPpF-F0uxhlkSTtXpiG1i_rpzdJiT137o855U0umgIgeykrB6qFtPUIozCsKJjXMrvEX8k5Wgq9OJ8NZ2SrxYY
320	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCbR28D-BEb0JWVt7L4-2j03RPcU2IiiC6FVdEbvF-T4QIhAPUg9_4kVcg8toaeYZpUr9DWDddao31KjGGVsLWkrEMA
320	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQC6Q9Hz4Z1ZeQ2kIqNJ0KdAwu5te5CkgxNbf56_37X5XAIgWoYsWVq-jPlzSqhYYkljJhCQ7pmnoPmxDAegPac7XCo
321	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDMSCaC3RxbfBbEBWn5AWrAPMFrxF8DuRebVlczWoAstwIhAPvU2J01-M6H7vyrNdR-uPZ0A-ZhEMXKD7WIKIshF5kv
321	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDcSvrFTlxNlJaxCQ_uo9ju05s1-0LjWeIbRGAFvKIkkwIhANyYZOPbf1GfeS9Zs6-q5nknY4mOi70_19gdyke4J33k
321	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIFK-n6Ioi-blu3K4MVPwzQnrWjr3GrYFRzL2iMCbZHWxAiBkrB1NRsi5b7ia49hAnFL2a73P0_RjO6C_1s767CXfiA
321	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCg77G5U6Dr0ybfbegXpWmQN0okkkoEnEKR50dJ143YfgIhAPyLhwHJhMQcRvx4uM47cZa2URjql0BSIc2RI-5q1zRI
321	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIHAeR7L5am6KeJasE7vVTfT41qOECJGTOtU99PFi1XUBAiAt36epnVY830eoNtj9tAFLm9hTanp3VU2gIbN9nD5iuQ
322	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDxw8VXYbPIDSGqIeMwdaQf8u1-epQlC9Ssxdv337CUXQIhANVNajyyBXWfzMpWyI4VY3qsdFe9xZ1Z9KY_H6k5ZZZe
322	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIC_GXYbvo0NY8DrBbjmtNkjA-bNS2K1HyDkVtZKuYk0yAiEAlvK9GFK1bM145lDXVZ6GsHJiFwlFqHqnYYT_MgtsmQc
322	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBrZ-KTPOIvaO9B9UqIdJano6o61Uprrw5GclSrloRyFAiBfj9UYIMX4zN-3yaol0UujvX5X06mR9-hRK6bCUrGmFA
322	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIAJXwgyjGcb02hbZ5G8AXFr2319islfPhIW-bgGPv7rwAiBzDXO4TrKdhfA_zdJuMJfmm3qb7FODuEZo4EQ6D-dXag
322	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIDrzEtPp63pVPrwXTy7HzgcmsM6thhq8K1FLsSoyp-LoAiAGx8KOJjS3r6OIpP8_6_Os4xqViwF8u8oc5j2WrYPF0w
323	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIFTnpcrWzqNPN1WO-1plHS3hT-Joxx0nAvHsHRcnnMRjAiAzYzTryBKSbnsSIxYzRPV7vJU9yl6LZctMNL7O2qS76w
323	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAKZ2czrCXDA5XgvcvPL_KppQ236IQBtcS7YEXQwZf02AiEA7fuEiEShMeDZo2CflQNbQJRAcX0FOXsRR5MXY_hKGRM
323	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDxG9nAN-hQ2suxXkZqVOmGopFHHV-xwil5hfrfR1coBAIgeJPzIvTijZmTz923D4ZJoVS_9wcxvIccRpIT8ikq74s
323	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCV4vEEFJOXY0-MXr3xV3BcnuGXJJvfzPsHv6JJBmWGFwIgX3TFnNjZvl932xjD264vaJ5ICu_wZViThb5tk7Q_Ckw
323	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIHnLZiIqhdehy75sJX60p8YFapRXnNnP0jEttwHKAvS9AiAvor6HRL5gS6YqRcAzZzG2SoSUAMm6phQq5R7vX3m_EQ
324	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCICyWBvNKO0-1gj6O-22Nc8ixhmk_4laOxGm9IRPCrUsvAiBZD8t8WTrR1Bfmkpqeqy_aJfYPjY4Fft0FRXawkAyxuA
324	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCcOHL1CSvWA7hsOIZCd4BllXuuEciOcpfRv47qr6wsAwIhAPVGRTIa_TaqwYh-OXTfz2666cDV4Be-UuXPb3E8AmTV
324	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQD5uqpi2Q1ORHHAICCUSGCiiPdwqZjeIjCsqGD__tu60gIhAO-CGSQqfxGqO8GKxg1fflsb16Q7FGjZTVsuElGmCV5j
324	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIA5SQS3a3qRIpfbH7yBf94ZuEVPJ4d2x8tTQlHt4UXhQAiAssUdtVXjUGrxF_UFguaVs8B6KDTmjeahJMcHbgRdyCw
324	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCICROiHnts8GLhXwd_-x40YzUbnTD40w0X0LPOcZjD_2dAiByw6EkzzWK2Jj5AHnKtjtRgUP_CE3DLyDB4n1n-gcmjg
325	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEvql7-PBp4pKAtugXpV9W61c7OKIP0jEB9Pbd2t33SgAiA7PG1ffld-UKYz_4sFBKjKF81nIKGjOcQ2LTYpTq1yGw
325	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEMCHyBvBO5GZtXJtMYRJyG-QDrFlw8oq68ksn7jIwNtq5oCIFEnP3AoXAOz1tdx0jjSoYrpueNbInUUr45VAHfabYhv
325	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCm4IM7f_6KgK1qCdoGQ2P_oWJA2WZocm6GAxUJoObMqgIhAO-icocOjwyV0DDmESJ0G81jjrqWm5_R6nzRFHMpT7do
325	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDn0sGwUkxoStE5kqTws2VLBYE5nZxSim7DRMkYT6syiQIhAPCjH5Y1_jTS6HcYR2TrExOo_1hWf_2vQ3_D3uMjYw6b
325	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCEsXvu-EiMOZiQLUKucOXqNHLxLv4dFePze6WORBlkuQIhAP-rkxE_At9L9jQIaNSYJykwS41xegtHapWJMWw823Du
326	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIDWuCZ8Zxkc2w9IVVpZt71S0p2KVp0DFiwAA20lG4oxFAiEAqXhnuwCDr6KEgHpW_SbhSeFp8YRGevWnoA2TdCdbO_Q
326	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIC-HAWrn4LrW9DjUXncEHZmYFQDuLTrjVZdVLMENjY_DAiBjhBGlqoUAZMxBkhlkU0vg1L49zyvTgSjzpKqSOeVhKg
326	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIBaISStIzPjl_40YRfnDEIFVvhEQzs4dZfLL03ZKIPA5AiEAm8jY9wT--1k3tHfhoJZSywQNSnOcFNIigMupMDOOFus
326	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIG6NCdqsIQ048WTblWuLdEXHZC9aa7N2XN9d5wfrftq5AiAZVy0xttvMkH8fpSw8fl007FhST9nFcfbmHb2dV3OB6g
326	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDEPTMr-ez1GmzbbV6hHLK3xGvfQmDpspdfWhv26oi8EAiEAiymtVSsMrkHAo_lqaseFRGb_FjvnjZhQ7_iHkfZI4u4
327	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCwvgN88OpGRJ3KKDM7WZjIE8jCx4DgIlyydtxx-DsUOgIhAJ9T4xamjH_7J6WL2XTSYqt8ikd8KLWfhujcoHGn0ihg
327	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQD1CO9T8J7SYBae8mNyBkRNvMJdwQ4vE9433nG-ROB7tgIhAOCPcgy4cLr_Qji9ZOgM24ALmonQWffhZhdHd1oiVlqT
327	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDwudbQmiKfbo5i-etZjS91S9cD1h9w5PADgboV9QX-LQIhAPMD9AOHuVL3waPPKMbDeWf9t_bXPqwAmCRu6ODxoY4N
327	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDrDUbbd6hdt_IF_sY-ErcBjFr2UnO68z2iYvPYtn9bGQIhAK82u9ZdUgIbTAILHrP7NwFdNtP3AnBecbQRnv83MINP
327	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQDD7Hy1fCgVF1ZezH2SucdGpzrcIkFkkLAXOn2PgheJPQIhANa6L3fBAH8HD8FsQ-QJGze3u6I74bO6jYPRu2SF67bT
328	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCe1puy5nbr4haA_Z_4ylVJCwFt2MJWCAvH-0l8cNXsmwIhAI0puHDsLFstARDhPMaRD3ubUl6keAuIV05qKkZ8Yv-H
328	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQC8quH1XqaRARz9gOrU9f4Qpi71M4qqRv5bKeI7irV6ZAIgEsp0k48qt77q5Y88Z0K3Hc7QTOJ5WEPhKiniDv_uuqs
328	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCFNipK4mzRBOfmz_qOqFo21J0QpWupj4mkHK0NCoLoigIhALIjXYBXlVCVOJGOtbFh2hae2lQhzRal2sZYcSXK78LH
328	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIBP2M-KRy-hA3QN045FXUU-TQZDVI1HxFL4dBR0G50BYAiBKw7bMHZu5ckW6ZW_JaYKdQJSbPuQayBTcJGut0aYtfg
328	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCP8IaDwDvHqCYJVE0sOg5XXmPzGphRoeOZ_Yy4xrlXCgIhAJNg-WhfILiqT6M8fqDd7n2ME3MliCuEAc2qY0-wpK-i
329	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCID7xttE5_pXvnRCarGZMwSLv2bRUwSsbNIqFrf-554FvAiEAqZuk5q6KJEY_hojVAw1fvxyYH_J2ceWHKnzXmhN98-8
329	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIEZIMRSIgNgbuLIkOvB4a-eHqG15kU5k0SxEs364_N7JAiEA-Mujre08hDUGjLl2wSffi2PmqQtgw0Gg2-7fc9GI-qE
329	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDPzxHx6Mchev8HikdihtSB8xXP2laIQ9jlLK8R1sCLlwIgEUJKv3IiFg6mwHl5W2pNgJnbHOP_fjRhZyYnfWkZIog
329	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCtpx3XUNVYGy6PZt__vX-310kRU2E_3L0eh2Hv6WF3nQIgJe9tJTxB9_F_rCW0-IdugaVwrp6VVNiUmhMhHQqdhlk
329	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDsxvIWANAPXNG0tN7xtVz2HzZ6oltLDXqW-y1drBBDGAiAAiUFPHuU_cvCT67VxzLPvO5f8YX5M-9A1XEdyjJsEow
330	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIE1kKABMfzRfL3yPs2cuJapZdN9LMrFcN82BucwJ4nGQAiAqBuhLbK7XMcEcdEVW74ByHtz0BxBGAfsV2twkM7IOcg
330	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCICVGH0497HavbXUEvupIIW5en59NZqgQjtxNOQQIijORAiEA5VVTDCve1p5PmhQenwjWmF2CT1P4h7xMzv6OINq8Hl0
330	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCICcZipsVh7wo5JO6jFW1MyA0iocx_SlNSk2psnzvNIyzAiEA436GjyqEs9XYdFZgpwplqHlHZHx2xv-KOLjZ8ZXVFcw
330	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFfZjc-6Fv-JGFqlZB1-6tN4oENfTGUemwuv1cccZ7g3AiBIdAc8QTFpEvQhJcVvDFtyQKhoZsmMwnu_95mp903tTA
330	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIE8s0QNotFdTElWxaV6DF2c6LBWdlRJQ5x-xqADFhQIMAiEA-xCx85YNIdSsxTexV0dsPVK3LirNcXsXBHJF_edchkg
331	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAcmpHSVpLTOZHHIv7NcbE4P9KBQSexF5Gid786e1w1HAiAs17wGVTD2uuoWpsLAvUHS0Me03rwTBeh8W4K5SsbwpQ
331	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHL4cJM_BcZ5wHuEUqaa4E35E1K8b1mtyIkgDPMAQM2_AiEAkqV3rcHm1iadXFwT07W5GAGPZpQVeVafsxbVlr3EMCQ
331	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQC47m267yqYs1vNBXFOaSKZ8701xPf5ar5u2V87owZ5fgIhAIi3QpUKOhG5Q8xZX_43N62X5Kyj0EnXC2Lb4Mavp7U5
331	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIBachvJshkrhWpbdYWXkBPiCw-Yn6_zNMCxY4PcjlFIKAiEAufzvj_AF4Y5QAapXOg7Xn4P5RISvQLqfYir6B-2-YA8
331	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIEqrIkbGyBsCRnZCZr2pz7XjecEkuGuMfZ4EdH34-OJoAiBaTPNqabpxmmNnyoj_D0gWYdGIimT8x-l8u1r_tZTrgQ
332	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIEULqMAZk_-4DAXQlpQ_eJLBemmipeNn01-6ewWYrOxYAiEA-G1SxlFnSpgKFRUEOPYC4ZBu2lz2vYWEjdNe9pHTnyY
332	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCW0BoweI4ZXNS4kI9lztCGm5GlDIgZw0uFPwmBm-GL-wIhAMxOv1fmfstXoPbKZ7C2VK33VAezx3fVr_7GTAT1UhiF
332	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCN9kbWg3xxqQgTeU5qHRInatw4aeW_oHS47WV8PvoD4AIgelIFM_WtNN7aNLjyki2V_EX9u9NEx-vtDLaTXFNIpoU
332	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIB5VX5jRdecv0MPCe-QD5b9s04prlvdW9fMAvfLs48QRAiEAuG5GTrC1WKXW7Bj1JdZLvSooXEcPfEQaVSdVKJen_Y8
332	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIFlLT1QoB7a8v3_cKZ1X2Nc0_X6xhbjI2Bzucq3AbEpnAiAKPJ0cTjQT0odRLXnqXdkUtlmljcPWfGYnARrl9QEIpw
333	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDqi_nq40-CpcMOHJ-fNvK_EuqK0oMsbYN2PMhEJX3sEAIhAL3paOTzMHxIdwTI9sr7g9X_epZHXXxCaIlMGTHX5iDP
333	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIGGZP-ludLOW7xSCw4Xq5HN1U-BzGRwgYNXtP0GOuDCJAiEAlXNIgzl7nLp5vu_mzotw50ludx7Xrb-RiJAxlr3JZpA
333	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCICiNEEAUY62lXSDPCA5pvy0qxvXLR895roEe1poLpolBAiBFju0RX-s5phX9oJf1a3G8iTmNrEfJo9cxDoLunk0YXQ
333	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCgUTPi1L7RoJnMiSO5jYgIiZdWEa7P2hktl82Wy8bh9gIhAOp8jqSI_iYyKuB-xRTLeYw6srxW7dGyaFGezTfMepfh
333	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIEDWVFTfSr4fUjwIdoed1P0QAYsci94-8Q3fk80e-1klAiEAyjV50zZ_Nxl7HtFSB-ANCUV5wSdV3an08SKFNXhKWsg
334	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCyO3kYFdYeMr36KC1TTP0ipH5TIosFWX4s08YqAymWqAIgJ1JWRmOn8SSyoHtsNrHR5OJ_OcUOPEy6u2WzJDaUtWs
334	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAlVDBHdgcGAlO7vlbIJrBXjhXo20ABOlJ2rh15V4jTAAiEAuXZjdAEHAyeWslQVHol-a_w2rqMtCgr0Yx3nNOcMfGA
334	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIAt96JH2jLKa6J74K9AOSiRM48UmgbQ7tMB6xdLf0SRkAiANRt8DKPl7I6U4HvDJDfYyZ_-bVhDOiZu-8p35tk3REA
334	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCrkTuAIyyTOVbwOy_QY-9tuHv2UCZ7frixq6rWXYlsJwIgd9f87mjDpHoomkyjxo8DN61qJEl1fSefDEgoqry-TVs
334	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIHoJMi5s0KEq5bMZX-hBWGbIBK13LfeMblb0vNNxh-XjAiEA3whXOvQzkn3n9tcYky4tJVhg4VcYUsT29lXhh6QBz7M
335	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCktYtd-aA5uhz3lpyOx-pRNVvhsk78veDD0Bf-Tup-hgIgDVKdok3sIqCOnwV8sV9f1ph3sApqBjSEsUe5pwuF4TA
335	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC-UOkPUyd9KWftsdKWgUCkl9Rbd6ZnXH92RUU5mD3D4QIgIE_Qfpe8SWySWGYF840Ebo0fdcoyKf7MrwNUSBAn1rM
335	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIHVP4-YbeiZRG4Fq4ZmFfzOiZiMoC0e--uDNlqU56A7fAiEAqWDmh4kqK6jFo-DLyGd_hKuG9gsR-TMvGDJYejW-wiE
335	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDHCCLltjRU9D6GVb18Cj9QfRaRJAPdygyvzs-50lzoKAIhAJ0UObbdidU5LfSK2wLPEAbQ2ZbMA5Im_hdsE-UiD8R7
335	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIDnvZAd7NRqqaVKVQzQaGyt8m--tWbtLPupvpS5ukeTtAiBptYMbSUE-juJYJzBSFPXT21ZZ0Wxx0EeLkJ978zU5vg
336	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQD9jM4575OMswoHRA0qXozrPvFRrBsn2iZ6KewUzuuYTQIgc2a3mJGWk_zHOLd4gyW-WQGwUrIMbrY-oOuGMBzZpN4
336	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQC8NvyJyaDQhO2fHRKwomv-W9rhzSPpiUHl_T_0ngA7vgIgWfNFjcbxgFSRqjxW8hHSQMO_lcgNGrzj4LZ-5HSG38k
336	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIBUzdTEMEpI2O2xp8NQVewPzrmA8XV-YLwYZqBSpANoYAiEAodvtojClB4Xe1KJ7q1oYlxprkG2HdAXQ_8X4R-vNaV0
336	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGYq5F1wLxq3kcaYCxSQM9Vou_wU8uYkpVRj1MVP2641AiEAiEnt9oHNtjPUi4LvEwXAZgMnh1x1nzF-O_odCUgslkA
336	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCUY-9bcEcIXNl5BkG-QPcy5_WvUs2tBCmvpN5kd8AYIQIhANMWWePjaOUPqEgDJ8QTaCUJ_7iqomzPA7KbQQBYDY9d
337	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHXVXY8YU3ZEJohjsoBnLOzihy9uCK3TU5wmDTl80bhxAiEAghhAW6ITMhxb4SImpq0ixMpfqqyuSlb33yaP1pvdw-M
337	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIAzgs_nGrdO7EjEYj2bO2eevxH-rxHf6kmi48gF6u7mQAiEAkXMylt8vEmCHaMtGx1XiNGFmwtNOTEWfgsODV3wjf14
337	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIERpbc6cqAQOe44Yh9dkN8MUwIEecj9AbAFtam0INOBGAiEA5P36011cWe62P8DmI_yEGLimPcxK8uwiIIN1r6MKzNw
337	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDHZ4Oc7yyXa_U8B6JvZxbuRfx7R1lc_5xtsSQ1gtu7pQIhAM-VvilQ1j-KBNWRvgtxPt8vgF2xRVmodXrrdiR1QUmv
337	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFhRJuiF6UILuTkrFn_4-sNM1OroOoUpLBMUYPni9S1aAiBh1kBdMIwnWQrgt7e1K4BFTxEFtIlmYdgUHm-FGe7YQA
338	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDwOs3x-Ta5s0Vt6dMdRolNGNLcyt2UogzpTxgeH5k7MAIhAND-sUNuhXFmbSRGQ9qRbm-z029HfEcrXfsQ-GwqnA2u
338	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQCVoxLaJ1KWpzNPnkymrckzHxkJXC1K9fzR7fSuqh3I5wIgMe9wJZUQ_DAvy7vemgbSBQnf2pv-lq4i4QWKd0f2gu0
338	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEMCIAmG24e5BKv7dVa8xadw8AsB9QekLTCPr6fBxrSBzgR6Ah8TDprjiZtDT7B39qFFXi0u54aoo-WesvSqf-eOEiPw
338	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDblnj6b19p4VnjPYvYmFI7nhSjlUvXy8IhtoLIUEzcSwIgHdC-UC6ZLr4sRroSzYlMlVPrzGrG-21zebSaXNGK-lw
338	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIF61GsaenlnqUM28BRFjfc_EOiXK22B-R0-e2TQHebT8AiBuuNReH3oqBkSJt6hHHpAEQO2bMIoDt_EVWhL17MYdfA
339	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIGVOgELVjtWZBUDWPCMEruPZ3-6xXKQ64x_CCjcGtuLVAiAqyvfwIKygalZutL1OsMLdBXGJgPBIHkYnn0dQG3Bbew
339	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCICG5-n_clpGvkSiya42k3JXnJokMFw436YwQvBdL_RoCAiBiMfCwa61_k8cCH3_X5yUkFVtGC_z4rF8A_kezB9ne6Q
339	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCn-OWJYPfKI1iYvdpzXaEoiI5PSSyz9Uo5DGO7Lbyj7AIhAJTz14irJP5M9NbzLlnIjG9ZTp59ZIcdmp4Kv3XBIU5Z
339	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQDw-t4q5UJpI8o2jVNl9UNZaqA7eMwIY-7eQ-Ayh9ENOAIhAKUCea9xFNqCWrpgfNQZyi4IyIFrMp8LDFODs9HkgKyt
339	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQCg9vAfvAZ0tN9CBvjxH-IXQE_HnICi5HRfkKmVxQAUZwIgFuyj9sGwsTnjEBpf0lyNZKKIIN2deCadFZX2X6tJzYI
340	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIG93XM2viXUNpJ0IU4a7eFuSnapQf76oV8rQJMixS2wrAiEA2Fp4F8etqwwEkRqRUIjIBLJnpH_bbqtEbuqzhNST0TQ
340	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIBqL8CBFdX6SFF_Xo529debCGv8uONbqW6SyNnxXuUJ7AiApK6fQDPs_Bju1zkA9jt5Az0M741LBjjS4-7g5QiNLdw
340	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIH9kIRxocbZnwJhH_vt8-947_ecrq3HwMjaLQdGcOqZNAiBmr47RkDx2uX-ZgbmDXEbfCVSgGS9j90J_g01nVjqZaA
340	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIAOUOVnZxVUDYskCUvLn2F3DFIE78SXzsuFajgKnfPliAiEA-QnFIhutuiiRgb9EcsULlMQokyom4Jn4JY89Ub9t2TQ
340	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIFGTyF2pdJFT0up4edDaeiV6R_m8P9d8jPTigy59DegmAiAQq8glIEUrU5Necsp8k9vwETE44Q0rikeTPkqfAhYxcw
341	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDFp7Fc6Sa3SJg1Vv2yQUwiXeJlZMzrcgYXa0oE4CtFyAIhAPDc5UecZHN8V-fdbqM03uESxm4Q1WQ1M956-DZXi5RW
341	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDYKodP-BEpObjeFSY8SvF2Tnd3m82cB12XUjZ4XMVREQIhAITDluY0AgN30RNDnYPdg1LXlw6XI3p4zpavndg9r3uH
341	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDRgml3u9dw3-KJcvRwKrHksMc56yA7iqjCSW6mFSxQiwIgCWhAjFy_BtvBiSbmV50p669jS_BNVrNhD43O_T4U7Tc
341	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQD5uC8rW2hrDaZLw01nL4aUM_MAkw1PLXvmORR7ZrKf8gIgFR7WwHOsgNcXgKfWSny2XOGP-nZKaqVD25M7d6iGsMU
341	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIBYjPIQGqD51uZeToaDDBM_R1vEQQPDlbFlDJjnI8U4vAiEA9E7Zq6WCJ7ikeWKTgezZXfJHBsQdpRFiQcSq0-cyOBQ
342	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDq8WoEpirSV0M-JVgh0jTXqpJNDrZTcX3-LufPyLiUZQIhAJaIs7JL7-gEAcFaQ47A5APKYlIbu_iQsaKLDzvhrBEg
342	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEJjKCvnQ6AGRL_oKwS8UfirrZcK0iCAKeJtoEKMM0wEAiAIO9PZ3s0fmHeKQywIFwGlTSrx8F9sDhHASs916ypG5g
342	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCkS8W32NDJIwoG_xjxlXdQCRl7zFizpT5fIQHPZlzwRAIgcRDsMDHKz_EfnmKf1KzlRrBASTD9iA4Tk0kFIiywhBM
342	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIGu1-PrlBif822_KF5MUoUwPsmwIR5fO6ce4mVwAwcHQAiEAvtQ-Os1fsViy4LmlFmdbFso4tvFguIbStdJ5U0Wq2A8
342	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIQD2dUlmZMlR_fUoprsaiEYKx-0Whm7bUCbIYe2NQADQPAIgBEb-QJh1bKLofhV-BZWOW4CYxjireiCvigcHqDLuZdg
343	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIHDPeGTZIS-2-K_CYzCPYSECE4_LDgQCQBE4kny32M_YAiEA3HImrTBvCvkuknr8f5UpRPwIMR4Q196sXnhX5bf0agk
343	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCID38J4-3kRoBbIPk_5LPsiJd1vtIAfhHODz8KUD43zj5AiEAgJkiBCM9bc6S9Qj_luFwuBjFNeQGMLtAXMaqZum1fZs
343	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAXlCgA5-UNSTpd_8CvHlGAHxRIQjnR7TN6d6okQwPhSAiEA7AKS6C94fIDnEgee-446mPurhdEMvI08UGwetN5dQfs
343	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDTf90tsmQEjvMTzOM4eqvHQkd0FNUZTRMQN-hjwXpTaAIhAO0rFyYwUf4E5vcLPK8pvSxWDzE3_n8gUSNfQtfjRZ59
343	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQCDAKPovjqu2hZVglx06XRyZSUw0kklNvPn1i5fYrdrRgIhAIxwkxcXI1rR0BsOZX8AyipG0f_xp2vIgNmNXx8LH8h1
344	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBE1Q0OmdZG50jhJ0eXGaYWz5DaoNT-erl69DrJlGozhAiBXQX6ZImVOv4jhxtPvbt4d6iV6R4BAXXciMgefoi5hUQ
344	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCICD6c5QHlaJDmAeR78_wNVTFCJS_18ieTVXF_ZqmMnhHAiEAh9EFHdLgQ5enW0N0wiADtTgPPPYoL3YyJc1PBlWYu5A
344	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDXA0x25nVZHJVUnGp7yR5ftzqaqgDu55tiTpQINygN3wIhAIewEOhrrargdsDVe9XDC2hkMvrxcpCdPsnuUMLzEy_I
344	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIB83nZWl3ZgWFurFd3l-7_uHcMClNU5yirpuAAcimDKOAiBBQnW3XesruYNOvY_HzINZjZNTVNx-3GaK5SD0jV37KA
344	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCICXmfN1U298GsgHaKnIrxpg_j1yGSf3OgcIYxX9GBuRqAiEA6tpyT61HjqLrx24NqEd2OmorEpMocFioTBi3Az8RNYw
345	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQC7TqneC1akI1cjFvuDAzSjpxoNnpCacpzitfYMzuEWFAIhAJf1B6b__GyKIByaVrp07vx5J_euQ_rLbgPeaxkHZQuL
345	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQC8Y-OK92ZfWmq5i-uaU93ScoFRMXd5EM_1SLdVt4hz6wIgd5-cNqGUxEOZ8VZszCkSVD-5icvE7F1SpTbSJYIaoD0
345	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCNrnFkvIvgkke82WJ842V9JPSWij6pvwvqDSM2dI3P7gIgX8PdcOU4miNQzYLOIcHqUNO_bEhIhboSVgPPQ_x-xuA
345	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIH7kxMkzCFx4g1bfKh0nh9YBlSE0c1UKkQn2pudFh-RsAiBjDyWw8yiz8cfR7przKNhAnS_bAdZqjEDu8wl1bGIAMg
345	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIGYzFEYvRfS43ZKzSLPRO9UmSyODFzZr6GDsr5fc_7jHAiBuDfalSE5VkS_caoBLWddbVin44UXpnffxfS4gbPVaPw
346	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD2q9Y7pIJeoR0V3cLhSkEtjyXKQ4Fe-gTJoPgRI4w5QgIhAPD4loU5DqCvoZcvwLfM3bZszzjhOdPL1dzMFAa9Rax3
346	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIF2wLEJkaAB8s1eL2feBRN-RrM64dFxbtPpHuFc6HZEoAiEA2_ZRUVnt77yHo5kuJjCzqC0V0Xhu7w6RQdJoALfreJs
346	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCzq8YldPa0yICBRfDqHv5_SRI1rEuvlgk_R6weqADajQIgUEUlysl5YgYDHs_ySs9mV6K4wVA3VA0o_6CGXFXKf30
346	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIGpsgy7MU2GC0Od3quwc2fwY-2rfVp60HP_u8qZnBYv8AiEAtGmu_AYKcZ-YCncC-2MNpONCrn8mDI00xiEywIj3a0k
346	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEQCIFSSTKckEpHQ1DDgWdIIU0TZ8A0y7iVHaCQPZtuYNR52AiBp71l8X-1PZq8KxaXd2E2z8AMKgmDvT-wzvGqXRcHO4Q
347	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIBL2b07Dt1SpItfDfdtcn_H5EDcDSKaHaKFPMT4ap2IMAiAfx0DV81r1wKR8XQ4XLwKYB6JQ1wjGMZIs4EIKGDvGoQ
347	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDOUKVcv6XS-0bVuhmIvCvQwHABEYbgpgSGxySs1pHKHwIgMye-PJcfyJTxWJYOPGql5hTYri1ixiLllkUjxEXXC0c
347	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBNE-5NZTEy7pIdOAPfKvzJQ-lN2yF9le3fRKbsr54fdAiB5LWFC4GwoH7Z9vl5ICu5YA31BBRbqsEMKYG_Qdx_h9Q
347	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDmymaez7GBZz6r3z7TYJ7IoDSEyCmSH08HAW8gVUYbwQIgFgWAlcar4Gasja9KfvdzfluAABbTplF_UFMak00jDOA
347	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIEgVZxOuwNPBmwS7_5d94RiF2YBlEONwtbGyJf9EkrXVAiEAgE9wIgTFOLZV6jpZGTxLP5UkL043mtoAITvUF0WDQ-Q
348	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD45E2vCCaWffh_mSC8Y94hEkG7y_FxenteRAG3-R2WaAIhAPyhEAJF6rkQGO_1WsQSjmqqCvEHuX8MX9PsNwzGd99q
348	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIAY0ORk4P47fDzik1xjVgZIoXZGIbLMMtlLO3kJx3mYfAiEAjt6Ys7grEBZ6XAlrxHB1a7b_wOYA5k3281LV0LEf_2E
348	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIGQK_IxW47JgHKfEunuIJibNMcII1bfveTosNMNZ7A-CAiBXtSrrY7m_DejFsjMvlNzHUAPYTzR3yk9_MmHceZn6UQ
348	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGSeWJYZFlZyh1-iJnkTEci67eXjA_hBKeducCoMy5C1AiEAmQvTSsf8532jw6ebwxYhL-3sAg1cxbVEwBZtLtqWHY4
348	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBwzc2WIhCZz1-gOPAJRSkmGVjCd1FAb7kP1uSehc400AiEA4MAlWIagDOHiWuopvAd8rR9_L-YFPGc4-cfqmYpBv8o
349	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDAdyOaXWN49AlTexEgPn6GyVCrm3xFQNL2XaFC0ntkJAIhAKnd7oPeTS1mq9lJ80dLTW68TrPXdjt-L6IzeMugmBAO
349	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCfqi3hw4Z5YN2Os9R0RKoFuEM2SgOs1yhGSD4hcZdZkgIgBtzX1Dh22O4I57o24LyHiGKj7Mqrhf0TUkQxJ_OU4Ak
349	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDKi5FUHAEmSE3I8MX-dQ12APopmyM3GzvCnv7rUtOuXwIgbET2U8K_IsBxZ6xX1LOO126kc0kMPEAu8MMF8rIefJY
349	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFSMe39iNMAB4VvGkxDKNia6R2xy_2HtmHBD-C9yMMICAiEAoaKBgf_3VT3YhDhKVg7ELZW23DJSb-xRvsD7wGuvrD0
349	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCICqVGYX9QMbdNbN0VSHfdBWspJ69TD5C84VuKrs1S0_QAiBd8PCKLP97tC-Mjo5gLbohknLhh5X7F0oth618ESg0cQ
350	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDxIgYVl2JlwUyydooVnCZFGWe6EuhmHicWMGayBd7lrgIgFuU81y_oaRlS9hptZkVKwz99BlxosFG6Y26TvtSDvMI
350	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCAs22DEAOOGRa8RFaJsauA5ytbi_sZidJ7bdmDxhgttwIgfSZfGgh6XNFVu8ZNElDB61pkxWMGGdtR9eYlP0nuK0w
350	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQCVYBsUoSyWsKxtNd7x7jq21-KT4IYVM9Typ1iwtVxr0QIhAINxf3kKi5HpuNA7odN3-LAmTuqKUULnrWuSznJLPqNy
350	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIHTt48bK7QpKmgqTRUmnv0Jbz7riNgtnIz0WHmAaeotUAiApOrm6FR0k7YHy4zdYqa9xpw6PHwg5O1dXSATMHynMwA
350	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQD6T0C84TUM25nBZ0KI780vyOAZKl5Rp7umGsqa2IJeGwIhAONl_RJPz583b1xYNI-UwYPg9HQm-YmbR-pQ7_h1-NI0
351	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDT5x3E7JLOOfPUYyR-YgiOSYtrVleJ_PhtPJJSkJmIDwIhAOSu_6f95qPb2VxbLZgNEw-_-MAR4x4Ts7GUeAlPy636
351	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCVBkPyLCUtc04ASwB69QNRLgIfq7WE3kWDk4SUiTXYawIgQNYoQgffCtIYerjNPv7Pk2PuGr_TTMGb7bjr2HhY7Uc
351	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDOsfOCS40_QAFKMBGZjp-_VQHB5p9UVGaTTiw5UuuUbwIgPEDdlceFGeOCG4XzPrtmmq1EwCYA6jVoAZE35y2IyAI
351	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDR8QR-Nawvfj6cax7uTNPmEJcXuQk92t7Z0iNK7iiwoAIgRVdv3K2_1NEkHbz4suYVQjad9gz3qH1VlzkfhXTDDGs
351	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEUCIBl04ewLdyqfqlLRCNPhj0KxTh_qurHkK9iCgyU7BVP3AiEA2q5pPXmiDQkOEnsr9PKstsQqfyRZ1EY6lIfW46CgwbU
352	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQCvId2E3dGWS6oIHQLcRoGp_aNODwFOcWnX5B7ZJyRZRQIhAKctbuAx4aKs_jet9T3qC4G0AhL5iocYDHbIGHoHkoCS
352	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQDwKeLEMuWDugVn7aAg0sWlnU4jOQe7HeKw0hz-GqiBeQIhAKebB_adNzK_Xzg97x91GcBge17p-cejSLBoO1t2zkW9
352	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQDLG-ajwY32qJe4YI0cxHu_J5axixGi4mcA0s59jrs7RwIgCGoHQPFJHs7NpICGK93w4GUgrnKhRUbGQ_ZVzut2_Lo
352	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQC72-icdQ01U1LCwSOmb-1F25koHybBkzBh2YGDWVghwgIgYPZCK1okK7lQY0JHME5zsvcyzjIkiXuYKpjZ93s3Y-U
352	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	MEYCIQDj3ujktMeP-Ce65lJoTGdFEk2tsOfp3aVXoTj_d03-2gIhAIdrFeskKg2-UDrvPh9JE9JsDmj4wGHBtx6Vj52zsTH5
353	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIH0epBcoTkzVDKxa5SfH-q-N3ZGLkJGU3n1Mtx7mSiWsAiEAiusCt1UE56rQKNEY2L7Rcoal-bNsAJbvJH10lAKiQ8E
353	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEQTn7im7w4jDz502B9T9_68qzT4kjq9YspOLlQBda4bAiEAxI-Un7r9TwD7Fs4mQYBBdiRoLJpgwAeaqtToreUIW4g
353	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIFi0tVXs5VdsZMDXr_rK-UCG-yReeCt8CQNmiQzaok3cAiEA-igkQAKNndquWQczyAkPY72mv3VtvGWJMeNEsa_KW5w
353	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIBD48Einqv_cI4H_Oy9TLIWzScf94dy8ltgh8GWi4d9XAiAGGuGFrPBTEy9bamvUiXaoBxHNQ34hNip3xggdDzqNUw
353	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDvyr3yXFcDJw6hnfsF3jgiIIFyBjAeWY561e8KEc2VfAIgcn2RVIJEfxH_M9X85oLWaz2JBU9OWLgHVKAY6SmJU2U
354	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQDOi_p-AgF1CmeGQqoNnDUDmBFAyAVfqwpJ7YE_ugHUvQIhAKta4ZLBk-Ng1i-JafvPc6cqh4heDgy7G_yaAE7u-6Cz
354	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDtu25VQVjiXo2DuGT67IOSWXIvSmZcfjbjMPC8UM9B-gIgQ2hKdJt88RGvRQkKnVvHnkCeyVtSKOeD2WmddCNqnQE
354	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEQCIEFgB1pzrJxNIiBbcZ4TFx4F0smqxxjaYJidXjR9sNTxAiAqDnvH4GRb09PBNvGnuyZ_CKURQ5kgkjZf7UunFGKpMA
354	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIGEEfB1VVRG0YXU3SF04PeVA1fZqd3Snppw2_zGzL_lcAiBl_Oee1UKFYugYNTzOT79m5sAVhoi-1ew1Zu1uBvUXjQ
354	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQDRa8I3bHK4zN9Jk8cbiRq0i415inL6OG7P2EVl3YW6LQIgB-7oIruKO5X1y-wnT8e_24k_gN4UTeF0i55dfald20w
355	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIAUwlfycCWO4nDwwBnL43FQtp2MiITveTdVhcz49FYtLAiBxzsZTrAPHMximl2HE-0CYdPhh0XbmpZP_hBgazeDqXQ
355	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQC20yTlOH2fQt1PIBdj9CoA8Mz5YYUpeEO1bY7KED4v3QIhAJBEff0_EFSOUQxL3l3W6jEMMeL-1eV7g_OZGDj-1H8h
355	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIHMwDo2Uemjq-3DXGhuHQcckbDwN70R9LvNbbkHS8OB3AiEAzwELL1CLcVMbro68pYUc2DDXqBZ-fBJCa1p0LHyfXNE
355	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCebRoKBU9ciNlGKA1W_c0Rzv2DQuE5UDiZe38BxyhsGwIgUa6MZGwK4OXobuXpUlmsZBAFO8Ocfbz5CKA7TkHnqn0
355	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCICLX0blX908ZZGEbDIaHIOGYCPjHEyOxv-FYcQlEb_ArAiEAk_jRMhiVJrTbkPkirXjHUT6RL_I2XuGHxTbSmUKpVew
356	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBR5VSOA_LU5rQN5DIQ4QDwqvKhHNKZdG4tzAktI7ZN1AiAHYcSnEDBSGiKUcp4pmuH1sZ6GyXj_73_VKwdnqxfuwA
356	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIDBjHo1Oo5SrjrHcx17VuE3KwgIG6k1_cMWSUlSJNOL3AiEApxJPo2aOh98o2njzUE_IzBSKi2DNv5nR8g9GV2MgHWo
356	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQDPslAoTcct5KwQO_ae5wCN-_gUVrU9ozGxBGoh4qvUhgIgVAFOT4-3V9Z5HeYZypQn67Ae61v-GnZPXOgrUZxM00c
356	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDpcz9KIeay-yCLvEMjnOeX7bblgITA27Fvw1XGqxnHMgIhAIECh08EdTScvY4JRsR20M8XElrIgGdxtylwSgmDWzYl
356	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD7uWB_lod11fnxEWRxfXB1Hcv1zo8NBqV1OIXXaNe_bgIgfbDdMz_0SQ-cTfv7nTZUo4LdD0ATivX441dZBR0AZb0
357	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCID3Sx6Zrad1dmIlOFejxV7ttcN3AyyhdLUWS2rd_x6QXAiBQH_QesjdKf45DfFE0inQhJ6QQrhsSBTB5uiTA0iZJxQ
357	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIQCV85ZiLNc2vnKSqrRcBSyn2DcNg0ow_toPR4Huu1uS8AIgUrVhYc-RjpXalp3aCAhf3HrKPjRseFvHttC7i5_835s
357	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEQCIAeTWrF0C_B-RtoZ8aihnAqszSBQgBYZdIaC3v4ouGP7AiAstSD8L3QAByyRtX17TD8MUX-jVX5WRuf2VFZ-F-QKOQ
357	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIEg6TzBpwttb8-KRgx94LzmXNkSa2VVa02mQ7Rl-5NANAiEAj0q9wE8eRajcEfXig7K7q9gRGfHpJp9MC_8Wgf99T14
357	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQDyGKGN_GTE3-0CGdYfF1VO0HBm1aJCits8d28iAfcAFwIgKOKOeGmOy3yVJgCeE1wLD8YwXWSgs_Lho2f31hnRj2s
358	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIEsrRBGk85UOwJ-MERwHsRVI_0LyiAP1uTRdVEPgqbUgAiEA9Fi473RTIPvJAncFLA4VBafSP_T65-gffdrDZ5fziwg
358	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCbbFKBPYhACzgO5kMR9EOO6ZtxVIp__T2NzyK1tfrCngIhALeVGao_eglvERxRMNR5HKAF2FXWJZ2kC5iA-G3z4z2M
358	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIQCVtjHzivLzxEtbZYKXKjuYWlbHBO_s9Cb1nqyENGexUwIgQh534OY8MmaIujr7rDN7jQkDM3BUAxCpTVjU948QKPM
358	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIHZKfNzJr2mVxjsKSgGz_--pexyi5WSC_0BZZ1i5u1PyAiBZJ0ik3sPWziAgbXBE8GkqdQ_mLLgVZBOOzevdZ29fGA
358	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDS88HyGxJN_90iFzVNAQjVVxjCgrqZ5Rcc_L5729HQPwIgTxzhHRUHP7PMBNu3TV9veIs7i_1mCq6ONtlMDyhPeRY
359	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCT7evcFKdHYkESusKPt5ZIaN7sOJm1BUSRfU3RrGrWnAIhAJ8Id5lwI1FIanD5v89XsQGyCnmTKGSs4FTD3Gjm6-6V
359	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQD-mJXgSfHs43EJEmvxma8OUMW1tnZVx5nFLMXUsouc5wIhAPW4rrFhu3OgGQAArXVmvrTFnUGZvm62NlWuHBK2ky-w
359	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIFwz3eqvwqapZAw6o8e29t9obB_lK4os0Zap0UxH74wSAiB0rN06mmlZkkMw-UufHTR-KfrtAhGasd5Qg_XGbE5ixw
359	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQCrisEwAHD9qzojmN_gvDX6rpWcbwkMMyfsXaUYAr4NiAIhAPViuSZ4kPhwcpWPyGB09yLgQN3fCmOJVQDr6XynCkUJ
359	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIAVJjzvAgag13qtqwpsh4IAA5dSQFQi5PlTA9OD9mvpOAiAyWT-Cv_sIjfd4s9vsradE9F0SWOrtW0yuvTOj0CCKpg
360	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQCyiUS3Su2RQc9E6dIdGIOuiu3TS32y4OsBKTiGEGS01AIgZomWNm5a8OBhI3VSrpAHF1OgRWsf16KbrU2wvmwvSj8
360	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIGe_xpExRrg2qPxIM46k641G-SIYIZdWqJ8gwltpUkbCAiEAjq5Zr_twn9OqfJQiMcspLMHkJKMyu5AFS9rKqg23jBI
360	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEYCIQDpRNI8tUbeE3RJGlUZvy1-X9d4Z6sLUjx0VSzE0e980QIhAJZ2eLnkndMVFO2tagTMdaazWpYPDqskHhBtygMTrZDU
360	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIQD0YgF-D7iecBPD0KLsm0_TmtFP1TyAaoTpbNPOp-aa-AIgYwi0FZ1doUMISD7vz86TJVzEr9FGNZuFtWo5eH3h4X8
360	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEQCIAoUJWooWYvcoIc9jTELaHZgulvETpnjP1mOeiW6XkSRAiBuuliCpt_DYoCqyV5FC109JQqk6V_v-YY1OjoM5JZHLQ
361	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEQCIEVscuY6N_TLAQjcunw_ziuNuZbmTspU5WtkEjwwCm-dAiB00fC92hnNi9XVSqXWXzxaDt1UdqKUcVDq8wTSA1cFqg
361	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCVjHT1BsJ7dOjQe3MeG_m8ivWiHBZC6ZshjyPcXLA_9AIhAM1QxSO-ufGT6jifS1f7XVs5b80lwCAeoKxTLlcl0NJM
361	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGEih6McxlTe4iBxDsqji1HZ5LGQt1iD2FOxz9cNxaaCAiEAjW54uztlYfRs0qVIcqv5LJJQ4TpNrCZ53XUIrnTrPh8
361	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIFpulXbRiGhdV9_4VYiuXbHvYVPOAzIQwsCS-UvDKuBHAiBVryoI5vIv-pRC7P-N7bgUupJ3IJp-dqG2f1Mb_aZRGA
361	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCyRYLYe3S6xU3fHh6Wji3s19aF8YtF-bpLUArc1XGzTQIhAIJ_MfyDDeSfXbcQWis8a5pr1tHSxasreDhbu7hLswht
362	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQCyJ2f3Yh465pD6frwvXJEOchZhvPYP1OuIH9g8r1YZxAIhAJVj_aTCX-n4rt0kGSt3PbjNj78W4Sgh9tcucoHkLlCs
362	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIHkuSCC_APH99oUtUHAOeu3vGmrDLOwUBJ7fDEA9yAR5AiEAu4sIEtd_5_E5-CXhhiSKvBvjkf97OBHN2qZWkq4YZxc
362	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEUCIQCb595vxKnfpJaZBT1ql39PIaMNyv-jjQfr8VMvPiZslwIgRCHSlYtE4jUJtGHs2ghRS01253ERhX-v5JCZxbimYSM
362	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIAN3YaqhNxRzv-t1pMFLHZ1x6F2-zEPgZypmPpE7CiRIAiEAplP1SVrfC_2XmemdLsRnH8oOGLDgREFBwZyFkwj1mhQ
362	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEUCIGHTkNjMOiehGaKcI1wGygQuY4WwmRekmEkZxWWJ98C9AiEAmabHVIw8j0vv095iTPavGHzlG8cGZypGb5EdeRweEg0
363	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEYCIQD01yHO-dFXYBDsjkV5EU_mILqekuiPrLNcSTMeH_Z2KwIhAMQcmf352lalpFaTVM4f9UCG2GBGB8AkEjsSC7INYOoS
363	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIFRXzRB3l8pOQhokZVMEQyQ11mz1yBaBUENu_6HLhveZAiEAu9aSNDoFf9QD3wCy6mttrefNwKn4S4GTMX0iAWGP4oY
363	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIEnCfp6Tm25UgWSB_lFDw1mcE6Sr8ABK96wksA2bqrnEAiAfNv_Po00BCmREVYNwFkTmL0-B1CzviAN81_9gB21bvg
363	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEYCIQDozehRLCd_FbCEgtRAWStyU9JaZMqGQmLNGSNSyMy2rQIhAPIRN1l7RXnltxnVxNtHxgcXK09QPOz72EgiD5V04txp
363	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIBfmlJRjzxa36hasXN-K9gCgbaR8YMcGzxTmbv-ob_TZAiEA_MdVvLAiF1L98N3HXvJqWyitW8mm-rtgPT879nk1i7s
364	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEQCIBIgzRwAXqmp6NAr348G4Og5yhONaW9uteSxgQm24aNjAiAhTMTuJ8TnGhaMbTogmZl7HU5SKHZ1LfRMWvbAhB8zBw
364	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEYCIQCeJUvdo9yiW51EWFa12h7RLEXiNeNp6kBcsvzOMaXjfwIhALuO74iXfcIwxcXMBCJMXHIFY0NILhUAkcMCWT0V9PFE
364	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	MEQCIBy_IJM8zvZhBn73v4kPu2jik5FI_E5kudJAdMJmAsKXAiAmjOtGx65RZU4MjMjXprm8WaIMUHHOZpPQPqLR9nXlEA
364	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEQCIBGWP41Di1WKrEsf4LB6kJe6za37VHl9F2K5sf0uDYu5AiBeCKPIkVasEO3NxV7GKus_u1PTeSgdC88jEAM1oqYZiw
364	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEYCIQCGNyJdNgBt65zWEZeHrD60Bxtjb0vtKy6m4SoNrZi4DQIhAJu-wjOmDZXSmDIa1lrkIqeTpDnXtTMReubDHZnBDb6S
365	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIFDA60FnXlNFFQNlSqmaRJqCkLc2S2APPPtHY8ZOk4pEAiEAv8uVRWqf1gj7R9c11BlKzBc09zbCT_8EaZanLRuFOnM
365	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEYCIQDOf-9ZuMHVY6aKFWB4OJY3RD1Lc3NgeYfeGqZlswHS4gIhAOgAFyIA7rdSAttMhvWwhN_LaXd_QdQ9gVvdFb1foCfU
365	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCyYPU7p26t8YFB9XTTJjKcYyyzY3gTDBQoHmG-3gEqogIhAPNANS4wgQvWOaL4vmCP27g9xMkrijIPnq6Zmpphpq69
365	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	MEUCIQD_MImwihwDQ17puZSoF7-BWtzh3Dm-psOOy3In6QNyFgIgIiWOacQYTUq_jcb5bXt3qHqyaw-UhdCc47ZFuAUgey4
365	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIEhfBpkplHZKSV9YG9u64wfuMhXLYq-3s_eQN8Wpei1VAiEAv2fdcgLeKPc0ZS81ejeP2QVVN0EYoaGsWeB_tGBU3uE
366	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	MEUCIQDmB-b220PIjxPs2hlQIA-_eoAwz-LBWMo8z58dRhAODQIgFmPzlGZ6O2EcNyEW7qc3-dGZ5A4SfrVNzUC6ZK7O0dQ
366	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	MEUCIE8YCxZykAI3tmVArzpvy8b5tUwon8rBtrho5ureIJ5AAiEAmwZqR8_F-D-413jjqdBJFU1AmgV5n5ALhUud1Priwb8
366	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	MEYCIQCf69AYeJY9lDH7KQ0utKHF6uY_u0UW_UgUNuJzWFnzEwIhAL89gybDrmDxNlv5lQNgHK77nD9LfCMj5IIUBOe8p__Y
366	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	MEUCIDGhgOBgF7Z65aDPnYCPQftUgsJzjq67kodwl0TAUFwvAiEA_Y_YBkbLy22NOylb0ZJSP5RVgD4HZqgE8YsgeJRhoHs
366	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	MEUCIQDSb-p4ZJyxfLwQhCHVr9n9ii22XWmkdQapUGIsa49UjgIgH-ZX-WJFYcYjJijgBsWmOzVAcxUEahUnBq1dKnTRFKQ
\.


--
-- Data for Name: blocks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blocks (height, "time", "timestamp", prev_hash, block_hash, transaction_count, hbbft_round, election_epoch, epoch_start, rescue_signature) FROM stdin;
1	0	1969-12-31 16:00:00-08	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA	QTb12QPl2cVpR5UWJfBEJJAH9yR41DNxoWL0spdR-j0	22	0	1	0	
2	1583966756	2020-03-11 15:45:56-07	QTb12QPl2cVpR5UWJfBEJJAH9yR41DNxoWL0spdR-j0	2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo	0	1	1	0	
3	1583966761	2020-03-11 15:46:01-07	2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo	p1Tlc8mVbhV4AwKiixJ3LX7X3LBsPxF6f6N9SQYgMiw	7	2	1	0	
4	1583966766	2020-03-11 15:46:06-07	p1Tlc8mVbhV4AwKiixJ3LX7X3LBsPxF6f6N9SQYgMiw	ncY_Kut0wgenoyESnxQZSpsE5OureUctQPT76O0Kur4	0	3	1	0	
5	1583966771	2020-03-11 15:46:11-07	ncY_Kut0wgenoyESnxQZSpsE5OureUctQPT76O0Kur4	AeQvs3-LDtePa7jcpJxdK2dMd7DVrWQ3kXksr_g6ASo	0	4	1	0	
6	1583966776	2020-03-11 15:46:16-07	AeQvs3-LDtePa7jcpJxdK2dMd7DVrWQ3kXksr_g6ASo	lEYeL_uegVddHV2MrA2bnyJal-4TngE3RZ6X-sUayic	0	5	1	0	
7	1583966781	2020-03-11 15:46:21-07	lEYeL_uegVddHV2MrA2bnyJal-4TngE3RZ6X-sUayic	q1xvU-S9tAHnFR_QXClmaFZh_RFcv8LZ2soWREHq4g8	0	6	1	0	
8	1583966786	2020-03-11 15:46:26-07	q1xvU-S9tAHnFR_QXClmaFZh_RFcv8LZ2soWREHq4g8	4vlhVp8c49NIRw6XhbxHfa8fHsy2Q-Q29HnIe0IlatY	0	7	1	0	
9	1583966791	2020-03-11 15:46:31-07	4vlhVp8c49NIRw6XhbxHfa8fHsy2Q-Q29HnIe0IlatY	yPsh7qXlSIyKPt_sM0ptXTSgILPJWFBFFwNIDE6a8iM	0	8	1	0	
10	1583966796	2020-03-11 15:46:36-07	yPsh7qXlSIyKPt_sM0ptXTSgILPJWFBFFwNIDE6a8iM	8gfj3IvOZuecHoEFgat-DJqbLjzob1Jvn7sFDJPB1jQ	0	9	1	0	
11	1583966801	2020-03-11 15:46:41-07	8gfj3IvOZuecHoEFgat-DJqbLjzob1Jvn7sFDJPB1jQ	rsQWoMbtugFNhlfpFtTlILxNPYgyljlwl76dA8WL_wo	0	10	1	0	
12	1583966806	2020-03-11 15:46:46-07	rsQWoMbtugFNhlfpFtTlILxNPYgyljlwl76dA8WL_wo	Iware2lh7FLFL6ptrc7uA83JJeC-2wVn5wgRNdFQIHk	0	11	1	0	
13	1583966811	2020-03-11 15:46:51-07	Iware2lh7FLFL6ptrc7uA83JJeC-2wVn5wgRNdFQIHk	jCP7bp1Ac4n_VXz8Gi1RjcBOr1C1g55TSbGWrKGC6Ps	0	12	1	0	
14	1583966816	2020-03-11 15:46:56-07	jCP7bp1Ac4n_VXz8Gi1RjcBOr1C1g55TSbGWrKGC6Ps	MPYShW1SsS5-UUb3MVHtdjdO0QXhWq3W9t3kvaS1gFc	0	13	1	0	
15	1583966821	2020-03-11 15:47:01-07	MPYShW1SsS5-UUb3MVHtdjdO0QXhWq3W9t3kvaS1gFc	i29yRrwwVUKD2U6yv-d_Uuq9R4bwecIjgdnnCXBi0bs	0	14	1	0	
16	1583966826	2020-03-11 15:47:06-07	i29yRrwwVUKD2U6yv-d_Uuq9R4bwecIjgdnnCXBi0bs	cSGkHu3ehYoILITZwvzox82p7vM6mrJ42Rs28NpSyWQ	2	15	2	16	
17	1583966831	2020-03-11 15:47:11-07	cSGkHu3ehYoILITZwvzox82p7vM6mrJ42Rs28NpSyWQ	M23tRUzf6EknBJooBgAr2uA7PiRQszjLj6MVHV6_Oig	2	16	2	16	
18	1583966836	2020-03-11 15:47:16-07	M23tRUzf6EknBJooBgAr2uA7PiRQszjLj6MVHV6_Oig	Dsa2DT0Kc6lgJ760gzUYfUzGTx72fNAE1V7FU1lryuI	0	17	2	16	
19	1583966841	2020-03-11 15:47:21-07	Dsa2DT0Kc6lgJ760gzUYfUzGTx72fNAE1V7FU1lryuI	4qasBYrynPlvuyPsYSCA-TG8xzIUYi7exDFKos9LeIg	0	18	2	16	
20	1583966846	2020-03-11 15:47:26-07	4qasBYrynPlvuyPsYSCA-TG8xzIUYi7exDFKos9LeIg	DZ1Aarnfw0ElZrUPUPTOe7urKre8uLPU0F8hGlhm4kc	0	19	2	16	
21	1583966851	2020-03-11 15:47:31-07	DZ1Aarnfw0ElZrUPUPTOe7urKre8uLPU0F8hGlhm4kc	8WYE60_aN3Q75tSt8a0IXaBiNgznV5gX89cN-fooZ3w	0	20	2	16	
22	1583966856	2020-03-11 15:47:36-07	8WYE60_aN3Q75tSt8a0IXaBiNgznV5gX89cN-fooZ3w	kAKn39bDP43i0stzqtIlXZto5Y3adi-2clCp7vmvL10	0	21	2	16	
23	1583966861	2020-03-11 15:47:41-07	kAKn39bDP43i0stzqtIlXZto5Y3adi-2clCp7vmvL10	yKcUjlX6XxpERJIF1_qpAmc-txAA-na5MkXyLLo1yik	0	22	2	16	
24	1583966866	2020-03-11 15:47:46-07	yKcUjlX6XxpERJIF1_qpAmc-txAA-na5MkXyLLo1yik	g5Di2bofcxRy4jLJ06-oB2RhZjsunP-yWNQI_uvBU7I	0	23	2	16	
25	1583966871	2020-03-11 15:47:51-07	g5Di2bofcxRy4jLJ06-oB2RhZjsunP-yWNQI_uvBU7I	TndgjT7RxBxunxYNuSsWII8sQOUEGgmLiKFRn1X0NWI	0	24	2	16	
26	1583966876	2020-03-11 15:47:56-07	TndgjT7RxBxunxYNuSsWII8sQOUEGgmLiKFRn1X0NWI	zpcs5wO5Q3hLSit09y6DLdRCYqJ26ncoZ0zdJZp82vk	0	25	2	16	
27	1583966881	2020-03-11 15:48:01-07	zpcs5wO5Q3hLSit09y6DLdRCYqJ26ncoZ0zdJZp82vk	r-frj6gCAuxe1i1LvV958mGOjs7_liak9WOSCjJwVPo	0	26	2	16	
28	1583966886	2020-03-11 15:48:06-07	r-frj6gCAuxe1i1LvV958mGOjs7_liak9WOSCjJwVPo	ZNWehHcUlJ8UBAUNaW3UMP7lgRsGnV3h-P8g-K4M6Ds	6	27	2	16	
29	1583966891	2020-03-11 15:48:11-07	ZNWehHcUlJ8UBAUNaW3UMP7lgRsGnV3h-P8g-K4M6Ds	vCY9hl-kkR_r1UGLnD1D3_tRmoaPv92mHOq6RAkiibc	0	28	2	16	
30	1583966896	2020-03-11 15:48:16-07	vCY9hl-kkR_r1UGLnD1D3_tRmoaPv92mHOq6RAkiibc	VDB98H9KzvedqZ3SQRnOylrp0c1QXKDlWrz3pPMVmkI	0	29	2	16	
31	1583966901	2020-03-11 15:48:21-07	VDB98H9KzvedqZ3SQRnOylrp0c1QXKDlWrz3pPMVmkI	Ws4OVcdvwSGuYRltY_eJ47zWB8BdmzLj1QqCPT3NpVo	0	30	2	16	
32	1583966906	2020-03-11 15:48:26-07	Ws4OVcdvwSGuYRltY_eJ47zWB8BdmzLj1QqCPT3NpVo	MfflsNMxnTtkskiL8O_gKP9fxpXj0kgEUjMl3V_xb_s	2	31	3	32	
33	1583966911	2020-03-11 15:48:31-07	MfflsNMxnTtkskiL8O_gKP9fxpXj0kgEUjMl3V_xb_s	NhwZQneze4EvMNENdqlmyBD-gv5FyGEL8vf54S5sfC4	0	32	3	32	
34	1583966916	2020-03-11 15:48:36-07	NhwZQneze4EvMNENdqlmyBD-gv5FyGEL8vf54S5sfC4	pn33hFbRNeA8GClJWuEQGhaIEHkiaEWK3gZVU6S_lTo	0	33	3	32	
35	1583966921	2020-03-11 15:48:41-07	pn33hFbRNeA8GClJWuEQGhaIEHkiaEWK3gZVU6S_lTo	ibk5iQB59zArTEaCrh89gwerQ7F8HiOusYF7oxXei_E	0	34	3	32	
36	1583966926	2020-03-11 15:48:46-07	ibk5iQB59zArTEaCrh89gwerQ7F8HiOusYF7oxXei_E	1iTr2pNXl3vq_C3Yyfq0Q80WrX7GX3TMCPi_KjK3G0g	1	35	3	32	
37	1583966931	2020-03-11 15:48:51-07	1iTr2pNXl3vq_C3Yyfq0Q80WrX7GX3TMCPi_KjK3G0g	1g6g6_n0VPsiyHNoKIYTOUw1U7Tzk6Hm7PosnBdNA-8	1	36	3	32	
38	1583966936	2020-03-11 15:48:56-07	1g6g6_n0VPsiyHNoKIYTOUw1U7Tzk6Hm7PosnBdNA-8	-yLfkJ9BmzlLnSBPz0JpHYUl-EhKKc6pv5d6MS1UsAY	0	37	3	32	
39	1583966941	2020-03-11 15:49:01-07	-yLfkJ9BmzlLnSBPz0JpHYUl-EhKKc6pv5d6MS1UsAY	x5wUyiFfQj162UHfyVlAE7Gc0mEnG8xpqMplYBEIlgo	0	38	3	32	
40	1583966946	2020-03-11 15:49:06-07	x5wUyiFfQj162UHfyVlAE7Gc0mEnG8xpqMplYBEIlgo	a5aSKcJk99u1tOkB1Fp3ceNFsgXjSuuY0jEcRWZU3_Q	1	39	3	32	
41	1583966951	2020-03-11 15:49:11-07	a5aSKcJk99u1tOkB1Fp3ceNFsgXjSuuY0jEcRWZU3_Q	RwlAhqPT0afmPN-db1_VhldTOAKXVY6akUyZqppxkjc	0	40	3	32	
42	1583966956	2020-03-11 15:49:16-07	RwlAhqPT0afmPN-db1_VhldTOAKXVY6akUyZqppxkjc	8YSQ8qq4fThiDYBoWqcGlofzhGxpPfUyMTwCeDl7n0A	0	41	3	32	
43	1583966961	2020-03-11 15:49:21-07	8YSQ8qq4fThiDYBoWqcGlofzhGxpPfUyMTwCeDl7n0A	itzuvP-oKJFD7GjIcnn_w6lFwEgTj98kCQ3FOcbx-fI	0	42	3	32	
44	1583966966	2020-03-11 15:49:26-07	itzuvP-oKJFD7GjIcnn_w6lFwEgTj98kCQ3FOcbx-fI	GOSWZqcS528o3C3EioD09xurgtL8aM9dkLUH7TpRkz4	1	43	3	32	
45	1583966971	2020-03-11 15:49:31-07	GOSWZqcS528o3C3EioD09xurgtL8aM9dkLUH7TpRkz4	c8fjBZP2HCU_utELGImtBxpfWAVcQHjGy42KY0OCLOg	0	44	3	32	
46	1583966976	2020-03-11 15:49:36-07	c8fjBZP2HCU_utELGImtBxpfWAVcQHjGy42KY0OCLOg	6dPAshC4PYfdQSUKQCCd02pAEoYWZZobN8Sqc5Wn_YE	0	45	3	32	
47	1583966981	2020-03-11 15:49:41-07	6dPAshC4PYfdQSUKQCCd02pAEoYWZZobN8Sqc5Wn_YE	c-kJwU_q_KFJkoVY7XkMJ_N7vUJ3j6nXLWDssTsirHc	0	46	3	32	
48	1583966986	2020-03-11 15:49:46-07	c-kJwU_q_KFJkoVY7XkMJ_N7vUJ3j6nXLWDssTsirHc	ZN1pkk-umA1sXVflJ679clwLt37lKwEHS2EWGmtBg1M	2	47	4	48	
49	1583966991	2020-03-11 15:49:51-07	ZN1pkk-umA1sXVflJ679clwLt37lKwEHS2EWGmtBg1M	i0iGvsEfZkUfl8DmoTkvB2eqvEYVhBV257pyJ6gG4yk	0	48	4	48	
50	1583966996	2020-03-11 15:49:56-07	i0iGvsEfZkUfl8DmoTkvB2eqvEYVhBV257pyJ6gG4yk	9XTo36iNac65TE2hEAMjq347xaKPHNOP6AbalD06Q6Q	0	49	4	48	
51	1583967001	2020-03-11 15:50:01-07	9XTo36iNac65TE2hEAMjq347xaKPHNOP6AbalD06Q6Q	KTt--WGPyDerni8a1f-ySDfNVCDGDz2Cxf3JsGC1WqQ	0	50	4	48	
52	1583967006	2020-03-11 15:50:06-07	KTt--WGPyDerni8a1f-ySDfNVCDGDz2Cxf3JsGC1WqQ	qv3Z5EoHaWbPEkLpyy4lEUeku3Ysltg5Jcyfc4n3cTs	0	51	4	48	
53	1583967011	2020-03-11 15:50:11-07	qv3Z5EoHaWbPEkLpyy4lEUeku3Ysltg5Jcyfc4n3cTs	tu7TZcow0_e0wJ-8m53m5i41pXurEyOewZOsbTZPaxQ	4	52	4	48	
54	1583967016	2020-03-11 15:50:16-07	tu7TZcow0_e0wJ-8m53m5i41pXurEyOewZOsbTZPaxQ	EinF-MCp07E6Rrwnko4DXoN-MZkywL6OpzGqGqLg_s8	1	53	4	48	
55	1583967021	2020-03-11 15:50:21-07	EinF-MCp07E6Rrwnko4DXoN-MZkywL6OpzGqGqLg_s8	0Acch_9d0WcK1vv0JBk-T9RVg9Uu0elTBTsEoRtFq5U	0	54	4	48	
56	1583967026	2020-03-11 15:50:26-07	0Acch_9d0WcK1vv0JBk-T9RVg9Uu0elTBTsEoRtFq5U	65emxBxzlKSG4H17Z1oZ6JChYhUJWIC2YIZKAknTANU	0	55	4	48	
57	1583967031	2020-03-11 15:50:31-07	65emxBxzlKSG4H17Z1oZ6JChYhUJWIC2YIZKAknTANU	0zgj-UESnImrgPODIWwuGwp-P3CojrgEv5c4rY4OHIQ	0	56	4	48	
58	1583967036	2020-03-11 15:50:36-07	0zgj-UESnImrgPODIWwuGwp-P3CojrgEv5c4rY4OHIQ	_gDlrWaglGzpE5VwbL7wlT0q8hJwiXEYdqy8PS7qF8w	0	57	4	48	
59	1583967041	2020-03-11 15:50:41-07	_gDlrWaglGzpE5VwbL7wlT0q8hJwiXEYdqy8PS7qF8w	Z0DCOebTgxn4a163vukB1Ph9MhW6vwZTNTNky5-SjRY	0	58	4	48	
60	1583967046	2020-03-11 15:50:46-07	Z0DCOebTgxn4a163vukB1Ph9MhW6vwZTNTNky5-SjRY	Lji65QlEPHQkRSK2jmUso2GGfQo7QTZw1Z5QeAFG6xg	0	59	4	48	
61	1583967051	2020-03-11 15:50:51-07	Lji65QlEPHQkRSK2jmUso2GGfQo7QTZw1Z5QeAFG6xg	-0CLFU-ZHgu7UGxfbY8nkGLutxQbVx0H3LbErzsbBUs	1	60	4	48	
62	1583967056	2020-03-11 15:50:56-07	-0CLFU-ZHgu7UGxfbY8nkGLutxQbVx0H3LbErzsbBUs	rtZl3rj63yXf3NewI6V3rD2FQlog67PAcCHvAdx5dUk	1	61	4	48	
63	1583967061	2020-03-11 15:51:01-07	rtZl3rj63yXf3NewI6V3rD2FQlog67PAcCHvAdx5dUk	IQlWeTW5lQ4rGrJhKXANqjso70LlIl935U8TszgbM2c	1	62	4	48	
64	1583967066	2020-03-11 15:51:06-07	IQlWeTW5lQ4rGrJhKXANqjso70LlIl935U8TszgbM2c	2ytii0wOXJDwt1nAGVVAd657uk1704H26HSNJ24zbpc	2	63	5	64	
65	1583967071	2020-03-11 15:51:11-07	2ytii0wOXJDwt1nAGVVAd657uk1704H26HSNJ24zbpc	MoxYC4EB2wL4e8aPJAvm6DhQuLkqZYxdHBx5_KXQ5nM	0	64	5	64	
66	1583967076	2020-03-11 15:51:16-07	MoxYC4EB2wL4e8aPJAvm6DhQuLkqZYxdHBx5_KXQ5nM	513Kzu7eP6MvPGGe6Yp1YiHgmX-kmbun1E3GiA6Az3Y	0	65	5	64	
67	1583967081	2020-03-11 15:51:21-07	513Kzu7eP6MvPGGe6Yp1YiHgmX-kmbun1E3GiA6Az3Y	sbKCsYl4XPN4uZtPauNV9rCwxgS5RJsuIaDRdtEKCBs	0	66	5	64	
68	1583967086	2020-03-11 15:51:26-07	sbKCsYl4XPN4uZtPauNV9rCwxgS5RJsuIaDRdtEKCBs	m2p0M-AfN_totOhDdWUlo8plaJw1HiTFHbPoGMcpILA	0	67	5	64	
69	1583967091	2020-03-11 15:51:31-07	m2p0M-AfN_totOhDdWUlo8plaJw1HiTFHbPoGMcpILA	9d0YJoVRo6v5LudNLI7uxSZxNBp5kDDTvce5TF-um8U	0	68	5	64	
70	1583967096	2020-03-11 15:51:36-07	9d0YJoVRo6v5LudNLI7uxSZxNBp5kDDTvce5TF-um8U	DGYtDWDBAi-Zioa7YmklRwqZr1kMGfECG7ZqJWOA2Ns	0	69	5	64	
71	1583967101	2020-03-11 15:51:41-07	DGYtDWDBAi-Zioa7YmklRwqZr1kMGfECG7ZqJWOA2Ns	jF5A05ZPVToADnEHZVL_1yroP2tuyf-JvIxCmbPyhao	0	70	5	64	
72	1583967106	2020-03-11 15:51:46-07	jF5A05ZPVToADnEHZVL_1yroP2tuyf-JvIxCmbPyhao	Tq29EBCZnkEVd8fT3npPohbd0qkuPB2aXeqO3NkZMFU	0	71	5	64	
73	1583967111	2020-03-11 15:51:51-07	Tq29EBCZnkEVd8fT3npPohbd0qkuPB2aXeqO3NkZMFU	SIRbzX5ZVzh3RGKyyeoR45vy14hYlKH4_Uqgj1NJ9HA	0	72	5	64	
74	1583967116	2020-03-11 15:51:56-07	SIRbzX5ZVzh3RGKyyeoR45vy14hYlKH4_Uqgj1NJ9HA	fSn6S-WoW_ae2UuHK8ZqQrh0dGW7r0-ujusCKYemdMM	0	73	5	64	
75	1583967121	2020-03-11 15:52:01-07	fSn6S-WoW_ae2UuHK8ZqQrh0dGW7r0-ujusCKYemdMM	PVbJw7CUJWrxI9s3h7IN7a8HZkg8Eygt2YDEBZg1urw	1	74	5	64	
76	1583967126	2020-03-11 15:52:06-07	PVbJw7CUJWrxI9s3h7IN7a8HZkg8Eygt2YDEBZg1urw	jAZXTsJCHFfZ_flsuu9H3PDyOU_NC5mb7mRr9aQU_5A	0	75	5	64	
77	1583967131	2020-03-11 15:52:11-07	jAZXTsJCHFfZ_flsuu9H3PDyOU_NC5mb7mRr9aQU_5A	xnckIjaq3HK_v6CqoVlaPGkxn-Kv85y0VScpZpVa_Iw	0	76	5	64	
78	1583967136	2020-03-11 15:52:16-07	xnckIjaq3HK_v6CqoVlaPGkxn-Kv85y0VScpZpVa_Iw	XP8HwXn4darGxAxfLOKHOF2D-OaLiJE8ssIGs7PXPo8	3	77	5	64	
79	1583967141	2020-03-11 15:52:21-07	XP8HwXn4darGxAxfLOKHOF2D-OaLiJE8ssIGs7PXPo8	ikm5Fxd8Skhog0uruG6xxwHBwon66srq3Vug4ai0ziw	1	78	5	64	
80	1583967146	2020-03-11 15:52:26-07	ikm5Fxd8Skhog0uruG6xxwHBwon66srq3Vug4ai0ziw	kyKlm4yep1VvGapEdm_GsphlhSSgE1GJxtaGMtgjHyM	2	79	6	80	
81	1583967151	2020-03-11 15:52:31-07	kyKlm4yep1VvGapEdm_GsphlhSSgE1GJxtaGMtgjHyM	romZkmN2snEPj3pAcgdFSeEFgeAF5v_scofSrPTXNfQ	0	80	6	80	
82	1583967156	2020-03-11 15:52:36-07	romZkmN2snEPj3pAcgdFSeEFgeAF5v_scofSrPTXNfQ	RqFyMdz995kAbWxsTYCE9orfVcXSmwX51XT6r7aO3CI	0	81	6	80	
83	1583967161	2020-03-11 15:52:41-07	RqFyMdz995kAbWxsTYCE9orfVcXSmwX51XT6r7aO3CI	yCL_ciLntK2_mO0ktdJgvbjbrUJQ4c7f_0XsbbfmFI4	0	82	6	80	
84	1583967166	2020-03-11 15:52:46-07	yCL_ciLntK2_mO0ktdJgvbjbrUJQ4c7f_0XsbbfmFI4	rX62E4UUpVL5--herDdhXZR6bwtyJx-0d0OlSvyE4m4	1	83	6	80	
85	1583967171	2020-03-11 15:52:51-07	rX62E4UUpVL5--herDdhXZR6bwtyJx-0d0OlSvyE4m4	bD0IcIishr0H6nWwbb2tnwSyd7_KScpbZtmm3lxnp94	0	84	6	80	
86	1583967176	2020-03-11 15:52:56-07	bD0IcIishr0H6nWwbb2tnwSyd7_KScpbZtmm3lxnp94	UPwme8sPZaz5FLGB-tohVjJf7cmkCaWtQ7aKC0KH4uM	0	85	6	80	
87	1583967181	2020-03-11 15:53:01-07	UPwme8sPZaz5FLGB-tohVjJf7cmkCaWtQ7aKC0KH4uM	e2jS5kYKjSDu-gYmFoV2rNFGaw-wXUcgFj_h5kCQgU4	1	86	6	80	
88	1583967186	2020-03-11 15:53:06-07	e2jS5kYKjSDu-gYmFoV2rNFGaw-wXUcgFj_h5kCQgU4	keOXjYMF0qLFCiKszvFdijy531SP6YbfJYIohEKbzlE	1	87	6	80	
89	1583967191	2020-03-11 15:53:11-07	keOXjYMF0qLFCiKszvFdijy531SP6YbfJYIohEKbzlE	emdZEmwQPEFwf07qu3VzfSLvVwpVRxJ2wp7SUbMsk3Y	0	88	6	80	
90	1583967196	2020-03-11 15:53:16-07	emdZEmwQPEFwf07qu3VzfSLvVwpVRxJ2wp7SUbMsk3Y	l1LmD4YIAbQCaJRNpMeMjEKI9Qv1uDDA6TSa2OdyYlw	0	89	6	80	
91	1583967201	2020-03-11 15:53:21-07	l1LmD4YIAbQCaJRNpMeMjEKI9Qv1uDDA6TSa2OdyYlw	ODsW3IIwuc_zbtutuvtZxo3bHUTZj_f8u0HiJqqoGrk	0	90	6	80	
92	1583967206	2020-03-11 15:53:26-07	ODsW3IIwuc_zbtutuvtZxo3bHUTZj_f8u0HiJqqoGrk	HdIXcyEvSI_xDPAsPNXxMNLULxIOrjBil7hSXEh9PGs	0	91	6	80	
93	1583967211	2020-03-11 15:53:31-07	HdIXcyEvSI_xDPAsPNXxMNLULxIOrjBil7hSXEh9PGs	vJZqH7RVi0b0ca_d-8Gc9cYoMUtur1ZGfVPuAf36HLE	0	92	6	80	
94	1583967216	2020-03-11 15:53:36-07	vJZqH7RVi0b0ca_d-8Gc9cYoMUtur1ZGfVPuAf36HLE	Ql32ztAq7z-O-61-3ZVbSJj2lsaHB_T4j6cJzUrPDdM	0	93	6	80	
95	1583967221	2020-03-11 15:53:41-07	Ql32ztAq7z-O-61-3ZVbSJj2lsaHB_T4j6cJzUrPDdM	xV8M4ttFrIvY37IUZu62VAZeZqYV3rpBeC3MS9VFNzo	0	94	6	80	
96	1583967226	2020-03-11 15:53:46-07	xV8M4ttFrIvY37IUZu62VAZeZqYV3rpBeC3MS9VFNzo	9niavtgBZbHXKoTy8tViNsWCgeRTQuNtA4JlEYSCPlI	2	95	7	96	
97	1583967231	2020-03-11 15:53:51-07	9niavtgBZbHXKoTy8tViNsWCgeRTQuNtA4JlEYSCPlI	SVHxDawl6kPnxuP0eQLKoegsdJsKJQC-Ipq9Yw7F62E	0	96	7	96	
98	1583967236	2020-03-11 15:53:56-07	SVHxDawl6kPnxuP0eQLKoegsdJsKJQC-Ipq9Yw7F62E	iUStM2qdocckxG4ZdLEpZHoU-NZu7hZ-QQ5sN301aD8	0	97	7	96	
99	1583967241	2020-03-11 15:54:01-07	iUStM2qdocckxG4ZdLEpZHoU-NZu7hZ-QQ5sN301aD8	nsfUdJ_OfSmUZ5oNa73S7wzsweJCCEpFVFQ20IBNsvU	0	98	7	96	
100	1583967246	2020-03-11 15:54:06-07	nsfUdJ_OfSmUZ5oNa73S7wzsweJCCEpFVFQ20IBNsvU	c_LwZqxhG_WQ8wSEmhHcxDg-68ko9L2lrgQpV70bK7I	1	99	7	96	
101	1583967251	2020-03-11 15:54:11-07	c_LwZqxhG_WQ8wSEmhHcxDg-68ko9L2lrgQpV70bK7I	UTJDvZcaxAtgyr5JUI2TB1sMigerTJERgFSB-pRzFsg	0	100	7	96	
102	1583967256	2020-03-11 15:54:16-07	UTJDvZcaxAtgyr5JUI2TB1sMigerTJERgFSB-pRzFsg	7-7bSdF9Kug8x5LOxisQQv6ZOTst9kaRI9_d3CmtUjU	0	101	7	96	
103	1583967261	2020-03-11 15:54:21-07	7-7bSdF9Kug8x5LOxisQQv6ZOTst9kaRI9_d3CmtUjU	SBAoIT3bF7mNAPTahRMIF1E9By9sbPSN3HnPLTXLwco	2	102	7	96	
104	1583967266	2020-03-11 15:54:26-07	SBAoIT3bF7mNAPTahRMIF1E9By9sbPSN3HnPLTXLwco	Zq3r_4p3CsOMqnRowxZvz3v8wqYq253-DHF-xw2MqKA	1	103	7	96	
105	1583967271	2020-03-11 15:54:31-07	Zq3r_4p3CsOMqnRowxZvz3v8wqYq253-DHF-xw2MqKA	hiAifGOw9qBGfwcIseI9olMNAtUXXwi8SkMECv9_Nso	0	104	7	96	
106	1583967276	2020-03-11 15:54:36-07	hiAifGOw9qBGfwcIseI9olMNAtUXXwi8SkMECv9_Nso	hRipx4J-rBTlluv337C7y3W82cEcY025P0gop6Y0RiA	1	105	7	96	
107	1583967281	2020-03-11 15:54:41-07	hRipx4J-rBTlluv337C7y3W82cEcY025P0gop6Y0RiA	lelnxtDPhrnjSq8olvwSYzZdq6PGX92ZYRHrHsR73N8	0	106	7	96	
108	1583967286	2020-03-11 15:54:46-07	lelnxtDPhrnjSq8olvwSYzZdq6PGX92ZYRHrHsR73N8	FFDojLBmhHpzXWsnipqmblGB-rMv9ru3PoJgfcl8LMg	0	107	7	96	
109	1583967291	2020-03-11 15:54:51-07	FFDojLBmhHpzXWsnipqmblGB-rMv9ru3PoJgfcl8LMg	YxhuPFCbTQ8-utBrBGLaBTbJl45ij0pEGQL0JqEpoZM	0	108	7	96	
110	1583967296	2020-03-11 15:54:56-07	YxhuPFCbTQ8-utBrBGLaBTbJl45ij0pEGQL0JqEpoZM	x_mhals1TQsHPtU0fa-nnDFq8icfF28md802OEZPMCE	0	109	7	96	
111	1583967301	2020-03-11 15:55:01-07	x_mhals1TQsHPtU0fa-nnDFq8icfF28md802OEZPMCE	dmrpdW5WmUpBMwusPLyVhMdWcheQ_HYLtcXi0Ij_t-o	1	110	7	96	
112	1583967306	2020-03-11 15:55:06-07	dmrpdW5WmUpBMwusPLyVhMdWcheQ_HYLtcXi0Ij_t-o	0g-xSOudYFaEk6mLTsiR9-XNWlsYudXNCKrACAv3KDM	2	111	8	112	
113	1583967311	2020-03-11 15:55:11-07	0g-xSOudYFaEk6mLTsiR9-XNWlsYudXNCKrACAv3KDM	L80bKldXvTHFSD_JluK2DpHaEQjgy0lg8P2xoZgUSrE	2	112	8	112	
114	1583967316	2020-03-11 15:55:16-07	L80bKldXvTHFSD_JluK2DpHaEQjgy0lg8P2xoZgUSrE	hMDwE6X5rhEQoRbNVdw9YqebV8miY4pLk9kiA8Jdz6M	0	113	8	112	
115	1583967321	2020-03-11 15:55:21-07	hMDwE6X5rhEQoRbNVdw9YqebV8miY4pLk9kiA8Jdz6M	2tTn0QFafoA8ZSr3MVS4n-ozx8hVLeZ2Buuie-0W2ZU	0	114	8	112	
116	1583967326	2020-03-11 15:55:26-07	2tTn0QFafoA8ZSr3MVS4n-ozx8hVLeZ2Buuie-0W2ZU	fW-hgcnbRj6bCTqoNUQQW0srakxll-cRkixYV76zs_0	0	115	8	112	
117	1583967331	2020-03-11 15:55:31-07	fW-hgcnbRj6bCTqoNUQQW0srakxll-cRkixYV76zs_0	j4faxmGk9mcEkGlTHdf3OJSWW3JZRTU359Y0ni_RSbg	0	116	8	112	
118	1583967336	2020-03-11 15:55:36-07	j4faxmGk9mcEkGlTHdf3OJSWW3JZRTU359Y0ni_RSbg	x8RpDVdz8GjVFpgXKvtL1mUB9UZiOqRH58MykNU1D0Y	0	117	8	112	
119	1583967341	2020-03-11 15:55:41-07	x8RpDVdz8GjVFpgXKvtL1mUB9UZiOqRH58MykNU1D0Y	5mgMSVaqlb7bQ1MTe-MCjgx1enIUSnClLZMsAIMCUro	0	118	8	112	
120	1583967346	2020-03-11 15:55:46-07	5mgMSVaqlb7bQ1MTe-MCjgx1enIUSnClLZMsAIMCUro	a9Us6PtP0dGtxdFlpi6V_iNcCS7KZYUVgAooQtxauVQ	0	119	8	112	
121	1583967351	2020-03-11 15:55:51-07	a9Us6PtP0dGtxdFlpi6V_iNcCS7KZYUVgAooQtxauVQ	XebxHIlk0FyfV9jwouekC9-e-AfxbHX7xvECwRavuLU	0	120	8	112	
122	1583967356	2020-03-11 15:55:56-07	XebxHIlk0FyfV9jwouekC9-e-AfxbHX7xvECwRavuLU	Z1lvt6WSPW7ZALuutKMtZgk_EdSnGlmn0MEpdbPn72E	0	121	8	112	
123	1583967361	2020-03-11 15:56:01-07	Z1lvt6WSPW7ZALuutKMtZgk_EdSnGlmn0MEpdbPn72E	yFG6OX159hdvGWjSIpexmm3HyC-3gou7JHEmHMRYHWA	0	122	8	112	
124	1583967366	2020-03-11 15:56:06-07	yFG6OX159hdvGWjSIpexmm3HyC-3gou7JHEmHMRYHWA	7akuFOkhAtr2l_Yc3oQjgH_SpvmejEZApRV-D6M68Ds	0	123	8	112	
125	1583967371	2020-03-11 15:56:11-07	7akuFOkhAtr2l_Yc3oQjgH_SpvmejEZApRV-D6M68Ds	PR6RQpnmpXXmOe-ImFYLu9o-iUO4DyggWCskyewZ5rM	1	124	8	112	
126	1583967376	2020-03-11 15:56:16-07	PR6RQpnmpXXmOe-ImFYLu9o-iUO4DyggWCskyewZ5rM	ubtpW_zRXeipMBcXsufo4DR0bJJGD6gVYB3qUjUjcoo	0	125	8	112	
127	1583967381	2020-03-11 15:56:21-07	ubtpW_zRXeipMBcXsufo4DR0bJJGD6gVYB3qUjUjcoo	MFXtQt2h08WUd0TfmDJm4oXzd8IzGymSt2KksHF17yw	0	126	8	112	
128	1583967386	2020-03-11 15:56:26-07	MFXtQt2h08WUd0TfmDJm4oXzd8IzGymSt2KksHF17yw	57U1jKZJqGVK9vyOk0dGYZm21qYSFl97s39Ixsh0Q24	2	127	9	128	
129	1583967391	2020-03-11 15:56:31-07	57U1jKZJqGVK9vyOk0dGYZm21qYSFl97s39Ixsh0Q24	z09JUT1zmU5MNsId0i82XUeIXReobys5WtNATkBBlDU	2	128	9	128	
130	1583967396	2020-03-11 15:56:36-07	z09JUT1zmU5MNsId0i82XUeIXReobys5WtNATkBBlDU	iDPo1SMMs0cK96oTRs0mHvTNjCGpUxQ8INuk8uUenfw	1	129	9	128	
131	1583967401	2020-03-11 15:56:41-07	iDPo1SMMs0cK96oTRs0mHvTNjCGpUxQ8INuk8uUenfw	3NhKCg1wDM1MttlfvY5OPnpfHLVTk8uNCUSXhPbde7I	0	130	9	128	
132	1583967406	2020-03-11 15:56:46-07	3NhKCg1wDM1MttlfvY5OPnpfHLVTk8uNCUSXhPbde7I	ctBa47sjuVYvbcpvbun3JfqWdk7d6k4X7__cPeppwk0	0	131	9	128	
133	1583967411	2020-03-11 15:56:51-07	ctBa47sjuVYvbcpvbun3JfqWdk7d6k4X7__cPeppwk0	mCbIuU7GwmLAJ5Eple1Sl0Ku8j6LVvspsSVwFVdf9HU	0	132	9	128	
134	1583967416	2020-03-11 15:56:56-07	mCbIuU7GwmLAJ5Eple1Sl0Ku8j6LVvspsSVwFVdf9HU	6OO-aLdBoEl1PUdTDR6eD18xGDOBsrZqpD9YrFBVrjk	0	133	9	128	
135	1583967421	2020-03-11 15:57:01-07	6OO-aLdBoEl1PUdTDR6eD18xGDOBsrZqpD9YrFBVrjk	XZsVkPmLZpvKhnPjsULgxGvDZ5p1_nVmmW0T6UwTVhg	0	134	9	128	
136	1583967426	2020-03-11 15:57:06-07	XZsVkPmLZpvKhnPjsULgxGvDZ5p1_nVmmW0T6UwTVhg	S4OZFsjjVDSOHQUCbvR_HnbViL_Km2GFI2lLb2SWEGE	1	135	9	128	
137	1583967431	2020-03-11 15:57:11-07	S4OZFsjjVDSOHQUCbvR_HnbViL_Km2GFI2lLb2SWEGE	a--_42bnxR_PI8AgR3g3uh7EzGUjDY8VsLyfek0W5mA	1	136	9	128	
138	1583967436	2020-03-11 15:57:16-07	a--_42bnxR_PI8AgR3g3uh7EzGUjDY8VsLyfek0W5mA	fTZs2PvYbYsKeG3D1OdrKiz2m-IXQX44_cCdhmlBOe4	1	137	9	128	
139	1583967441	2020-03-11 15:57:21-07	fTZs2PvYbYsKeG3D1OdrKiz2m-IXQX44_cCdhmlBOe4	H6eA3l7eMzc3R_4e82qzM3KY0QiUKtcybNHimeXA46Y	1	138	9	128	
140	1583967446	2020-03-11 15:57:26-07	H6eA3l7eMzc3R_4e82qzM3KY0QiUKtcybNHimeXA46Y	TM1yfrkRcc3H4aESOwWFJ5OWwq3eGCWp2rfx1ta18U8	0	139	9	128	
141	1583967451	2020-03-11 15:57:31-07	TM1yfrkRcc3H4aESOwWFJ5OWwq3eGCWp2rfx1ta18U8	laNh-9IPrfPRA46WTYc_XPLIex8NHzq9V5jIeiw2kqI	0	140	9	128	
142	1583967456	2020-03-11 15:57:36-07	laNh-9IPrfPRA46WTYc_XPLIex8NHzq9V5jIeiw2kqI	KQobmljrPyw7atdaKGe4NA-1rAxiHARxEGcAu_HbHio	0	141	9	128	
143	1583967461	2020-03-11 15:57:41-07	KQobmljrPyw7atdaKGe4NA-1rAxiHARxEGcAu_HbHio	mp_GfpHSolITuI6g3ltCiRvFIZpN-jicfiTcU3_Qm2Y	0	142	9	128	
144	1583967466	2020-03-11 15:57:46-07	mp_GfpHSolITuI6g3ltCiRvFIZpN-jicfiTcU3_Qm2Y	4vODzC5S7PNNpeQYekdMNv-lO_wtF7yzubdP1eXF-kA	2	143	10	144	
145	1583967471	2020-03-11 15:57:51-07	4vODzC5S7PNNpeQYekdMNv-lO_wtF7yzubdP1eXF-kA	i-5eJBFA7bEJJtVeLeL0qPysmOnrF9kuJ3vR6C01T2U	0	144	10	144	
146	1583967476	2020-03-11 15:57:56-07	i-5eJBFA7bEJJtVeLeL0qPysmOnrF9kuJ3vR6C01T2U	Ni0A0Rz8GKFLll7bBPj2q2_Xf2VQcoOe_sTuSaOOlQg	0	145	10	144	
147	1583967481	2020-03-11 15:58:01-07	Ni0A0Rz8GKFLll7bBPj2q2_Xf2VQcoOe_sTuSaOOlQg	bcxQkBcKlL_H3pOnDQc5Y3xHzeOqTXN4e--3QTyH7U4	0	146	10	144	
148	1583967486	2020-03-11 15:58:06-07	bcxQkBcKlL_H3pOnDQc5Y3xHzeOqTXN4e--3QTyH7U4	1tYQntbq3BBC2OtnLH3Rqd_KBPpTVfeOjHof35pwAGY	0	147	10	144	
149	1583967491	2020-03-11 15:58:11-07	1tYQntbq3BBC2OtnLH3Rqd_KBPpTVfeOjHof35pwAGY	BcVA_yTG1ws5Vrp2fbM_-hqxIqm5XQRDFKB87r6z-tM	0	148	10	144	
150	1583967496	2020-03-11 15:58:16-07	BcVA_yTG1ws5Vrp2fbM_-hqxIqm5XQRDFKB87r6z-tM	1qag09TSg9S-5I5bNjEKZtCpgLFhSSRpYSzYlNUJ6Vg	1	149	10	144	
151	1583967501	2020-03-11 15:58:21-07	1qag09TSg9S-5I5bNjEKZtCpgLFhSSRpYSzYlNUJ6Vg	67Cudp101glk3BXs24ehKS0j7QivrDAOqCHMN4_fX7I	0	150	10	144	
152	1583967506	2020-03-11 15:58:26-07	67Cudp101glk3BXs24ehKS0j7QivrDAOqCHMN4_fX7I	Ve2L-lKfLVubSfjh3MnEhy9A2KBhR4MGUdj0xkU9HvA	0	151	10	144	
153	1583967511	2020-03-11 15:58:31-07	Ve2L-lKfLVubSfjh3MnEhy9A2KBhR4MGUdj0xkU9HvA	DBQXX7_4HhwU-hTCk_yMxRh_U7gXmPtWFXxtEqpd01I	0	152	10	144	
154	1583967516	2020-03-11 15:58:36-07	DBQXX7_4HhwU-hTCk_yMxRh_U7gXmPtWFXxtEqpd01I	7o_EUJUchc3ndtUA-1WHMi12pnip0WCwy6kqSz5ah2E	2	153	10	144	
155	1583967521	2020-03-11 15:58:41-07	7o_EUJUchc3ndtUA-1WHMi12pnip0WCwy6kqSz5ah2E	t3_S4AKt8EK6Ua7JXxXsCBpcyTYa9dl1w6l_aH1eRRY	0	154	10	144	
156	1583967526	2020-03-11 15:58:46-07	t3_S4AKt8EK6Ua7JXxXsCBpcyTYa9dl1w6l_aH1eRRY	zwk5i3OIFxY-n-rM-A6cpba957KaEPMje38-wXpobow	0	155	10	144	
157	1583967531	2020-03-11 15:58:51-07	zwk5i3OIFxY-n-rM-A6cpba957KaEPMje38-wXpobow	hqhBkF9AL0NQVMbBaWuVmn5Otv5aHVi6we8xAD40Xbg	0	156	10	144	
158	1583967536	2020-03-11 15:58:56-07	hqhBkF9AL0NQVMbBaWuVmn5Otv5aHVi6we8xAD40Xbg	ME6t-C_gs70RvzpecZ5W1PvJY90BcUpUMyU_irS7lRA	1	157	10	144	
159	1583967541	2020-03-11 15:59:01-07	ME6t-C_gs70RvzpecZ5W1PvJY90BcUpUMyU_irS7lRA	FO6u-jcy4Iqmatgu17maHsced4MYSCLFRzJktt9dNz4	0	158	10	144	
160	1583967546	2020-03-11 15:59:06-07	FO6u-jcy4Iqmatgu17maHsced4MYSCLFRzJktt9dNz4	j-ziRREfxmT3RDRHGIh_6SCASOhfegCUIpYuE0qAzrQ	2	159	11	160	
161	1583967551	2020-03-11 15:59:11-07	j-ziRREfxmT3RDRHGIh_6SCASOhfegCUIpYuE0qAzrQ	5fTfAP4FxiAOu8C6xgZ8cjZ0bK0P81959EanT0oQyh4	0	160	11	160	
162	1583967556	2020-03-11 15:59:16-07	5fTfAP4FxiAOu8C6xgZ8cjZ0bK0P81959EanT0oQyh4	rJhao7eumbzVbmah1wY6_EQokC7U0mS6Mah1z9Aef1Q	2	161	11	160	
163	1583967561	2020-03-11 15:59:21-07	rJhao7eumbzVbmah1wY6_EQokC7U0mS6Mah1z9Aef1Q	_w6uPEdVk5Izhvilq1CGBHp0YIM2F0Sjbs7KBG6VjyU	0	162	11	160	
164	1583967566	2020-03-11 15:59:26-07	_w6uPEdVk5Izhvilq1CGBHp0YIM2F0Sjbs7KBG6VjyU	Njp9GBOHP3A2wicZWjEVleHJxPQm8PD0TVuLam4_YHA	0	163	11	160	
165	1583967571	2020-03-11 15:59:31-07	Njp9GBOHP3A2wicZWjEVleHJxPQm8PD0TVuLam4_YHA	fSFPzcW_jHXzKa9F-zOmp6aWRKVFyokgV-ck_qyTV1g	2	164	11	160	
166	1583967576	2020-03-11 15:59:36-07	fSFPzcW_jHXzKa9F-zOmp6aWRKVFyokgV-ck_qyTV1g	Hx2e87ruZkoq_vxofwvNa9WBjs8b3tRkW6fhphu0VW8	0	165	11	160	
167	1583967581	2020-03-11 15:59:41-07	Hx2e87ruZkoq_vxofwvNa9WBjs8b3tRkW6fhphu0VW8	EdMmVicMKH5plEAbliwJeLG-WcIOX8v9HYeps4QZf4I	0	166	11	160	
168	1583967586	2020-03-11 15:59:46-07	EdMmVicMKH5plEAbliwJeLG-WcIOX8v9HYeps4QZf4I	nYB0Y96fDDFwbQnzFfCn8xIpnwczQ9BZnbtJJNVDWck	0	167	11	160	
169	1583967591	2020-03-11 15:59:51-07	nYB0Y96fDDFwbQnzFfCn8xIpnwczQ9BZnbtJJNVDWck	FHyBz3SDBCLnGHok_kblclzU9SqlPpSPhiyFWfQK3r8	0	168	11	160	
170	1583967596	2020-03-11 15:59:56-07	FHyBz3SDBCLnGHok_kblclzU9SqlPpSPhiyFWfQK3r8	OXE5ifVeizWnofZ_ZJEeb-ssYZ7iIeMmiB94-OcAfzg	0	169	11	160	
171	1583967601	2020-03-11 16:00:01-07	OXE5ifVeizWnofZ_ZJEeb-ssYZ7iIeMmiB94-OcAfzg	3ccc6s78aBqZGAAAvKDbP9Lzy_7vumFilNnI8exGPMg	0	170	11	160	
172	1583967606	2020-03-11 16:00:06-07	3ccc6s78aBqZGAAAvKDbP9Lzy_7vumFilNnI8exGPMg	qIhX8zfdfFyedYwEE0B-cTX8AlYbqvN_qCzAy6aeqg0	0	171	11	160	
173	1583967611	2020-03-11 16:00:11-07	qIhX8zfdfFyedYwEE0B-cTX8AlYbqvN_qCzAy6aeqg0	BS_V24X2jk0ibhmp39oY6U3ADu6tvcreN6mCI0GDLKQ	0	172	11	160	
174	1583967616	2020-03-11 16:00:16-07	BS_V24X2jk0ibhmp39oY6U3ADu6tvcreN6mCI0GDLKQ	jesv01eTDYxAxLGHpfObJGvw2yBZ_ljCc0Ce0zscNbk	0	173	11	160	
175	1583967621	2020-03-11 16:00:21-07	jesv01eTDYxAxLGHpfObJGvw2yBZ_ljCc0Ce0zscNbk	kLm9HTN-vzro7y2Tl0R9ecg9YStXA6u0yNhEzR3fJdg	1	174	11	160	
176	1583967626	2020-03-11 16:00:26-07	kLm9HTN-vzro7y2Tl0R9ecg9YStXA6u0yNhEzR3fJdg	1uJ_1TrFoZGnRNux2Ukw95R6jEONdyMrFX9szVNazyQ	2	175	12	176	
177	1583967631	2020-03-11 16:00:31-07	1uJ_1TrFoZGnRNux2Ukw95R6jEONdyMrFX9szVNazyQ	U-PMyWNRgKwWpNNZKXyXV7JxeNvNnQzPGY-zS5czy5E	0	176	12	176	
178	1583967636	2020-03-11 16:00:36-07	U-PMyWNRgKwWpNNZKXyXV7JxeNvNnQzPGY-zS5czy5E	vsSozwOcQND83EpxFlcTpaM6_qEuKIWsBm2nnp33D_I	0	177	12	176	
179	1583967641	2020-03-11 16:00:41-07	vsSozwOcQND83EpxFlcTpaM6_qEuKIWsBm2nnp33D_I	IQCkgRsQBiPi5BylCfYWqidzLl7JNvoV9zp_imkbVEg	2	178	12	176	
180	1583967646	2020-03-11 16:00:46-07	IQCkgRsQBiPi5BylCfYWqidzLl7JNvoV9zp_imkbVEg	NYF_xeQWDWWCEe-6FIkkhWj9vxfr036IBdfCEvclOPM	0	179	12	176	
181	1583967651	2020-03-11 16:00:51-07	NYF_xeQWDWWCEe-6FIkkhWj9vxfr036IBdfCEvclOPM	bQotLxJXhgi_n8JzCnFKki6A5qgm3oQzEjPxp2WlA30	0	180	12	176	
182	1583967656	2020-03-11 16:00:56-07	bQotLxJXhgi_n8JzCnFKki6A5qgm3oQzEjPxp2WlA30	RMB7pqa6mBTP0U07r-k_PCZ4rdjinH_57SYur5evk6Y	0	181	12	176	
183	1583967661	2020-03-11 16:01:01-07	RMB7pqa6mBTP0U07r-k_PCZ4rdjinH_57SYur5evk6Y	wrchs1xAdTzzBPgezJTAtseWp3IL4nL3cYC8hqQ46gI	1	182	12	176	
184	1583967666	2020-03-11 16:01:06-07	wrchs1xAdTzzBPgezJTAtseWp3IL4nL3cYC8hqQ46gI	vgL7YXIZja4W50VrehSWQW6YnQ64mVpP9xrr2rJgYps	0	183	12	176	
185	1583967671	2020-03-11 16:01:11-07	vgL7YXIZja4W50VrehSWQW6YnQ64mVpP9xrr2rJgYps	CqtTWadsp9_LKVuDXzKW6nY8dHXNI6jo5nqEbAwuM2k	0	184	12	176	
186	1583967676	2020-03-11 16:01:16-07	CqtTWadsp9_LKVuDXzKW6nY8dHXNI6jo5nqEbAwuM2k	sgn34YUaaehB_p4s9CIXoGklGYAy-Y_tJe_5U30FC8Y	0	185	12	176	
187	1583967681	2020-03-11 16:01:21-07	sgn34YUaaehB_p4s9CIXoGklGYAy-Y_tJe_5U30FC8Y	vMFa1MaSDj7yu6_Ov4uUEls3jTx2E61FGNK5f1lsns0	1	186	12	176	
188	1583967686	2020-03-11 16:01:26-07	vMFa1MaSDj7yu6_Ov4uUEls3jTx2E61FGNK5f1lsns0	vUMePOth9kDyxDv4Mp0LzSh44kDkfGGNS4JVZHXWa4k	1	187	12	176	
189	1583967691	2020-03-11 16:01:31-07	vUMePOth9kDyxDv4Mp0LzSh44kDkfGGNS4JVZHXWa4k	d8yFL3gESMVNHyW3GoL1m0Q4Ye5v8yl2zeE30OQfOm0	0	188	12	176	
190	1583967696	2020-03-11 16:01:36-07	d8yFL3gESMVNHyW3GoL1m0Q4Ye5v8yl2zeE30OQfOm0	WPy3hLDd_KP7TNV8HkDA_kK-mUPCKRMnRV2CSO-lBXY	0	189	12	176	
191	1583967701	2020-03-11 16:01:41-07	WPy3hLDd_KP7TNV8HkDA_kK-mUPCKRMnRV2CSO-lBXY	fL-2syd7oZFWxVyFNLe4JMSdq2bG_xY4nsqCNjw-_WY	0	190	12	176	
192	1583967706	2020-03-11 16:01:46-07	fL-2syd7oZFWxVyFNLe4JMSdq2bG_xY4nsqCNjw-_WY	mSXHRhBzTNqiSgsbFH1czJRn2bguQCPwlsJa8YyFWlk	2	191	13	192	
193	1583967711	2020-03-11 16:01:51-07	mSXHRhBzTNqiSgsbFH1czJRn2bguQCPwlsJa8YyFWlk	WEKkFoYOx-rNFII9LxRdcswju0-fpe7UPwLszYljlXI	0	192	13	192	
194	1583967716	2020-03-11 16:01:56-07	WEKkFoYOx-rNFII9LxRdcswju0-fpe7UPwLszYljlXI	wnVJmkhY6F-JA0VKD89hCI2g7i3gzcZ9KwzTunatd7s	2	193	13	192	
195	1583967721	2020-03-11 16:02:01-07	wnVJmkhY6F-JA0VKD89hCI2g7i3gzcZ9KwzTunatd7s	r-J9OS4AiUaViustOmhwEA8CqOJe64ksb--zD6Pa6yE	0	194	13	192	
196	1583967726	2020-03-11 16:02:06-07	r-J9OS4AiUaViustOmhwEA8CqOJe64ksb--zD6Pa6yE	BKBkNa07Zfl7huGmC-C6Kakef-I5Ey5ZsNb1fwD3VVI	0	195	13	192	
197	1583967731	2020-03-11 16:02:11-07	BKBkNa07Zfl7huGmC-C6Kakef-I5Ey5ZsNb1fwD3VVI	WisddFHnnbUNvyXXOMQaZ2GqTw_F0gEdz5Jrwz7Ntw8	0	196	13	192	
198	1583967736	2020-03-11 16:02:16-07	WisddFHnnbUNvyXXOMQaZ2GqTw_F0gEdz5Jrwz7Ntw8	9dQtRl6Bqy0RjtTqZD3sirJOMIR2v6eYBvhe_DP0ZxE	0	197	13	192	
199	1583967741	2020-03-11 16:02:21-07	9dQtRl6Bqy0RjtTqZD3sirJOMIR2v6eYBvhe_DP0ZxE	lhAOelqdtC7ggKNFy675cK3yXVGK7ulF8LZ36srjXuI	0	198	13	192	
200	1583967746	2020-03-11 16:02:26-07	lhAOelqdtC7ggKNFy675cK3yXVGK7ulF8LZ36srjXuI	9eXcipPtD5yHMnkii4RB8mWBK5PCXcKqDR7Rs80TSXc	1	199	13	192	
201	1583967751	2020-03-11 16:02:31-07	9eXcipPtD5yHMnkii4RB8mWBK5PCXcKqDR7Rs80TSXc	X3J7CocfQRg3Fa1Jn_dpsPlafshZhFf9y1i4H5518V4	0	200	13	192	
202	1583967756	2020-03-11 16:02:36-07	X3J7CocfQRg3Fa1Jn_dpsPlafshZhFf9y1i4H5518V4	GmNtaMFltTwzPGNM-snejaUZhYaSbr3QyUDoGn-P9vw	0	201	13	192	
203	1583967761	2020-03-11 16:02:41-07	GmNtaMFltTwzPGNM-snejaUZhYaSbr3QyUDoGn-P9vw	e19twopdwqpXRaUr_QCG208GfW_9hRNL4tbdiPAbgLY	0	202	13	192	
204	1583967766	2020-03-11 16:02:46-07	e19twopdwqpXRaUr_QCG208GfW_9hRNL4tbdiPAbgLY	_DvvFdHPrEwpfKnoNnz1NghYXEosF347aMzSpXoc-So	1	203	13	192	
205	1583967771	2020-03-11 16:02:51-07	_DvvFdHPrEwpfKnoNnz1NghYXEosF347aMzSpXoc-So	BuP37kWTg9yjXveCA9M93dh0_Hx2ZePK7VkyBS0VGps	1	204	13	192	
206	1583967776	2020-03-11 16:02:56-07	BuP37kWTg9yjXveCA9M93dh0_Hx2ZePK7VkyBS0VGps	BQD1T4kvuaTFU6xSaq37633krHdKsNnvd0N0rXIQGJw	0	205	13	192	
207	1583967781	2020-03-11 16:03:01-07	BQD1T4kvuaTFU6xSaq37633krHdKsNnvd0N0rXIQGJw	7p_h6rDF5ZkMYeh6r26jFMssQdKEWcr4uEnXzwPVe_8	0	206	13	192	
208	1583967786	2020-03-11 16:03:06-07	7p_h6rDF5ZkMYeh6r26jFMssQdKEWcr4uEnXzwPVe_8	8vVlV0CH3XZuP909Pwm7mlVt4tX-YbipyLEDHsmnZsY	2	207	14	208	
209	1583967791	2020-03-11 16:03:11-07	8vVlV0CH3XZuP909Pwm7mlVt4tX-YbipyLEDHsmnZsY	W45vPDNbVnKrzo3q2E5J4c1c52a5bToPQYOQt2o7qsc	0	208	14	208	
210	1583967796	2020-03-11 16:03:16-07	W45vPDNbVnKrzo3q2E5J4c1c52a5bToPQYOQt2o7qsc	sxHY6v8RIKXgsH4eUBNvu_PSQ0jtsH7Ozs7DM9_w7Dc	1	209	14	208	
211	1583967801	2020-03-11 16:03:21-07	sxHY6v8RIKXgsH4eUBNvu_PSQ0jtsH7Ozs7DM9_w7Dc	LpO02L9AhrwKTlOwB3qXN44Seb7nFSstRAfjAb_4tz4	0	210	14	208	
212	1583967806	2020-03-11 16:03:26-07	LpO02L9AhrwKTlOwB3qXN44Seb7nFSstRAfjAb_4tz4	QFuSm_ctvNedsFLJijE1XYVsjV0-Rx5G82xnUIysll8	1	211	14	208	
213	1583967811	2020-03-11 16:03:31-07	QFuSm_ctvNedsFLJijE1XYVsjV0-Rx5G82xnUIysll8	isDNIMRsZQ9qBHotIh-RO1sPdetxPpm40irfNBV4dUQ	1	212	14	208	
214	1583967816	2020-03-11 16:03:36-07	isDNIMRsZQ9qBHotIh-RO1sPdetxPpm40irfNBV4dUQ	_L0x0AN3oa3eY0u2eK3HMGe13iMCm4TETENFdtAqOtw	0	213	14	208	
215	1583967821	2020-03-11 16:03:41-07	_L0x0AN3oa3eY0u2eK3HMGe13iMCm4TETENFdtAqOtw	miKUI8Azfd3fj-uCV1qVuluzgpYxSDO0q6HXw9xclgw	0	214	14	208	
216	1583967826	2020-03-11 16:03:46-07	miKUI8Azfd3fj-uCV1qVuluzgpYxSDO0q6HXw9xclgw	S7Kj84x5X_nZUZnDtAWnf3801ttCMy7UuGuFLJYe7bk	0	215	14	208	
217	1583967831	2020-03-11 16:03:51-07	S7Kj84x5X_nZUZnDtAWnf3801ttCMy7UuGuFLJYe7bk	w2WpUv9Q2xXYnZ0a_-J8xF9R68RvlFlT7q1MSdN3NkQ	0	216	14	208	
218	1583967836	2020-03-11 16:03:56-07	w2WpUv9Q2xXYnZ0a_-J8xF9R68RvlFlT7q1MSdN3NkQ	NI3ij63pSzxfjw4ACNAmyGCVtSxEsycbMl4pd58gbPU	0	217	14	208	
219	1583967841	2020-03-11 16:04:01-07	NI3ij63pSzxfjw4ACNAmyGCVtSxEsycbMl4pd58gbPU	6kpbibwjhzoLGOYhBL3ESotoGZecoZde4HEEqgfUyyU	1	218	14	208	
220	1583967846	2020-03-11 16:04:06-07	6kpbibwjhzoLGOYhBL3ESotoGZecoZde4HEEqgfUyyU	d-c7sSaozpPwRK1IpwSNn5LqIAjvycBl3bUvM2PUOs8	0	219	14	208	
221	1583967851	2020-03-11 16:04:11-07	d-c7sSaozpPwRK1IpwSNn5LqIAjvycBl3bUvM2PUOs8	fTlQLUN27IEPS-XpHSCra_mS61FVXjjyOtxxYF4DJrg	0	220	14	208	
222	1583967856	2020-03-11 16:04:16-07	fTlQLUN27IEPS-XpHSCra_mS61FVXjjyOtxxYF4DJrg	7opmlRDnYzzjK9zIjpJQ_454ds3vQI9rj6P0Vzio8q0	0	221	14	208	
223	1583967861	2020-03-11 16:04:21-07	7opmlRDnYzzjK9zIjpJQ_454ds3vQI9rj6P0Vzio8q0	kmrL9pEFm78nQ5yfOD_LWWboxe3vS329UO3Hu2wYGXo	0	222	14	208	
224	1583967866	2020-03-11 16:04:26-07	kmrL9pEFm78nQ5yfOD_LWWboxe3vS329UO3Hu2wYGXo	pRLrNtW-G1GozzMT4YoK1f1mK6pUhUOx28ca-TVTOmo	2	223	15	224	
225	1583967871	2020-03-11 16:04:31-07	pRLrNtW-G1GozzMT4YoK1f1mK6pUhUOx28ca-TVTOmo	5qzhPeLEZQkR-SUA_yoD1e9HaCwKIKXeC3j8iDWtLrU	2	224	15	224	
226	1583967876	2020-03-11 16:04:36-07	5qzhPeLEZQkR-SUA_yoD1e9HaCwKIKXeC3j8iDWtLrU	Y2uznglFoxKSFxajgrcbZ01u3MULKi350See80T3UjM	0	225	15	224	
227	1583967881	2020-03-11 16:04:41-07	Y2uznglFoxKSFxajgrcbZ01u3MULKi350See80T3UjM	pAo9CVrjtU_vpru5hg6fm5UKRazjT6UhQeN7qlP4CAU	0	226	15	224	
228	1583967886	2020-03-11 16:04:46-07	pAo9CVrjtU_vpru5hg6fm5UKRazjT6UhQeN7qlP4CAU	-RGno9PMcAo4BcYqYJ3ZqcclooTorWnVf7zrKBVV3Cg	0	227	15	224	
229	1583967891	2020-03-11 16:04:51-07	-RGno9PMcAo4BcYqYJ3ZqcclooTorWnVf7zrKBVV3Cg	LJxk3GvNjOjBRjd4ZcQp9o_CyTWy-c6QOIhmUbN2RHA	0	228	15	224	
230	1583967896	2020-03-11 16:04:56-07	LJxk3GvNjOjBRjd4ZcQp9o_CyTWy-c6QOIhmUbN2RHA	5oHGKA8JQ_3XZ_XRiLNoLp4e_vyLy6ykLz3-nLMokoY	1	229	15	224	
231	1583967901	2020-03-11 16:05:01-07	5oHGKA8JQ_3XZ_XRiLNoLp4e_vyLy6ykLz3-nLMokoY	IMJgmasJOA56IQC7-ITU6kqpO0rvVAxwJuoZ59hvGPs	0	230	15	224	
232	1583967906	2020-03-11 16:05:06-07	IMJgmasJOA56IQC7-ITU6kqpO0rvVAxwJuoZ59hvGPs	-vTDayHkt81Okpyqhikb2_ZN53DBTzXFqs4gTQEOvY4	0	231	15	224	
233	1583967911	2020-03-11 16:05:11-07	-vTDayHkt81Okpyqhikb2_ZN53DBTzXFqs4gTQEOvY4	AFIWKQeAaSn5T_AJ18iwF8SeM5ymIu5TyI9R13lWcdU	0	232	15	224	
234	1583967916	2020-03-11 16:05:16-07	AFIWKQeAaSn5T_AJ18iwF8SeM5ymIu5TyI9R13lWcdU	NGV_X7jzjZa-pHtATkuScGlQGb58TM7e8R16ZeEhQ64	1	233	15	224	
235	1583967921	2020-03-11 16:05:21-07	NGV_X7jzjZa-pHtATkuScGlQGb58TM7e8R16ZeEhQ64	XQs2OAb22nKUkRGMO0VFkzu-_CcEAATEO-AhxC0OWnE	1	234	15	224	
236	1583967926	2020-03-11 16:05:26-07	XQs2OAb22nKUkRGMO0VFkzu-_CcEAATEO-AhxC0OWnE	dRX73Fg8P8HztUyE4cnxJ2GHlNg_Mj3z6eCZlN_QaH4	0	235	15	224	
237	1583967931	2020-03-11 16:05:31-07	dRX73Fg8P8HztUyE4cnxJ2GHlNg_Mj3z6eCZlN_QaH4	mBj1OzgzYbfq-5dyyhR3oX-O5z-x3qVjtl7Bv04zBFM	1	236	15	224	
238	1583967936	2020-03-11 16:05:36-07	mBj1OzgzYbfq-5dyyhR3oX-O5z-x3qVjtl7Bv04zBFM	vwvA3GtpZj23V7d7hzpB68tWnzVTggXeXsJspfDKFcY	0	237	15	224	
239	1583967941	2020-03-11 16:05:41-07	vwvA3GtpZj23V7d7hzpB68tWnzVTggXeXsJspfDKFcY	UmrpNJTCL3x8U3x4S8dYZYxbxOz-Unb8YAHJ-jiGIss	0	238	15	224	
240	1583967946	2020-03-11 16:05:46-07	UmrpNJTCL3x8U3x4S8dYZYxbxOz-Unb8YAHJ-jiGIss	OOic8HmRyfWhA3t66MgFAc21bUZOF1g4Rcw2UmdxrZg	2	239	16	240	
241	1583967951	2020-03-11 16:05:51-07	OOic8HmRyfWhA3t66MgFAc21bUZOF1g4Rcw2UmdxrZg	Mdcmlvsv0XMCvI2nu8r5eyh65o4Y3NLcPbgXnKfMNvI	1	240	16	240	
242	1583967956	2020-03-11 16:05:56-07	Mdcmlvsv0XMCvI2nu8r5eyh65o4Y3NLcPbgXnKfMNvI	T-oseLLZbMIh_H7J_VOsNbJDwEcPxNj6off0wt85kQI	0	241	16	240	
243	1583967961	2020-03-11 16:06:01-07	T-oseLLZbMIh_H7J_VOsNbJDwEcPxNj6off0wt85kQI	ggpHMJ9hFoFcetkkomPkTbs7xCBPGcB9XsNZUiuA1Sk	0	242	16	240	
244	1583967966	2020-03-11 16:06:06-07	ggpHMJ9hFoFcetkkomPkTbs7xCBPGcB9XsNZUiuA1Sk	z650M8z6y3ntOKkRTeNrPi_i_JOK7DhURGP4QbXpKRM	1	243	16	240	
245	1583967971	2020-03-11 16:06:11-07	z650M8z6y3ntOKkRTeNrPi_i_JOK7DhURGP4QbXpKRM	G8GE4a0eWBx4UOiELFFw5WB9lqRdnsi4bpq7pQS7ipA	0	244	16	240	
246	1583967976	2020-03-11 16:06:16-07	G8GE4a0eWBx4UOiELFFw5WB9lqRdnsi4bpq7pQS7ipA	EG07vi1GclBESpIv7D72qbVOvo7jmuj8aWp9XMpSLs0	0	245	16	240	
247	1583967981	2020-03-11 16:06:21-07	EG07vi1GclBESpIv7D72qbVOvo7jmuj8aWp9XMpSLs0	mEcSB8KCNH420M6D74sUzkrcxrRKRPiP0WV1YgSJ_KU	0	246	16	240	
248	1583967986	2020-03-11 16:06:26-07	mEcSB8KCNH420M6D74sUzkrcxrRKRPiP0WV1YgSJ_KU	fhYFltOWN7C6kj7GJjHLU9rahq7YD-drvb7YdYJ--JE	0	247	16	240	
249	1583967991	2020-03-11 16:06:31-07	fhYFltOWN7C6kj7GJjHLU9rahq7YD-drvb7YdYJ--JE	zbH7kvZOyXo-FyvcsCykKBGGZDaMY2IPiWLVdjCDJhU	0	248	16	240	
250	1583967996	2020-03-11 16:06:36-07	zbH7kvZOyXo-FyvcsCykKBGGZDaMY2IPiWLVdjCDJhU	W3_OM_IlVqwmy9Ffj7MqSUvRv5L2PUo4qF5XgLOW6mo	2	249	16	240	
251	1583968001	2020-03-11 16:06:41-07	W3_OM_IlVqwmy9Ffj7MqSUvRv5L2PUo4qF5XgLOW6mo	hk7UjqcaMVnoamTNivZDBza9NV2nmPB23xFi4lXdA6k	0	250	16	240	
252	1583968006	2020-03-11 16:06:46-07	hk7UjqcaMVnoamTNivZDBza9NV2nmPB23xFi4lXdA6k	ITsMVMhR7HMsNVb581bMUGkfdSzD_iGK8H_V6xO2vks	0	251	16	240	
253	1583968011	2020-03-11 16:06:51-07	ITsMVMhR7HMsNVb581bMUGkfdSzD_iGK8H_V6xO2vks	7d9SI9kSMaPJpKp9Go92nm5QZAHm-olp1OLE2Zr_17w	0	252	16	240	
254	1583968016	2020-03-11 16:06:56-07	7d9SI9kSMaPJpKp9Go92nm5QZAHm-olp1OLE2Zr_17w	Ox9tAUkHV48dPV8gAtd8LfpwoHOO-25yzvpKlSw9t7Y	0	253	16	240	
255	1583968021	2020-03-11 16:07:01-07	Ox9tAUkHV48dPV8gAtd8LfpwoHOO-25yzvpKlSw9t7Y	MNYCt05kameTzC_lLzVpiZgjGaKQCtj4EoQLHfhhtb8	0	254	16	240	
256	1583968026	2020-03-11 16:07:06-07	MNYCt05kameTzC_lLzVpiZgjGaKQCtj4EoQLHfhhtb8	F51VNXd29MMd8uiEiwIQtvl_JeNxJSvQ-5AJEKRgGKo	2	255	17	256	
257	1583968031	2020-03-11 16:07:11-07	F51VNXd29MMd8uiEiwIQtvl_JeNxJSvQ-5AJEKRgGKo	zpHdb9JIbzLj32FzfWxEgXYyejGNnhLl8balplGBqSY	0	256	17	256	
258	1583968036	2020-03-11 16:07:16-07	zpHdb9JIbzLj32FzfWxEgXYyejGNnhLl8balplGBqSY	9GA5VpD8Z4TquJ3jdB1FCxzZcZ4NSLEutTeyZ5wI9PY	0	257	17	256	
259	1583968041	2020-03-11 16:07:21-07	9GA5VpD8Z4TquJ3jdB1FCxzZcZ4NSLEutTeyZ5wI9PY	YgqBTPNDv5D5kIF9D97qKRe_u7PsRRsA5QjOEijCsbY	2	258	17	256	
260	1583968046	2020-03-11 16:07:26-07	YgqBTPNDv5D5kIF9D97qKRe_u7PsRRsA5QjOEijCsbY	ETGKKMRONhEhFNS5RIXtIDr9C8L4osmQxdnHzlu4bJw	0	259	17	256	
261	1583968051	2020-03-11 16:07:31-07	ETGKKMRONhEhFNS5RIXtIDr9C8L4osmQxdnHzlu4bJw	-sNo0yl2iXIxY-AIh1mom_kE7n3It5RPoFymBvr66-4	1	260	17	256	
262	1583968056	2020-03-11 16:07:36-07	-sNo0yl2iXIxY-AIh1mom_kE7n3It5RPoFymBvr66-4	zkZKGYlkQn7HDfhSVxy2v4pj09wcV8B1wD5IiJx-wxY	0	261	17	256	
263	1583968061	2020-03-11 16:07:41-07	zkZKGYlkQn7HDfhSVxy2v4pj09wcV8B1wD5IiJx-wxY	1M_RDQMDPsNJIBNgAZ6ip79vVI53TxLkaOIn7O-KN0U	0	262	17	256	
264	1583968066	2020-03-11 16:07:46-07	1M_RDQMDPsNJIBNgAZ6ip79vVI53TxLkaOIn7O-KN0U	hDpJ2osqkLBrC9xeBEEr2H3cLmqRCLp03MjfcEmT3w0	0	263	17	256	
265	1583968071	2020-03-11 16:07:51-07	hDpJ2osqkLBrC9xeBEEr2H3cLmqRCLp03MjfcEmT3w0	3AfzRKjm--jtTRogjCbEDDszzMnz-z7i-f4Nv7WCCG8	0	264	17	256	
266	1583968076	2020-03-11 16:07:56-07	3AfzRKjm--jtTRogjCbEDDszzMnz-z7i-f4Nv7WCCG8	3resTXvkrBxKHkpVdMgB0AmeiyY7jRcEg8eZWawdVjk	1	265	17	256	
267	1583968081	2020-03-11 16:08:01-07	3resTXvkrBxKHkpVdMgB0AmeiyY7jRcEg8eZWawdVjk	f8-0A4HHSYc74TgsvW5xl3Gf-bHfRa71zRIK0yQnhtw	0	266	17	256	
268	1583968086	2020-03-11 16:08:06-07	f8-0A4HHSYc74TgsvW5xl3Gf-bHfRa71zRIK0yQnhtw	N_TMo9zNQnShicZti2OSCUY5o33kVhQ2wuYA-D20I9g	0	267	17	256	
269	1583968091	2020-03-11 16:08:11-07	N_TMo9zNQnShicZti2OSCUY5o33kVhQ2wuYA-D20I9g	vicl76_V8-tLxNmE5-z8l_kdMnld7RtCiC5CEt-3o0w	1	268	17	256	
270	1583968096	2020-03-11 16:08:16-07	vicl76_V8-tLxNmE5-z8l_kdMnld7RtCiC5CEt-3o0w	MhrCDpqmL6D3GLGYcLQeqFyL5liO6Zh3Xt8CYpfNGAA	0	269	17	256	
271	1583968101	2020-03-11 16:08:21-07	MhrCDpqmL6D3GLGYcLQeqFyL5liO6Zh3Xt8CYpfNGAA	Xz31-UGmsfZt0YZYy5zGvo8UQ2YcOJ6dAdn9yJsygDs	0	270	17	256	
272	1583968106	2020-03-11 16:08:26-07	Xz31-UGmsfZt0YZYy5zGvo8UQ2YcOJ6dAdn9yJsygDs	Bo6nQe7MgqPPHN5GumIABzhwaxQL5ZK2Mh3oxNffS2k	2	271	18	272	
273	1583968111	2020-03-11 16:08:31-07	Bo6nQe7MgqPPHN5GumIABzhwaxQL5ZK2Mh3oxNffS2k	mFxnLXRJotGaia9ie2iWY5RM2yZm_yfoY-yBapoT2qs	0	272	18	272	
274	1583968116	2020-03-11 16:08:36-07	mFxnLXRJotGaia9ie2iWY5RM2yZm_yfoY-yBapoT2qs	MCGuRDTnFMrWslN4fineWN7LJBksMNFqjK00ypzrjfw	0	273	18	272	
275	1583968121	2020-03-11 16:08:41-07	MCGuRDTnFMrWslN4fineWN7LJBksMNFqjK00ypzrjfw	R76xMGIA_OFNho304CYRUnpyUkVMk8nTvblrx3FXXc8	1	274	18	272	
276	1583968126	2020-03-11 16:08:46-07	R76xMGIA_OFNho304CYRUnpyUkVMk8nTvblrx3FXXc8	q6L7m7BewWDv2QskIrqz_2sGVMXNybKBs2aXAOB5ViY	1	275	18	272	
277	1583968131	2020-03-11 16:08:51-07	q6L7m7BewWDv2QskIrqz_2sGVMXNybKBs2aXAOB5ViY	KM-ky-tfcwzAstt-_ECqClqqLMh8l97lnp8w4FMCRn4	0	276	18	272	
278	1583968136	2020-03-11 16:08:56-07	KM-ky-tfcwzAstt-_ECqClqqLMh8l97lnp8w4FMCRn4	IjwJOJThBSYas7u-mltbK6blGqxa_PB21ZsjcCIcbIg	0	277	18	272	
279	1583968141	2020-03-11 16:09:01-07	IjwJOJThBSYas7u-mltbK6blGqxa_PB21ZsjcCIcbIg	ho-LS3Qd7GI53djNOsvqZze59hko58KZ5Em-FWp-CqI	0	278	18	272	
280	1583968146	2020-03-11 16:09:06-07	ho-LS3Qd7GI53djNOsvqZze59hko58KZ5Em-FWp-CqI	yqur0eM19PSKBq2zkQhzHmYa8gHCbr7DZzE5PW28Afw	0	279	18	272	
281	1583968151	2020-03-11 16:09:11-07	yqur0eM19PSKBq2zkQhzHmYa8gHCbr7DZzE5PW28Afw	Mn-hrS2zu8Bvy1MYTITXo8DgnuaBGnDmOOrFVK3tqRQ	0	280	18	272	
282	1583968156	2020-03-11 16:09:16-07	Mn-hrS2zu8Bvy1MYTITXo8DgnuaBGnDmOOrFVK3tqRQ	DkgOyKtNZ9wCog9tpQGWtyiccHqN2YPVPip78E42Hdc	1	281	18	272	
283	1583968161	2020-03-11 16:09:21-07	DkgOyKtNZ9wCog9tpQGWtyiccHqN2YPVPip78E42Hdc	M6x7BujZIuh6bj8X9xdiEsAEwuu5YgD7d7vVbVw5vsE	0	282	18	272	
284	1583968166	2020-03-11 16:09:26-07	M6x7BujZIuh6bj8X9xdiEsAEwuu5YgD7d7vVbVw5vsE	cTRaKGD3xBJDpkMOnjJVnFVfykxc5bzeC6XlVqk2WeQ	2	283	18	272	
285	1583968171	2020-03-11 16:09:31-07	cTRaKGD3xBJDpkMOnjJVnFVfykxc5bzeC6XlVqk2WeQ	V0CHYVVwnWBvToxEaw2wxtZfM_wt10BWyrk2B6UujLk	0	284	18	272	
286	1583968176	2020-03-11 16:09:36-07	V0CHYVVwnWBvToxEaw2wxtZfM_wt10BWyrk2B6UujLk	4mMwCuHjctRDgRZTXk7dPY_VYaMeLWDhVoib4TxIdC4	1	285	18	272	
287	1583968181	2020-03-11 16:09:41-07	4mMwCuHjctRDgRZTXk7dPY_VYaMeLWDhVoib4TxIdC4	FvF-dWlRumie0R6YGKIX0b7JX4RUQbcyX4BBxXVkYn0	0	286	18	272	
288	1583968186	2020-03-11 16:09:46-07	FvF-dWlRumie0R6YGKIX0b7JX4RUQbcyX4BBxXVkYn0	t-evnLhOnN9NWl4t-JWSHMqlTeNaLofdoc-KFfo6uHk	2	287	19	288	
289	1583968191	2020-03-11 16:09:51-07	t-evnLhOnN9NWl4t-JWSHMqlTeNaLofdoc-KFfo6uHk	elZYhaFM2UrFwPh4mShStuF3oFDHjsETB0iZW2RL-Dk	0	288	19	288	
290	1583968196	2020-03-11 16:09:56-07	elZYhaFM2UrFwPh4mShStuF3oFDHjsETB0iZW2RL-Dk	AyBcb7EFLDqcdAOyt4DuEgMUqIfrRAu_CSXUNSMdtXg	0	289	19	288	
291	1583968201	2020-03-11 16:10:01-07	AyBcb7EFLDqcdAOyt4DuEgMUqIfrRAu_CSXUNSMdtXg	5WxXlXOZQuTxNsfD62SeBZT5Se4FEFpgy3EYIZedxGg	0	290	19	288	
292	1583968206	2020-03-11 16:10:06-07	5WxXlXOZQuTxNsfD62SeBZT5Se4FEFpgy3EYIZedxGg	Cjl5H_EV_GskBWBdrURomDBMVYjPY3X1PTBYOp5hvu8	0	291	19	288	
293	1583968211	2020-03-11 16:10:11-07	Cjl5H_EV_GskBWBdrURomDBMVYjPY3X1PTBYOp5hvu8	hs8daDb38ot19y99u66XJBv8e6tmBJlQsnlM3McgxIQ	0	292	19	288	
294	1583968216	2020-03-11 16:10:16-07	hs8daDb38ot19y99u66XJBv8e6tmBJlQsnlM3McgxIQ	9V7YRrKgxyXM1earmWHkhmu1qDrC_g2l9rgd-kshcig	1	293	19	288	
295	1583968221	2020-03-11 16:10:21-07	9V7YRrKgxyXM1earmWHkhmu1qDrC_g2l9rgd-kshcig	alzOjqaf8x9dnLpPKdyMujWDEaye2LNEygqnnqBzGE4	0	294	19	288	
296	1583968226	2020-03-11 16:10:26-07	alzOjqaf8x9dnLpPKdyMujWDEaye2LNEygqnnqBzGE4	_H5zt5EReIoALTkEJrWH1TGV-gXSFc9imgtutOXmP2Y	0	295	19	288	
297	1583968231	2020-03-11 16:10:31-07	_H5zt5EReIoALTkEJrWH1TGV-gXSFc9imgtutOXmP2Y	t64vgfCaEYWEEk8_lIrMiC4hu05dfZ00xQQXqqV2G2s	1	296	19	288	
298	1583968236	2020-03-11 16:10:36-07	t64vgfCaEYWEEk8_lIrMiC4hu05dfZ00xQQXqqV2G2s	30HQ-uBPTIylCB2XP7LQFwbiNw6JelsbM5qIBqfCWOg	0	297	19	288	
299	1583968241	2020-03-11 16:10:41-07	30HQ-uBPTIylCB2XP7LQFwbiNw6JelsbM5qIBqfCWOg	eBSt1sMJy4cqDwouInWtUPAPZaXcIyud6wKBMFU-0Z8	0	298	19	288	
300	1583968246	2020-03-11 16:10:46-07	eBSt1sMJy4cqDwouInWtUPAPZaXcIyud6wKBMFU-0Z8	d-D5FkgiJ6YspRQJQ1InIVJsbiwqD-OAW84Zf8FLihw	1	299	19	288	
301	1583968251	2020-03-11 16:10:51-07	d-D5FkgiJ6YspRQJQ1InIVJsbiwqD-OAW84Zf8FLihw	6ZsPD4nrTZRUFMTp3I7rhzQTeJyZm4PnMg1Ccs3ucek	1	300	19	288	
302	1583968256	2020-03-11 16:10:56-07	6ZsPD4nrTZRUFMTp3I7rhzQTeJyZm4PnMg1Ccs3ucek	dArUDwevSBuV-CLgDca1nrJtYY4NB1wlAY2rwA5-4ss	0	301	19	288	
303	1583968261	2020-03-11 16:11:01-07	dArUDwevSBuV-CLgDca1nrJtYY4NB1wlAY2rwA5-4ss	Tu0tiWGp5LNASVeKGgceHhe1S8yZHxvhDYFdGMZuQos	0	302	19	288	
304	1583968266	2020-03-11 16:11:06-07	Tu0tiWGp5LNASVeKGgceHhe1S8yZHxvhDYFdGMZuQos	IgMbI76i5XvJ48oskYNTHWQvAzOEnYtdLOghMcQxuvA	2	303	20	304	
305	1583968271	2020-03-11 16:11:11-07	IgMbI76i5XvJ48oskYNTHWQvAzOEnYtdLOghMcQxuvA	Am-y7041sY-pA9aFWHuSCEyu0-437iZ5KNLyvlCZFXg	0	304	20	304	
306	1583968276	2020-03-11 16:11:16-07	Am-y7041sY-pA9aFWHuSCEyu0-437iZ5KNLyvlCZFXg	ZEFmXrdiOPzcOdyDFr4sDenvF0QlToKJs9pnsD15TuA	0	305	20	304	
307	1583968281	2020-03-11 16:11:21-07	ZEFmXrdiOPzcOdyDFr4sDenvF0QlToKJs9pnsD15TuA	clyIo3wXMuDYe8vS77fPcLOJxijNZOE7D_QtFfKnFO8	1	306	20	304	
308	1583968286	2020-03-11 16:11:26-07	clyIo3wXMuDYe8vS77fPcLOJxijNZOE7D_QtFfKnFO8	JPF8gxrLUZ9aFjP04DK8xs1fftxJkUgbADfy2wEL310	0	307	20	304	
309	1583968291	2020-03-11 16:11:31-07	JPF8gxrLUZ9aFjP04DK8xs1fftxJkUgbADfy2wEL310	ScI8LfYuTe5KBZQX25SM-dw8by07u9d-egXzDztJia4	1	308	20	304	
310	1583968296	2020-03-11 16:11:36-07	ScI8LfYuTe5KBZQX25SM-dw8by07u9d-egXzDztJia4	-9qOJwkZhKn4-rf9T7ebkXOQnEpSVVQOIopeADE5sBY	0	309	20	304	
311	1583968301	2020-03-11 16:11:41-07	-9qOJwkZhKn4-rf9T7ebkXOQnEpSVVQOIopeADE5sBY	tSB9YCA32ykaVEfySI1jNTfz2RHs-2GhTOkhMJGQ9Sk	0	310	20	304	
312	1583968306	2020-03-11 16:11:46-07	tSB9YCA32ykaVEfySI1jNTfz2RHs-2GhTOkhMJGQ9Sk	mUe347P2-xvCtUQmWY_PgOyPB0FauOcDXvHT6AizBAo	0	311	20	304	
313	1583968311	2020-03-11 16:11:51-07	mUe347P2-xvCtUQmWY_PgOyPB0FauOcDXvHT6AizBAo	22XxnVHk1Hdd_KD-kgsZi4K82NMpRh_J5lJY08T0yK4	0	312	20	304	
314	1583968316	2020-03-11 16:11:56-07	22XxnVHk1Hdd_KD-kgsZi4K82NMpRh_J5lJY08T0yK4	tirWYOyfAET88cmM_k7Jn3qcJrWAaWUrqK_ueVfTFYs	0	313	20	304	
315	1583968321	2020-03-11 16:12:01-07	tirWYOyfAET88cmM_k7Jn3qcJrWAaWUrqK_ueVfTFYs	ayGTuqootbVpStALx-JgXF05oKJOjBn07tzZFHE1v2A	0	314	20	304	
316	1583968326	2020-03-11 16:12:06-07	ayGTuqootbVpStALx-JgXF05oKJOjBn07tzZFHE1v2A	4k5dtY8idV54QbtXc1OrHUTw4jp_h9VdhTkOI_JcHgQ	0	315	20	304	
317	1583968331	2020-03-11 16:12:11-07	4k5dtY8idV54QbtXc1OrHUTw4jp_h9VdhTkOI_JcHgQ	66Cm53HLcWoBYc4VkUWWUfDkxR5jEhI-_S_74SELp-U	0	316	20	304	
318	1583968336	2020-03-11 16:12:16-07	66Cm53HLcWoBYc4VkUWWUfDkxR5jEhI-_S_74SELp-U	IKphyfHYw3viFwQZUD13YCiXZyTo0R8ZZ60p5PLkcGY	0	317	20	304	
319	1583968341	2020-03-11 16:12:21-07	IKphyfHYw3viFwQZUD13YCiXZyTo0R8ZZ60p5PLkcGY	WlTjR1jc8U5aygAGdY_K77jIU4nSaLVO1xgD9haOO3s	1	318	20	304	
320	1583968346	2020-03-11 16:12:26-07	WlTjR1jc8U5aygAGdY_K77jIU4nSaLVO1xgD9haOO3s	pEEkEWyLWl6Q2svIz7FgkyklbmjmDXB3eiHGg6Vn39Y	2	319	21	320	
321	1583968351	2020-03-11 16:12:31-07	pEEkEWyLWl6Q2svIz7FgkyklbmjmDXB3eiHGg6Vn39Y	sMbsCR4WLj8ksFMFZOWMd7-EaVeIk7zkKnf8KhPssec	0	320	21	320	
322	1583968356	2020-03-11 16:12:36-07	sMbsCR4WLj8ksFMFZOWMd7-EaVeIk7zkKnf8KhPssec	AoYxfBY54Dqb716lyNj6WqJZdutXnxPDRLEF08xncrE	1	321	21	320	
323	1583968361	2020-03-11 16:12:41-07	AoYxfBY54Dqb716lyNj6WqJZdutXnxPDRLEF08xncrE	NBmycaZtiaTmXE7Ge3QXFHcSJ7mC2jzyASZkoS81M0Q	0	322	21	320	
324	1583968366	2020-03-11 16:12:46-07	NBmycaZtiaTmXE7Ge3QXFHcSJ7mC2jzyASZkoS81M0Q	6AuovG7V2qnpdtjKcE7mlyV0-UrZuD0nbYEudI5_vIs	0	323	21	320	
325	1583968371	2020-03-11 16:12:51-07	6AuovG7V2qnpdtjKcE7mlyV0-UrZuD0nbYEudI5_vIs	Jc0YX5ECrVgWN6f29yXCF5qata3BAKaNTbtNmM0X1vw	1	324	21	320	
326	1583968376	2020-03-11 16:12:56-07	Jc0YX5ECrVgWN6f29yXCF5qata3BAKaNTbtNmM0X1vw	CVBo1nhGS5pVi1yIIT4xjaC3b7sJ_d-ISC8xWNzo-hQ	1	325	21	320	
327	1583968381	2020-03-11 16:13:01-07	CVBo1nhGS5pVi1yIIT4xjaC3b7sJ_d-ISC8xWNzo-hQ	hYjqgMg5zYxwd6Zg0Zdgai8O5ESWYR1AujwNxZV05PE	1	326	21	320	
328	1583968386	2020-03-11 16:13:06-07	hYjqgMg5zYxwd6Zg0Zdgai8O5ESWYR1AujwNxZV05PE	Q-eALQn6SifL1K9WLJ9JcxnVYGENjWCN3VsUWEjiRQY	0	327	21	320	
329	1583968391	2020-03-11 16:13:11-07	Q-eALQn6SifL1K9WLJ9JcxnVYGENjWCN3VsUWEjiRQY	JqjHKpDH2h6896M73u_ahN-WpF7oFoRb3sjYpbvYZLg	0	328	21	320	
330	1583968396	2020-03-11 16:13:16-07	JqjHKpDH2h6896M73u_ahN-WpF7oFoRb3sjYpbvYZLg	P3Mk3MNkRlW5HNpptDX8RKtN3tI3BM6EzYBbpgcqfgE	0	329	21	320	
331	1583968401	2020-03-11 16:13:21-07	P3Mk3MNkRlW5HNpptDX8RKtN3tI3BM6EzYBbpgcqfgE	Tx_mM11KNYqGBILTAFCqzA71oJAmHRbXtZH5ydu14NI	0	330	21	320	
332	1583968406	2020-03-11 16:13:26-07	Tx_mM11KNYqGBILTAFCqzA71oJAmHRbXtZH5ydu14NI	FP5RpsBE7xOTk0csOOL20jmAPCwEHsmgcWC5Bi4vXMI	2	331	21	320	
333	1583968411	2020-03-11 16:13:31-07	FP5RpsBE7xOTk0csOOL20jmAPCwEHsmgcWC5Bi4vXMI	Fm6_uDQ99jwZIPz8S7UQXpak3SR8mJBzFfHQCbCZTLw	0	332	21	320	
334	1583968416	2020-03-11 16:13:36-07	Fm6_uDQ99jwZIPz8S7UQXpak3SR8mJBzFfHQCbCZTLw	BbRBxeac-rc1q0sXGMLhSESxDmkVhPrI9iqDyCe5agk	1	333	21	320	
335	1583968421	2020-03-11 16:13:41-07	BbRBxeac-rc1q0sXGMLhSESxDmkVhPrI9iqDyCe5agk	ZMBULkawM8IZYSu9C4ubjXzqEmlCFQjwvcthq1MZVZI	0	334	21	320	
336	1583968426	2020-03-11 16:13:46-07	ZMBULkawM8IZYSu9C4ubjXzqEmlCFQjwvcthq1MZVZI	xrGR-4mKYPd2PvYE_0GxZdyvWK1IERfxjy1oBqsRFIo	2	335	22	336	
337	1583968431	2020-03-11 16:13:51-07	xrGR-4mKYPd2PvYE_0GxZdyvWK1IERfxjy1oBqsRFIo	59kcG3hub0Tn4W9I1Y3AvYEmL3mq18znwhXqFKzUIJI	0	336	22	336	
338	1583968436	2020-03-11 16:13:56-07	59kcG3hub0Tn4W9I1Y3AvYEmL3mq18znwhXqFKzUIJI	Ap6k6w1XeXk7Upo4bEURh2DcBIV7GTRCPbGRM6DOgn4	0	337	22	336	
339	1583968441	2020-03-11 16:14:01-07	Ap6k6w1XeXk7Upo4bEURh2DcBIV7GTRCPbGRM6DOgn4	MDW5T11wvn-878nqHx_CHsmwDIblW3buPZytBRuxgIo	0	338	22	336	
340	1583968446	2020-03-11 16:14:06-07	MDW5T11wvn-878nqHx_CHsmwDIblW3buPZytBRuxgIo	Evm4bz7PQMYEJ3KKzw7ZpxuqEkUY0ZAt6svIZsiBkIA	0	339	22	336	
341	1583968451	2020-03-11 16:14:11-07	Evm4bz7PQMYEJ3KKzw7ZpxuqEkUY0ZAt6svIZsiBkIA	Q8OLLq2rPZNIOqfiuKPdXvvA2Fgc7WkeN9OnqJbqacc	0	340	22	336	
342	1583968456	2020-03-11 16:14:16-07	Q8OLLq2rPZNIOqfiuKPdXvvA2Fgc7WkeN9OnqJbqacc	AEpYpljJWdYikCnhz-0Y7MfcpBUqsllSgxOGOeZ453g	0	341	22	336	
343	1583968461	2020-03-11 16:14:21-07	AEpYpljJWdYikCnhz-0Y7MfcpBUqsllSgxOGOeZ453g	hUTZm_9Hd1qyXjnMQ3pH04spVEP2r9fiLbyeK2aVGiU	0	342	22	336	
344	1583968466	2020-03-11 16:14:26-07	hUTZm_9Hd1qyXjnMQ3pH04spVEP2r9fiLbyeK2aVGiU	0KDeqM1wqhNDUa4HZ9T3k3coQkuFg3SKeU0NHHrxo6Q	1	343	22	336	
345	1583968471	2020-03-11 16:14:31-07	0KDeqM1wqhNDUa4HZ9T3k3coQkuFg3SKeU0NHHrxo6Q	9_YIX9E9le18__Bv5rASnCYNvGDGGbm-esEb2M8GyjE	0	344	22	336	
346	1583968476	2020-03-11 16:14:36-07	9_YIX9E9le18__Bv5rASnCYNvGDGGbm-esEb2M8GyjE	uu3cr55AFynPYufTxYvCIC1NQ27jwrxi-f-oTyVwpKI	0	345	22	336	
347	1583968481	2020-03-11 16:14:41-07	uu3cr55AFynPYufTxYvCIC1NQ27jwrxi-f-oTyVwpKI	qF4S5J3gJAy8Yxv9G3AU4-ZfU20HdeCrCaT35jP2234	1	346	22	336	
348	1583968486	2020-03-11 16:14:46-07	qF4S5J3gJAy8Yxv9G3AU4-ZfU20HdeCrCaT35jP2234	fTZNjVt-dTmreTlBKrTK5bijN8GHJrUUUH8UCd4t3t0	0	347	22	336	
349	1583968491	2020-03-11 16:14:51-07	fTZNjVt-dTmreTlBKrTK5bijN8GHJrUUUH8UCd4t3t0	-21_oEjD1E2eGWt0wDm1IALob2MwLLvwXmLlUDLixyI	0	348	22	336	
350	1583968496	2020-03-11 16:14:56-07	-21_oEjD1E2eGWt0wDm1IALob2MwLLvwXmLlUDLixyI	dswHQCDy7bqK9zS-UKZPQogEh61bIVH5kCWZeTtMvic	0	349	22	336	
351	1583968501	2020-03-11 16:15:01-07	dswHQCDy7bqK9zS-UKZPQogEh61bIVH5kCWZeTtMvic	Xyy31_7WQWa1c8ROizx8zg29cjw_tGYHcK8-Gc82uos	1	350	22	336	
352	1583968506	2020-03-11 16:15:06-07	Xyy31_7WQWa1c8ROizx8zg29cjw_tGYHcK8-Gc82uos	Bkgi4ffPoQ1CNpDnFjGLv8yoYMVSO-mbIZVEZbS85fM	2	351	23	352	
353	1583968511	2020-03-11 16:15:11-07	Bkgi4ffPoQ1CNpDnFjGLv8yoYMVSO-mbIZVEZbS85fM	Ihv9s0tMNHaEZ2LnE8aXIoF9U6otg3uS89-RCGNq_Wc	2	352	23	352	
354	1583968516	2020-03-11 16:15:16-07	Ihv9s0tMNHaEZ2LnE8aXIoF9U6otg3uS89-RCGNq_Wc	NZOuS6vYimhFe7fBmwKwBx2UVg1t12lWue8SCWlbZTg	0	353	23	352	
355	1583968521	2020-03-11 16:15:21-07	NZOuS6vYimhFe7fBmwKwBx2UVg1t12lWue8SCWlbZTg	2gkfCKt6Y0t4zY2IquZSyCpT8R_rN6GkzypSsPAaPSg	0	354	23	352	
356	1583968526	2020-03-11 16:15:26-07	2gkfCKt6Y0t4zY2IquZSyCpT8R_rN6GkzypSsPAaPSg	WDkzjN7l16nMBzfXfpcNxw2AL4_IKJMl9c6lSAQJGeQ	0	355	23	352	
357	1583968531	2020-03-11 16:15:31-07	WDkzjN7l16nMBzfXfpcNxw2AL4_IKJMl9c6lSAQJGeQ	zcwHP3Yf4xiNMT5ogcKhj81haVav78LgzE0ZZrRrGTg	1	356	23	352	
358	1583968536	2020-03-11 16:15:36-07	zcwHP3Yf4xiNMT5ogcKhj81haVav78LgzE0ZZrRrGTg	7yH1pRIYYclE7MWBRV6WYd7w6m4u3DCrbPjJ5TnFAJk	0	357	23	352	
359	1583968541	2020-03-11 16:15:41-07	7yH1pRIYYclE7MWBRV6WYd7w6m4u3DCrbPjJ5TnFAJk	QLbRtU45D4p10CmpNQ7_mvITn4GdOoaBu2hEpC-imzE	0	358	23	352	
360	1583968546	2020-03-11 16:15:46-07	QLbRtU45D4p10CmpNQ7_mvITn4GdOoaBu2hEpC-imzE	U90n2KZzVFxioGbuSiOucHFuseVYxqUd_k9Ic2YPwv4	0	359	23	352	
361	1583968551	2020-03-11 16:15:51-07	U90n2KZzVFxioGbuSiOucHFuseVYxqUd_k9Ic2YPwv4	EfdR9NoVU8r-XhGI4zspAx4-BEwrk00k9W9HA7pXFSc	1	360	23	352	
362	1583968556	2020-03-11 16:15:56-07	EfdR9NoVU8r-XhGI4zspAx4-BEwrk00k9W9HA7pXFSc	UZDcqUARuY_TAHiK5yuhvUwrjzXShQ305YJtckmdEgk	1	361	23	352	
363	1583968561	2020-03-11 16:16:01-07	UZDcqUARuY_TAHiK5yuhvUwrjzXShQ305YJtckmdEgk	SfBXomYvK6vjX-K3b_ecfwq690HZ3EJiedNhLXg8qMU	0	362	23	352	
364	1583968566	2020-03-11 16:16:06-07	SfBXomYvK6vjX-K3b_ecfwq690HZ3EJiedNhLXg8qMU	fWCUyuumbQZoC4O-nRNrYvoCm7zBrWqYyJLPNBUU8b0	0	363	23	352	
365	1583968571	2020-03-11 16:16:11-07	fWCUyuumbQZoC4O-nRNrYvoCm7zBrWqYyJLPNBUU8b0	ajoRrpFFp_agDFp0-PDjYDBlix6kFjX_Tc_IXksSaAg	0	364	23	352	
366	1583968576	2020-03-11 16:16:16-07	ajoRrpFFp_agDFp0-PDjYDBlix6kFjX_Tc_IXksSaAg	c3qXNmJQ4Kv8z-CH3tRgOZZkt3-NcStpY6fBhb6QriM	0	365	23	352	
\.


--
-- Data for Name: gateways; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gateways (block, address, owner, location, alpha, beta, delta, score, last_poc_challenge, last_poc_onion_key_hash, witnesses) FROM stdin;
1	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
1	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	\N	\N	{}
3	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	3	PmSNpXpGNDRE0r2nrrGF2RX0r_88JEcH_-56lHJEH48	{}
3	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	3	VLxbpc8ytthaiDIMXFODLjYIq2R6pQFedplcVkqOGEU	{}
3	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	3	zL2qMcN7rpPQdtO1gJ0zc__phrK6FMl1dztvlMSd0nM	{}
3	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	3	5nPwxES2mdDZJoK7dCgdDgGcKK9uNSc7aNWnV_MvzAk	{}
3	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	3	lbvy1dKm0Yr0QWUcgU1gV3eEBwnJ7JKPvB7fErGqMLg	{}
3	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	3	Lhd4jEsdVyLmYMU6-imQYpMwMMGBqS4sIofJmqTod8w	{}
3	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	3	r8o9N8H96ZS5lJTUcMBooW4F8V1wBBcUMweXOowrTck	{}
17	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	17	39cAniZz2tEaYW7ROxMlMOp-U-_aSNAcm1YXVgkX8VE	{}
28	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	28	sgt3vtsRwjUDsw0J2KrVIAUA2s25SLZeMDRQU4-5JKg	{}
28	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	28	XOHoOsL5rXzO5UPP_IWe5vSROb_4XQxqgkf1Gu612Iw	{}
28	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	28	ThLUJBNopjGTpIZVweOZw6W6qNPLThd_neFKJzSqS_0	{}
28	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	28	DfbEhgt99VEK7vW04Z6pe_-gq3zAR4HIIt95LBofXY0	{}
28	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	28	rs8axn7DgdNYMNnkM8tim7gUrxbTyr3wCjq3TS6arss	{}
28	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	28	w6JuSKriuSu712DA3y03bRaFXYEvQjMcmIftuHx_J14	{}
37	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	37	sAx6PxlgqX6U009v3ekocQqRQtr43vVNe9ZXXaUDJN0	{}
44	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	44	2fDdAqEQ9svXLfNevMOu3bRK47uCND7zAFe28p4GVE0	{}
53	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	53	K3YfgntupgniFQgAUkG3EVQcibDci3cItkNXn7gU4Hs	{}
53	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	53	qO4pZWtFiasTGYMDoSM2vKq_nXqybbSdFSMlcJhqGko	{}
53	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	53	clUa7HMrw9wFQvJVI0HSV1TivXT6rTDBWXenUhL4gbA	{}
53	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	53	h1dnKwhJ0qDhdGvfGAvm3EDB--MF0vrtQTU2Rwp7N-Y	{}
54	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	54	szzR1EYBDy_Cvua9e2tHPVmL7lGJpdw-9gSyL2psTHw	{}
62	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	62	2gRG2U78oetpgnhfZ5spIHyXSpnv93XBMdp2x0OzQzE	{}
63	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	63	bV10WyYiclTZsg4e8G-DqCN42nnWvpVT32xs9OsvhlE	{}
75	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	75	0TkgTGsyH3plBjPQabDOwd9AUSaRGthHrlt6RRvAT4M	{}
78	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	78	W09RQVpXHAVGuQOMxmz91doAyuN3m_wEV24E4TtEWME	{}
78	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	78	5jjxLqPahiseM0BTubOVQnLewtmbXLH6O2h2MFHVfOM	{}
78	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	78	6vGq46m3LiYjUveGb00zRwIvLTcfdDfgJjrsgOXNAco	{}
79	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	79	Eo3-ETmzKk3v-NFDL73SLGVFqgT6oDxwy1daRMPk0DE	{}
84	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	84	_5rLdyyJGGYRbG1K-PlccTaz2SADCxjAdJxuuITQBvM	{}
87	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	87	Q4NwBckRdP1R5Od3LMbeQO0Z1Zmv22PdMKG7bQhkHec	{}
88	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	88	qDAGT_O8WMfTwwlSXMp2YognagA2Ge6TWP9bAfV9WNc	{}
100	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	100	03NKWL96ZEpGUxwJp0-dtkPyLaL46mPqWE-Xnwo8y5U	{}
103	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	103	HQeTEoYn6FpXemVUBQTHWBnC0TrL4QEjv-LGI6Bq8AE	{}
103	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	103	VRSvmsZl8CSEOYmhZjNK9FXU5ZpoPRf0po43W_Yv5tY	{}
104	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	104	8RuJpLM8H-_ObUzeAdrMvnzZ8RI8-Uw11C_u6Q3x0-U	{}
106	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	106	76KV6C2e4CJ0a6J0YdheTdLQdKx2zQaVr7fo_kSFCdA	{}
111	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	111	12EFqmkDYOZ9bpO_WY7U2FntKnQbkrJU3hRQBiB99eA	{}
113	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	113	_8ODYN1jsVzzXwGtKBSuX6YsF0mxbAd1965dMGnZVjY	{}
113	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	113	mJI8IhMlKDU8mACS1wjANn0I_1PHkvmP3e16gbdVTdo	{}
125	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	125	7RI4PL2RnUkHzApdDt9pry2K9Mv5RcWIF9yVsS4QumU	{}
129	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	129	EGSzbKT_pwxi8t4s8unt4tg4wN2TEQk5xj8oFgmW9rA	{}
129	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	129	TDQhdV1CB9kiyN3JdDFeeZiUQpl4X3x5_6QaT_g2FL4	{}
130	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	130	QJTAKqSrQXawUYBShvpicsyz2-3lJ8k9ut0p2w--Ibo	{}
136	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	136	ZpirIepO5sUxeAg6GlYrDV3h6knPvWy5RWKxYaj-SS4	{}
137	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	137	Cp1GmEe5wSc-fHuifg1ND9RDUDq5y7zs-QgvBNx14Ng	{}
138	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	138	KQeEhNZKmM1WII-L1XxXEiDJZliFiI8zEx-NeMTLoXM	{}
139	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	139	-YuF6IVzwxUdReNbyXVS2WuieUnGlNkuLyCrS_Us5wU	{}
150	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	150	PWREx2ujBKGIZIcimXWzQRILwYdluRFaxcszwG0RcaU	{}
154	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	154	GpcfBgex5VitlKl65qKEN9ShFWq3F0tzo18YRIMBX0U	{}
154	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	154	NAsklXuL44Cog5NOvml_8hGNhukAEe1j7KqaqoiT_cQ	{}
158	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	158	5XvNJKch3cruuboOoJ_cwVGvSk5DewxzyHADHV0ceSs	{}
162	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	162	L4K9YOjE5jBOl9VMSguXmCvkqiQ9i2HQXnYV4ddXtFA	{}
162	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	162	uzZQJkdGMVWBKjjjHY3fFe_myRx6Z0Yzlr76j42AkEY	{}
165	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	165	F9fJoHJgtG7mOEdNzm7jS6TmchpCHWxUm2CCeOtu_7k	{}
165	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	165	uzHT4WCGZH7jyU7_tGjOBEwiOnZFoFJbqBLtqUWeoSY	{}
175	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	175	KipGxq4gr0rR7Y6nIGnT4k-7O_sM4G5OdeVLaexJkbQ	{}
179	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	179	VJ0NisN97eeYwzykBfDq7e5QmYJBs-_swoNn3QSDKso	{}
179	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	179	mM2cEjEMN8_U7Zwcytp4DMp5ITSfD_mbWP0r4GKMWrE	{}
183	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	183	yIeHml9i_xs76a29FpYnYMeph1uwz8rf7oA6sQ7XckQ	{}
187	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	187	Krrafb_1smIprhU21I60AUJex4W0GI6ZaNmFzOrCPeQ	{}
188	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	188	YO5ARcIfaVjmrrlWiCB7imATqaJvzy91MZNpyIB-aCY	{}
194	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	194	vCaj3nxkrgA9cdim7BkRopQcfurUgG8zixUG5aGziWA	{}
194	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	194	I6oHLpmMCNdxm-oQDPRn1yWUcVoNCUKuG4-HuI_UCAQ	{}
200	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	200	XSI-KEtnZ1qiuy2bMOht6JsvuXTwRg2TLiZ2TGUaetU	{}
204	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	204	NtnUi6KDJNSnrMXyDZA4x0wuBioeYOZ63NXjOcB3eg4	{}
205	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	205	rPA5cVNtIl6JJSMlTuTgKbQp4zx8s7nixDxZObdLgZw	{}
210	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	210	Fk-RISjOJ3TjVnGAzC98GoG-nNkjF_-jpnC9ljBLBac	{}
212	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	212	L-7gERD6-v4wbgf-F1sq4InIIaOkFtDtTpX5ex-7Pes	{}
213	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	213	6RdsVg4TzqM_n_zZMOJ-P1DrTN56XWnidTvlCfBOHbw	{}
219	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	219	fIXcNIEAq39nfnNjnuBFfn0bXrI7orwrwfvDBYEZMdA	{}
225	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	225	vE7IA03d4ek0zuoXVo5vgvSCyqPDo-9MdjLdKfpTooo	{}
225	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	225	DGBxbVrGeaJ5u2K2jX4fHHAc4vLQX6dEvclpPrCSSDw	{}
230	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	230	LHMA0xYP4Cegkai82SjHdeRnZvBE6WlIEUjSU3E38m4	{}
234	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	234	0imG0VnmP2Hsj3dceqXso-Xa0z1_0loixmOrEIDmyy4	{}
235	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	235	50vnEyC3MDjVheehoz5c1poGHQzMVv_SM_0l74DNcp8	{}
237	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	237	6QttCKgtyCRWw8MHgwcOLjJ_GVA3_TCwyNnwn4h4C04	{}
241	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	241	3n5z9GTPn2zG3sRdonCiyDiBaRcn9cks6o08Xh0EI9g	{}
244	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	244	EdwPVYQasDzeBACRxqz-63ziEkAj6T8H5mQUxLDdWMY	{}
250	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	250	FWUaVwCLJ5wrqJYlKU7EsluRqWGj-f0bt4OI9shCOK4	{}
250	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	250	SPi-wROAeFOs_cwqcVuqEpMK4snbLaQRgei2hsty-r8	{}
259	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	259	ezJ2RvC_PJ-xIfb1AZbSg53OYnMyaJkzcgP6CPgUc08	{}
259	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	259	sGllSROBKR3kYUqP71naj6SQYv291LkAv4q99axJxiU	{}
261	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	261	H-ZyyA-wiHkio6AjXP3EZeyzl4mkAIdeJN5h0u3otfE	{}
266	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	266	8dsGPP478TJcPJe34AlAkU9YdJrdLBWp2x5KJ2w-hL8	{}
269	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	269	c0UHuo0wV4xyYGmX779wgypChnsduF_QScIrL8v_htI	{}
275	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	275	9gLOARtFpRlnUxPHsldE9VpbaeRgW3gzz9YsMwTEPC4	{}
276	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	276	QM881LhnMfDDG0ArimXd-LrXp4Gs3I-jwqgTg9Qa8UA	{}
282	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	282	_wIn9Qsvpg9ZYQj9AlxRCLlP10i7kkMBXDtFttpNfKU	{}
284	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	284	Fd2oi0tgOdzFPV8oO_ApBxz11iRFn-BkL15UWwVlPUI	{}
284	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	284	cYcPO15ShbBw_7kxvTptBLLSdzNstBS9mpIUlzOtqd8	{}
286	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	286	QcqZdGVpFq7CCzHwjUaBW-Xi8GQvP3-dUWcUgpou2_4	{}
294	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	294	OLukcVIGmmxxS6gBwjGp6l_iX40YtPEP7IngysM5-30	{}
297	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	297	gjcySa6OFs6amjxGq46sUgC_9ByJBqwZHrv7Z08KXMw	{}
300	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	300	jGC4sJmvbkyfWy0Jm4iwDWeeWEFnwI4z4s5Vbjwq6g8	{}
301	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	301	nvtPtS7Kh3zCNeZP2a9xzX7k2mSs1ZLOPLIyNZ4vBZg	{}
307	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	307	KX-Hrbm_OCm-wvKEFtImo5pbe9jkPN6Uaz7M7rGBGZg	{}
309	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	309	0LMunfImr0qsY1aZlmhLb5lh2k1ND5wS2ODOevKJJEY	{}
319	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	319	NvfyqS-K6HEsvK_cprtvrlTpFOg7XTBi4WnPJ0EtQ1A	{}
322	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	322	DlMcEzayAKeHKKyWhgvetdR0ZGyZlGIPel4Di_H7hoU	{}
325	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	325	aJ2Hpv3bO2W3bEXKredFrSDh3aJUxNk_PsEXVBUGyv0	{}
326	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	326	iWdet4FaOWdACafVnHp5QQNwfL1-EMJX5pnpPf050IE	{}
327	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	327	iXSQ3VARmmYCY_LKl0prJmkfihmy_LclkPXO-My--8c	{}
332	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	332	ahU88W5MAzjBm2rCKz1cE4XjQYwraNBYFyLOFfyvWpw	{}
332	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	332	Jol6xR9XFwgFD040Gm9DTLVpxSMZmrjxsgUo6DRl_fU	{}
334	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	334	YN8ZAIpwJTTG5BYTZ4gOKE4EN9uXccV6KtLL_rli8jI	{}
344	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	8c283475d4e89ff	1	1	0	0.25	344	QRWozzK7zaGA1fs1efopZbM0NNNGEZ6wkC4q5Uggrc0	{}
347	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	8c283475d4e89ff	1	1	0	0.25	347	Bx5a4Q7a_qmhs3cB7ADiK-rta0O4uE_JNyg88MCS9Os	{}
351	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	8c283475d4e89ff	1	1	0	0.25	351	RvU19l6BtR4ck3bAWlVB3xZOg4uUDKnBm9vHZ3HEqec	{}
353	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	8c283475d4e89ff	1	1	0	0.25	353	RU86vDA1G_l30f-jJShM0rJpTIYXsZQKFrJt5Srp1hI	{}
353	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	8c283475d4e89ff	1	1	0	0.25	353	TAe3I7VFMYleEbzaynas7rNs1ClFEDmQrg_eChg7CjM	{}
357	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	8c283475d4e89ff	1	1	0	0.25	357	Czm5yPVf_HR8hUb8PmdLL4UcCFe1g2M9szBG6VQGO1w	{}
361	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	8c283475d4e89ff	1	1	0	0.25	361	h-8mMjR1-5qR94QdZC4OkDaMbDB4z4GPSjnKup5tvV4	{}
362	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	8c283475d4e89ff	1	1	0	0.25	362	JeobN_qSzBwrtrS-ktvieZAL_tFhUJsc8RKsOE0tUI0	{}
\.


--
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.locations (location, long_street, short_street, long_city, short_city, long_state, short_state, long_country, short_country) FROM stdin;
\.


--
-- Data for Name: pending_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_transactions (created_at, updated_at, hash, type, address, nonce, nonce_type, status, failed_reason, data) FROM stdin;
\.


--
-- Data for Name: transaction_actors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction_actors (actor, actor_role, transaction_hash) FROM stdin;
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	35T98NAHm_hJ9LcxfuBfKsWHLq6UGSnzyhH59VHnI_w
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	7lAeFzlCep7fld57ecUIdU47lxL3fr77yQsRbmEB9Rk
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	veL5Yxv3cnW476mZZZwwCcRrooLgpPSYg4YNjXrtYOs
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	Wal0LnXcYxnkX4tHjPw-xp1aojNQ-6vpIJTLQBjuCSw
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	owner	xjXvfCLvuAWnFXsKs1fJHeeyKO9A81Ch7xkeFGPm8ak
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	gateway	xjXvfCLvuAWnFXsKs1fJHeeyKO9A81Ch7xkeFGPm8ak
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	owner	A6qyvOcKl7SHNw-TehsS4oLmvOnRKWlz4G8HWyd_moU
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	gateway	A6qyvOcKl7SHNw-TehsS4oLmvOnRKWlz4G8HWyd_moU
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	owner	BKgbE5bhnmgWRUnNDrq7FbI8PGQTRwv5CAn07S6Kp0A
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	gateway	BKgbE5bhnmgWRUnNDrq7FbI8PGQTRwv5CAn07S6Kp0A
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	owner	PkHfoutRjCMolH7Ey4ByR20yxQanQw41iWsnQfY7TK0
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	gateway	PkHfoutRjCMolH7Ey4ByR20yxQanQw41iWsnQfY7TK0
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	owner	UOuuGZbqfM4mzIevX4pqqqLULvZo8SNRR8pi77c7FTA
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	gateway	UOuuGZbqfM4mzIevX4pqqqLULvZo8SNRR8pi77c7FTA
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	owner	4peQOKTqEykFZxdJzB9o2r5sm5UxN-J_QN05_VL9haU
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	gateway	4peQOKTqEykFZxdJzB9o2r5sm5UxN-J_QN05_VL9haU
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	owner	wgpT-E64NPI7-FCv9V8ZQrY134vosqZglZDL3HzwVRE
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	gateway	wgpT-E64NPI7-FCv9V8ZQrY134vosqZglZDL3HzwVRE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	owner	nhg0QAzkRzZ33iDjmSkRoaEK2b5OgdILigFxhGrKueQ
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	gateway	nhg0QAzkRzZ33iDjmSkRoaEK2b5OgdILigFxhGrKueQ
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	xLdMj9AnBjxs6uct0uNXHHIUBilbRJdwuxz2xwaC8ak
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	97nSjwHZovbYknu1PLymxSRIk_YjGy7sVwL31eUw9SI
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	1u4TIdTdpmnPAkizXd5byJ1gfAASEjPqb3vufRq2Lco
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	fWuRS6NAoyGhSxo9yfgEKdu8M94IMjUunxXeb2hZGBA
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	ZshlvU46kD4IYE-EQ9Im4HJfpt9_-Jq_fQDex7U5_bM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	7zQg-aHpmR41P38TDUH_184TE3J2Zv5nr2BBm78IT54
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	SpKakfACEZH7Unk3krX9jmT20DmtGt_7f9_kV7xvkA8
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	wykmJEA3yYe061MJA7P_ceO8IlTi5NSDM93mToCry3k
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	tWs61cHBl9mYwDRv64SWEoOpk7kp0VzdqQR7TpZwQpQ
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	l-Cury9gMVO8LAR1rPnhKVLjPoMK2PThtVK7xq9VwzU
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	ulk91m5i_6VZshbBoNP9I6uJCZRjBBD6McAvkM8YbhE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	hMu6PWU0ti1UpjFCthZakZh6-Q9m2RJ-FEMfJPOrAb8
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	8afSIbXxPI7vx2i4HI80mcnxiVHBDfzLxM5Rgegodxk
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	ZVpeeU2m23N8j6WVCVgb7CKiFZKquCd4QYub7CQlbKE
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	ASKD0S7m0kwAzamGoRrIKxRnHwM6EGVe7t_ZZd4JB1Q
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
1Wh4bh	reward_gateway	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	Z2KSm3mFzeColOGjIbt9meIvwNM3NGdaxvw1Bymq9Hk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	C0ywf9ozFvF4zOIeZOVVNA9MJkuqRvJkPYXybul57bA
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	f0hvz84ciMOYwZyeXVjnDjH-STz6FtR563Ctdz7Vda4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	3HCnQz2JP6TWtayaqDV2yKzJvtIDBcd2p_fMUl3olmM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	I53l47dnhOjYni5Vy3V-FEEkwL0u8RLaCr_3DW8WvII
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	Pau39MsXjnKBMZPAuPaAzKgOvH3CUZw29-eF8oh4p2A
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	L5sHo3SyfKBGp3dqL8HzE0c2XBpTMxzBpFRnW4MlrIw
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	nNYc_WptfMk6zAgEMGH6_AmOzYUBHOOP5Fg8waBw5hQ
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
1Wh4bh	reward_gateway	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw
1Wh4bh	payer	i4OFqpVSiV4ZnQ-FH_MOEWZ1fUEsf12F7D7G7cou0Fo
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	owner	i4OFqpVSiV4ZnQ-FH_MOEWZ1fUEsf12F7D7G7cou0Fo
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	zcLvrA400BICZ7h4-610t-pjp9WHUuExG8L9CadNapQ
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	sc_opener	gIzoXYwxjkzgOj1ACZL9SsGiK5Yl2tvC5-1P28tTLZo
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	PVOL142WcccRXo9vRTC8g5CEZLCT_mMQuh-OeYU4p_w
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
1Wh4bh	reward_gateway	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	FL2c8RxLwPLV76-8h2LY-IMLVBXQ5iHoiU4UGFqKjtw
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	T0sKUTKHhr0DSpIHzPm11n7Wnv4yyUXqvWddr3dgyz8
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	2cRkt52xNDx6UpgePQ-VcJCJ5Em0_VEjj9qu12lkxTA
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	IDjre52DnKcadg5s3_kRqk-PpeJgkpREglE4dotYnAI
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	aBoW3jOnDP5brb3m8-kQnb8scK5fo9QrzI0l8A_Kqnk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	sc_closer	Qmd4tYPJAF1E5SjLU28fbrj8ivEdwS9xp9euLlphag0
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	ZQ0W2HT0Q2dTwgHOZjmWL89OmyWB9O6oi4-SF9qlU5s
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	anhiVdSq7K3x6D2M8Z9Ic0LqnNRVZtYbhgECVZNYBBg
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
1Wh4bh	reward_gateway	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	Pd3YMOgQkCZ35QdlaWehr8lLxwg8P3yW02Ghax_yNWM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	BtqUxK49cl6kHNwEss_vfUwYhM-tAWowIKRZSBlJ19s
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	BLtEfIkXXUYWq5iqULVSIInJMUkINEtB6UFqfzoQpFk
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	wXv6vg1l-IXyyRwswN9OBRNxbxTLFRauS40Fi168gjU
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	ONfcMhDeUHS8kFQ2XejelkrN2Q-wT_j1-gvYsQLCkuk
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
1Wh4bh	reward_gateway	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	t5F-2LtdrI0j0l7QT9RAFoOff81Cfu5EKZ5I67QFAHM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	8f0J4or-CDaPKfPXZ1HAF3HwbcbXaxWqibJ3rBxUdp0
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	tqmtNWej7X13ItsIsrdoJjXg-2qZgyo2sbdwZ2DrFxA
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
1Wh4bh	reward_gateway	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	xPg_jIhIKQ4pZWzbF0znrEipkMdRQLpCRkR6SkzOcMc
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	2dZAblIvT8OWMdkFzRU8utLKAPeVtQdntAC-ftgOsvY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	-_q-EGtTjJNIlkE3YEvLVsEaCm6HUseZe-WLNtTy-dk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	QYgtTIWOzXg1cjUm1fkww4EuoXnPPzguC8C9vBTmM5M
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	vsaBuQAHKuGfPIMZweu5zlilovrM4bnY0KljK7iApKI
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	Z-xB867oU3iUProNwKEQYySv1mvBWXLOyU3YtbUP8mI
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
1Wh4bh	reward_gateway	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	PjvOdsmRXHLj0-VDC-Munv8nZ-1VxHyMSJJQJNEUL9U
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	Y7J_UdPONnlV7HZL7TYgsIz1Xw1ou_z8ub1AuhMvjmg
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	zmpdbm8NjPtTa3bRV2veJecOijJh_pCmF5uWFXV4Dus
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
1Wh4bh	reward_gateway	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	7gsHhqNWfMdY0WGlgKhd--8vVhWOaRy5Kaj61JvmxpE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	7XRDdxm1x-ZB8XEZYVnzhK3YSOMAafWMnVOThGcyi4E
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	oA-iYPwFDscJ2NBEdkt3o-nWU402MTZVBj5UyOTZ_Yw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	ofodN7IukdeXY0IHCmp0BdR4LJK61QnyRuXInydjrRo
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	WS0P7fvwSnLdj8_tlhTPv7li3vj8YXJHTkwH3dERfZ0
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	nIpof3MAtwwIkAfh4arcO3yqzG30CcR6YP8JwHSkUDU
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	HRailuqbGnrlq7a43z64izHAa0Aide6_Pbw1PtN8tMI
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
1Wh4bh	reward_gateway	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	j6ewiwNaS1rmGzKbI9tczLLK6aLiMwBjg1s4UOZp6jA
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	F0p5JznlhNi9qeutIqjb89wyf-XHCQdxjSu-VWmY55s
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	ISRhUgE67AYVGm7j2TWYN10EjyKOX-H5MWpJc8QS-B0
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	HrWg-LktG0AxR1EcOttlQ6zd3nAES2lz0Q_axfrmZWI
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
1Wh4bh	reward_gateway	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	EpJyohD1gKpQ8q5Bm74MVtvZxTGGfnRVWNg2qMclML8
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	IBdF2g2n9VcxnrB29rcI_iVOIfB1sXUCb9vUFnnX8Zw
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	e69qoLZiYeZS-1dXjUROzOKRytDmeTxBs8rBy7WPq2Q
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	piQXdRW9qbxEVoNmPxwtAkanRRucTGCbg5c_VwmEO9k
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	k49F_B8FCaIrrMa7TrdNe5lSzCKLDF2lFykHigDCwMo
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
1Wh4bh	reward_gateway	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	lXNmHeOisKc8o0E481FhPxBHCXF9ybOaSMk-JfiogBI
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	eDsy1T2iMtRU1NLJuf01UA0kzxSfC9qkqaV7NM6r_d8
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	TGTiCNqCC6lY81c9Ee2rYipu_R72FyVLPH5CWzO8y4Y
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	pWpw8uy1wOT09mtl1ioqD5wynsfelxudMrFfw-fN_TQ
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	lMfAuzi_rJBZnSI5_qksMNWJZ81oIrgHdBJzlP9GP3I
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
1Wh4bh	reward_gateway	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	wAv9vDCo54z8BUvr579NGQGLFRvJSth8D7L20Z-JBoc
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	joA7XtuiiwcktJDbHoexZKXdXO7D71Th4x7IWFzCaks
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	jt9G-U38D0uJ_JM8VT-jr74NuX3iGiE_1vXxfRc_HM4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	PyPhMkp43mgwBlA_F0GMqSdyseDKghvBJCeLcIUD8yE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	LOTgno53J4KUF1NRGLFE0AdgHToTFW_XutC_aV2qXdA
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
1Wh4bh	reward_gateway	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	gRKo9waXfzzfI6yivcsYh41-yagCXjzluPR0dsNa0Ow
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	1NTIiC6T1Gg6dMXTYLD4_Tn5snHFhLwh-kOPofMIIkA
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	MyiuwEV8Its8G1Cuh1TZG2e5CfTFMDtVZ97infFJHpc
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	xDJl832xamNdZK6YH2XXDqo2hX7evrRw6NOU9-qZ00I
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
1Wh4bh	reward_gateway	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	9qGjntiPyjwiLPQCe8J1Q9urAQBHD-WKJfceowHmh8Q
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	4Ui1PSXp2qsgAcKUarGZyNkgQ8_M51y8QIePeyehDvI
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	n__1hH38H7d2oLyw68goXikiFeV_W7DkmwnQpjsRpqs
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	iPt9oJBFgSHxYLR3rWmD2aZvfaHL51bhw_52kfjYRBg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	oMCHpSvWrOObwFeDAYbeNTuMqo9cr26Jo_JGyb-KUNo
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	F2rD48ZLU665cGOXvCuZMTWeIQwNCXZTeyTluBDWVYM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
1Wh4bh	reward_gateway	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	rdNIWqwVaSsk2fb1ZyKqUnIcK0uNXIk65eO7lL1-9o8
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	vhkuxzS6D62xL1DBJKlej9Lu5SG9a1zajod0GiytIwE
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	u6hGDaLLQ-RXy5lVxZI2cG5VO7_7PsIaUTJtB6bQcIU
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	HjvYn9X6_vyJR6n-vLFvy7buwOMwjHMmELPGzPv0Cls
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
1Wh4bh	reward_gateway	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	DxdOAZS1lCW9vfYZhheRsPqvcKpgLyHPv7IDNj8Qih0
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	rNVwPTPV5X3ZeOfO-3QvLw_aRWR2kuLqHRUE44kqbEg
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	tAMEDuUa6OCMxY9KEAvKK8WyQyHIq55lh-y2euEXrr4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	11cicZ7RjlJyckinp12BtAStlYtuMxbelgasZ2WupEA
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	kVOupdvYQWD9NRO1tHFx4Dm_iNINAfGG9ASYe3Ych8g
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
1Wh4bh	reward_gateway	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	DEAv6zEgRXHEFJUnPpNo865NXTfLoFgooiEiuZmK-xo
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	K2EHEkyI5ScBEZ5qW7bBClgoQyB72sT4Xhihw3Ha-vM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	jkyFgqxJkB9rlFooYrrC_sZNAqMcfc2z0K163S_4TX4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	adQEeY7n2NbidjB-ecfsZUXDj7pdxgi1HllrfBml0NQ
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	qMZFI5bp6HP8wEo4Qxcf8gLJmkCPhn8vhKYvJKkm9Ys
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	i_yskCuXPhLRrMVb_2jIPW-f6l3r-71-YZCukEMEOu8
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
1Wh4bh	reward_gateway	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	pxpWeW8EuaRO-iPsJeuyVSG_xgjAzPefBPQ4MlbUPYg
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	47qnncniBi6BM-lbobtqs9BvdF9ON-j5HVloIkgTUUo
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	ELRltQpFFVrsZDtTrX9j29VbCI_yFi5nzbfMQ_dzgSg
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	-hXr1B-c6Ic47L1_fWocPWWBLFHAMxZJNflyVCPMP8E
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
1Wh4bh	reward_gateway	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	geG97dwlGQYy5zUHhmcoOuy9fruf7QGBZ5F_g-TFZHQ
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	k7n8BcPA57PSQhQqJxVeL44Zzr_M-TlbE0j6NIsrTpY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	plgj_oA_lkD4ob854WwcQAIFmzTCWVKK4GxQz-rJ8bA
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
1Wh4bh	reward_gateway	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	tuoUr7W4Ms1RNWkE_Z3f0YiORACvi_-QfFEvd72v43E
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	_fAE-MchDUxiFEVi1j_bQ0PztN9D-suuxNIa-YLIiHM
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	m8vuNuS9oploxKY0HdeldS_Ap3RlfC_Iw3XjzR4OxMU
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	HoDIQC1d5-W7nleZekOKGazeJk7UjqSfcTWOHwVYsS0
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	7ZluZm56I_mZLyrpEZPhxTcLfRiBK-naey33lRFRq_k
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	CftGYLp5bsxvEu04phPOIwsmf-yZJgPTMpbuVVFlT8I
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	Wip5YKvlaOB_6S1OTnq-ryLgfc6ZcDaQtFYQC0KRXYM
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
1Wh4bh	reward_gateway	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	challenger	4ajEoDaV4vF8_e1AoQJBGWzZikSbiJhrwPxFnqjPKRo
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	challenger	XxOqfARJx0_FSbJ_EAPO2se1qoIVLKWK53inboD6ZeI
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	challenger	UDj_fOXXiLUYAizX59QkyEPqgK6nyCbSgOP3RQRSQ7s
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	consensus_member	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
1Wh4bh	reward_gateway	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef	payee	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4
11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu	challenger	zCfeZ863seKfF5af83psP99bWjPk9pStgVnz3_ywLB8
11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7	challenger	twkKob87iXsnsIQuhO76mFd-_SqDmMSP320Y9u52jP8
11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa	challenger	q6WzuYAUFz1VXeFq7nN_r2D60NGu8MXPmbbr1Bur8jw
11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy	challenger	O4ncYBLGSFeY-f1A80306b9Er-_19A4IGr4Wy3BMX90
11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2	challenger	vzZzYlp8sL_VDoyv_GtiSqKXLONHAcRNddzDOBrzigk
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (block, hash, type, fields) FROM stdin;
1	TjTfiMakfCHArih2tRU6W9rq-mdyf8S6PhEFgDtsmjc	consensus_group_v1	{"delay": 0, "proof": "", "height": 1, "members": ["11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"]}
1	35T98NAHm_hJ9LcxfuBfKsWHLq6UGSnzyhH59VHnI_w	dc_coinbase_v1	{"payee": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "amount": 10000000}
1	7lAeFzlCep7fld57ecUIdU47lxL3fr77yQsRbmEB9Rk	dc_coinbase_v1	{"payee": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "amount": 10000000}
1	veL5Yxv3cnW476mZZZwwCcRrooLgpPSYg4YNjXrtYOs	security_coinbase_v1	{"payee": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "amount": 5000000}
1	Wal0LnXcYxnkX4tHjPw-xp1aojNQ-6vpIJTLQBjuCSw	security_coinbase_v1	{"payee": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "amount": 5000000}
1	xjXvfCLvuAWnFXsKs1fJHeeyKO9A81Ch7xkeFGPm8ak	gen_gateway_v1	{"nonce": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "location": "8c283475d4e89ff"}
1	A6qyvOcKl7SHNw-TehsS4oLmvOnRKWlz4G8HWyd_moU	gen_gateway_v1	{"nonce": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "location": "8c283475d4e89ff"}
1	BKgbE5bhnmgWRUnNDrq7FbI8PGQTRwv5CAn07S6Kp0A	gen_gateway_v1	{"nonce": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "location": "8c283475d4e89ff"}
1	PkHfoutRjCMolH7Ey4ByR20yxQanQw41iWsnQfY7TK0	gen_gateway_v1	{"nonce": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "location": "8c283475d4e89ff"}
1	UOuuGZbqfM4mzIevX4pqqqLULvZo8SNRR8pi77c7FTA	gen_gateway_v1	{"nonce": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "location": "8c283475d4e89ff"}
1	4peQOKTqEykFZxdJzB9o2r5sm5UxN-J_QN05_VL9haU	gen_gateway_v1	{"nonce": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "location": "8c283475d4e89ff"}
1	wgpT-E64NPI7-FCv9V8ZQrY134vosqZglZDL3HzwVRE	gen_gateway_v1	{"nonce": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "location": "8c283475d4e89ff"}
1	nhg0QAzkRzZ33iDjmSkRoaEK2b5OgdILigFxhGrKueQ	gen_gateway_v1	{"nonce": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "location": "8c283475d4e89ff"}
1	xLdMj9AnBjxs6uct0uNXHHIUBilbRJdwuxz2xwaC8ak	coinbase_v1	{"payee": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "amount": 500000000}
1	97nSjwHZovbYknu1PLymxSRIk_YjGy7sVwL31eUw9SI	coinbase_v1	{"payee": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "amount": 500000000}
1	1u4TIdTdpmnPAkizXd5byJ1gfAASEjPqb3vufRq2Lco	coinbase_v1	{"payee": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "amount": 500000000}
1	fWuRS6NAoyGhSxo9yfgEKdu8M94IMjUunxXeb2hZGBA	coinbase_v1	{"payee": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "amount": 500000000}
1	ZshlvU46kD4IYE-EQ9Im4HJfpt9_-Jq_fQDex7U5_bM	coinbase_v1	{"payee": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "amount": 500000000}
1	7zQg-aHpmR41P38TDUH_184TE3J2Zv5nr2BBm78IT54	coinbase_v1	{"payee": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "amount": 500000000}
1	SpKakfACEZH7Unk3krX9jmT20DmtGt_7f9_kV7xvkA8	coinbase_v1	{"payee": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "amount": 500000000}
1	wykmJEA3yYe061MJA7P_ceO8IlTi5NSDM93mToCry3k	coinbase_v1	{"payee": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "amount": 500000000}
1	KyxEpEIpdXswtSZe3O5i2HLTkp6FbCUlt7Auw_-joCg	vars_v1	{"vars": {"dkg_curve": "SS512", "min_score": 0.149999999999999994449, "batch_size": 2500, "beta_decay": 0.000500000000000000010408, "block_time": 5000, "dc_percent": 0.00000000000000000000, "alpha_decay": 0.00700000000000000014572, "poc_version": 8, "block_version": "v1", "max_staleness": 100000, "monthly_reward": 50000000000, "poc_path_limit": 7, "poc_typo_fixes": true, "h3_neighbor_res": 12, "consensus_percent": 0.100000000000000005551, "election_interval": 15, "min_assert_h3_res": 12, "poc_centrality_wt": 0.500000000000000000000, "poc_max_hop_cells": 2000, "poc_v4_parent_res": 11, "vars_commit_delay": 1, "chain_vars_version": 2, "securities_percent": 0.349999999999999977796, "poc_good_bucket_low": -115, "poc_v4_prob_no_rssi": 0.500000000000000000000, "poc_v4_prob_rssi_wt": 0.00000000000000000000, "poc_v4_prob_time_wt": 0.00000000000000000000, "predicate_threshold": 0.949999999999999955591, "h3_max_grid_distance": 120, "poc_good_bucket_high": -80, "poc_v4_prob_bad_rssi": 0.0100000000000000002082, "poc_v4_prob_count_wt": 0.00000000000000000000, "poc_v4_randomness_wt": 0.500000000000000000000, "num_consensus_members": 7, "poc_v4_prob_good_rssi": 1.00000000000000000000, "poc_witnesses_percent": 0.0500000000000000027756, "election_selection_pct": 75, "h3_exclusion_ring_dist": 6, "poc_challenge_interval": 20, "poc_v4_exclusion_cells": 8, "predicate_callback_fun": "version", "predicate_callback_mod": "miner", "poc_challengees_percent": 0.349999999999999977796, "poc_challengers_percent": 0.149999999999999994449, "election_restart_interval": 10, "poc_target_hex_parent_res": 5, "poc_v4_target_score_curve": 5, "election_replacement_slope": 20, "poc_v4_target_prob_edge_wt": 0.00000000000000000000, "election_replacement_factor": 4, "poc_challenge_sync_interval": 30, "poc_v4_target_challenge_age": 300, "poc_v4_target_prob_score_wt": 0.00000000000000000000, "var_gw_inactivity_threshold": 600, "poc_v4_target_exclusion_cells": 6000, "poc_v5_target_prob_randomness_wt": 1.00000000000000000000}, "nonce": 1, "proof": "", "unsets": [], "cancels": [], "key_proof": "MEQCIGa5jo_9Ola_ZoY5SYOVPG31gneV1mhyp_tyhITe6YiBAiBw4jDkIjqZ_DmSKQyt-yaPgeK8Z6xA3BClBc3ASIAHaA", "master_key": "1123s5Larv3wNYJmkh9BaFeQXFyMozYAczKRXqbWxaAt9QVmjRHr", "version_predicate": 0}
3	tWs61cHBl9mYwDRv64SWEoOpk7kp0VzdqQR7TpZwQpQ	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIEdR61hlbbE5GqyCejy-35DI5g9orA5g8ZbzKwrKXIq9AiAhUGGd1nluUFQmqORgDSVy6AEmLk22Y9pHVlX-CeLvng", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "igLReTrmj0waN7s0BxMOxcl_ppW2gj6--zuv3idFYjc", "onion_key_hash": "PmSNpXpGNDRE0r2nrrGF2RX0r_88JEcH_-56lHJEH48"}
3	l-Cury9gMVO8LAR1rPnhKVLjPoMK2PThtVK7xq9VwzU	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIClJFR6_T9_4lfEwgd0sm8TMPdK0KX5h1MAOQEB7j5E-AiEAzFd2_YP5D6bs1hyCFUxeu-Vif5pZNJ4Ib0B53J0MCdI", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "RlXwvwKyVBYauq1C6nXZmYx1GTUAAkIssohLN2sF3ow", "onion_key_hash": "VLxbpc8ytthaiDIMXFODLjYIq2R6pQFedplcVkqOGEU"}
3	ulk91m5i_6VZshbBoNP9I6uJCZRjBBD6McAvkM8YbhE	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIBv22EYSjlYToQLM9itYH_5k4-X-xO_fFfAAWb09o85oAiBlxKEMs9bM28CL4xGtM7loJEmIFCdq6P5DhzB2i6-quw", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "qTLqXt6nY7fQWZdRe6-W8jBOac-CUEhalgnROWyNTI0", "onion_key_hash": "zL2qMcN7rpPQdtO1gJ0zc__phrK6FMl1dztvlMSd0nM"}
3	hMu6PWU0ti1UpjFCthZakZh6-Q9m2RJ-FEMfJPOrAb8	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIHrWhrFt53Pb_3Mysp2_HLXiEjSL_L_Q_-Ctgh3nAZbXAiEAlLGE_LKjnJedtROUOeixc2l7vIUzxFGLHqLjzlqv9Zk", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "O6bzOw_MeVoFGrm6sFf43Mj9evQ3vphKT2f5bbJNb4s", "onion_key_hash": "5nPwxES2mdDZJoK7dCgdDgGcKK9uNSc7aNWnV_MvzAk"}
3	8afSIbXxPI7vx2i4HI80mcnxiVHBDfzLxM5Rgegodxk	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQD9LgiQooUM-HY2oK-BO8cMmA-Hi_Aky2NwGEctyQkwbAIgZ_pIXsjqwrZKLamIdML8-hO9HY2nwrlAs2sE0Yl57IM", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "xcpj7s5LRgHQw1Xs7nf9sIawQ__B7JCxfS2AAjYPXSU", "onion_key_hash": "lbvy1dKm0Yr0QWUcgU1gV3eEBwnJ7JKPvB7fErGqMLg"}
3	ZVpeeU2m23N8j6WVCVgb7CKiFZKquCd4QYub7CQlbKE	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQClnMISWHApDzF73XJXNXmxvmIVOSy0-33-KagRwunfUAIgdiTjI20VKyPFYCvHOZ1LVExqZufU7uFS0zV4gT1VMKw", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "lwNA4RO1qM8NIMEnroSxBwA_izVd9drBMZNC5QqwudU", "onion_key_hash": "Lhd4jEsdVyLmYMU6-imQYpMwMMGBqS4sIofJmqTod8w"}
3	ASKD0S7m0kwAzamGoRrIKxRnHwM6EGVe7t_ZZd4JB1Q	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIE8vVvA2rp0zMrGWo2uDsPkrRaGYZZvc71ibw2yxdAmPAiEA29dIjBLm6GrSGGSseGYlgntifpVz0Z5ojhhz5z1Nvj0", "block_hash": "2wiylxdFo3dDjQ6goJeJmXH3KFXRyQwyNTwFssJblTo", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "Tym-uSJM7J8IPQyBRWcJADbxOIcWwUs960t9fmvcQjI", "onion_key_hash": "r8o9N8H96ZS5lJTUcMBooW4F8V1wBBcUMweXOowrTck"}
16	Wt-4pGmMMJDNTbRUGg64BrHnG7WQvnKaSwOLkU9sVlg	consensus_group_v1	{"delay": 0, "proof": "g1AAAAM0eJzLYWBgYM9gygVSigxNXekBYRoJdX-Ebjy_L73hD_N7fZlwj4S3b5OuCDy_EvMPpMrDwI1JkeHFhumBc5fMltkwN_qoa3vIxn6lPYk-R16_8-G8VxraxTALqGT1p_Pcm227Chhjujfw_dV4ffCacqqy5dOVz8xiPP6-2JwMs7Q2zH35rpcpDM3u6UGP3MMvsRyd-0kx9nzMGiHrX_28vW4gVe4GrkAT35XM4dyld9Xr87lNb9VnBPy45WBgnd_AXjT9glO-UMgcNSaFtAOe6n_EFH2l77075PioSTHV2fOItlynQ_orxeQJYvVhMDs9X6ed2J76-tNHkekZFquCpq_pqZv0wOKHgfwejZ9lUhb1CI-2MVpv19ZMe3Jzzs-f-_QWqou2FfBdnKMYdXpJ2i1OjshVQCVrtEq1WCaVSRoGy17pim85Uu65-sPDXjefDe5LCnXtcnfBLE3Y_7h50e2m0Jvvhf2d5Ouc9zrdPzNboEXu-sqdHMndh7xgHlWoPr72f9m3Vatyjl2Ydvehv0hp1av3K162W75jCNzMvb3uBtDOXdqr_NK02I7tk3TYWm29bGmnyYugZV9ygjbeuFYl17pdEmZnZW_QR48HB9c-crYo3MTGluUUf2Nmfo3rb-P9JT8n3DtZAVLlZuDCpMBvHcQ5yWaGdwhfxCM10SWXjeL_LP2pvqr536c_PDeK35gzKUipnJ31cefaKbufr2aP2doh8914D9sRjSiut6fqxV4Wbf8Ls1Lm1PtP91oXbm0N2STUceqMGHOMq8XtA0eOsaedWfSz68ghuDdTvvc6NzmEzqiyULq1_Pf23TO1FxpYcyU1fwsU3hP863U70Js7y2zt2He_dU5QmZTe21M6b6-ivMoLhhUlLho_jMv51i-E2VnTdjdFZu02Jde221t_Lfg2jdPSK9u8tcfH8_V35p2cq0oR8XlwOf__3lqHTP77e-7UTtXQcbh1stTcbtuifxI5KbfvC18DKmnWEXm7V3F-RW_Yu7fNBhYPHi7-HJvaE_D7YE-QVMaOeTZZAKhIZdU", "height": 15, "members": ["11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"]}
16	42vxoV7seXVoVp0uDFD72EjjHUT_UDOAZ4QMAnfNLus	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}], "end_epoch": 15, "start_epoch": 1}
17	Z2KSm3mFzeColOGjIbt9meIvwNM3NGdaxvw1Bymq9Hk	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDU3qWgNH737fQiVdfJlNkXZ1hmXUN3i-lFmIZ67_ZpJwIhAJFua87IpgWUUJP8D7tM2UWu7WAosuJKBjG0QAKWu774", "block_hash": "8gfj3IvOZuecHoEFgat-DJqbLjzob1Jvn7sFDJPB1jQ", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "ehYJCKsgSSdS6PAsS53UNd0gIdb4YmZH3S2QmfLgGv4", "onion_key_hash": "39cAniZz2tEaYW7ROxMlMOp-U-_aSNAcm1YXVgkX8VE"}
17	C0ywf9ozFvF4zOIeZOVVNA9MJkuqRvJkPYXybul57bA	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCreTmR7ar5ULcHVdUM5UEN6qUTkIafzBxMcVsNxKdwigIgGTR4A0gMBOT_W1DqmLpZcaX5aT9Fk-XTrUdqu7WdPN0", "block_hash": "p1Tlc8mVbhV4AwKiixJ3LX7X3LBsPxF6f6N9SQYgMiw", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "pJZvFiSLiJ9kpb1-GYogeoLoinHAOrpYfQHZxNIutRU", "onion_key_hash": "CSVtZWvhUa1ygSIBQKT2Va495CD9Yit4nmN51lvo404"}
28	f0hvz84ciMOYwZyeXVjnDjH-STz6FtR563Ctdz7Vda4	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIHtmM3y_FAOsQH6d1v3mwS8LZUOOXaECokDVLJdkEntOAiA87bUkDOeSmRw-2e0ZN-_Dy7GWnfOT37mmm12n1-mEmg", "block_hash": "TndgjT7RxBxunxYNuSsWII8sQOUEGgmLiKFRn1X0NWI", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "6wuEy5a8OJ4WRJMrXTaYninQSrStvAvft5N9hIJ1E8Y", "onion_key_hash": "sgt3vtsRwjUDsw0J2KrVIAUA2s25SLZeMDRQU4-5JKg"}
28	3HCnQz2JP6TWtayaqDV2yKzJvtIDBcd2p_fMUl3olmM	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDrqmUidXb768b2-kDRQb_4nRxD1VNNAMOxCUar6MqhYQIhAJ7-UsUUJygW1iwcW3QbYXFJcHZygEp6n4RLkOoX7Tsh", "block_hash": "zpcs5wO5Q3hLSit09y6DLdRCYqJ26ncoZ0zdJZp82vk", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "rpjfNoBU9WZfM0BDsnV2-yuUXzGKHHPbfBGCPXsP0hE", "onion_key_hash": "XOHoOsL5rXzO5UPP_IWe5vSROb_4XQxqgkf1Gu612Iw"}
28	I53l47dnhOjYni5Vy3V-FEEkwL0u8RLaCr_3DW8WvII	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIEMEwKA9CXS9brr_z0nwfWlnFsUU1zjUY8h-akstfeS7AiEAgMROP_vDP50CC-PhBIh2dhFLuJ6BXhkc2KUIaPmPNjg", "block_hash": "g5Di2bofcxRy4jLJ06-oB2RhZjsunP-yWNQI_uvBU7I", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "qT7VLEnsFue2SpgOccL0xrdDphbR373fZOOgV9aiYIo", "onion_key_hash": "ThLUJBNopjGTpIZVweOZw6W6qNPLThd_neFKJzSqS_0"}
28	Pau39MsXjnKBMZPAuPaAzKgOvH3CUZw29-eF8oh4p2A	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDfJ-4ouB3mD3N5_6L0Kyy7NcaiqKoRStNjCILOtDNyigIhAKp9K4ngGPTLP0Byy-9d_xCcNkp_4uVnEeLvdMMmMtxL", "block_hash": "g5Di2bofcxRy4jLJ06-oB2RhZjsunP-yWNQI_uvBU7I", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "oF6kdZlsVZ3auqJayS046w2UVwKhoP3B5sctIv10zCo", "onion_key_hash": "DfbEhgt99VEK7vW04Z6pe_-gq3zAR4HIIt95LBofXY0"}
28	L5sHo3SyfKBGp3dqL8HzE0c2XBpTMxzBpFRnW4MlrIw	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIHWW9bZGC2ARLCb6tjwPp04FI3Egi1Ne9zmrp8Erv5sYAiEA20k33zmTp7PYj8AIk4TaK-O3vQ2XdJmyQUV2D0A2Nfw", "block_hash": "zpcs5wO5Q3hLSit09y6DLdRCYqJ26ncoZ0zdJZp82vk", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "Os2yeKLGcRxh9FfVyZOamJZdnoXjImSyeGd6y6595cQ", "onion_key_hash": "rs8axn7DgdNYMNnkM8tim7gUrxbTyr3wCjq3TS6arss"}
28	nNYc_WptfMk6zAgEMGH6_AmOzYUBHOOP5Fg8waBw5hQ	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIFWiqf9b8UM04d3WnGz1Tb_uIH9nFglk2sl1-zl__vPEAiAszKMXrmuP0KjAwcL9Msx-7RMNUmrMTNZ3s-rZQSuOUQ", "block_hash": "g5Di2bofcxRy4jLJ06-oB2RhZjsunP-yWNQI_uvBU7I", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "Jk7Ym67XxiVQdCQ_l2a9CVOIUT99tD4v7kpJwPxxdkU", "onion_key_hash": "w6JuSKriuSu712DA3y03bRaFXYEvQjMcmIftuHx_J14"}
32	OfcfKoY5jsAUkVM5rgflFs0lP0IUNHqxdy4gPKf82JU	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJW7gSuTIsPD__f-bVKeVnFuke9CE7vHuo6vnuu8lvt_8wyH6v_Le0ufMSk4BryqT58x-Z9lg9MM7suRxZ9CH169y2u0SnXO96VGaZuOw-yUPshpr741zbkgneVHkAz_7386V07c1LCaeWbZniymsKc7EXaudDxpZP5HtJY1zmqx3YF04VvLIzb4b5N7xqRjmbMharUCk4JJ-o3aijWeTxYIPSz0-O6q2s5Tf7NvIvvi1G7GKV3ujUdhdta03U2RWbtNybXt9tZfC75N47T0yjZv7fHxfP2deSfnqlKQKg8DN6Cdq-p-cP4uaz2_b6eT22fvTr7vry9ssjPMX610c2HG6oiAuUAlFzZJy3RMLBPYxOoxu-Sjs1GYtvl6x9vdy1Itth8Mdln3GWZpZW_QR48HB9c-crYo3MTGluUUf2Nmfo3rb-P9JT8n3DtZAVLlZuDCpMCqWXKO--TXCZ8aJi5f-r9t_fLjeuoL-RVnmG1b79rlxt3BpCDz-EebxaKJqRNuHlv54sMHp1ZWE88Zq3OdZCXTRTZfvrULZmVtmPvyXS9TGJrd04MeuYdfYjk695Ni7PmYNULWv_p5e91gYauQXx1xlvFgwFTWI_7H9VReT2UreXbVs-Buz8Zi8ysbP82NAXrz2Msv54AhKiHlVfRfQUr0kdqNz7OCWt_kTWK_w3v_o-RfmJ1NXekBYRoJdX-Ebjy_L73hD_N7fZlwj4S3b5OuCDy_EvMPEba3Y6dGd1nYSAis4slZfnqGg1utn7xG6FZj4_0x5zWdv14CKvlQnPFtVyefQnbDnCCtktbiyPebXaZyXXz4Uc7c6GnNFA2YpZ6v005sT3396aPI9AyLVUHT1_TUTXpg8cNAfo_GzzIpi3q4R2MMtTqTVoXk1HTeWPXLSbXhwc_Jhqv33jgUs2qVnKC-6GagnVP2eEZeOrS5tjTR9xqfwpfpwjEXDz83jGKzDn-v_L0yUjgLAHYiY5M", "height": 31, "members": ["11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
32	wC_FRS797dJ16Wg93Y8pyDfrdIJncDv5GvF-qn6zKbw	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 31, "start_epoch": 17}
36	i4OFqpVSiV4ZnQ-FH_MOEWZ1fUEsf12F7D7G7cou0Fo	oui_v1	{"fee": 0, "oui": 1, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "payer": "1Wh4bh", "addresses": [[47, 112, 50, 112, 47, 49, 49, 120, 67, 90, 113, 111, 120, 82, 120, 50, 77, 56, 113, 74, 109, 110, 82, 80, 65, 116, 121, 55, 88, 100, 116, 65, 78, 117, 120, 75, 120, 50, 111, 122, 68, 109, 110, 97, 111, 115, 74, 74, 110, 104, 88, 116, 97, 122, 80, 121]], "staking_fee": 1, "owner_signature": "MEQCIF7E-Rq53-JyZ6Dbx4wOPe7ZksZrJRJ9DIfCshni6m3AAiA2LG9kysgSa4_EAh9ZgH04BzVyQbhaL5ZenLWHSha1vw", "payer_signature": ""}
37	zcLvrA400BICZ7h4-610t-pjp9WHUuExG8L9CadNapQ	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCgW2YRT-4vXvLqTfAuhbcUalpPsOv60t7_R-iQkHIxdgIhAO3TiqUQwHsxSxjD3AoATcCRi8fKCaK6lhiKwGgnIl8d", "block_hash": "1iTr2pNXl3vq_C3Yyfq0Q80WrX7GX3TMCPi_KjK3G0g", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "Bsy5GXya1n78k_mPh-NybbEL81uZSUOzdsoRU1gRj1Q", "onion_key_hash": "sAx6PxlgqX6U009v3ekocQqRQtr43vVNe9ZXXaUDJN0"}
40	gIzoXYwxjkzgOj1ACZL9SsGiK5Yl2tvC5-1P28tTLZo	blockchain_txn_state_channel_open_v1	{"id": "s7JCJp38kdXRVRNMSclsQeU1kt-Ks_zXPwziXEzYwmI", "fee": 0, "nonce": 1, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "amount": 10, "signature": "MEQCIEJ7hjgrx_LHERZzFy7DiUA7MYVIhXDJtjqcLRde2XDiAiAg3GItErHLFhMC70Iu9-F440TzTesboTtrqd78bPfItw", "expire_within": 20}
44	PVOL142WcccRXo9vRTC8g5CEZLCT_mMQuh-OeYU4p_w	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIEuu22vCEigGYw2yU5EnFTG80ffyQNBP9YrBRDICaWX4AiEAt7DyVj5pTPP5TLZg7YiTmEFKclhddFkIr5EUCs6534Y", "block_hash": "itzuvP-oKJFD7GjIcnn_w6lFwEgTj98kCQ3FOcbx-fI", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "zBfqyrYisuR8ReL69E3aN5Hx5kI5VYGC_ftZmRBLiIM", "onion_key_hash": "2fDdAqEQ9svXLfNevMOu3bRK47uCND7zAFe28p4GVE0"}
48	-P48ZTCDAOhGrkHMQ75mRzLBBGIQ5RBGxKzIm9jaTTs	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMxeJzLYWBgYM9gygVSigyVvUEfPR4cXPvI2aJwExtbllP8jZn5Na6_jfeX_Jxw72QFSJWbgQuTQuIZ6RM8z5Y5Rqa9kY9K3SizTIwpd3nnQZsVabe89Oe9jmRSSOKZK6aqwJW38fTEDXvfiW8ssZKLZvVb-232WlV-40fbDsOslDn1_tO91oVbW0M2CXWcOiPGHONqcfvAkWPsaWcW_ew6cgikysPAjUmR4Y-HRq3v65rIY7b7bkh93fKnbLP9PaPTtveTsu4L7y7i_QNU0jMpYEaPik3QkRJV6dWWe4SOzHi7oGmG5cavjJOX3g_c3A2zNGH_4-ZFt5tCb74X9neSr3Pe63T_zGyBFrnrK3dyJHcf8oL7UzM3oyB1V0P7tt5Dp-Mao73jV2UlX47Lv_CjrsFsaXWVLpNCkOwha84LXtY3Reb1sZdwqmXXzls7tUot1-70AY8DR3hUYVbWtN1NkVm7Tcm17fbWXwu-TeO09Mo2b-3x8Xz9nXkn56pSkCp3A1egJ7qfJB_odd09V01zq7Zg_IZi8_yumxkM3He-HSzObHoeephJgc8y4-v11kkBG8_cnCnkKGbIMVsix4-Jx_hnX6vsfpYt92B21oa5L9_1MoWh2T096JF7-CWWo3M_Kcaej1kjZP2rn7fXDWHnL3ZWx0Nf5l2LiDp1WOv6ZG-bjVm3pro0_3pZHOzq3nMsnEkh7ekR_qV8G59dXn31S1ST3YuJpxksNVMebq_xmbn20hOGWTA7m7rSA8I0Eur-CN14fl96wx_m9_oy4R4Jb98mXRF4fiXmH8xOhbDls3PyVltzbi_wDX15M-CfHeOXUMXzPr0Pl2rpv12l9gvoqk0tn02vX7_Dtoz3Y1hP43Lmg8lZM1Z5FiYk1dtK7Ou12gmz0_N12ontqa8_fRSZnmGxKmj6mp66SQ8sfhjI79H4WSZlUQ-30_z0MvtTs_03tnx9wrnrdvbDm49nqCYuKzVoEfvf__gd40ygnZMzdte-fq2noS0wT32F7btDquLhzNaaHab_40sMb5zxO5oFAPqtY2M", "height": 47, "members": ["11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
48	O-tEtSjVRNUxMBICk2DLUc_MuuufFUr1aYHmhQPdnUM	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 47, "start_epoch": 33}
53	FL2c8RxLwPLV76-8h2LY-IMLVBXQ5iHoiU4UGFqKjtw	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQD4xTdznXCpxZBzh4Ip1Bs-9FeTuwUbDdm7TJYw1qokOwIgIdAjSkKxZgL7jujI0GN1JmNCU_SOzB_TvPW25842t_4", "block_hash": "i0iGvsEfZkUfl8DmoTkvB2eqvEYVhBV257pyJ6gG4yk", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "L7ZfO4MAW-QJSW3XXQzEH_czNNEE-xcychvlQshpG1I", "onion_key_hash": "K3YfgntupgniFQgAUkG3EVQcibDci3cItkNXn7gU4Hs"}
53	T0sKUTKHhr0DSpIHzPm11n7Wnv4yyUXqvWddr3dgyz8	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIAfQPOXxgoJEqWkb2lvnu9aSg1vlVuJlzoZDeRDF-mFAAiEAsLJOybiRTsNph1fJcg49nnR2SmS3W6FD_R9yZ5NcFxA", "block_hash": "9XTo36iNac65TE2hEAMjq347xaKPHNOP6AbalD06Q6Q", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "5RjD4JftQCcroOgPXHVLWhwF_DNdjDe0waJWRs9WUY0", "onion_key_hash": "qO4pZWtFiasTGYMDoSM2vKq_nXqybbSdFSMlcJhqGko"}
53	2cRkt52xNDx6UpgePQ-VcJCJ5Em0_VEjj9qu12lkxTA	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIBgb1lzCLkApKUG-74_-Le0BYdl3Poh2WWtRIhCs3OrqAiEAxrjOEdaxF98fa_DHDjeWaegYNzrVbsJ-U2qWsLXScpI", "block_hash": "9XTo36iNac65TE2hEAMjq347xaKPHNOP6AbalD06Q6Q", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "bxh7Q40fP7PRJoNlyiSz4psKnwak4sFkK_m0tzBQOsY", "onion_key_hash": "clUa7HMrw9wFQvJVI0HSV1TivXT6rTDBWXenUhL4gbA"}
53	IDjre52DnKcadg5s3_kRqk-PpeJgkpREglE4dotYnAI	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCEo2HofaLPEEaQLybv1RC0Cp09Pb5beh63AM0NiyLRpwIhAL2RcVHxroDm6Qg7XgKqmhEo8Y7_SFn5_rlwSQxs7tK_", "block_hash": "9XTo36iNac65TE2hEAMjq347xaKPHNOP6AbalD06Q6Q", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "zxuus-qMrE8yRyjqmsxrKGTDOek0y17q5zaSn3pQTgY", "onion_key_hash": "h1dnKwhJ0qDhdGvfGAvm3EDB--MF0vrtQTU2Rwp7N-Y"}
54	aBoW3jOnDP5brb3m8-kQnb8scK5fo9QrzI0l8A_Kqnk	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQD_GkSfPnSertSj-DIlUNsAGUpdH94yJVfxrpUVPvp45gIhAIQF9p1tAUV2A-_SLzwQDOBtTx-1CHlaSpQZGfWChzDs", "block_hash": "tu7TZcow0_e0wJ-8m53m5i41pXurEyOewZOsbTZPaxQ", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "L3eg-v8HhE4cIrECj0w3DDG2mIIX1Ctfwqqbqec8NBo", "onion_key_hash": "szzR1EYBDy_Cvua9e2tHPVmL7lGJpdw-9gSyL2psTHw"}
61	Qmd4tYPJAF1E5SjLU28fbrj8ivEdwS9xp9euLlphag0	blockchain_txn_state_channel_close_v1	{"closer": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "signature": "MEQCIC2AWWCDbV9hUzRI0DhNnNxchaN7ur_B6JE95smHn6ROAiAFPcNi2ZRbpU5wVzfsq3GIAwPD5Q0Rh-ci_NNVSkVVQg", "state_channel": {"id": "s7JCJp38kdXRVRNMSclsQeU1kt-Ks_zXPwziXEzYwmI", "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "state": "closed", "credits": 8, "balances": [{"address": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "num_bytes": 5}, {"address": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "num_bytes": 2}], "root_hash": "ckuc4kccrKqs_gHauhYzB1SWqA4cctXGGlv-4Mp7mDk", "expire_at_block": 60}}
62	ZQ0W2HT0Q2dTwgHOZjmWL89OmyWB9O6oi4-SF9qlU5s	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIACZgOr0x3I5UlSovL3NjSFL5Sh7N9K-g5Z9UWoDEeKtAiB2-t5ZylxYfoZkD3AXzkxLCLmMe8L5g8g_xkxIMOklqg", "block_hash": "Z0DCOebTgxn4a163vukB1Ph9MhW6vwZTNTNky5-SjRY", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "ow8-mMVb3RQidk_ScZ5KlM_bIbnB3U7FoXy-y7YKniY", "onion_key_hash": "2gRG2U78oetpgnhfZ5spIHyXSpnv93XBMdp2x0OzQzE"}
63	anhiVdSq7K3x6D2M8Z9Ic0LqnNRVZtYbhgECVZNYBBg	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDrxayCVw95uwACXAnmPZN4zPy3Dqpvs9sjRae1L9COGQIhAPKFMSklDtQQ07pTv3LMdeKwHWK3Oh3UiVvxsC10HGgH", "block_hash": "rtZl3rj63yXf3NewI6V3rD2FQlog67PAcCHvAdx5dUk", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "q_Qm08xewhhhfxfSuuk0RlRY_Rw09hkHhCWah32o8Vo", "onion_key_hash": "bV10WyYiclTZsg4e8G-DqCN42nnWvpVT32xs9OsvhlE"}
64	VgS3AJ7eb96D2AegmZP7gmagFJYnrrvxTJeGIlQLj_g	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJW7gSuTIsPPF6wybbdUtuwr4xc9vpA5YWm6U8cR66jHdiHWPcyurGeZFIwie0Mi7rHvKuE299i1sqhzTXO7tUsEl97FAru4rENz8mB21rTdTZFZu03Jte321l8Lvk3jtPTKNm_t8fF8_Z15J-eqUpidCsYzei7t3it1a8ZDfZnWPXVC_NXvI78_1t37NPyxmkK_ahTQVVcV_05_bXjlcOSpJpaN_ksdF-Ywmckt9UgVEPeUOPZqBwfMTumDnPbqW9OcC9JZfgTJ8P_-p3PlxE0Nq5lnlu3JYgp7uhOkys3AhUmBeXvFlt8ZVof_5U0SnTDJS-oAy8eT_WmFt2rP2x73PjJtHpNCoewhrhSLvqLHra1fjrewebWqhKemO32c7j31oOksf614mJWVvUEfPR4cXPvI2aJwExtbllP8jZn5Na6_jfeX_Jxw72QF3Jt6LxZvd5I4cfzIlC3vuffL12odC1okldQSfv7LdVnO8Ldrgd68tu7Rfv6_TDVcMfVr_sxaHZOpaDn9jSlDNPuhlEOPm47pwuysDXNfvutlCkOze3rQI_fwSyxH535SjD0fs0bI-lc_b68bIjqvp-_7NnlTrtftL2zZCw-86vjnLaKhsT1pupC-dtSfSeIZTAqidZ6inh_85ctPz350NlHvadaCri_mwmez3PZLCAl0LG-C2en5Ou3E9tTXnz6KTM-wWBU0fU1P3aQHFj8M5Pdo_CyTsqiH-zNZ9M-tG4ztTx6xZW8-a3Ew697kuJz9DUbbCx9dest58kM00FXHAzV1NeIPvykI4p9yQufL1RK3tOzXbD4v1haYT78cb2MMs7OpKz0gTCOh7o_Qjef3pTf8YX6vLxPukfD2bdIVgedXYv6BVHkYuAFNPCG8NpW3V-mZ-vzW5K1d3gI_doRNFkq1O9GcxvZaq3yyAVDJYflW1xPZckWvQow_Xu9gak7o9WMLDngzyaqNVfLDseOzswDgO1rc", "height": 63, "members": ["11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
64	a-02MPbu1IqWOEfITPXt-O0ZAM1-8gcdH2Griavk5CY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 63, "start_epoch": 49}
75	Pd3YMOgQkCZ35QdlaWehr8lLxwg8P3yW02Ghax_yNWM	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDNssQY4ExxC4rSMZWocKeyuQWfk68omQfpWDjaNF_w8wIgVL6vRM4tYRhoV65w8xd4XcopkQUAwZMTurN1ekUqhrI", "block_hash": "fSn6S-WoW_ae2UuHK8ZqQrh0dGW7r0-ujusCKYemdMM", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "o7n7j3U3-WqQTXnYWFIfOIXEG9y2ZRbB29IhB-RRlog", "onion_key_hash": "0TkgTGsyH3plBjPQabDOwd9AUSaRGthHrlt6RRvAT4M"}
78	BtqUxK49cl6kHNwEss_vfUwYhM-tAWowIKRZSBlJ19s	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIDyLslA_Irp9zvgqoXdNrN_wmWEvw7eWtrGNGBwB8yh7AiEAmPRCgZ3ZCymRnbiUMex86tbQuSLbObTRqJfBhPi-r9o", "block_hash": "PVbJw7CUJWrxI9s3h7IN7a8HZkg8Eygt2YDEBZg1urw", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "2leZReNnubH34J7FUUGfVvyUWr8XSCZqMJGRtapXQIk", "onion_key_hash": "W09RQVpXHAVGuQOMxmz91doAyuN3m_wEV24E4TtEWME"}
78	BLtEfIkXXUYWq5iqULVSIInJMUkINEtB6UFqfzoQpFk	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDsP7pmCd2aJBZ200-QVPTUo1k36GX6Tb3mAKLiwVhUHAIgIwj0ZPNyrPtAADmJib0qKNf_ucqa0y12HRej06CIKoo", "block_hash": "fSn6S-WoW_ae2UuHK8ZqQrh0dGW7r0-ujusCKYemdMM", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "3cwrO8REGQYaQ_DChzjRn1W4UrAoBdQWGr-xqfIXo4g", "onion_key_hash": "5jjxLqPahiseM0BTubOVQnLewtmbXLH6O2h2MFHVfOM"}
78	wXv6vg1l-IXyyRwswN9OBRNxbxTLFRauS40Fi168gjU	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCDn6GPCloZV9wyv2zX_OXyXcKoD9LbEVHTSiCvdl74SwIhAOdK7F7d1Ga69pgNP1ASBJ4wWyo5aNnAzukmrV0eWse6", "block_hash": "PVbJw7CUJWrxI9s3h7IN7a8HZkg8Eygt2YDEBZg1urw", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "3LUfTQoblzG1MKJV_w3wkw_U5gw8M_-zEoiTk0z7huo", "onion_key_hash": "6vGq46m3LiYjUveGb00zRwIvLTcfdDfgJjrsgOXNAco"}
79	ONfcMhDeUHS8kFQ2XejelkrN2Q-wT_j1-gvYsQLCkuk	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCnasrBfmgGU-rJiBvG0Qv6CYcq5-elYAbWHggjYg1uBQIgGtYerxO7jrzyP5YHt7U-ekh75wTYhLUl4VfuXUOgZsA", "block_hash": "PVbJw7CUJWrxI9s3h7IN7a8HZkg8Eygt2YDEBZg1urw", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "gIMXG_P8NDPdFLNpQ3Eg2gE4R-gdmhtUNGz9siLfGWg", "onion_key_hash": "Eo3-ETmzKk3v-NFDL73SLGVFqgT6oDxwy1daRMPk0DE"}
80	oi2F69UBIFvjY2ga1iXagAD65j3Zg6jSAaRAPmIMj3I	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigw1bXdTZNZuU3Jtu73114Jv0zgtvbLNW3t8PF9_Z97JuaoUpMrdwJVJkeHPNGsjj9PasUdmPI8ouOT8fdfxQN7ZwRXnczQXx-1hW3yaSUFv5acNBtezVestypd1Fgbz3p6zwCB7XfSa2Q3zWrkWTp4IszNh_-PmRbebQm--F_Z3kq9z3ut0_8xsgRa56yt3ciR3H_KC2akgvzNQQ1t_i6QJ52weQdX3Bi3lvvd0_omcE-aYdKjE61At0FXfvPw3_VDRVnoifPPMrYcpc1-dnlgfrDzd_VW3YhTzLK8VMDubutIDwjQS6v4I3Xh-X3rDH-b3-jLhHglv3yZdEXh-JeYfSJWbgQuTQsFLp-X_55TIWVj_q5e_V63-IeqL1oed_HMstR5e3uYr95JJIdg94xTHcl4H7e89UovSXOPl2rZtVm2czG745yaTKddVBpiVlb1BHz0eHFz7yNmicBMbW5ZT_I2Z-TWuv433l_yccO9kBdzKTIcne157Hdquf--02u3M3TEnsyJ7_pffeG_moH79l7-4MJNCTOyB-S_jaySTn39kuP9k4cQ_bG4ek84XOe5xfXNons3LIpiVtWHuy3e9TGFodk8PeuQefonl6NxPirHnY9YIWf_q5-11A6nyMHADhtti0eQnYcohWlyW9tek_5Rz3WBe_GpN7cLbE85s-LrTz9AdqGTWySNz5_h8PBhrfHlH29YaE8ZU46VN1w-enrS4aDnDCdlymKUyp95_ute6cGtryCahjlNnxJhjXC1uHzhyjD3tzKKfXUcOISw96i6eJ1XSKfrgaZxdb9n2hLJ5EjIND4s6xWPiz4hqPjgNVHKgt9Tb3tpcUpBJvK6fkat2wsFmbfG5Jwwd30R0nl67OxpmqfRBTnv1rWnOBeksP4Jk-H__07ly4qaG1cwzy_ZkMYU93QlPQ-GB_xdNtI_mYeC6_v4V14Qp03Mzpp7qE16SUMOQMKM3czfQzj0PVtideP35wwdDm3vlk993NLEzft6z0Utdb0mqyd-asz-yAC4BYBs", "height": 79, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
80	eVu2woB4H8u-ixUtcJhuawMO-RxR1wv7ppH6FtXVsp4	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 79, "start_epoch": 65}
84	t5F-2LtdrI0j0l7QT9RAFoOff81Cfu5EKZ5I67QFAHM	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCQriF5eLP6QmfBb6ChQnntWukcPE6zuaANbwNovqDOzAIgR-myRD6JodaJNj6xln_KAfsGjL60jNlhSZVjIvcdtls", "block_hash": "yCL_ciLntK2_mO0ktdJgvbjbrUJQ4c7f_0XsbbfmFI4", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "A2Lvlk_4y8YStu48c4HaZnseEtSmXefw9U5rm6ZFqs0", "onion_key_hash": "_5rLdyyJGGYRbG1K-PlccTaz2SADCxjAdJxuuITQBvM"}
87	8f0J4or-CDaPKfPXZ1HAF3HwbcbXaxWqibJ3rBxUdp0	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQC49_-6iU1-3BK-0pyvde1yP5Q4zVSJ5zYmU4RcfQIRQgIgU5SfYTatRHNhIUAhXuVyLhUy2_Kyd6VsjQGS5B3vFDE", "block_hash": "UPwme8sPZaz5FLGB-tohVjJf7cmkCaWtQ7aKC0KH4uM", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "M03GPS1QejqL0I2RXMyGda_dw4DlmrhDNJ28gjTdHGc", "onion_key_hash": "Q4NwBckRdP1R5Od3LMbeQO0Z1Zmv22PdMKG7bQhkHec"}
88	tqmtNWej7X13ItsIsrdoJjXg-2qZgyo2sbdwZ2DrFxA	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCs8VTW1LrAqJQ2Vum-laF6Bx5JvzmCqOMWSqX6e7ArFQIhAPSvxNP0Dlxb1ayUSNyr29azl8zvKF0vYkiUU4Lc82xD", "block_hash": "bD0IcIishr0H6nWwbb2tnwSyd7_KScpbZtmm3lxnp94", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "2-TYbFUe9SM14WVkiRvxbQfEhiynKMFndKtbZkObjVQ", "onion_key_hash": "qDAGT_O8WMfTwwlSXMp2YognagA2Ge6TWP9bAfV9WNc"}
96	JCnHfou6-T_8ovPrMP6aDJInSZnGqexXpPdmbwFFl60	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJWbgQuTQvyckofqJ_jVvuuu3zFj1Yz21R8yas5lL-2OV-84FyTLGMakkHLnc3Wr0qonN7_ODVQzW5HMqlsWlvpejvlVteWsaUIS0jArK3uDPno8OLj2kbNF4SY2tiyn-Bsz82tcfxvvL_k54d7JCpAqdwNXJkWGTW_--ixlnfjp1lbDmymyZy23T5xZPWdN17yTUf0rQydPdgC66mfDzyzHHq-FxyXOmi8x73_L6HDIS9h04r6-PJOPaV7-MDtlTr3_dK914dbWkE1CHafOiDHHuFrcPnDkGHvamUU_u44cAqnyMHAD2jlr61qbY6c831Tv3CqwZh1P7dobYvP-WX46t4_xQ__aVhcWoJJLomYT_0_nLJoRtXXf7d7S32wvPIOFbiZVRP8veN5ld3olzNKatrspMmu3Kbm23d76a8G3aZyWXtnmrT0-nq-_M-_kXFUKD1t2uRv9WUqT1jb_3_vRXWTL7bMXn7hF_tm7Ij1g_YKNNY9ymBSUvn0w_X9nDpfUt4_z5phqbDXsKv1wV-jcvZpNby7KTIzcDbOyNsx9-a6XKQzN7ulBj9zDL7EcnftJMfZ8zBoh61_9vL1uCH_uDfvNvqnmbsXNvnlZTjpMO0zcjnVG7y3wcJnpn22lo2wBVPL-Lc-haSfWLPPzvmxRGXpY7_Gulx1rcufF9Mz9qJp8WuE_zFLP12kntqe-_vRRZHqGxaqg6Wt66iY9sPhhIL9H42eZlEU9LEIVIrwfVseuU32g5J5au_2t70GJBaI5W9vK6yJNjM_ppJS1g6L8RdD1optuvLET1L8ycqz5KuGns_dORu93B9vET1eur4ZHaFNXekCYRkLdH6Ebz-9Lb_jD_F5fJtwj4e3bpCsCz6_E_IPb6cRzMeXyDkadzjCJR88yrm87sm5Cj-E19pTg6bWnez3tGoB2TvZ4tIitofnC548Fl1cEpb9eOZn9ufrDiX1KPv-jzW083mQBAN27btE", "height": 95, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"]}
129	7XRDdxm1x-ZB8XEZYVnzhK3YSOMAafWMnVOThGcyi4E	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCutPOo1i-gVQsSzLkiK4s5r8RbikbQFLSrzjLOmeu6PQIgXMxnSTVMdbCjtyd2FuXEcxFI-wNx5PdePvpbggBfseE", "block_hash": "7akuFOkhAtr2l_Yc3oQjgH_SpvmejEZApRV-D6M68Ds", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "QkmBv-U4LLg3ES7qmoZr-fRZqUFBXu6TzEMR3OBLO8k", "onion_key_hash": "TDQhdV1CB9kiyN3JdDFeeZiUQpl4X3x5_6QaT_g2FL4"}
96	KNWYr2akEej56FWeCOOGPgjKFNqAIYd7Nqh2jDq91T8	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 95, "start_epoch": 81}
100	xPg_jIhIKQ4pZWzbF0znrEipkMdRQLpCRkR6SkzOcMc	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIGNDZoUQ0zbv_Hnfkv58G_vMXoYoLwtWtDb3086p4PmHAiEAoISWp0NLf2_fevGDoOd6XeLuon8HRN5ZEFi5kjnvZto", "block_hash": "9niavtgBZbHXKoTy8tViNsWCgeRTQuNtA4JlEYSCPlI", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "QD3xdTL6ehmsfLZrq7W_KuhW1zm-fozr5KJAkLVQVTY", "onion_key_hash": "03NKWL96ZEpGUxwJp0-dtkPyLaL46mPqWE-Xnwo8y5U"}
103	2dZAblIvT8OWMdkFzRU8utLKAPeVtQdntAC-ftgOsvY	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDEDDpXuFOKghNreAXdzIxcfQqdSjJTN-F9LjnU_7x_UQIgMhtVHJTUYB82w42P217UvHg_hWSZJDxPQObQ39Z88XI", "block_hash": "7-7bSdF9Kug8x5LOxisQQv6ZOTst9kaRI9_d3CmtUjU", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "6ETyBbdkhQ6F4nkx_Ge6cnaVi9zuCvsFncrZjQjI9RU", "onion_key_hash": "HQeTEoYn6FpXemVUBQTHWBnC0TrL4QEjv-LGI6Bq8AE"}
103	-_q-EGtTjJNIlkE3YEvLVsEaCm6HUseZe-WLNtTy-dk	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCV3K5bPDZYRj7VagDfQHePfD-v6q0o-4odDDs5JA_wtQIgFGwpo2dtIhITR8m_a2edV9CF33x2iVivQDkFURRy14M", "block_hash": "UTJDvZcaxAtgyr5JUI2TB1sMigerTJERgFSB-pRzFsg", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "-OlqoSdxtTSkxQsSaZif_NcqGkjNeRxYFgNxRt98y2I", "onion_key_hash": "VRSvmsZl8CSEOYmhZjNK9FXU5ZpoPRf0po43W_Yv5tY"}
104	QYgtTIWOzXg1cjUm1fkww4EuoXnPPzguC8C9vBTmM5M	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDipnbFpK2oC3yvKej1f-2A0u_vs8l7H56i224YNY74_AIgDMHP75L1qbiQF27dcZxG9EuEVqgIAb5hsUZWHMEY3QI", "block_hash": "SBAoIT3bF7mNAPTahRMIF1E9By9sbPSN3HnPLTXLwco", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "cg0CG5fFvGAyzjH79CXDxa65555h2kgYIn4LldyIyUw", "onion_key_hash": "8RuJpLM8H-_ObUzeAdrMvnzZ8RI8-Uw11C_u6Q3x0-U"}
106	vsaBuQAHKuGfPIMZweu5zlilovrM4bnY0KljK7iApKI	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCJM0MnJFxwr3WoqU1cwDD70zx78yO6hkSPDf_9_GybEgIhAJkX8wjb778I15P5nGqhSv1U1GA5VOfr8rhwhyZV_lkD", "block_hash": "hiAifGOw9qBGfwcIseI9olMNAtUXXwi8SkMECv9_Nso", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "wR4wbrRWG_hCgD7F803pS8xdZCF-tBmeviVhuWViPIs", "onion_key_hash": "76KV6C2e4CJ0a6J0YdheTdLQdKx2zQaVr7fo_kSFCdA"}
111	Z-xB867oU3iUProNwKEQYySv1mvBWXLOyU3YtbUP8mI	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIApGcAQo7Z7mTVe4JCwwmbFlZ4qg7VuT_eW-ZQEMURq7AiAJbm_LZpNLhHev2XRPA1jwul5g7djg4CN3lKdCmwfLbA", "block_hash": "x_mhals1TQsHPtU0fa-nnDFq8icfF28md802OEZPMCE", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "XX3J08pqzsymqRUdbtJnraWfP9N--I_rprUbg1QMCEY", "onion_key_hash": "12EFqmkDYOZ9bpO_WY7U2FntKnQbkrJU3hRQBiB99eA"}
112	aunFqYXt-xCtp1KSOSHFRhSDAbKdOKcH-92mQPnt0x4	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigzSBznt1bemOReks_wIkuH__U_nyombGlYzzyzbk8UU9nQnSJWHgRuTIsMtpYWOKlZnXxqxr3JZuHV70ruvh9YYv60LbjFxXCK_w9AEqORqd9P06q5-ps_dTIYemaYGE16rr3vOVyr746vOHKNwOV2YpZW9QR89Hhxc-8jZonATG1uWU_yNmfk1rr-N95f8nHDvZAXC0r4tRy7_Y3AO4C94uyksMSXpRJHMzpbgqoUakvHW_yfvmwxUcuKz5exD62Rmesvb7n5aUj6j6lj4CQ6t3vtq9X-V8y5-XAuztKkrPSBMI6Huj9CN5_elN_xhfq8vE-6R8PZt0hWB51di_oFUuRu4Ak38cnv642KO7JNb_8842rxHV5Zhoo7X1u6V9y9zhHZ9P3qbm0lB6Zp-taBA6vNwba3Qx9UfOd8_97nIa_6haabs5873HDvdYHZ6vk47sT319aePItMzLFYFTV_TUzfpgcUPA_k9Gj_LpCzqYXYq6J5r-jr94I_lsp5TCzMqTPPOqjS8zFScc62CqTHOT0DnINBVS3fWPziUWM_7slX-m8PF9pOOxcvOO22YvGH_vwi2ltiI2TA7E_Y_bl50uyn05nthfyf5Oue9TvfPzBZokbu-cidHcvchL5AqNwMXJgWp73ebZxZ83nDm6x2_SIkzXgXb5R87zFz26JlNytXtaeu2MymkMS6p6b7N6jbzXIbakwU1sb5LQ-KuPz3u6m9gZMmnpWEJs7I2zH35rpcpDM3u6UGP3MMvsRyd-0kx9nzMGiHrX_28vW5wK1kTj7m_F_z-MkfhdM7_RYF5dt0tYX9MEot6rnFUe51seMWkUBeS6r7qi96F9CNn_RdxcS2MvTVPcvf5OdOm3pZszfkyKRNmZU3b3RSZtduUXNtub_214Ns0TkuvbPPWHh_P19-Zd3KuKoWHbCwn67NOe49NfDI67nu8L_-p3b5kQ60KS1-eKUdq5lqBdGDIfktqOVviEasQrLFPvOJ23ASHL6n8bWYr0nuOr5h1uEkoKgsAsbFhog", "height": 111, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
130	oA-iYPwFDscJ2NBEdkt3o-nWU402MTZVBj5UyOTZ_Yw	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIDGMjdcJ6u5wKHB7BWGUUXiE6V-8GmhCzwm2e1VcMvp0AiEA9tuWJgpA07JpZJBubxIRaD_H45s757ULFolQCk8FQGU", "block_hash": "z09JUT1zmU5MNsId0i82XUeIXReobys5WtNATkBBlDU", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "udWODREaMNnHR-dCfRsl3vMa9RGu0jVtUsv2tIyUvcY", "onion_key_hash": "QJTAKqSrQXawUYBShvpicsyz2-3lJ8k9ut0p2w--Ibo"}
112	JRR_jNohaelyvGK1Rpd01IP_43PVNn9AinvJAjvCfRg	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 111, "start_epoch": 97}
113	PjvOdsmRXHLj0-VDC-Munv8nZ-1VxHyMSJJQJNEUL9U	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCID9EcN9LLKpgf5CeRt8kakYilA8NaZWmsuZbjWagP3MhAiEAnvnTrToRqOrvcm8-x2QzG2qcn-T3nxKE2RMf3xLEKVE", "block_hash": "x_mhals1TQsHPtU0fa-nnDFq8icfF28md802OEZPMCE", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "P5Y7caqKb6X60OX5mP5YoSyrf8dITE14MmGsU4VSvWs", "onion_key_hash": "_8ODYN1jsVzzXwGtKBSuX6YsF0mxbAd1965dMGnZVjY"}
113	Y7J_UdPONnlV7HZL7TYgsIz1Xw1ou_z8ub1AuhMvjmg	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIGzFe1YfsYWs0QN9HIB4ntZx4JWGMq065T_Q8tGiKvGTAiBt49yoNmkj8hC8Pr0IBmBQ_8HCvisuJkkcH1pxvyQdMQ", "block_hash": "x_mhals1TQsHPtU0fa-nnDFq8icfF28md802OEZPMCE", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "K0AlmPMZEYj75Jw69nsst-ofxGuLeHo3VobITzIXh3Y", "onion_key_hash": "mJI8IhMlKDU8mACS1wjANn0I_1PHkvmP3e16gbdVTdo"}
125	zmpdbm8NjPtTa3bRV2veJecOijJh_pCmF5uWFXV4Dus	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCUlItnYHjQ1lIn6IH_KkUaUfXNP-C1B0pikYqwCUdMrAIhAJ-ZyiyCBigC-8NI--ROAwmDyFRq7ik7u2js6gAMmEKL", "block_hash": "XebxHIlk0FyfV9jwouekC9-e-AfxbHX7xvECwRavuLU", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "EeppOKGDLwJYs_1Bz3jrc3Kwxpb6n10W638Bh_t90z4", "onion_key_hash": "7RI4PL2RnUkHzApdDt9pry2K9Mv5RcWIF9yVsS4QumU"}
128	FdfA6sGQ03Xl8JoM4w1Wn_SzuvnoFh4oBSZa4DtQb08	consensus_group_v1	{"delay": 0, "proof": "g1AAAAM0eJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJW7gSuTIsPqD8xRbzTcHhlub9qs9fzm2a9W-XuqFmyboZtfd_RDToo9k0JkV_FO1Ru6H9UO6n4u4dt_U_89P8_0P2l7lE_Yep8M21QOs1P6IKe9-tY054J0lh9BMvy__-lcOXFTw2rmmWV7spjCnu4EqXIzcGFSEFyvlLg5ZM7fY58ul8lUnAvPPuQlc2C-uv39A7bTklQyVZkUFJ141JndZrNpffY6tcvzz6t_dn6b1_Y19Rxi2iH_12ZxHMxKmVPvP91rXbi1NWSTUMepM2LMMa4Wtw8cOcaedmbRz64jh0CqPAzcgN6c1Zdak2suv6f55AxTnquKXw9MmeC7xKJ9xRvFp8v-6K-eAFSy6pFz0gnfPw8atTOTJv-a0B3oGW7V7bDhtmJ14mHNdwsdYJbWhrkv3_UyhaHZPT3okXv4JZajcz8pxp6PWSNk_auft9cNYemV_Yzmq-rzrP7878qaESIXnG4W77UnOr7r_32NxaLyJdeBSuakaPHMTZ77MHfy9ZPlvKZr-Tc68G7btvFHy9wXC_fnPaiBWVrTdjdFZu02Jde221t_Lfg2jdPSK9u8tcfH8_V35p2cq0oRlk589-LkrPeCGzYEKWv-WTdT_X6c6X22aUdPerw8FXDCNdUHqGR-7CTJmKw0abt1N92lmCq5ewvvH17AVi_iw7PynIqY0yWYpU1d6QFhGgl1f4RuPL8vveEP83t9mXCPhLdvk64IPL8S8w-WihS4Z2tozL_TcvzniQa_1Yfy6ktKoxasZLeYGmO4Re-FhNMfUATkFGu1HLOedfrQuotTqu8KRz0z4D9S_WVNiEHO-ofLX9XC7KzsDfro8eDg2kfOFoWb2NiynOJvzMyvcf1tvL_k54R7JysQKfe79KWTrKun8Sr0RVbdsPoew1o8aZGJyLRVx-X_VJg9_s_LpGDlLLo_zvV_ysrVC7pt3HeZ5T0I_pB-_kjSlZDJzx5evbs1CwADnWeu", "height": 127, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
128	SmUbuMLU0Dq1NyjOgiY10IeI4q7csB_J_NVNgtD-RiM	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 127, "start_epoch": 113}
129	7gsHhqNWfMdY0WGlgKhd--8vVhWOaRy5Kaj61JvmxpE	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCVBGkv0AxJvEgaYmgERasIQA3Mq2Uios1R9u9POZJsmgIgNVG7h0qJst3tI_OLqATNnjOm8dPQ0ZMhhyrCLR1FASg", "block_hash": "7akuFOkhAtr2l_Yc3oQjgH_SpvmejEZApRV-D6M68Ds", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "umjAuNg08Ws4xOQQR5K0zRHBi2nqD_sOrz5RcNIP_gE", "onion_key_hash": "EGSzbKT_pwxi8t4s8unt4tg4wN2TEQk5xj8oFgmW9rA"}
136	ofodN7IukdeXY0IHCmp0BdR4LJK61QnyRuXInydjrRo	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDqiCsYjS4SSQVRTeO0pG0_Uy7DK11ALs7x09b213UgkwIhAOigrXrbt0oQiRCMx4f48ZFBsQxI0oF4c7T1oi5sE8Nw", "block_hash": "XZsVkPmLZpvKhnPjsULgxGvDZ5p1_nVmmW0T6UwTVhg", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "xI78CVBrFrDbANw3RVEJ9PUef8Zv98sRDHDfXcW7c4Y", "onion_key_hash": "ZpirIepO5sUxeAg6GlYrDV3h6knPvWy5RWKxYaj-SS4"}
137	WS0P7fvwSnLdj8_tlhTPv7li3vj8YXJHTkwH3dERfZ0	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC9utudYL8Yt22VdYzPlzdoVsjiz7ofN7-JNFKdYyqnmgIhAIC-tTjWzKbdaoBXSYFWJb4G159DFDyckjBgjGKGXh4-", "block_hash": "S4OZFsjjVDSOHQUCbvR_HnbViL_Km2GFI2lLb2SWEGE", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "GRoyEs5dy760eZPDsvja5w0rjmIx6S4bf-BB-ZDCH-U", "onion_key_hash": "Cp1GmEe5wSc-fHuifg1ND9RDUDq5y7zs-QgvBNx14Ng"}
138	nIpof3MAtwwIkAfh4arcO3yqzG30CcR6YP8JwHSkUDU	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDPE2XCrTX8aNjX2kmGC5EXe14U8lRPjE2xILMDz2_CdgIhAPWaVJj1VAaDl28iDSAa_g2OxOxoiVfSFQGEOPttTIQj", "block_hash": "S4OZFsjjVDSOHQUCbvR_HnbViL_Km2GFI2lLb2SWEGE", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "v64yKcoGi8l93-r1_hgfXT8zriKWE9DB_rGwduzb7yI", "onion_key_hash": "KQeEhNZKmM1WII-L1XxXEiDJZliFiI8zEx-NeMTLoXM"}
139	HRailuqbGnrlq7a43z64izHAa0Aide6_Pbw1PtN8tMI	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIECboQedEhuMSnI6Us_ruzDFMwNWAWEK0w7ZC6nhwrizAiEA9vheAiCmKOoMZw9xF5cy5HG4VJTJzN0TMhVh7XiEp14", "block_hash": "fTZs2PvYbYsKeG3D1OdrKiz2m-IXQX44_cCdhmlBOe4", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "AUulKN5K2UZK9n-uLJ_BeJsl45h9z8OO25wgNUR3qxY", "onion_key_hash": "-YuF6IVzwxUdReNbyXVS2WuieUnGlNkuLyCrS_Us5wU"}
144	t0zjRltCJtR-JonN0PVCEuVWvpLHINuLgV2Ps_x3peE	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJW7gSuTIsMHttWhsn87lfrsPSyXr6p-8YGrwYzL7VlPx7twK_ePvtVMCnYnYoXfXVkjzdIYVmqTNcPmgfCypc075K99OyfUaDozxhBmZ03b3RSZtduUXNtub_214Ns0TkuvbPPWHh_P19-Zd3KuKoXZqaCv7JbGtdi278nn2oaHTepT43t2ZQWqzontqnXh3PHWLA_oqo9HjFRtk_Or1sjcS7pQZ_Q9r6ZvZ2LDRbuJ33U-TzaaJQezs7I36KPHg4NrHzlbFG5iY8tyir8xM7_G9bfx_pKfE-6drACp8jBwA5p4yj46wLle9-m0hKW5epZar1m2TBc882mDTN_MlcyLFrvtBipp2XmN--jrvRt66oXOdahemr2A20M-ZcuNac5nX_6c9F5EBWap5-u0E9tTX3_6KDI9w2JV0PQ1PXWTHlj8MJDfo_GzTMqiHhG4t6QEgya67Wq47uVrO0eZ896RLa-31HtfmNw215Cp7-h2fSaF6D-hG789T35-8r25f96Jjw5L-Hfse9rU6rVnqvZRuQ7RHJidTV3pAWEaCXV_hG48vy-94Q_ze32ZcI-Et2-Trgg8vxLzD6TKzcCFSaFw13Fz35LQWbG5HyV-yMwwfezg-qYqtJ7lv8sBxWebDmYxKXgKvb5yrrlki3fFz0zei4c4pZo38Ce_Dvrrf-XMmk-Pe_VhVtaGuS_f9TKFodk9PeiRe_gllqNzPynGno9ZI2T9q5-31w1upbuNsdN5oXfLebM-Lsso-B8z2_edySWerad7FX2c6gwzRJgU4p88iH3JkBDq97739535T8xyOt2Ltns-mPrjrmraDQuzTJiVMqfef7rXunBra8gmoY5TZ8SYY1wtbh84cow97cyin11HDiGi88f_s_phe-SnRjxgO7xGxO_p4Y2y7XGpP_p3Cq15t0GIkwuoZMbKkkeTHHSmv5hYmbby_G6be5b_eCIy9YoXiD7UzLyncj4LAAE8Z-U", "height": 143, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"]}
144	R3L97JF-sFJP0HLtZNcLMs5FZdx_LG09d1bOjPLlZtY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 143, "start_epoch": 129}
150	j6ewiwNaS1rmGzKbI9tczLLK6aLiMwBjg1s4UOZp6jA	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCICYIpEzDV0Dqz09vR6gB6i9aDsqTg88Ec7VkfaaKwRb4AiEAgcSeFyYqqO0LmjbpuO4a2JJ3z3ZxL59r6I0SvKX64IQ", "block_hash": "BcVA_yTG1ws5Vrp2fbM_-hqxIqm5XQRDFKB87r6z-tM", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "qP8Z9UoBFlp_PlcwKf0Z33xve15bXNtFFDP1eiQDhw8", "onion_key_hash": "PWREx2ujBKGIZIcimXWzQRILwYdluRFaxcszwG0RcaU"}
154	F0p5JznlhNi9qeutIqjb89wyf-XHCQdxjSu-VWmY55s	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCyk3z5YefE3_dsJ_sn3qv_Vyt240G03AnZHp14zWYrCwIgCufmlolWadeJftrGLiDqCnZ3AuprKpoQgP1t2E7dH7M", "block_hash": "Ve2L-lKfLVubSfjh3MnEhy9A2KBhR4MGUdj0xkU9HvA", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "2O-D-OuKXjfD2uYQyc8QtwidiKfgZymKCLtckTU_UhY", "onion_key_hash": "GpcfBgex5VitlKl65qKEN9ShFWq3F0tzo18YRIMBX0U"}
154	ISRhUgE67AYVGm7j2TWYN10EjyKOX-H5MWpJc8QS-B0	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQD5WTEMXLY7UzBg3ewmFO-LER24M68a_Zr7TNHmYUoGYwIhAKdCTH6qvpOCitg4PPouc2NV-b5Cfga8JYVlfn0DK0tf", "block_hash": "DBQXX7_4HhwU-hTCk_yMxRh_U7gXmPtWFXxtEqpd01I", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "0-o9uYAl5tmkls_4_0wbcBCZHbGnAJLssKwFq8cb-gM", "onion_key_hash": "NAsklXuL44Cog5NOvml_8hGNhukAEe1j7KqaqoiT_cQ"}
158	HrWg-LktG0AxR1EcOttlQ6zd3nAES2lz0Q_axfrmZWI	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIBF2-zh9Ytlxgfe-qfabNr3HLGoKW_Kwle7kF8atkzRYAiAWMvDOXyGAMkwf5OLQhkgoPn8ZG-EoRbu5MfPfXHZ5ow", "block_hash": "hqhBkF9AL0NQVMbBaWuVmn5Otv5aHVi6we8xAD40Xbg", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "oYwQllqdlMU_krBHMhcougeDkbgKxw_dpZQ5EX5311M", "onion_key_hash": "5XvNJKch3cruuboOoJ_cwVGvSk5DewxzyHADHV0ceSs"}
160	WCpyAY0eOkdp56hTp-_MPSkPyn0q6xAFjoBN_7ZXBNk	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigwyp95_ute6cGtryCahjlNnxJhjXC1uHzhyjD3tzKKfXUcOgVR5GLgxKTLsbdWOn3H267aqLm4fH94ZOzb-cy77OuFoskO2r8l3g2uTgEp2R30--V6qqkYjprZse6Weth3L-tn3VeLOvZqV4xezIPcjzNKmrvSAMI2Euj9CN57fl97wh_m9vky4R8Lbt0lXBJ5fifmHsPTHusV5NiIXtKWbNFp-itU_kGcXNaorn_NnCkOI-EeWVyBL1369E5axZ_cy3U0X_1b9tPvySPrrN82I6ov7F26YyeckcwJmaU3b3RSZtduUXNtub_214Ns0TkuvbPPWHh_P19-Zd3KuKkVY-q7i6nR-_wcpx28kHOQVUSzya5W_ZafuwPhI_8CxGyIsIUAlKzb6W7Pkrs37K3PqqXJU3GdWfhPj580SvsqLrrLaX_jxBmZpZW_QR48HB9c-crYo3MTGluUUf2Nmfo3rb-P9JT8n3DtZAVLlbuDKpFC9-PfcRfvt5fe2uPWnfX7-9_jPuYVZL1-2W63gTq55azUTaOf62bdfWKxU33PA2J_VT1ad41Sy5Y3Vi4Rut5smvo17sy0cZmdtmPvyXS9TGJrd04MeuYdfYjk695Ni7PmYNULWv_p5e91AqtwMXJgUwoqOmu9RmKMk1G886aJ7vAnXpTkH7fgXVPhfKUl7cTlWkklBs0_iVfNMxSeHDxfK5c55ruczf_H1Kz_mbAzLZtz_b-ePxzArpQ9y2qtvTXMuSGf5ESTD__ufzpUTNzWsZp5ZtieLKezpTriVJXWmGsc03u3hzzhvu3vt20OzeG_vLuP65Jp4b-GhrI1zdzEp5K2tnbnuzUvWsqZ9_3UFomtbnb4cU1zY5jSjbIWESsEqEZiVCfsfNy-63RR6872wv5N8nfNep_tnZgu0yF1fuZMjufuQFzxkmf19tTaXMJUn1SZzH3kf4_fiZc_vsDPurI8kyr6If1Z8CAzZX29WmwbxNGv7CodmTp4-r9Fw5-SVB__rOT1UmKdd1rnwSRYAZTpndA", "height": 159, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
160	kjROCjvak3oz3maP9cKBWo897xLkxXpzi3dimCyETVY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 159, "start_epoch": 145}
162	EpJyohD1gKpQ8q5Bm74MVtvZxTGGfnRVWNg2qMclML8	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIFeHK0U3ahpGadAXbOUZM5IxAXks70zfm39RR91B9ceyAiEAoBR6V0neBbA0Id2hBAfzYKkXId3kGRd_yjrVPAaK5uc", "block_hash": "5fTfAP4FxiAOu8C6xgZ8cjZ0bK0P81959EanT0oQyh4", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "2fUJTIYii3a2nA_DNgh6bvHqfSHZM3cg_MSbd8cCJyo", "onion_key_hash": "L4K9YOjE5jBOl9VMSguXmCvkqiQ9i2HQXnYV4ddXtFA"}
162	IBdF2g2n9VcxnrB29rcI_iVOIfB1sXUCb9vUFnnX8Zw	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCPWLWc3LSZylacubftB4Ga5zTPfk75awDUop-XSnH3kQIgW8svrfck7ZJKC0euiefqyKle7JvdwhOA4W5NUTD489U", "block_hash": "FO6u-jcy4Iqmatgu17maHsced4MYSCLFRzJktt9dNz4", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "O1qkRNM91_KuskReZjfzPhu7RmvHGQZgNb1WH4FT6rY", "onion_key_hash": "uzZQJkdGMVWBKjjjHY3fFe_myRx6Z0Yzlr76j42AkEY"}
165	e69qoLZiYeZS-1dXjUROzOKRytDmeTxBs8rBy7WPq2Q	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQC-ipKeotg0Ou8-IHkTSPcPaEFNH8Jh49J-HCCcYMXnhAIgZ0igrgV0XZhUIB6xjhRbt4ia3hBwis7gkkPXBJVsszk", "block_hash": "Njp9GBOHP3A2wicZWjEVleHJxPQm8PD0TVuLam4_YHA", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "u69IZhBTTEwzZKxDsOZzlz9nsBXIo1gGpoSeH_SWRHE", "onion_key_hash": "F9fJoHJgtG7mOEdNzm7jS6TmchpCHWxUm2CCeOtu_7k"}
165	piQXdRW9qbxEVoNmPxwtAkanRRucTGCbg5c_VwmEO9k	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDJsO-m7cX3tHzEfsH2voVXmiv5B3qVqzvHxeAW5PcFdAIgE5YZRprgAIAQzApCk6zN3HyIp1aS7pc0l-Gqz6Io5yU", "block_hash": "Njp9GBOHP3A2wicZWjEVleHJxPQm8PD0TVuLam4_YHA", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "5M2FGEnfxBfgxj28T953bdqGg8u34GLGqC0YHfOLU2E", "onion_key_hash": "uzHT4WCGZH7jyU7_tGjOBEwiOnZFoFJbqBLtqUWeoSY"}
175	k49F_B8FCaIrrMa7TrdNe5lSzCKLDF2lFykHigDCwMo	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC1RkJNp0OolsCXx4ZIiC8EcEnprHJrCd7ELcQPRnFeVwIhAMSsi8jz46fzcIQgegW14E5pBgpFrjgfALZWZmqAKerW", "block_hash": "jesv01eTDYxAxLGHpfObJGvw2yBZ_ljCc0Ce0zscNbk", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "hxcM42RMP9O5WmYw72U2d1lP2NpEXuisCHPxBtPOofA", "onion_key_hash": "KipGxq4gr0rR7Y6nIGnT4k-7O_sM4G5OdeVLaexJkbQ"}
225	9qGjntiPyjwiLPQCe8J1Q9urAQBHD-WKJfceowHmh8Q	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCSizmrTb76CsUUIpkcqZUfCDMDjjRgnV7teI8gvqHxEQIhAOIE8p5QVM0h1-W8-Osp6keeyB6YNucss2if179WSjAa", "block_hash": "pRLrNtW-G1GozzMT4YoK1f1mK6pUhUOx28ca-TVTOmo", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "jPRRAAIi26B5AMJEXYLzCzAmPEZwRwo8UDCREiFdmMc", "onion_key_hash": "vE7IA03d4ek0zuoXVo5vgvSCyqPDo-9MdjLdKfpTooo"}
176	ufElQ7IkMUutalLmP1C-s8adUcXwMWCsXS2ZPiecVkk	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigyVvUEfPR4cXPvI2aJwExtbllP8jZn5Na6_jfeX_Jxw72QFSJW7gSuTIkPDpc45CSYfz-9ptDpyhtXqSYhE6rcNVb_e2Har5v-W4xNlUog4lL1oT78J66dipo8hotJiOwWTfn-3TSyOcj3-d_3ihjSYnZ6v005sT3396aPI9AyLVUHT1_TUTXpg8cNAfo_GzzIpi3qQKg8DN6Cdl5QDHSpixG4ZhO4zEzD47OirpyMxSYkxgUttbraq1Us-oJKvt1gjGLSlAk_F_m1gXjbTQu3dodNpBYolMUeX3HyVXPYAZmlN290UmbXblFzbbm_9teDbNE5Lr2zz1h4fz9ffmXdyripFWPr_y666tz5cHX4TZSafMF3xzu3KjUXzPj__WHXr1VqVpeUzgEru-nmwlqYF33kQyq4s0J-os9Va85H_Zw0tZ461a5ZrsHDCLG3qSg8I00io-yN04_l96Q1_mN_ry4R7JLx9m3RF4PmVmH-w0FUofvforohiAGNgRAl_6rXbdrtvX-Xut5ptXmC0VVvKMSMTaOeknNS8pytyn0hX5ko97I3dVCV0RL97_xsThlVZ_-_sO7MbZmdtmPvyXS9TGJrd04MeuYdfYjk695Ni7PmYNULWv_p5e90QMfp5xdPfLsZXUiUmPWDiOW1-z9E9X9Fmuej_618dpPL-JfxiUtDLebhHKV7g_xFVm9t3TJet0DKewjPN3U8y2v7XAskfB11gdibsf9y86HZT6M33wv5O8nXOe53un5kt0CJ3feVOjuTuQ14gVW4GLkwKcbu9Pu1WjnOMm2xiyml4YMbpIgvJO9delJzY8mt2QccKeyYFBd6D9ZnuXB0n6_m__vsguiRhcmrntm82NjU3Usy_sgmfgFkpc-r9p3utC7e2hmwS6jh1Row5xtXi9oEjx9jTziz62XXkENzK3ElL75jeP-AofUpVsWV6isT_vOedu8Lfrjzxabn2j_zcfUwK8ZxJnoHCszW3OkwIdki9de-diYrKyrnSUpsCuo3i2RvfZQEAQw1eDw", "height": 175, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"]}
176	WeRMw-4tMIebuko27FV1L_qPO_TQKielXRl_72JpGAM	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 175, "start_epoch": 161}
179	lXNmHeOisKc8o0E481FhPxBHCXF9ybOaSMk-JfiogBI	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIFkD3NCq98kHmH6SeDx0T84zlPZ-IsClzvPo6attNHFbAiEA8ZhtsNzwoa9hQcGxwEuCOl5XzapvdrI7NHXJPunvhdY", "block_hash": "1uJ_1TrFoZGnRNux2Ukw95R6jEONdyMrFX9szVNazyQ", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "cbL3vc3HjeqL9oMxz72qSbQ5USMAAx9qDElXwJ6c90s", "onion_key_hash": "VJ0NisN97eeYwzykBfDq7e5QmYJBs-_swoNn3QSDKso"}
179	eDsy1T2iMtRU1NLJuf01UA0kzxSfC9qkqaV7NM6r_d8	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIEvgsBrWvHbs-6M0k_5EXfPjPIxbVr7kpvryjJWrv43BAiATlbRMrZGIPcDBG5Kr9CKa1E52S65i7djdbxS1SQ9YPA", "block_hash": "U-PMyWNRgKwWpNNZKXyXV7JxeNvNnQzPGY-zS5czy5E", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "20d7GtneCMkr8OIL7Z21MVeV8r2AV6aZ835qPBRvgdo", "onion_key_hash": "mM2cEjEMN8_U7Zwcytp4DMp5ITSfD_mbWP0r4GKMWrE"}
183	TGTiCNqCC6lY81c9Ee2rYipu_R72FyVLPH5CWzO8y4Y	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCGBI-9pweLbIRU-5nMu0CBkR7f22Z0gPN0RRO7qkT9wwIhALXUPa1nDPF62U-kaghXaMfWsn-2MtaxSBcKcocO2dcM", "block_hash": "NYF_xeQWDWWCEe-6FIkkhWj9vxfr036IBdfCEvclOPM", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "SAGRku-HV0a0wDsGWkiVOSJ1upY3y0qPGSq-UMjBtSU", "onion_key_hash": "yIeHml9i_xs76a29FpYnYMeph1uwz8rf7oA6sQ7XckQ"}
187	pWpw8uy1wOT09mtl1ioqD5wynsfelxudMrFfw-fN_TQ	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDmcr9eQoHEmZdRKLYj14c1RZ1piY1ycEH6C1c0xr8XLAIhAKvUU8P5mcnA5t-TwETWXWwac969Ogj-DHZ5dhl0Mh_T", "block_hash": "CqtTWadsp9_LKVuDXzKW6nY8dHXNI6jo5nqEbAwuM2k", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "XhJHfX79HFwfyIFl6b3H6lIhBEKv7vYPDVk_OpNjFlU", "onion_key_hash": "Krrafb_1smIprhU21I60AUJex4W0GI6ZaNmFzOrCPeQ"}
188	lMfAuzi_rJBZnSI5_qksMNWJZ81oIrgHdBJzlP9GP3I	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIAoieZ-ayW9jF7ZmPzmi5U6Lw_OYHlNCuHobWqdBIZkFAiBEV57FUsXu3IW9R-jsIsbf7kVdKZoKU9bPQJlWB1fHgA", "block_hash": "vMFa1MaSDj7yu6_Ov4uUEls3jTx2E61FGNK5f1lsns0", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "lxCOf_Efs6HTXEe2UHRRzP32DvD8hl_Ne-ykS9yL1bY", "onion_key_hash": "YO5ARcIfaVjmrrlWiCB7imATqaJvzy91MZNpyIB-aCY"}
192	rp3m-oKX9VwdzyZUEsiCoT0RO90gkK0CLUIWyA3Ovek	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigy1Ye7Ld71MYWh2Tw965B5-ieXo3E-Ksedj1ghZ_-rn7XUDqXI3cGVSZJihcr_x9EHRy88tC3Q-VZ3kydk3zdhH_u0S9b3lC8yT2M4zKRROkL29nvlSyAHpdWa2bAt3LVZdmLXZxHKF_VTDJ82ZJQwwO2va7qbIrN2m5Np2e-uvBd-mcVp6ZZu39vh4vv7OvJNzVSnCzjNz1fVtOgQsj79kmGD0aUXcps3XHUr_zDQ-ZPRh2jIZwzgmhaxd1Up2KyYtFq1Pv2AeOHki_9d17IruCVzTHB12LHRLdobZ6fk67cT21NefPopMz7BYFTR9TU_dpAcWPwzk92j8LJOyqIfZqWB7PqHfgnOamuo1601pXf-TTNlStqmsTi9oidb8eUZu-jegq9r8-re1ZL6Y4vXzY-ILvh9edTVhCj7-K75cnBIaekJw00SYnQn7Hzcvut0UevO9sL-TfJ3zXqf7Z2YLtMhdX7mTI7n7kBfcTkPTCXc3yh0KFpws_7ol4OzzhITqFGmvYFb5IInVqsxOvEA7N-4TZUrbzdcpvyFmnVZpR50jg8wDG9uVd1YHfmsUTOtcCrOzsjfoo8eDg2sfOVsUbmJjy3KKvzEzv8b1t_H-kp8T7p2sAKnyMHADmrje3319aP_z3jdWB1556853XldgyPp910T1DRx55ppZS58DlXx3US1weJvMHOM68dbJBRWcTiuu9tkJfRV6wSGyr_Dpwl6YpU1d6QFhGgl1f4RuPL8vveEP83t9mXCPhLdvk64IPL8S8w9h6YGGlUJTWtjyZb5umuMybeavTfx7azUOy90V0zssFFfHlw1U8lUv4pPol5z1ubOY5q6f07Zy4ZsS98n6ZTd_9s_6dFs4bQfMUumDnPbqW9OcC9JZfgTJ8P_-p3PlxE0Nq5lnlu3JYgp7uhOkys3AhUlBx-XrHDHniF63BJ9Xl9l3ZR5h5BaY2RTu-uiRoemzMxPfMylE3_Kql3WZZl_6-cX7LYsnKJedf_Wm3uTQnayIa4Zro3w8sgD9r1gO", "height": 191, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
192	-3VKDev0jYo9fLzOgEf22_WqRwoXwN-VVW6hvGa34V4	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 191, "start_epoch": 177}
194	wAv9vDCo54z8BUvr579NGQGLFRvJSth8D7L20Z-JBoc	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQC5lINPylnx2phb9Kq-UxUCghbO3JO1JYUZkVjDhhtguwIgcbKlyDVzTDrbjlNdZjinLPUmG2x2SfAFHWjvjy0yFjo", "block_hash": "WEKkFoYOx-rNFII9LxRdcswju0-fpe7UPwLszYljlXI", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "ZekXrLw9ddafPPGo531dSUcIcObgte8OZx7I-iP9HgU", "onion_key_hash": "vCaj3nxkrgA9cdim7BkRopQcfurUgG8zixUG5aGziWA"}
194	joA7XtuiiwcktJDbHoexZKXdXO7D71Th4x7IWFzCaks	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIDrGH_CY0hd8ERVcQOetNhWcV3JWH0z8FRX8Rhr2Q_yGAiEAiIvh8Padtve_DjyyfKf9IJwLh21nyIG6pzlze9l2-Kg", "block_hash": "WEKkFoYOx-rNFII9LxRdcswju0-fpe7UPwLszYljlXI", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "pRLJN1vwBfwGDs0C8eAXusRdLgBSlEsPJtNabBymfTo", "onion_key_hash": "I6oHLpmMCNdxm-oQDPRn1yWUcVoNCUKuG4-HuI_UCAQ"}
200	jt9G-U38D0uJ_JM8VT-jr74NuX3iGiE_1vXxfRc_HM4	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC5oNyYGNUSmAHb7GPtzr1LTM0Pkt5WkJAqv-JArBTKFwIhANb3FcWF_uIybeM28spIRwsHoXlgc4aITpWMeN4etquh", "block_hash": "BKBkNa07Zfl7huGmC-C6Kakef-I5Ey5ZsNb1fwD3VVI", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "jyBOLhweGeJDBpyn40mSPDaPCPI0lQMdI1M56xDfupY", "onion_key_hash": "XSI-KEtnZ1qiuy2bMOht6JsvuXTwRg2TLiZ2TGUaetU"}
204	PyPhMkp43mgwBlA_F0GMqSdyseDKghvBJCeLcIUD8yE	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQC36dWEM3qqxUM_OQ4ArJeiCpcuvmDouwuJeCZJHA9jjwIgSURhaF7BhgZfGo10h3nkj0aRuspqyJwh9xXc9RlNdtk", "block_hash": "GmNtaMFltTwzPGNM-snejaUZhYaSbr3QyUDoGn-P9vw", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "BDJEzTKV6jUTK80d0_Avm0T8ktFbU7zTyxAvMbJWiGk", "onion_key_hash": "NtnUi6KDJNSnrMXyDZA4x0wuBioeYOZ63NXjOcB3eg4"}
205	LOTgno53J4KUF1NRGLFE0AdgHToTFW_XutC_aV2qXdA	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC2aeWosJQYKUrq92_zoavtVGDhje1viDwbKBB5rYlstQIhAL2efMAbBkv72C5mdKK3-wYMwsyczR7hHfskwXkhPJfk", "block_hash": "_DvvFdHPrEwpfKnoNnz1NghYXEosF347aMzSpXoc-So", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "5dLqRnQRpGHpqKWGbWnrtNtu-kqsD03tKrKt5RQplWE", "onion_key_hash": "rPA5cVNtIl6JJSMlTuTgKbQp4zx8s7nixDxZObdLgZw"}
208	Em5qGGcOwDkmPtlrQSjrdYezeFA-wgM8o932eHKGl5k	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMyeJzLYWBgYM9gygVSigw1bXdTZNZuU3Jtu73114Jv0zgtvbLNW3t8PF9_Z97JuaoUpMrNwIVJITjZP1hcUmGf8YXqy1Pv8ihYMNU55uwq_9-wepXhW-_fSUwKzg7PrZYcuaere2FikfDj05udvpue5RT7IOjMfKzh1vqFt2FWNnWlB4RpJNT9Ebrx_L70hj_M7_Vlwj0S3r5NuiLw_ErMP5AqDwM3JkWGjWeVFLj3au_3On-o-xdv_tN4NcYj8YVrzF9yarSuOOx6A6hkg0hf7LTAVz7VOgtfndWxKp0S9e6JQdPLheJVd5elaCf4wyxN2P-4edHtptCb74X9neTrnPc63T8zW6BF7vrKnRzJ3Ye84P7UkZI8unMZ59Z2VZNlqWdnT958Ydb3iyVMJWoiKQ_973U0MSmEbNt_X7mvbfPCbJ93d1izXzz0dZ54OiDxn9H689XVfTt-wqys7A366PHg4NpHzhaFm9jYspzib8zMr3H9bby_5OeEeycr4FbGR25-WSMpYr9q89OHvTl797NNzGJW1WtuOXDSZcb8PV9-MSmYH_LXsdLZFnrn4ekJ2le-LzMzUbZs_TLjxl7WS9xaHv9SYVbKnHr_6V7rwq2tIZuEOk6dEWOOcbW4feDIMfa0M4t-dh05hAjajjm7ttYoX-Vq_r3282bvl9MKtwQ8l9xwPOlBk8BNt1-2b4FK9vE5rDihKs5yNSxlC8_nAtULu5sWzxZpX3JmzX3FhmmZUTBLPV-nndie-vrTR5HpGRargqav6amb9MDih4H8Ho2fZVIW9SBV7gauQBMXcBs7VuxsLSz9rOzPO2lFb9nPE62BPVUlJSsaf8TxzJ_KpJD3xs5gxi4u_RNHlQwd53sdSX1q-0Ana39wYXC_iJbynL0wO2vD3JfvepnC0OyeHvTIPfwSy9G5nxRjz8esEbL-1c_b64bw6NJfZi0ZE_vuPpC882eD47V7DTOtRJk0Y6brnC3wi3Q4WgVU8k7q8cZNrlZZnCfL0pJsNvxL3t-pvj6E4X_7hVI3w4AopSwAMSBmuw", "height": 207, "members": ["11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
225	4Ui1PSXp2qsgAcKUarGZyNkgQ8_M51y8QIePeyehDvI	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDrEKUeomM-qpmodPUb117sO1BwzYtkPmqHlXn2v2FMMAIhAKII8pp2vUrdehqba_PxTfPO0i88Bd6l5d-2cSKyBr6i", "block_hash": "kmrL9pEFm78nQ5yfOD_LWWboxe3vS329UO3Hu2wYGXo", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "O06ZorrBfAZDQRc3luOBBQWHqb3uU7Er0g64zxJv9KY", "onion_key_hash": "DGBxbVrGeaJ5u2K2jX4fHHAc4vLQX6dEvclpPrCSSDw"}
230	n__1hH38H7d2oLyw68goXikiFeV_W7DkmwnQpjsRpqs	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIDDtz3zYN5bJODf7VaaOFKS_ZCWqSdFjgyCUJkJ8j6OeAiA5iz7PHg0SaNhce5kK0JVXn_9MP-IRSdSbqakLgb0lQA", "block_hash": "LJxk3GvNjOjBRjd4ZcQp9o_CyTWy-c6QOIhmUbN2RHA", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "HRz-XXyLCw-d4g1lY-gypl6b1wCMuBdNFcgsWw8_Pac", "onion_key_hash": "LHMA0xYP4Cegkai82SjHdeRnZvBE6WlIEUjSU3E38m4"}
208	HrktA1EG7wKufUFfI4jjR_x3Vk12Y5KLCLQscqFMOvE	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 207, "start_epoch": 193}
210	gRKo9waXfzzfI6yivcsYh41-yagCXjzluPR0dsNa0Ow	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIFbGc_R1tr-QKhk_LdCFGXlgjOfiQbPgec29FivvzpATAiAgBPfxojUgxbXh3_8xVT8_-jN5OuskgkN03AMO6lANVQ", "block_hash": "W45vPDNbVnKrzo3q2E5J4c1c52a5bToPQYOQt2o7qsc", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "56kqP5GBsuXf8aCA-j6FVT9SxrrjCleDGxA68L6p5sc", "onion_key_hash": "Fk-RISjOJ3TjVnGAzC98GoG-nNkjF_-jpnC9ljBLBac"}
212	1NTIiC6T1Gg6dMXTYLD4_Tn5snHFhLwh-kOPofMIIkA	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIGLpGh23DBfmkENtLWPTTbTu0PXnfLdS3znAbBqLY8m5AiATp8EQ-ItuNQfaQ816Rb2mP0-eY6QfYL8b65Z5XzcWLg", "block_hash": "W45vPDNbVnKrzo3q2E5J4c1c52a5bToPQYOQt2o7qsc", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "P8r0sOXugLOhtNgv0mtuYP7E60mIkFVcHfrU4eH96Uk", "onion_key_hash": "L-7gERD6-v4wbgf-F1sq4InIIaOkFtDtTpX5ex-7Pes"}
213	MyiuwEV8Its8G1Cuh1TZG2e5CfTFMDtVZ97infFJHpc	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIFFIZrdAGeEs6Pu3CrVh64HkqScmP9ZGneizDV9riKJeAiAkn7dl0R2Lml2R3aslB20wBdsKkCbLTYXldBKz6xAcrg", "block_hash": "sxHY6v8RIKXgsH4eUBNvu_PSQ0jtsH7Ozs7DM9_w7Dc", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "9kugN2EhbWpih8MlAdo-Hgh5UxfQAE-Yvj4Dv9_Zetk", "onion_key_hash": "6RdsVg4TzqM_n_zZMOJ-P1DrTN56XWnidTvlCfBOHbw"}
219	xDJl832xamNdZK6YH2XXDqo2hX7evrRw6NOU9-qZ00I	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIAXReeJ9s5EgEjayIlSJCBwIy6osAMBf4rcCt7POpq0UAiA3W02pE20DkPY-dJDH-Id_-xN5Rq3BRJyDCHmOf1NzoQ", "block_hash": "w2WpUv9Q2xXYnZ0a_-J8xF9R68RvlFlT7q1MSdN3NkQ", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "8stWxdP0Zf3JcNzRwAp_ySaiHg7OxpR7b_pB-0MBnHg", "onion_key_hash": "fIXcNIEAq39nfnNjnuBFfn0bXrI7orwrwfvDBYEZMdA"}
224	NbU8LQAAMpSQAkBhdu-s5RUcnGM243uLealc0s2kTOE	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigxNXekBYRoJdX-Ebjy_L73hD_N7fZlwj4S3b5OuCDy_EvMPpMrdwJVJwXZJ7_-7zmseNX2Zc6ajvaWgTUP4vLHqnVNea191-07aVsikyHDl6ZJtzv_9zB9MPvIs2WX6szOn54jcyClv2LUhvP8v56FzMDtlTr3_dK914dbWkE1CHafOiDHHuFrcPnDkGHvamUU_u44cgtmpyLDG-03Fp12sFT1JK2vqVVm3VskFClTVMkq8vmoyL7MlbhaTAnfz3v5a3SB2mXV3_v1aH3Kt3PZuonCe_-xfGrveLGb6owyz0_N12ontqa8_fRSZnmGxKmj6mp66SQ8sfhjI79H4WSZlUY-wc57Hg_8-X47oyD-rkUjnUXurq7Xtr_unV5zFO5cvZPBK4WRSkOk_Hbrcq1Tp65ptGa8rdSxZGRaw3T0nxzktyrFlTv31cJidNW13U2TWblNybbu99deCb9M4Lb2yzVt7fDxff2feybmqFB62lUHNkpbbuhee1D17x8kwcbrP4zeh_YtabUPis0vDZ178C3TVKt5NG1rELq-evu3xtXrZ6Rontq3pmpFs2nloe5eHxcMnxTA7pQ9y2qtvTXMuSGf5ESTD__ufzpUTNzWsZp5ZtieLKezpTpAqDwM3oIk_pPpKtzoalO1x9ljWNF-9y_aSU_HvJof22ze-Hb66aP8UoJLtjyYeSVuz78NRjji_c08W7T7SLybGK28w_cPs60yTr619CbO0sjfoo8eDg2sfOVsUbmJjy3KKvzEzv8b1t_H-kp8T7p2sQFi61kFl7sJXIiZPD55_trJN51_Sp0k-34-rupzZrvdcKvgTH1DJ_Gc8-aEtbxpjTFxTdseWXrBd_XgtWwXXkpwtya41E5liYZbWhrkv3_UyhaHZPT3okXv4JZajcz8pxp6PWSNk_auft9cNpMrNwIVJwWLpee3_aQbcu13SOIpO-JSbxNz_srE6MVTA74hwzwuNY0wK1ZpSWjkL-liP7n4hIPXzw01bW57rEjcfbBPsOzXL-tG2yVkARxdr_g", "height": 223, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
224	E_MSJ8O-P_LoQfZxo7GK-ZCNGDLxKZ1uLI5ZjNMOrcE	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 223, "start_epoch": 209}
234	iPt9oJBFgSHxYLR3rWmD2aZvfaHL51bhw_52kfjYRBg	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCo6u0cX9UhdvTsy5T347_SclaIm3-t5eRSfESBCUnWDgIhAK_j0OkFt8c8OXpvIOwWYl_YHgTYx_iF_b4oZSrj7v27", "block_hash": "AFIWKQeAaSn5T_AJ18iwF8SeM5ymIu5TyI9R13lWcdU", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "xxqDw3wK3qtc09Wl-OxvX1t5iLj-IY78f9FIUdWizVE", "onion_key_hash": "0imG0VnmP2Hsj3dceqXso-Xa0z1_0loixmOrEIDmyy4"}
235	oMCHpSvWrOObwFeDAYbeNTuMqo9cr26Jo_JGyb-KUNo	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIArRgeLqfHoWYEDFtoJi4RUixqw9TzjfAKbG1zle9J9wAiEAvwGl_ks2GU-_HfzdyI8dfHs3NtbYA6dib80pdj17W68", "block_hash": "NGV_X7jzjZa-pHtATkuScGlQGb58TM7e8R16ZeEhQ64", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "DrjzOBcMBZeinPpN6_PLT4Y2mPn824NJSObmLYn5-Zs", "onion_key_hash": "50vnEyC3MDjVheehoz5c1poGHQzMVv_SM_0l74DNcp8"}
237	F2rD48ZLU665cGOXvCuZMTWeIQwNCXZTeyTluBDWVYM	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCwuXqC16Li4k9n4lhZG26ZSg_Ph2cE-_3YFsBrlwuCQAIhANi63WBQRwiRIwZJ_sCukTfE0HMSEvivWKBM1F43tVYE", "block_hash": "NGV_X7jzjZa-pHtATkuScGlQGb58TM7e8R16ZeEhQ64", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "I_mDTrylgs88sehxTXochQGxhYbkgdUek7snCincFNc", "onion_key_hash": "6QttCKgtyCRWw8MHgwcOLjJ_GVA3_TCwyNnwn4h4C04"}
240	bxwDcs1pGsRA__MJ1jubWoTBZ_WFQHGFyfpiS6rQbSg	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigyer9NObE99_emjyPQMi1VB09f01E16YPHDQH6Pxs8yKYt6kCo3AxcmhayDSgXzD2_jP-jecfl8jM7pO9PqSptMsxYV35nyZbWh_EcmBalr_5vvy0vO52VsODW7rv5mQsOl54HOocLfZG4d4Ws_WAOzsqkrPSBMI6Huj9CN5_elN_xhfq8vE-6R8PZt0hWB51di_oFUuRu4MinIVE75xry7w1RXwuaHJ2-K9NxpOyz7XMP1ddSWVmzwybvLpMjQpnDmpUe-odn07MRdmvu8cupmTJa_xxBeqHFRdkGV5cVymJ21Ye7Ld71MYWh2Tw965B5-ieXo3E-Ksedj1ghZ_-rn7XWD28lb80q_8axacoDjJNd8qfrCdUevWFq3L5Q14T0V4pKb9hto5wfnwzk7FOu3sG16evjnss59xglxQXazIrt1dj3usf_6pxBmZ03b3RSZtduUXNtub_214Ns0TkuvbPPWHh_P19-Zd3KuKgWp8jBwA5p42eiS72UxDbboE6dKJ6Q94hWamKRRUHqYJWPmjq956iuWAJXM2TmpYtHb767vWN-_j39T-cixOub3xhmBam-7VzVea-tIg1kqc-r9p3utC7e2hmwS6jh1Row5xtXi9oEjx9jTziz62XXkEMLSnqyUj_pHog4uzv6cdG9tjyDnPo2FjOX-B7vvxHbVT7W5ClTy74omx5vuDxcvM95XmxGbvipQbc6HzyaezWY8r7uDFjq1wiyt7A366PHg4NpHzhaFm9jYspzib8zMr3H9bby_5OeEeycrYKGryPDK8uSfzjVzUztzphk0L_58qCtPVIX1u0_S5IVzFA5UqR9hUvAIvDjlQ7Ku1ofMPS-e_yiJ5MuT5-eMWWPl4M3VdS5G5THMzoT9j5sX3W4Kvfle2N9Jvs55r9P9M7MFWuSur9zJkdx9yAseo7YvzZfu5zyuUjdjdUHdsrrd8_eKXZlfPYlV5_8sjV1TMkGB--6A3a1NHFlCy5MXlM6sd71vXNr30iklbYoOh_qFhFt827MAvX5k1A", "height": 239, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"]}
240	NDExALVdMltqgek1mdDz-JfVMM5eBIrHe0S7nzLHYPY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 239, "start_epoch": 225}
241	rdNIWqwVaSsk2fb1ZyKqUnIcK0uNXIk65eO7lL1-9o8	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIGK3CT4f1KlYBxcvad0BPPPPpLURzITWMJsCOcRxdf1xAiB57YXKf-xnGFyprfs3uch3kKaktIZX0K9Y8xqS8f-ZNA", "block_hash": "UmrpNJTCL3x8U3x4S8dYZYxbxOz-Unb8YAHJ-jiGIss", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "rW-LftlXtHdf1W03BvTX2eM1pRuLxUiMgU25hZ4fXk8", "onion_key_hash": "3n5z9GTPn2zG3sRdonCiyDiBaRcn9cks6o08Xh0EI9g"}
244	vhkuxzS6D62xL1DBJKlej9Lu5SG9a1zajod0GiytIwE	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC-a86xNLrudLvwLNknjZ3Z4rY_TLcc-0Lx8VWpc0rEEAIhANLagCBcMtymyFgHtXAN5GgiQmLcTYDkiN1vEXtSczQf", "block_hash": "OOic8HmRyfWhA3t66MgFAc21bUZOF1g4Rcw2UmdxrZg", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "MoI4DQCtAy76uY4EKD1giMjSWNgVEf4IWMaxAPZTO48", "onion_key_hash": "EdwPVYQasDzeBACRxqz-63ziEkAj6T8H5mQUxLDdWMY"}
250	u6hGDaLLQ-RXy5lVxZI2cG5VO7_7PsIaUTJtB6bQcIU	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDMEkAC8Z2tP8mV4vPW1o_dlRnGUb3XrTNxoUZ5kVHSsgIhAIcRSedbweMZL7krhYRJ5J4sI3ls-1O4K-Hm3aOibo-m", "block_hash": "zbH7kvZOyXo-FyvcsCykKBGGZDaMY2IPiWLVdjCDJhU", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "OBRvNdAt95wBrCgC_kYIOkWiIQrvlKxMKVohQ1ABtxY", "onion_key_hash": "FWUaVwCLJ5wrqJYlKU7EsluRqWGj-f0bt4OI9shCOK4"}
250	HjvYn9X6_vyJR6n-vLFvy7buwOMwjHMmELPGzPv0Cls	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIHtpZV5oRaqRCsduzYTZgsvLafr6hpdF-iv7KkmzurUtAiAhy-12ThumsJkfg2waHEPvIZS6dVsvxB2SNatsc-yZKw", "block_hash": "mEcSB8KCNH420M6D74sUzkrcxrRKRPiP0WV1YgSJ_KU", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "zlftzl82iPvVDrwLSXrvI3c9PjGkaNjAzadRrnVPFXM", "onion_key_hash": "SPi-wROAeFOs_cwqcVuqEpMK4snbLaQRgei2hsty-r8"}
256	9aO-QC9xRIH4TbBKGfPP3Sj471uhBUtQHUi10cuQbEk	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMweJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJWbgQuTgol461_DEKaKtvusCR4xUVOWl5x9K_dkb8jLso1tuZ3mbkwKMc-u-9Z8d1PaJF4pG1yRM_FYyPs_eRcqe_8d3r-b6bDuTJiV0gc57dW3pjkXpLP8CJLh__1P58qJmxpWM88s25PFFPZ0J9xKIVFHpdXOB-67Fpj1td53atny69fJverswvONVJt_m7jPZ1Kw_fbndfrsE0YGh65wsNVKRfJfW3VV8sHp7t_3VqQr3w-fDLOysjfoo8eDg2sfOVsUbmJjy3KKvzEzv8b1t_H-kp8T7p2sAKlyN3BlUvCbqCWhPPXGpsWy0ZrxsV5a0qtm1xYtt255edjoD_sakzImRYZ1ZYwC7GfUJlfmn4_aIPLATELwcgnfrMKu4j9iB021GTJgdta03U2RWbtNybXt9tZfC75N47T0yjZv7fHxfP2deSfnqlKYnYoMG6Z3qUzRrBOc-9yl9m_ffqXK0htmb6sfWyToc-SbGGW0Minkhsgw3oqZIvfF5WPJ48fuW-S7HQW6Tkh-YD870T1-pcFymJ2er9NObE99_emjyPQMi1VB09f01E16YPHDQH6Pxs8yKYt6uD_rz1TqNHGY_PYwfn7dh7f7of_KnjV2Km4br0wquqV98_FaoKumx6f_VrDecW6FZlhomnbT18xN0RLSxhN51wl1i3Js_GoMs7OpKz0gTCOh7o_Qjef3pTf8YX6vLxPukfD2bdIVgedXYv7B7dRPWz5v0fmvigfOXKy4drjjVbqE2c2ftUwzzJfmFC_eX7UHaOfUjMKyGwae4hF-zDciTngdr5f8EcslVrQ4cfWNTmt-9WMwO2vD3JfvepnC0OyeHvTIPfwSy9G5nxRjz8esEbL-1c_b6wa3M-O36B2RN79q8uKl3hspyMklH3t8_6LM9J6YjNP6jEIe64F2Hn3F2F36x_lq0avgGfuvf6oJYsniPn2E9YVmSMxN40vrErMAehZaMw", "height": 255, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
256	Ud2j3oGxp3Z4HPIpPQ8YEUVaVxUtxLHOkmYmfnHTyZU	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 255, "start_epoch": 241}
259	DxdOAZS1lCW9vfYZhheRsPqvcKpgLyHPv7IDNj8Qih0	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCE36GkVHFVQ1_HYM1j6cU6ChUXtExndirUK8BOG0wivAIhAIPNcM0PoW8hwOtyX6VEV5jmxEJ6UIucZx1_PoTGBIvM", "block_hash": "9GA5VpD8Z4TquJ3jdB1FCxzZcZ4NSLEutTeyZ5wI9PY", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "2ZcslYl3UcB7pGus43qcyTP2Fw1bxFA4l6-FYdf5qsQ", "onion_key_hash": "ezJ2RvC_PJ-xIfb1AZbSg53OYnMyaJkzcgP6CPgUc08"}
259	rNVwPTPV5X3ZeOfO-3QvLw_aRWR2kuLqHRUE44kqbEg	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIEbunungw4kB0xETXX4uzfOXlkYOAiNr4OSF4JVCDT0MAiB4pTP1xMMvi7yYtd4D13G7gGbc8-e27djZaSEiZO9-XA", "block_hash": "9GA5VpD8Z4TquJ3jdB1FCxzZcZ4NSLEutTeyZ5wI9PY", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "GK5kI-NxVerMBZeuqMcFoCIcmtsHSEUw-XiEODh2mgs", "onion_key_hash": "sGllSROBKR3kYUqP71naj6SQYv291LkAv4q99axJxiU"}
261	tAMEDuUa6OCMxY9KEAvKK8WyQyHIq55lh-y2euEXrr4	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCi6kwB7dcJj4f_hmoLxo24XswPcfzijvuQKchqwHPXtwIgLQQFaDKtHZVI91OVpFn2puyPZomjzqAkpgtsTPn-ztw", "block_hash": "ETGKKMRONhEhFNS5RIXtIDr9C8L4osmQxdnHzlu4bJw", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "Rv9-bn-v3vd2D6Kavm55CGxLB2VROpDts3WaiiNKQ_w", "onion_key_hash": "H-ZyyA-wiHkio6AjXP3EZeyzl4mkAIdeJN5h0u3otfE"}
266	11cicZ7RjlJyckinp12BtAStlYtuMxbelgasZ2WupEA	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDgJ6H1I6yscZN5DhJHOinbFbrEXLmfK2R_Mqy561f16gIgPTw2YtjqlE9yUVXTf3TWk3lelgserCmLvVDAO3aflKU", "block_hash": "zkZKGYlkQn7HDfhSVxy2v4pj09wcV8B1wD5IiJx-wxY", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "bbcz0cDdaieLvhB5l8IxgmlRTcnKXQYME8dPwijMYVE", "onion_key_hash": "8dsGPP478TJcPJe34AlAkU9YdJrdLBWp2x5KJ2w-hL8"}
269	kVOupdvYQWD9NRO1tHFx4Dm_iNINAfGG9ASYe3Ych8g	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCzj4UCEsbvFBrAJUuDn5Gw20mrUL4sfNRY669s9V-zsgIgHUejbWMnkC0NcHqF7TsS_574r0z1zuq0Tsv-3rS60ug", "block_hash": "3AfzRKjm--jtTRogjCbEDDszzMnz-z7i-f4Nv7WCCG8", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "yVN5J_DliPsSVyg5t8usRvMJxqRQRnoeblnbuLeXci8", "onion_key_hash": "c0UHuo0wV4xyYGmX779wgypChnsduF_QScIrL8v_htI"}
272	FQWUbENOmRD6vj0iF8u34ye2PWji9y7ORjKvzo9n0Qk	consensus_group_v1	{"delay": 0, "proof": "g1AAAAM0eJzLYWBgYM9gygVSigwJ-x83L7rdFHrzvbC_k3yd816n-2dmC7TIXV-5kyO5-5AXSJW7gSuTIsOsgH1_13RmP4ickWx4TFre7_zCdOFj5__d8TzZ-9B_eto0JgX57q222ZrPrB1LTvNK77IOvLvEQLVJeP3Efh9njXvsMb9gdjZ1pQeEaSTU_RG68fy-9IY_zO_1ZcI9Et6-Tboi8PxKzD-QKg8DN6Cdq8K1-fIezJXd3jrlVvGGxPMlrclXFC69nburauNS3f5lq4BKzgtd_2Kl7XDb_3ea5AGznZzTZx4McrvUF7kixprp0tzcSpilMqfef7rXunBra8gmoY5TZ8SYY1wtbh84cow97cyin11HDiE8OsHgXz_XpHO5z37Eev5zal545RhD7UqDqoTI4ivTqxJ6fzMpRCw_I1d5_lRAREl_0YJfV4JavJJfyDpcZJ781X1te4WgMczO2jD35btepjA0u6cHPXIPv8RydO4nxdjzMWuErH_18_a6ITz6dtKqAhEFnYlyU3ubLH8vLLw4_-SJUlOjI3ZOMW53onz2A5V8SHHzrJ05b3L7Xe50r-B6p0r--pIrh3KWKJ19lPmnetkbmKU1bXdTZNZuU3Jtu73114Jv0zgtvbLNW3t8PF9_Z97JuaoU4dGeUmObVzJb-Ps-_Jn33PljsPlj3_NHWw7Vrpe9caLdPrGOSYH9gd3b1Ds7p2yaXfBDMDr1uklKjIlNx7dJl23UC_sU-9thdlb2Bn30eHBw7SNni8JNbGxZTvE3ZubXuP423l_yc8K9kxUIO5fXHKtq7JpycobIki1ikxv-6Gma6haz_boi6nqu97mB4E0mhXD3sEr17BdHVLID53RdC7fRZbLuKjUu2ruoslS483Mj3J-er9NObE99_emjyPQMi1VB09f01E16YPHDQH6Pxs8yKYt6mJ0K4u9D_5ZyK3z_fW5iSnD-YnmnWXf3LNr4azPj3GP7ny7j1ga6qvnzbaNdSjpbzc1ZJ3V-WPpCmDcgYkd1m4j8wX1pGZoxb7MAg2Vn-w", "height": 271, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
272	CqJbcM4GovaDFN6FMArKGQH2MHIDza-umFXBOFUd9sY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 271, "start_epoch": 257}
275	DEAv6zEgRXHEFJUnPpNo865NXTfLoFgooiEiuZmK-xo	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDNepi-quiuVjCxIflpn647eKj86frUhuNZrQZfKeYxdgIgTgV-NWAjCFd7RlENVRmG4PvRUq1PFLz9XBBMXlNZZW8", "block_hash": "Bo6nQe7MgqPPHN5GumIABzhwaxQL5ZK2Mh3oxNffS2k", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "ITQxY074q0ovnOOsFTT8BSmhhRP7MCvjuoMhmd0ZTHk", "onion_key_hash": "9gLOARtFpRlnUxPHsldE9VpbaeRgW3gzz9YsMwTEPC4"}
276	K2EHEkyI5ScBEZ5qW7bBClgoQyB72sT4Xhihw3Ha-vM	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIDwaI8ivDXNvpoR7G9rCBe2nMOmYR88HXp9Vt7MHFPC2AiEA8K0lH_va-yA5yLvRLo8jaSqNqFKHRMkYowEyv8u65Bc", "block_hash": "R76xMGIA_OFNho304CYRUnpyUkVMk8nTvblrx3FXXc8", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "L-EjypgzcgichB85trF7GsQ-KvfrQkLGWqfaPidzVQI", "onion_key_hash": "QM881LhnMfDDG0ArimXd-LrXp4Gs3I-jwqgTg9Qa8UA"}
282	jkyFgqxJkB9rlFooYrrC_sZNAqMcfc2z0K163S_4TX4	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCw-wG3Rg5RULlfEBiFbXvWTtEwfKR2YeUcOytx9K-omwIhAOAyPsE1KnkOy90rLp1GNZUpQyJWPAWNGLUWD9U4eO1B", "block_hash": "Mn-hrS2zu8Bvy1MYTITXo8DgnuaBGnDmOOrFVK3tqRQ", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "2GviMYMb6t3btQVr-xOVqqXO8xNCjsWRqfaZ4bvEjTo", "onion_key_hash": "_wIn9Qsvpg9ZYQj9AlxRCLlP10i7kkMBXDtFttpNfKU"}
284	adQEeY7n2NbidjB-ecfsZUXDj7pdxgi1HllrfBml0NQ	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIF-0assHvcg_TMou-a9EbxN_8vY06MwnCUpGIN-lwQyUAiBRc84mZbs9XErY-sVmrJtwWdQzsnSI4DcpcQy87s7cyQ", "block_hash": "DkgOyKtNZ9wCog9tpQGWtyiccHqN2YPVPip78E42Hdc", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "KnY69clgovhq6ioakzZocowzaRNs86cMwRjZc8C-Q3Q", "onion_key_hash": "Fd2oi0tgOdzFPV8oO_ApBxz11iRFn-BkL15UWwVlPUI"}
284	qMZFI5bp6HP8wEo4Qxcf8gLJmkCPhn8vhKYvJKkm9Ys	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCYVRe6L513gpm5zzReqbux185cRkyAxCSrUcO0QcVzegIgCYpfulfPUVGWqvMu9_P4lkZme_H24qYLcuf8PBmhImE", "block_hash": "yqur0eM19PSKBq2zkQhzHmYa8gHCbr7DZzE5PW28Afw", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "XVR5K8zRYGvGTD99DIzmjAcDDEdridkssAkzRZtxEDo", "onion_key_hash": "cYcPO15ShbBw_7kxvTptBLLSdzNstBS9mpIUlzOtqd8"}
286	i_yskCuXPhLRrMVb_2jIPW-f6l3r-71-YZCukEMEOu8	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDO18pv8y2AHg_7hIZb7q_4Tc94JtjTm-Wi9mePdpYo2QIhAMUTQBoC_V6GXGXibVJjCoWK2gOnHGczUuAY9bgqizHo", "block_hash": "M6x7BujZIuh6bj8X9xdiEsAEwuu5YgD7d7vVbVw5vsE", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "wjlXx4uBAiY6JxOXjlF60NnUXBNQP1u6CfKkq-n-FJg", "onion_key_hash": "QcqZdGVpFq7CCzHwjUaBW-Xi8GQvP3-dUWcUgpou2_4"}
288	rbQwFe9BcaUKAzr0ksEiNipO4tN4MCVCYcETBX5YKXI	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMxeJzLYWBgYM9gygVSigyVvUEfPR4cXPvI2aJwExtbllP8jZn5Na6_jfeX_Jxw72QFSJWHgRuTIsO77FA9ZaWfB9qN3y86dfOSem7xr9zf9w5K7HKMX3JkRcYBoJLTygc39JxYlrjm2sddj5ujLFiLN0nLcLxRTYp9vHmRx40jMEubutIDwjQS6v4I3Xh-X3rDH-b3-jLhHglv3yZdEXh-JeYfwtKJOy6-brl_WIWHl1fZVlupJLvun7mt2KTbJa-urjj1SKcBqKRB9pCS1r7gVWv0llr_67njGuTfeUyVx-Tru_yV07Zu-OIJs7Q2zH35rpcpDM3u6UGP3MMvsRyd-0kx9nzMGiHrX_28vW4gVW4GLkwKbA-rNa_-4Hx7ZKvm7_ssLNv-sZ1hlvu9Y3PpjdXecxVmT2NSEFf-7zMxc_-q0NrNQlEH-s40zQv3OXSu032iZFpU0boYVZiV0gc57dW3pjkXpLP8CJLh__1P58qJmxpWM88s25PFFPZ0J0iVu4Er0BP3mxet59QP-_23R8JXRrpw5bbPvpNUDWMtBLT2Ctmcm5DPpGBYfqaQvakw96qDiYTlKS2u2UuNM7Z0THJpnDhvd1bhhBKYnTVtd1Nk1m5Tcm27vfXXgm_TOC29ss1be3w8X39n3sm5qhTuTV-fe2yLj34NT2x-a9b8vlGQs9LW6Eb4iZdSgV-2Fz7m-c6kELDE4NWSi3MY3ppxv_nqvlLko42X2yRJ7d6fGrcX9geHisOs9HyddmJ76utPH0WmZ1isCpq-pqdu0gOLHwbyezR-lklZ1MO8qeBn97CgP2-S1-q61B_l04P5vB294iR0nP5P_qLhdkqo2QYYEB-OF_DqbdUot1vycZPFl1tnGjlCko5VWqiXSS27ey75wDyYnQn7Hzcvut0UevO9sL-TfJ3zXqf7Z2YLtMhdX7mTI7n7kBfcm2EGF7x150x9esLXNr570vbYH8dKbjPMqzSacpqh8BPbyTVMCizy778cqw83fSn27LaCyI-jzlwF01nbnq_TD_t3ePqmf8ZZAK5yYlA", "height": 287, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
307	geG97dwlGQYy5zUHhmcoOuy9fruf7QGBZ5F_g-TFZHQ	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIDjyH_botUAi-CbctPq_cZ_baJYsm5dtLCLbgmjBtmafAiAxmzzwIYxMQ-d7BToabgrVsmwZxmKGCMoKQE7XJn2kmQ", "block_hash": "IgMbI76i5XvJ48oskYNTHWQvAzOEnYtdLOghMcQxuvA", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "W2kcCiDMy-fyIUfzLqHInX6YwpnrP_Du_tYGMcqiq3g", "onion_key_hash": "KX-Hrbm_OCm-wvKEFtImo5pbe9jkPN6Uaz7M7rGBGZg"}
288	qulFNdCtJ7SMMoRqkTWn0WRCJ4InIwe4jYcoK5zNySQ	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 287, "start_epoch": 273}
294	pxpWeW8EuaRO-iPsJeuyVSG_xgjAzPefBPQ4MlbUPYg	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDXwR7ebt_SsRZEMEjhW5g4LhSmOl9Gj5pRseTQ7LwIfwIgfudHyVTAbqImq9IGNOvYwLrjTQ9fCKQv0j5YXw8THyM", "block_hash": "hs8daDb38ot19y99u66XJBv8e6tmBJlQsnlM3McgxIQ", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "4_N_cNRRtUJHjLNnk4TWzqrKzy52EGGGAV-LIpCGjU8", "onion_key_hash": "OLukcVIGmmxxS6gBwjGp6l_iX40YtPEP7IngysM5-30"}
297	47qnncniBi6BM-lbobtqs9BvdF9ON-j5HVloIkgTUUo	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCTJ2q4-ittogzUqp-F1UL3pugZOOTTYaZLpnYC9EA9qgIgYMeKfXaiLU5tqLtHuv8dQ8DzPOo5PeIzslFtKithrAQ", "block_hash": "_H5zt5EReIoALTkEJrWH1TGV-gXSFc9imgtutOXmP2Y", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "4d6GlrhW8HgdryQCUSPJF4Q1E4fi09GXM36hTPNClYk", "onion_key_hash": "gjcySa6OFs6amjxGq46sUgC_9ByJBqwZHrv7Z08KXMw"}
300	ELRltQpFFVrsZDtTrX9j29VbCI_yFi5nzbfMQ_dzgSg	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDpc_7kyiRTJRAcJoDyJ9Q2H7rECmXNHVQ3N0xNjmVTxgIhAPeNiVPlyPB6PjLMd0CzaAB1I3sIhChzGR6e9EQBGa9E", "block_hash": "_H5zt5EReIoALTkEJrWH1TGV-gXSFc9imgtutOXmP2Y", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "gxL0tXOuDTJ8u0DFB-bA4UWwgxPEqZ9FnqoEPUJoe08", "onion_key_hash": "jGC4sJmvbkyfWy0Jm4iwDWeeWEFnwI4z4s5Vbjwq6g8"}
301	-hXr1B-c6Ic47L1_fWocPWWBLFHAMxZJNflyVCPMP8E	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIAyL8XYbTTKYfIQlWs16yB8SbVXilDsco0IZudmUxwWRAiEAyJdVWUDWBjzAML6LY6z4V_aMBN8u-51hXfKmEhkGLN4", "block_hash": "eBSt1sMJy4cqDwouInWtUPAPZaXcIyud6wKBMFU-0Z8", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "jYbO0x4vVupYzk8Gu-UnaOWtHPHVbU0NsCusf3xT1vw", "onion_key_hash": "nvtPtS7Kh3zCNeZP2a9xzX7k2mSs1ZLOPLIyNZ4vBZg"}
304	7c2FvjseR6HUMs8DjKT1DeWmsDrq_D5jAsyCP_P8ElQ	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMxeJzLYWBgYM9gygVSigwyp95_ute6cGtryCahjlNnxJhjXC1uHzhyjD3tzKKfXUcOgVS5G7gyKTIct57MfIHxy2ZDxgNtJh1TNhoYn5_J-DpC9HjX7sSon986mRRCdq06w6_4rudrKreLjmDHoo9Zh7qSVnsurK8yuiQ6O-sezE7P12kntqe-_vRRZHqGxaqg6Wt66iY9sPhhIL9H42eZlEU9zE4FoY0R7vofZpyZN3tttfYDiXz7dTJuIQ5t__4wZfEbrAq-BHTV_qNGr2aUWpswSun8OHnsDXMs06y7awP2Pyi9GKDhUCGqCrMzYf_j5kW3m0Jvvhf2d5Kvc97rdP_MbIEWuesrd3Ikdx_yAqnyMHADmnh_TpBMcQh7Xe65bXPKUy0ZWivmsh1OjxQx0Xu9f_a9BZFAJSdURabf3pkbU8L1-Bnb5TNJqi_31y5uDvnFy1aV4zox_gjM0tow9-W7XqYwNLunBz1yD7_EcnTuJ8XY8zFrhKx_9fP2usE9mr_1FuP5WXU6fC2vA0pfML4_MJ9vQlLfce5TAjlNp5zYpwHtXB1x6-3JK_p3-QVvesZu3LT6a6DUyRWZi58EWemFl31a9gRmZ2Vv0EePBwfXPnK2KNzExpblFH9jZn6N62_j_SU_J9w7WQG3k3tVMIOlnjt_qGDCO3vl2hnzjxRuTJ6kvTnz5bs_qdH7tIF2Tn_GbJG16_2EC348oj7Wq89x_-A6KpDcf7jT26lfObHjGczOpq70gDCNhLo_Qjee35fe8If5vb5MuEfC27dJVwSeX4n5B1LlZuACjFC33h0rO1-U69-IKO7omSJYx3QvaeXq4MOqsT6rnuflZzAphM18It15zSLnkIyC4MLLoYfqtZ-aR7L02375d9sx-kL7WpiVNW13U2TWblNybbu99deCb9M4Lb2yzVt7fDxff2feybmqFG4lx0erH5_zZL8vTIx7ZGed2Bzy5n274Lk29r2Wp6K_nJ--HBj4bOeK07f7HtdjmLxr0bIl5dG5hm5rZrGf-p9wesUqy_PnswD2RWHT", "height": 303, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
304	IZogFwew5_LXoCLsJ2BRk1r666HK6sqUfvzksH5bKDM	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 303, "start_epoch": 289}
309	k7n8BcPA57PSQhQqJxVeL44Zzr_M-TlbE0j6NIsrTpY	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEMCIH9mIRVRRe9Qc6oLX5oIqS9OimDQDkX-iTEw9QVTM5U1Ah9SJas26RbcNJlhXPziYYiu50vuPKUguZdXlCH28E6a", "block_hash": "Am-y7041sY-pA9aFWHuSCEyu0-437iZ5KNLyvlCZFXg", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "OrD2-rYYN71f6yp20tsPZVEkMjsmlPkyDqpFWf1f-H8", "onion_key_hash": "0LMunfImr0qsY1aZlmhLb5lh2k1ND5wS2ODOevKJJEY"}
319	plgj_oA_lkD4ob854WwcQAIFmzTCWVKK4GxQz-rJ8bA	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQD7oNFHSQ38nzUEJvB7w2pD1Jr8SCdBQ-t30cYouLuwXAIgE6qNrCQ83ptxmXZTWBY3b1-AX2tF0WM_Qf_8fi6TOcI", "block_hash": "IKphyfHYw3viFwQZUD13YCiXZyTo0R8ZZ60p5PLkcGY", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "ymITeyVrs1igGoLkgEGmVjQv1jIc-m7WnSK3r9hUC8s", "onion_key_hash": "NvfyqS-K6HEsvK_cprtvrlTpFOg7XTBi4WnPJ0EtQ1A"}
320	zwHGon2bmG1toNOg07UcecnHfncqlmwOBwJNyNZS72Y	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigyVvUEfPR4cXPvI2aJwExtbllP8jZn5Na6_jfeX_Jxw72QFSJW7gSuTgljCwSblIK-uiUYRYWveCUatif5a94Tr7scQ44N_H2puPsqkyHDqb5_U2c3Hr_49obosJUj-vl5f87-vj-wlmj9NffxDR0EPZmdN290UmbXblFzbbm_9teDbNE5Lr2zz1h4fz9ffmXdyriqF22kaHyhe-fZdwmQhG5bCjqKOAIUUfbb8Pda7Qr9lKzD7GQHt_P-84vidf5vSdp_xnavpzX1xE7fVubbHu_x36Qhz_t1hpgWzU_ogp7361jTngnSWH0Ey_L__6Vw5cVPDauaZZXuymMKe7oTbmaLzp2zSv_VOAdVnptVOPdCwZp90pLWtXkRWp07UwdXby4B2rk75-s1GuOHOxAmLl4k7mly52ms1PX_7V7vKH-W6v2wN3sHsbOpKDwjTSKj7I3Tj-X3pDX-Y3-vLhHskvH2bdEXg-ZWYf3A7TQTPMVRt_W5y_PcG6Vc3u3O5PjQtS2deKLgqe4dD4EL7cqCdnao1yTb8-x-eDCk0463_IOxb5vXm6Pv4kyFPiycwKjFIw-ysDXNfvutlCkOze3rQI_fwSyxH535SjD0fs0bI-lc_b68bSJWHgRvQxC33PRTdo9xuN6yyUjO2m_Pdfo50u7ocZ8gv07Sfib1tG4BK1kzwFrC-kKDD__imMMsmUXZugZhJcqV-J2qET5XGl0UehlmasP9x86LbTaE33wv7O8nXOe91un9mtkCL3PWVOzmSuw95ISydxvi4Zdm_RjFv18cu6VdZvj028Vhl_Op9eO-S0rLsZTf-AZWc_CH1MSr8RtLieo66J06bY849blz8V4Hf5UmNnL3h4e1dMEs9X6ed2J76-tNHkekZFquCpq_pqZv0wOKHgfwejZ9lUhb1IFVuBi5MCmqr5A4cafz6pEj3F3fI3vUb2zkzeGv7321_fdx9d3zop0NMClpxc1OXnnWZ2CV45vqm00WXXcqZGP_ITvCuX7hyyp6deyuyAJfvYaI", "height": 319, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
320	FJJBVjkwHxup3P1O3DUjX5TL0u3zTn6XTcy327huQcY	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 319, "start_epoch": 305}
322	tuoUr7W4Ms1RNWkE_Z3f0YiORACvi_-QfFEvd72v43E	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIB1RXcMwDFTTFyaC0meb0CqBp-wI5oMYTqQ_m5Tw8qKWAiEAiaXN9KAWkYFlavhVdD7TVJTksHgm5EwVRVV6FlFvcqI", "block_hash": "sMbsCR4WLj8ksFMFZOWMd7-EaVeIk7zkKnf8KhPssec", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "hKWpgt4hYFF_EIJ9ob3IsNgCq2WSBRBVGkoZ7-o6PYE", "onion_key_hash": "DlMcEzayAKeHKKyWhgvetdR0ZGyZlGIPel4Di_H7hoU"}
325	_fAE-MchDUxiFEVi1j_bQ0PztN9D-suuxNIa-YLIiHM	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIGBh7MWAovJWMVh0oSuCp-TqaYbCHj29BQUGFDFZZ1mKAiA1eUaz4U7RU0G74xLUfSrUx_6qerPsznjhZ_Ka2EKOwQ", "block_hash": "sMbsCR4WLj8ksFMFZOWMd7-EaVeIk7zkKnf8KhPssec", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "eWsiKCN0mai9Yt9XyhEAJcA0A_3CzuKvlzHufHbOleE", "onion_key_hash": "aJ2Hpv3bO2W3bEXKredFrSDh3aJUxNk_PsEXVBUGyv0"}
326	m8vuNuS9oploxKY0HdeldS_Ap3RlfC_Iw3XjzR4OxMU	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCe_8bSJoKMfaiSa6FlSIBhqtM9REkaODsE9XNHW2OAbwIgH_5Y_PbNrMyMSHahzrOPYOx7gwG2xDnpETgCvr6Aq80", "block_hash": "Jc0YX5ECrVgWN6f29yXCF5qata3BAKaNTbtNmM0X1vw", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "w7eAko7YxezdeW5GELJ8EBD7kOUYI3mW010biU96080", "onion_key_hash": "iWdet4FaOWdACafVnHp5QQNwfL1-EMJX5pnpPf050IE"}
327	HoDIQC1d5-W7nleZekOKGazeJk7UjqSfcTWOHwVYsS0	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDIgL3EeK8_wSQGg7rnML9mhh3z-jZAP4BaxqX0panRngIhAOAviYT1WQc8ZXqIPgqnS__6gZw0JXGXlOG2R5p8aksE", "block_hash": "CVBo1nhGS5pVi1yIIT4xjaC3b7sJ_d-ISC8xWNzo-hQ", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "ctE0SZN2TRz2LMzgslw1qo2mti5jfMpPwbj3c2cql34", "onion_key_hash": "iXSQ3VARmmYCY_LKl0prJmkfihmy_LclkPXO-My--8c"}
332	7ZluZm56I_mZLyrpEZPhxTcLfRiBK-naey33lRFRq_k	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCCFVqcbAB37TqHpSBScKuggsTG_voPVU0M5SOd_iCdegIhAPkIYDEGguB8xKPMaaEVx5qro5x5s8X7MEq4_aiCtPvf", "block_hash": "P3Mk3MNkRlW5HNpptDX8RKtN3tI3BM6EzYBbpgcqfgE", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "f2_s1-IuBMHKX3eOv381Z_c2vCq0Tk7zOhM3zPslxpg", "onion_key_hash": "ahU88W5MAzjBm2rCKz1cE4XjQYwraNBYFyLOFfyvWpw"}
332	CftGYLp5bsxvEu04phPOIwsmf-yZJgPTMpbuVVFlT8I	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDyGIkvBf1AnPwDML913NFAFDJkH7U9x1YVzBGZfFsAbgIhAIvdqKsEjMuWP5Ys-uZobzNF4jdW-mWikpIGaFVi-ZQb", "block_hash": "Tx_mM11KNYqGBILTAFCqzA71oJAmHRbXtZH5ydu14NI", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "HlDYRb9jwmu107fpspGzURfsTfl9nET28JQwjXQcXCw", "onion_key_hash": "Jol6xR9XFwgFD040Gm9DTLVpxSMZmrjxsgUo6DRl_fU"}
334	Wip5YKvlaOB_6S1OTnq-ryLgfc6ZcDaQtFYQC0KRXYM	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDmrkHXAWxwPn3WFKYLMs1YZdGy8YoOhvkVWTQygFrDEAIhAMPBtgCR43tsfQ7XBgCRDdPKM06mXj7xnGHXyzc_vwsY", "block_hash": "Tx_mM11KNYqGBILTAFCqzA71oJAmHRbXtZH5ydu14NI", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "oMpgc9pPf2IZabrQq7uikjWebhTccBqcxxanDjPvpAI", "onion_key_hash": "YN8ZAIpwJTTG5BYTZ4gOKE4EN9uXccV6KtLL_rli8jI"}
336	gFldTTPFUoDGOl76mmxwTSOAIV9_E6M7XU_a3BbiqJk	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMzeJzLYWBgYM9gygVSigwyp95_ute6cGtryCahjlNnxJhjXC1uHzhyjD3tzKKfXUcOgVS5GbgwKcRv2K934IX659z-d8vv5EkZLIs8wTtn5SemH_X2f-dGTU1hUhDYXtbwTlw2_W57lOcEhg0nn2lc3NA81715r_WcG_c7t_-CWZmw_3HzottNoTffC_s7ydc573W6f2a2QIvc9ZU7OZK7D3nBrUwxPHvpuuRBtsrLcYtmKnBFMorMf8KePCfy8olybb7QLWeYFJQXJd7iqbSryipdu-hKIbtSd-l9JeMpbRnbza_M-FXx-xjMSs_XaSe2p77-9FFkeobFqqDpa3rqJj2w-GEgv0fjZ5mURT1IlYeBG5Miw8W1wfafpQLiHmdOVzh-wIm1xfjPhAlTv0mIWG-9rCS3ygao5BXfOZM94psaNgqY5n1qN4hfpLH1Eu8iBgf24j1hv9q7rWGWVvYGffR4cHDtI2eLwk1sbFlO8Tdm5te4_jbeX_Jzwr2TFQhLr054uWutee5Ul90Z-oqK8-4rzfyq6_a1b4U52xIW2SnpWkAli88JdHExvXG65couyP0354tTxvmNpx8ZFB5xu_Dt7s1Se5iltWHuy3e9TGFodk8PeuQefonl6NxPirHnY9YIWf_q5-11A6lyN3AFmniE76Jt4H3m-eWNPM8lEnT2RXNf9r229NTWkv6Je-JmGqkzKUhnH9SSWqUj_CjuReEGbvX8L5fu_7k57-IExd_1uvuP6abD7Kxpu5sis3abkmvb7a2_FnybxmnplW3e2uPj-fo7807OVaUwOxUC7-1Rltz12uxBheUj-82RZ8w9jGQFjUTUyxjkDr6Nq78GdNXme4f3Ocx-f9dxVtPfdLlztSuMMkNia1U4NZhlXDXYlqyF2dnUlR4QppFQ90foxvP70hv-ML_Xlwn3SHj7NumKwPMrMf8QgfvdUFVc5nfXEqYXivc3fOi6VFx76fGH8gNlH71erfx5V_w-UMnkFadmsmZocYu9f7hyv8dnYIq68f3uS_lJfzYot3VNqJ6RBQAcEmWV", "height": 335, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"]}
336	Z6mq3jV7We5kVzw9zjggrgYgT5k2mxTPCYdLFZ4rGLw	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 335, "start_epoch": 321}
344	4ajEoDaV4vF8_e1AoQJBGWzZikSbiJhrwPxFnqjPKRo	poc_request_v1	{"fee": 0, "owner": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC8PbFWUnNvL-QvfSFlugR-WwWPVSKwMmkC9mk6IHOwggIhAIkAGVVFh4G_a0BYhoE4BuupyOQ6DPJIxlXYBshX71Da", "block_hash": "hUTZm_9Hd1qyXjnMQ3pH04spVEP2r9fiLbyeK2aVGiU", "challenger": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "secret_hash": "aVu3sYbd7CiBFNYCeYULJ1uNvAu5P42RdgJFSXW3Gbk", "onion_key_hash": "QRWozzK7zaGA1fs1efopZbM0NNNGEZ6wkC4q5Uggrc0"}
347	XxOqfARJx0_FSbJ_EAPO2se1qoIVLKWK53inboD6ZeI	poc_request_v1	{"fee": 0, "owner": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQC9YZ086ye7jGrjBd7Wm1A5GzjVA3A1pPbEx24oWyfGmAIhAK5nCRxpNMZdjOzuKarMqD2kYYXsnydrLtcwgWOMlgXX", "block_hash": "hUTZm_9Hd1qyXjnMQ3pH04spVEP2r9fiLbyeK2aVGiU", "challenger": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "secret_hash": "Q-FBCTNqmrXmsXR0l-NAasPU0nAd_0W9n9_WPUTZQqk", "onion_key_hash": "Bx5a4Q7a_qmhs3cB7ADiK-rta0O4uE_JNyg88MCS9Os"}
351	UDj_fOXXiLUYAizX59QkyEPqgK6nyCbSgOP3RQRSQ7s	poc_request_v1	{"fee": 0, "owner": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQDaorgVrdl1MeT2Kp_8ZQd1cV2ydXtoemJ-O7ZGHJnpPwIhAMMz_KLhsv88uuUu5l4onZCwrqNWX5OU-oOP94CQosVS", "block_hash": "fTZNjVt-dTmreTlBKrTK5bijN8GHJrUUUH8UCd4t3t0", "challenger": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "secret_hash": "EhBQqFcVu4V4iLMRfj17BUKHVLX0lMWrDKpz34TU480", "onion_key_hash": "RvU19l6BtR4ck3bAWlVB3xZOg4uUDKnBm9vHZ3HEqec"}
352	ohzah4OiKL6b1CvtSTLD93sr381loAnhP-RWyDAV-do	consensus_group_v1	{"delay": 0, "proof": "g1AAAAMweJzLYWBgYM9gygVSigxNXekBYRoJdX-Ebjy_L73hD_N7fZlwj4S3b5OuCDy_EvMPpMrNwIVJgcumtG1dV8CFxxd-bAg42rHxx3R1UxOd2lQt68Oe6Tm9bEwKeqd3Bf5_vTS6Wk100Yp3offOXbmlvO_o3SpTngeB_nfN2WBW1oa5L9_1MoWh2T096JF7-CWWo3M_Kcaej1kjZP2rn7fXDW6lbub7U1uYH0WvL0rc21Ijtk9q3qrWY980NmsuYuX48OrZEyYF1-tL9l2z-9aYX7SBf_-S1CIH_rMtZzbcEZzDs0y4t6U0E2al9EFOe_Wtac4F6Sw_gmT4f__TuXLipobVzDPL9mQxhT3dCVLlbuDKpMiw-6jg0bdpaau_9d1iqhCf0dOzZNKRD8WXT0ntas6sN3rKxKQQeeJqNrvnut9K0hqVlcdPuX04--Yn7x83H_fJ7EfE_2yaBLPT83Xaie2prz99FJmeYbEqaPqanrpJDyx-GMjv0fhZJmVRj7DzFOOcxFzJvfp73YTv5s4X1nvWNrP4-Y9khp29fv6fRXceZ1JI2s7z7F3T0z-N-ruCt7-OnzTh4L86oYJrU977LNn5umz3NpidNW13U2TWblNybbu99deCb9M4Lb2yzVt7fDxff2feybmqFB607LbeJ_8s6wnLjft7MHSHsdjGKXqzeuoVKz15hb_x3fvynEmBO-iXyAnPWfEcb2dxt_d4dX-e46Zp4p5k1rCwasu9us5DMCsre4M-ejw4uPaRs0XhJja2LKf4GzPza1x_G-8v-Tnh3skKkCoPAzegNzee_xP1u-Ov543nlh-3vX5qZMrIFbHHYsv0ddZBytes3VmBSqZNaty3_WYeW6yb98kgYcXH8kFB-7dqNupFJWc63Ei5ZAizNGH_4-ZFt5tCb74X9neSr3Pe63T_zGyBFrnrK3dyJHcf8oKFrULu1pdXXm20E0lZsm9_kwMP39aJp1RvfJ25ZqXkJtnnO1pbQaGvsY1TwDd86vb98paLpOeeu8a6-9zvE_um7Vh956TsVtOELAAJCWt0", "height": 351, "members": ["11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef"]}
352	Y9M712uqWiRkM2OVeRVpm8_mygV5-Pz5E5euclpz5w4	rewards_v1	{"rewards": [{"type": "securities", "amount": 253183, "account": "11DDwWnixcBiAQhkemwGLTTNmbCy4Z9QMchAjyfyb2D88TAynef", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "gateway": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2"}, {"type": "consensus", "amount": 20668, "account": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9", "gateway": "11ZZBAvowQ2EjxjSLavwDeC7smVzJEu9bsN99ZtRDPADUWWJXd9"}, {"type": "consensus", "amount": 20668, "account": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "gateway": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7"}, {"type": "consensus", "amount": 20668, "account": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "gateway": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa"}, {"type": "consensus", "amount": 20668, "account": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi", "gateway": "11wqsUwHe4CvVv8tz6at7YJ34yCLkXuTh7E22fzTkdNuCHJCopi"}, {"type": "securities", "amount": 253183, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "1Wh4bh"}, {"type": "consensus", "amount": 20668, "account": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "gateway": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy"}, {"type": "consensus", "amount": 20668, "account": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "gateway": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu"}], "end_epoch": 351, "start_epoch": 337}
353	zCfeZ863seKfF5af83psP99bWjPk9pStgVnz3_ywLB8	poc_request_v1	{"fee": 0, "owner": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQCLluOIsUfCYdVMGWhyXXuhCkptHHC3hsKNeWUDr5t9jAIgQMJ4V-grplVfBUq61yh3cUNDF_hn6BKiOJM-TL90ZW0", "block_hash": "Bkgi4ffPoQ1CNpDnFjGLv8yoYMVSO-mbIZVEZbS85fM", "challenger": "11zVV9wq1yWt3ef9uNbzRgqHjFxztFh7ojwMX3UsoGmcXqk5pbu", "secret_hash": "x7b65PC5JmZA8kiQaILK4xF1oSI9hx8ELhWyvGbyEDc", "onion_key_hash": "RU86vDA1G_l30f-jJShM0rJpTIYXsZQKFrJt5Srp1hI"}
353	twkKob87iXsnsIQuhO76mFd-_SqDmMSP320Y9u52jP8	poc_request_v1	{"fee": 0, "owner": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDb75Khr_Sof7UWu0JQEjNDa8otNkM4JpitEiyE3I91CAIgWR-IgasnioTv_jbxzjQlYKufp1diXV2eAasT3tsEUAk", "block_hash": "-21_oEjD1E2eGWt0wDm1IALob2MwLLvwXmLlUDLixyI", "challenger": "11jcLbLrg27cThMozncv3fNiq87C4ASx2qpsVrwLQyq6rpdr5r7", "secret_hash": "IpCE3rFYo4Bz6_4KSAglmgDABaNdjGoqJx-HVG6nxLs", "onion_key_hash": "TAe3I7VFMYleEbzaynas7rNs1ClFEDmQrg_eChg7CjM"}
357	q6WzuYAUFz1VXeFq7nN_r2D60NGu8MXPmbbr1Bur8jw	poc_request_v1	{"fee": 0, "owner": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "version": 2, "location": "8c283475d4e89ff", "signature": "MEUCIQDSDylb91WkH4qkTqgtrXK-_ZkvdXyqKm-ml_S5y9rhBwIgDQLyzHNujX88t_fIdAC3OcppRNlqiPUtUAdHd8EDBY8", "block_hash": "Ihv9s0tMNHaEZ2LnE8aXIoF9U6otg3uS89-RCGNq_Wc", "challenger": "11vXtGRrxXLptKY3MBwho8DkwPJCjUV87ojqN8AHUmvLiNWAzqa", "secret_hash": "wMWQlqDE839Sv6agvIw_00NsHHWMtoAORGVHZRrSC6Y", "onion_key_hash": "Czm5yPVf_HR8hUb8PmdLL4UcCFe1g2M9szBG6VQGO1w"}
361	O4ncYBLGSFeY-f1A80306b9Er-_19A4IGr4Wy3BMX90	poc_request_v1	{"fee": 0, "owner": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "version": 2, "location": "8c283475d4e89ff", "signature": "MEYCIQCqR5x0lyNn8GDR2r7rO7YyXKmNteIeKSFOtyGUbiuspAIhAMaz2pv645gr_XiF7m8rpwG3klF8GSlsGhA8CZBYdDMN", "block_hash": "U90n2KZzVFxioGbuSiOucHFuseVYxqUd_k9Ic2YPwv4", "challenger": "11xCZqoxRx2M8qJmnRPAty7XdtANuxKx2ozDmnaosJJnhXtazPy", "secret_hash": "OAEswTeo7zRWwzx1uVGUZdQmp1GDW6pslfp_3FTOOFE", "onion_key_hash": "h-8mMjR1-5qR94QdZC4OkDaMbDB4z4GPSjnKup5tvV4"}
362	vzZzYlp8sL_VDoyv_GtiSqKXLONHAcRNddzDOBrzigk	poc_request_v1	{"fee": 0, "owner": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "version": 2, "location": "8c283475d4e89ff", "signature": "MEQCIA_85EwFjihif7KD2f4WEkn62CY1FOxMWkQDsVW9gkhaAiBRJrU9sI_gIGADiU64RQULHeWrXUfybeCYfX7VIlOrFg", "block_hash": "EfdR9NoVU8r-XhGI4zspAx4-BEwrk00k9W9HA7pXFSc", "challenger": "11DgUM5d3mF4BY5U27qRQaJ4iusumHBWX76eBA695utoyVfk4h2", "secret_hash": "bB86kPwr8xydwqN-060yoIo9zDWGJl22Lggpcp0WJOE", "onion_key_hash": "JeobN_qSzBwrtrS-ktvieZAL_tFhUJsc8RKsOE0tUI0"}
\.


--
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: __migrations __migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.__migrations
    ADD CONSTRAINT __migrations_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (block, address);


--
-- Name: block_signatures block_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.block_signatures
    ADD CONSTRAINT block_signatures_pkey PRIMARY KEY (block, signer);


--
-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (height);


--
-- Name: gateways gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateways
    ADD CONSTRAINT gateways_pkey PRIMARY KEY (block, address);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location);


--
-- Name: pending_transactions pending_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_transactions
    ADD CONSTRAINT pending_transactions_pkey PRIMARY KEY (hash);


--
-- Name: transaction_actors transaction_actors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_actors
    ADD CONSTRAINT transaction_actors_pkey PRIMARY KEY (actor, actor_role, transaction_hash);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (hash);


--
-- Name: account_address_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX account_address_idx ON public.accounts USING btree (address);


--
-- Name: account_block_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX account_block_idx ON public.accounts USING btree (block);


--
-- Name: account_ledger_address_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX account_ledger_address_idx ON public.account_ledger USING btree (address);


--
-- Name: gateway_address_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gateway_address_idx ON public.gateways USING btree (address);


--
-- Name: gateway_block_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gateway_block_idx ON public.gateways USING btree (block);


--
-- Name: gateway_ledger_gateway_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX gateway_ledger_gateway_idx ON public.gateway_ledger USING btree (address);


--
-- Name: gateway_owner_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gateway_owner_idx ON public.gateways USING btree (owner);


--
-- Name: pending_transaction_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pending_transaction_created_idx ON public.pending_transactions USING btree (created_at);


--
-- Name: pending_transaction_nonce_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pending_transaction_nonce_type_idx ON public.pending_transactions USING btree (nonce_type);


--
-- Name: transaction_block_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX transaction_block_idx ON public.transactions USING btree (block);


--
-- Name: transaction_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX transaction_type_idx ON public.transactions USING btree (type);


--
-- Name: pending_transactions pending_transaction_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER pending_transaction_set_updated_at BEFORE UPDATE ON public.pending_transactions FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: accounts accounts_block_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_block_fkey FOREIGN KEY (block) REFERENCES public.blocks(height) ON DELETE CASCADE;


--
-- Name: block_signatures block_signatures_block_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.block_signatures
    ADD CONSTRAINT block_signatures_block_fkey FOREIGN KEY (block) REFERENCES public.blocks(height) ON DELETE CASCADE;


--
-- Name: gateways gateways_block_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateways
    ADD CONSTRAINT gateways_block_fkey FOREIGN KEY (block) REFERENCES public.blocks(height) ON DELETE CASCADE;


--
-- Name: gateways gateways_last_poc_challenge_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateways
    ADD CONSTRAINT gateways_last_poc_challenge_fkey FOREIGN KEY (last_poc_challenge) REFERENCES public.blocks(height) ON DELETE SET NULL;


--
-- Name: transaction_actors transaction_actors_transaction_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_actors
    ADD CONSTRAINT transaction_actors_transaction_hash_fkey FOREIGN KEY (transaction_hash) REFERENCES public.transactions(hash) ON DELETE CASCADE;


--
-- Name: transactions transactions_block_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_block_fkey FOREIGN KEY (block) REFERENCES public.blocks(height) ON DELETE CASCADE;


--
-- Name: account_ledger; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.account_ledger;


--
-- Name: gateway_ledger; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.gateway_ledger;


--
-- PostgreSQL database dump complete
--


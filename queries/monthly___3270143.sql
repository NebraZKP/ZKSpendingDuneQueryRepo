-- part of a query repo
-- query name: monthly
-- query link: https://dune.com/queries/3270143


WITH ASSUMPTION AS (
  SELECT
    220000 AS base_verify_cost, -- using roughly experienced 220000
    27 AS eth_gas_price,
    200 AS matic_gas_price,
    5 AS op_gas_price
),
ETH_PRICE AS (
  SELECT
    2000 AS eth_usd
), 
MATIC_PRICE AS (
  SELECT
    1 AS matic_usd
), 
ZKSYNC_ERA AS ( SELECT * FROM query_3270154 ),
AZTEC AS ( SELECT * FROM query_3270315 ),
POLYGON_ZKEVM AS ( SELECT * FROM query_3270164 ),
LOOPRING AS ( SELECT * FROM query_3270329 ),
TORNADO_CASH AS ( SELECT * FROM query_3270335 ),
RAILGUN AS ( SELECT * FROM query_3270346 ),
SHARP AS ( SELECT * FROM query_3270351 ),
DYDX AS ( SELECT * FROM query_3270361 ),

ALL_ZK_PROJECT AS (
    SELECT name, mon, cost, verify_call FROM ZKSYNC_ERA
    UNION ALL
    SELECT name, mon, cost, verify_call FROM POLYGON_ZKEVM
    UNION ALL
    SELECT name, mon, cost, verify_call FROM TORNADO_CASH
    UNION ALL
    SELECT name, mon, cost, verify_call FROM AZTEC
    UNION ALL
    SELECT name, mon, cost, verify_call FROM LOOPRING
    UNION ALL
    SELECT name, mon, cost, verify_call FROM RAILGUN
    UNION ALL
    SELECT name, mon, cost, verify_call FROM SHARP
    UNION ALL
    SELECT name, mon, cost, verify_call FROM DYDX
    -- UNION ALL
    -- SELECT name, mon, cost, verify_call FROM WORLDCOIN
)

SELECT * FROM ALL_ZK_PROJECT

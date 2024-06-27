-- part of a query repo
-- query name: ZKP Verify Spending
-- query link: https://dune.com/queries/3128234


WITH ASSUMPTION AS (
  SELECT
    250000 AS base_verify_cost, -- using roughly experienced 220000
    27 AS eth_gas_price,
    200 AS matic_gas_price,
    5 AS op_gas_price
),
ETH_PRICE AS (
--   SELECT
--     2000 AS eth_usd
select price as eth_usd
from prices.usd_latest
where blockchain is null
    and symbol = 'ETH'
), 
MATIC_PRICE AS (
  SELECT
    1 AS matic_usd
), 
/* ZKSync */
/* how we calculate the gas cost */
/* gas limit before entering the verifier.sol: 7537188 */
/* gas limit after: 6989391 */
/* total spending: 547797 */
/* source: https://etherscan.io/tx/0x2e7b8d87a0c682e5d498348b1c16ced198ceab818458c16e821e7790da191488/advanced#internal */ 
ZKSYNC_ERA 
AS (
  SELECT
    'ZKSYNC_ERA' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * 547797 * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM zksync_v2_ethereum.ValidatorTimelock_call_proveBlocks
  CROSS JOIN ASSUMPTION
  CROSS JOIN ETH_PRICE
  GROUP BY
    eth_gas_price,
    eth_usd
),
/* gas limit before entering the verifier.sol: 231182 */
/* gas limit after: 32160 */
/* total spending: 199076 */
/* source: https://etherscan.io/tx/0xa51e3791aac8082ea69c4756388116add0a715103a4b8b14ca18578174a516e8/advanced#internal */ 
POLYGON_ZKEVM AS (
  SELECT
    'POLYGON_ZKEVM' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * base_verify_cost * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM polygon_zkevm_ethereum.Bridge_call_verifyBatchesTrustedAggregator
  CROSS JOIN ASSUMPTION
  CROSS JOIN ETH_PRICE
  GROUP BY
    eth_gas_price,
    base_verify_cost,
    eth_usd
), 
/* gas limit before entering the verifier.sol: 11,662,192 */
/* gas limit after: 11,163,927 */
/* total spending: 498265 */
/* source: https://etherscan.io/tx/0x565626fc27fac951144d672fd8f4858b0e60a9c6f0045f98e607f04dbe652501/advanced#internal */ 
AZTEC AS (
  SELECT
    'AZTEC' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * 498265 * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM aztec_v2_ethereum.RollupProcessor_call_processRollup
  CROSS JOIN ASSUMPTION
  CROSS JOIN ETH_PRICE
  WHERE
    call_success
  GROUP BY
    eth_gas_price,
    base_verify_cost,
    eth_usd
), 
/* gas limit before entering the verifier.sol: 4,258,232 */
/* gas limit after: 4,141,264 */
/* total spending: 116968 */
/* https://etherscan.io/tx/0xcdd129cf9ec40f2048bf12d4ec1af7362f9ea1899d3b9254e96eb1a607a1f39b/advanced#internal */
LOOPRING AS (
  SELECT
    'LOOPRING' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * base_verify_cost * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM loopring_ethereum.LoopringIOExchangeOwner_call_submitBlocksWithCallbacks
  CROSS JOIN ASSUMPTION
  CROSS JOIN ETH_PRICE
  WHERE
    call_success
  GROUP BY
    eth_gas_price,
    base_verify_cost,
    eth_usd
), 
WORLDCOIN AS (
  WITH MAINNET AS (
    SELECT
      'WORLDCOIN(ethereum)' AS name,
      COUNT(*) AS verify_call,
      ROUND(
        TRY_CAST(COUNT(*) * base_verify_cost * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
        4
      ) AS cost
    FROM ethereum.traces
    CROSS JOIN ASSUMPTION
    CROSS JOIN ETH_PRICE
    CROSS JOIN MATIC_PRICE
    WHERE
      (
        to = 0x163b09b4fE21177c455D850BD815B6D583732432
      )
      AND BYTEARRAY_SUBSTRING(input, 1, 4) = 0x3bc778e3 /* verifyProof. -- TODO : more verifier address ? */
      AND block_number > 17584562 /* from deploy */
    GROUP BY
      eth_gas_price,
      base_verify_cost,
      eth_usd
  ), 
  OPTIMISM AS (
    SELECT
      'WORLDCOIN(optimism)' AS name,
      COUNT(*) AS verify_call,
      ROUND(
        TRY_CAST(COUNT(*) * base_verify_cost * op_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
        4
      ) AS cost
    FROM optimism.traces
    CROSS JOIN ASSUMPTION
    CROSS JOIN ETH_PRICE
    WHERE
      (
        to = 0x57f928158C3EE7CDad1e4D8642503c4D0201f611
      )
      AND BYTEARRAY_SUBSTRING(input, 1, 4) = 0x3bc778e3 /* verifyProof. -- TODO : more verifier address ? */
      AND block_number > 106734667 /* from deploy */
    GROUP BY
      op_gas_price,
      base_verify_cost,
      eth_usd
  ), ALL_WORLDCOIN AS (
    SELECT
      name,
      cost,
      verify_call
    FROM MAINNET
    UNION ALL
    SELECT
      name,
      cost,
      verify_call
    FROM OPTIMISM
  )
  SELECT
    'WORLDCOIN(optimism)' AS name,
    SUM(verify_call) AS verify_call,
    SUM(cost) AS cost
  FROM ALL_WORLDCOIN
), 
SISIMOS_ZKBADGE AS (
  WITH GNOSIS AS (
    SELECT
      'SISMO_ZKBADGE_GNOSIS' AS name,
      COUNT(*) AS verify_call,
      ROUND(TRY_CAST(COUNT(*) * 220000 * 0 AS DECIMAL(38, 10)) / 1000000000.0, 4) AS cost /* * */
    FROM gnosis.traces
    CROSS JOIN ASSUMPTION
    CROSS JOIN ETH_PRICE
    CROSS JOIN MATIC_PRICE
    WHERE
      (
        to = 0xf219a3a016DD785332A2305bf52544eE189fe233
      )
  ), POLYGON AS (
    SELECT
      'SISMO_ZKBADGE_POLYGON' AS name,
      COUNT(*) AS verify_call,
      ROUND(
        TRY_CAST(COUNT(*) * base_verify_cost * matic_gas_price * matic_usd AS DECIMAL(38, 10)) / 1000000000.0,
        4
      ) AS cost /* * */
    FROM polygon.traces
    CROSS JOIN ASSUMPTION
    CROSS JOIN ETH_PRICE
    CROSS JOIN MATIC_PRICE
    WHERE
      (
        to = 0x362Ff03CaC33C4c8Dc7fF98396Dc19a68F29F57C
      )
    GROUP BY
      matic_gas_price,
      base_verify_cost,
      matic_usd
  ), ALL_SISMO_ZKBADGE AS (
    SELECT
      name,
      cost,
      verify_call
    FROM GNOSIS
    UNION ALL
    SELECT
      name,
      cost,
      verify_call
    FROM POLYGON
  )
  SELECT
    'SISMO_ZKBADGE(Gnosis/Polygon)' AS name,
    SUM(verify_call) AS verify_call,
    SUM(cost) AS cost
  FROM ALL_SISMO_ZKBADGE
),
/* gas limit before entering the verifier.sol: 645,661 */
/* gas limit after: 277,993*/
/* total spending: 367668 */
/* source: https://etherscan.io/tx/0xb84fc66d11b8bb08c443015b384a5840a6a6cb013d9fe7204fd18e62dd801a9a/advanced#internal */ 
TORNADO_CASH AS (
  SELECT
    'TRONADO_CASH' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * 367668 * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM ethereum.transactions
  CROSS JOIN ETH_PRICE
  CROSS JOIN MATIC_PRICE
  CROSS JOIN ASSUMPTION
  WHERE
    (
      to = 0x12d66f87a04a9e220743712ce6d9bb1b5616b8fc
      OR to = 0x47ce0c6ed5b0ce3d3a51fdb1c52dc66a7c3c2936
      OR to = 0x910cbd523d972eb0a6f4cae4618ad62622b39dbf
      OR to = 0xa160cdab225685da1d56aa342ad8841c3b53f291
    )
    AND success
    AND BYTEARRAY_SUBSTRING(data, 1, 4) = 0x21a0adb6 /* withdraw */
  GROUP BY
    eth_gas_price,
    base_verify_cost,
    eth_usd
),
/* gas limit before entering the verifier.sol: 4,667,846 */
/* gas limit after: 4,078,049 */
/* total spending: 589,797 */
/* source: https://etherscan.io/tx/0x65f1192061bd0c3690cec8e201a29c60a10aff599a69b55954caf108c26da294/advanced#internal */ 
NOCTURNE AS (
    SELECT
      'NOCTURNE' AS name,
      COUNT(*) AS verify_call,
      ROUND(
        TRY_CAST(COUNT(*) * 589797 * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
        4
      ) AS cost
    FROM ethereum.traces
    CROSS JOIN ASSUMPTION
    CROSS JOIN ETH_PRICE
    WHERE
      (
        to = 0xA561492dFC1A90418Cc8b9577204d56C17CB32Ff
      )
      AND BYTEARRAY_SUBSTRING(input, 1, 4) = 0x2a1e64b6 /* processBundle*/
        AND block_number > 18524519 /* from deploy */
    GROUP BY
      eth_gas_price,
      eth_usd
  ),
/* gas limit before entering the verifier.sol: 1,320,699 */
/* gas limit after: 899,450*/
/* total spending: 421249 */
/* source: https://etherscan.io/tx/0xf961c5aee4b000de71c34f075ad1f5b1b3069144283d971e3a924b5083cbd76b/advanced#internal */ 
RAILGUN AS (
  SELECT
    'RAILGUN' AS name,
    COUNT(*) AS verify_call,
    ROUND(
      TRY_CAST(COUNT(*) * 421249 * eth_gas_price * eth_usd AS DECIMAL(38, 10)) / 1000000000.0,
      4
    ) AS cost
  FROM railgun_ethereum.RailgunLogic_call_transact
  CROSS JOIN ASSUMPTION
  CROSS JOIN ETH_PRICE
  CROSS JOIN MATIC_PRICE
  GROUP BY
    eth_gas_price,
    base_verify_cost,
    eth_usd
), ALL_ZKSNARK_PROJECT AS (
  SELECT name, cost, verify_call FROM ZKSYNC_ERA
  UNION ALL
  SELECT name, cost, verify_call FROM POLYGON_ZKEVM
  UNION ALL
  SELECT name, cost, verify_call  FROM TORNADO_CASH
  UNION ALL
  SELECT name, cost, verify_call  FROM AZTEC
  UNION ALL
  SELECT name, cost, verify_call  FROM LOOPRING
  UNION ALL
  SELECT name, cost, verify_call  FROM WORLDCOIN
  UNION ALL
  SELECT name, cost, verify_call  FROM NOCTURNE
  UNION ALL
  SELECT name, cost, verify_call  FROM RAILGUN
  UNION ALL
  SELECT name, cost, verify_call  FROM SISIMOS_ZKBADGE
), SHARP AS (
  SELECT
    'StarkNet/ImmutableX' AS name,
    SUM(1) AS verify_call,
    SUM(gas_used * gas_price / 1000000000000000000.0 * eth_usd) AS cost
  FROM ethereum.transactions
  CROSS JOIN ETH_PRICE
  WHERE
    (
      to = 0x47312450B3Ac8b5b8e247a6bB6d523e7605bDb60
    )
    AND success
    AND BYTEARRAY_SUBSTRING(data, 1, 4) = 0x9b3b76cc /* verifyProofAndRegister */
), DYDX AS (
  SELECT
    'dydx(starkEx)' AS name,
    SUM(1) AS verify_call,
    SUM(gas_used * gas_price / 1000000000000000000.0 * eth_usd) AS cost
  FROM ethereum.transactions
  CROSS JOIN ETH_PRICE
  WHERE
    (
      to = 0xC8c212f11f6ACca77A7afeB7282dEBa5530eb46C
    )
    AND success
    AND BYTEARRAY_SUBSTRING(data, 1, 4) = 0x9b3b76cc /* verifyProofAndRegister */
), ALL_ZKSTARK_PROJECT AS (
  SELECT * FROM SHARP
  UNION ALL
  SELECT * FROM DYDX
),
ALL_ZK_PROJECT AS (
  SELECT name, cost, verify_call  FROM ALL_ZKSNARK_PROJECT
  UNION ALL
  SELECT name, cost, verify_call  FROM ALL_ZKSTARK_PROJECT
), ORDER_GAS_ZK_PROJECT AS (
  SELECT * FROM ALL_ZK_PROJECT
  ORDER BY
    cost DESC
), ZK_PROJECT_COST_SUM AS (
    SELECT
      *,
      (SELECT SUM(cost) FROM ALL_ZKSNARK_PROJECT) AS zksnark_gas_total,
      (SELECT SUM(cost) FROM ALL_ZKSTARK_PROJECT) AS zkstark_gas_total
    FROM ORDER_GAS_ZK_PROJECT /* ORDER BY name */
    ORDER BY cost DESC
)

SELECT
  *,
  (zksnark_gas_total + zkstark_gas_total) AS gas_total
FROM ZK_PROJECT_COST_SUM /* ORDER BY name */
ORDER BY cost DESC
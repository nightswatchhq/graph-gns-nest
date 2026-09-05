-- What a subgraph *is*, from the GNS events (nuthatch#1160, group B). Names, descriptions and
-- manifests live on IPFS behind the hashes these views carry; nuthatch never fetches IPFS, and
-- Lodestar does, caching what it finds. A hash here is a bytes32: the CIDv0 is base58 of 0x1220
-- followed by it, the same rule as for deployment ids.

-- Every version of every subgraph, in order. `publishNewSubgraph` and `publishNewVersion` both emit
-- `SubgraphVersionUpdated`, so the first row per subgraph is version 0, as the subgraph numbers them.
CREATE VIEW subgraph_versions AS
SELECT tx_hash || '-' || CAST(log_index AS VARCHAR)                                     AS id,
       CAST(subgraphID AS VARCHAR)                                                       AS subgraph_id,
       subgraphDeploymentID                                                              AS deployment_id,
       versionMetadata                                                                   AS version_metadata,
       ROW_NUMBER() OVER (PARTITION BY subgraphID ORDER BY block_number, log_index) - 1 AS version,
       CAST(block_timestamp AS BIGINT)                                                   AS created_at,
       block_number,
       tx_hash
FROM gns__subgraph_version_updated;

-- One row per subgraph: its current deployment and version, its newest metadata hash, and whether
-- it has been deprecated. `SubgraphMetadataUpdated` fires on publish and on every later edit, so the
-- newest one is the subgraph's metadata now.
CREATE VIEW subgraph_current AS
WITH latest_version AS (
  SELECT subgraph_id, deployment_id, version_metadata, version, created_at AS version_created_at
  FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY subgraph_id ORDER BY block_number DESC, id DESC) AS rn FROM subgraph_versions)
  WHERE rn = 1
),
latest_metadata AS (
  SELECT CAST(subgraphID AS VARCHAR) AS subgraph_id, subgraphMetadata AS subgraph_metadata, CAST(block_timestamp AS BIGINT) AS metadata_updated_at
  FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY subgraphID ORDER BY block_number DESC, log_index DESC) AS rn FROM gns__subgraph_metadata_updated)
  WHERE rn = 1
),
first_seen AS (
  SELECT CAST(subgraphID AS VARCHAR) AS subgraph_id, MIN(CAST(block_timestamp AS BIGINT)) AS created_at FROM gns__subgraph_published GROUP BY 1
),
deprecated AS (
  SELECT DISTINCT CAST(subgraphID AS VARCHAR) AS subgraph_id FROM gns__subgraph_deprecated
),
from_l1 AS (
  SELECT CAST("_l2SubgraphID" AS VARCHAR) AS subgraph_id, CAST("_l1SubgraphID" AS VARCHAR) AS l1_subgraph_id, LOWER("_owner") AS owner FROM gns__subgraph_received_from_l1
)
SELECT v.subgraph_id,
       v.deployment_id                       AS current_deployment_id,
       v.version                             AS current_version,
       v.version_metadata                    AS current_version_metadata,
       m.subgraph_metadata,
       m.metadata_updated_at,
       COALESCE(f.created_at, v.version_created_at) AS created_at,
       d.subgraph_id IS NOT NULL             AS deprecated,
       l.l1_subgraph_id,
       l.owner                               AS l1_owner
FROM latest_version v
LEFT JOIN latest_metadata m ON m.subgraph_id = v.subgraph_id
LEFT JOIN first_seen f ON f.subgraph_id = v.subgraph_id
LEFT JOIN deprecated d ON d.subgraph_id = v.subgraph_id
LEFT JOIN from_l1 l ON l.subgraph_id = v.subgraph_id;

-- Deployment to the subgraphs that ever published it, newest version first, with whether that
-- subgraph still points at it. The subgraph's `subgraphDeployment.versions` in table form.
CREATE VIEW deployment_subgraphs AS
SELECT sv.deployment_id,
       sv.subgraph_id,
       sv.version,
       sv.version_metadata,
       sv.created_at,
       sc.current_deployment_id = sv.deployment_id AS is_current,
       sc.subgraph_metadata,
       sc.deprecated
FROM subgraph_versions sv
JOIN subgraph_current sc ON sc.subgraph_id = sv.subgraph_id;

-- A Graph account's declared default name: the newest `SetDefaultName` per account. `nameSystem` is
-- 0 for ENS, and `name` is the name as declared; this is the subgraph's `account.defaultDisplayName`.
CREATE VIEW account_default_names AS
SELECT LOWER(graphAccount) AS account, name, CAST(nameSystem AS INTEGER) AS name_system, nameIdentifier AS name_identifier,
       CAST(block_timestamp AS BIGINT) AS set_at
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY LOWER(graphAccount) ORDER BY block_number DESC, log_index DESC) AS rn FROM gns__set_default_name)
WHERE rn = 1 AND name <> '';

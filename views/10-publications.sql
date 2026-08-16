CREATE VIEW subgraph_publications AS
SELECT
  tx_hash || '-' || CAST(log_index AS VARCHAR) AS id,
  subgraphID AS subgraph_id,
  subgraphDeploymentID AS deployment_id,
  reserveRatio AS reserve_ratio,
  block_timestamp AS published_at,
  block_number,
  tx_hash
FROM gns__subgraph_published;

-- Pinned fixture: immutable L2GNS publication history and its covered block range.
SELECT
  COUNT(*) AS publication_count,
  COUNT(DISTINCT subgraph_id) AS subgraph_count,
  MIN(block_number) AS first_block,
  MAX(block_number) AS last_block
FROM subgraph_publications;

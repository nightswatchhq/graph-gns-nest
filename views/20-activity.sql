CREATE VIEW developer_activity_weekly AS
WITH weeks AS (
  SELECT
    date_trunc('week', to_timestamp(published_at)) AS week_start,
    COUNT(*) AS published_count
  FROM subgraph_publications
  GROUP BY week_start
)
SELECT
  week_start,
  published_count,
  SUM(published_count) OVER (ORDER BY week_start) AS cumulative_published,
  -- The latest observed week may still receive publications. Derive this solely from indexed
  -- chain data, rather than wall-clock `now()`, so a sealed historical query is reproducible.
  week_start = MAX(week_start) OVER () AS partial
FROM weeks
ORDER BY week_start;

CREATE VIEW subgraph_activity AS
SELECT
  subgraph_id,
  MIN(published_at) AS published_at,
  COUNT(*) AS publication_count
FROM subgraph_publications
GROUP BY subgraph_id;

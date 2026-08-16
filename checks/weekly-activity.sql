-- Pinned fixture: the latest deterministic weekly publication buckets.
SELECT week_start, published_count, cumulative_published, partial
FROM developer_activity_weekly
ORDER BY week_start DESC
LIMIT 25;

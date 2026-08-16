# Graph Name Service nest

An installable Nuthatch nest for L2GNS publication activity on Arbitrum One. It is the standalone
package intended to serve Lodestar's Developer Activity chart.

```sh
nuthatch init --from https://github.com/nightswatchhq/graph-gns-nest
nuthatch dev --dir graph-gns-nest --rpc https://your-archive-rpc
```

## Query surface

`subgraph_publications` exposes the immutable L2GNS publication stream. `developer_activity_weekly`
is the dashboard-ready weekly series, with an explicit partial-current-week flag, and
`subgraph_activity` gives each published L2GNS identifier's first publication.

This nest is intentionally event-native. It does not pretend to include L1-origin or legacy entities
which the Network subgraph may fold into its entity model.

## Provenance and release gate

The contract is L2GNS at `0xec9A7fb6CbC2E41926127929c2dcE6e9c5D33Bec`. The ABI is vendored from
the production nest. Before catalogue availability, record fixed-block parity fixtures against the
Lodestar production chart and document its known L1/legacy divergence.

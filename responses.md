# Flowchart Design Improvements

## Biggest Wins First
- Transitive reduction of prerequisites
  - Remove long, redundant edges (if A→B and B→C, prune A→C).
  - How: build reachability over CourseTiles and drop edges with alternate paths.
  - Toggle idea: `PRUNE_TRANSITIVE_EDGES = true`.
- Connector “bus + stub” routing
  - Draw a vertical bus per term, connect tiles with short stubs, and route inter‑term edges along buses.
  - Groups parallel edges and reduces crossings dramatically.
- Show only cross‑term dependencies
  - Within the same term, replace full arrows with a small intra‑lane mark and add a legend entry.
  - Toggle idea: `SHOW_INTRA_TERM_ARROWS = false`.

## Layout & Visual Tweaks
- Increase spacing via constants in `src/constants.jl`:
  - `DPCANVAS_TERM.sem_gap += 5–10`, `year_gap += 10–15`, `tile_sep += 10–20`.
- Fade and thin connectors:
  - Use semi‑transparent colors in `CONNECTOR_COLOR_HEX` (e.g., `#842bd777`) and slightly reduce `CONNECTOR_LENGTHS`.
- Soften crossings:
  - Use mild Bezier curves for long connectors.
- Raise branch threshold:
  - Increase `BRANCH_Y_THRESHOLD` so more arrows use an extra hop away from tiles.

## Structural Options
- Group by type bands
  - Add horizontal bands per type (GS/MS/CR/…) and route along band borders for chunking.
- Multi‑page outputs
  - Produce separate charts: short deps only (term_gap==1), long‑range only (term_gap>1), per type or per academic year.

## Implementation Hints
- Transitive reduction (in `src/functions.jl`):
  - Index nodes by `(code, term, order)`; for each edge `u→v`, BFS from `u` ignoring that edge—if `v` reachable, drop.
  - Rebuild `CourseTile` list with pruned `prereqs`.
- Bus routing (replace current `get_fork_points` use):
  - Precompute `bus_x[term]` slightly left of tiles.
  - For each edge `u→v`: stub to `bus_x[u]` → vertical run → cross to `bus_x[v]` → stub into `v`.
  - Draw buses first (low alpha), then stubs/arrows.

If you want, I can implement transitive reduction and a minimal bus routing mode behind flags in `src/constants.jl` so you can compare results easily.

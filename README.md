# Degree Plan Flowchart Generator (Julia)

A small Julia project that renders degree‑plan flowcharts from an Excel file into a PDF (or an on‑screen preview) using Luxor.

## Requirements
- Julia 1.x
- Packages: `CSV`, `Colors`, `DataFrames`, `Format`, `Luxor`, `XLSX`

Install deps:
- `julia --project -e "using Pkg; Pkg.instantiate()"`

## Quick Start
1) Place your Excel file at the repo root. Its name should start with the prefix in `DEFAULT_FILENAME_PREFIX` (see `src/constants.jl`).
2) Ensure the sheet/table name in your file matches `DEFAULT_DATA_TABLE`.
3) Generate the PDF:
- `julia --project -e "include(\"src/main.jl\"); draw_summer_chart(output=:pdf, is_summer=true, filenameprefix=DEFAULT_FILENAME_PREFIX, data_table=DEFAULT_DATA_TABLE, degree_name=DEFAULT_DEGREE_NAME)"`
4) Preview (on screen instead of a file):
- `julia --project -e "include(\"src/main.jl\"); draw_summer_chart(output=:draw, is_summer=true, filenameprefix=DEFAULT_FILENAME_PREFIX, data_table=DEFAULT_DATA_TABLE, degree_name=DEFAULT_DEGREE_NAME)"`

Outputs are written to `charts/` (e.g., `FlowChartSummer.pdf`). A working copy of the Excel is kept in `./copies/`.

## Configuration
All hard‑coded parameters are centralized in `src/constants.jl`:
- Paths and filenames: prefixes, `charts/`, `copies/`.
- Canvas and layout: margins, lane sizes, tile sizes, spacing.
- Colors, fonts, and legend settings.
- Special courses and note‑box geometry.

Adjust values there to tweak visuals or data defaults without touching logic.

## Data Expectations
The sheet should include columns used by the code: `Course`, `Cr`, `Type`, `Term` (and optionally `INTERN_Term`), `PreReqTile`, `Note`, `Notes`, `PreRequests`.

If your sheet uses a different tab name (e.g., `Data` vs `DATA_LIST`), pass it with `data_table=...` or update `DEFAULT_DATA_TABLE`.

## Troubleshooting
- “No Degree Plan File”: ensure a matching `*.xlsx` file exists at repo root and matches the configured prefix.
- Empty output or missing courses: check the sheet/tab name and the columns listed above.
- Overlapping connectors: tune routing constants in `src/constants.jl` (`TOP_RIGHT_INCREMENTS`, thresholds, etc.).

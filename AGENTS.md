# Repository Guidelines

## Project Structure & Module Organization
- `src/`: Julia source (entry: `main.jl`; helpers in `functions.jl`, `types.jl`, `depts.jl`). Use `includes.jl` to load internals.
- `charts/`: Generated outputs (e.g., `FlowChartSummer.pdf`). Created automatically.
- Data inputs: Excel file at repo root matching prefix (default `Yazan_DegreePlan*.xlsx`). A working copy is placed in `./copies/`.

## Build, Test, and Development Commands
- Install deps: `julia --project -e "using Pkg; Pkg.instantiate()"`
- Run in REPL: `julia --project` then `include("src/main.jl")`.
- Render PDF: `julia --project -e "include(\"src/main.jl\"); draw_summer_chart(output=:pdf, is_summer=true, filenameprefix=\"Yazan_DegreePlan\", data_table=\"DATA_LIST\", degree_name=\"B.S. DATA\")"`
- Preview on screen: same call with `output=:draw`.

## Coding Style & Naming Conventions
- Julia 1.x, 4‑space indentation, UTF‑8, no trailing whitespace.
- Prefer descriptive names. Follow existing public names; use `snake_case` for new functions; types in `CamelCase`.
- Keep pure rendering logic in `src/main.jl`; data/load/layout helpers in `src/functions.jl`; structs and types in `src/types.jl`.
- Run formatter if available: `using JuliaFormatter; format("src"; style="blue")` (optional).

## Testing Guidelines
- Framework: Julia `Test`. Place tests in `test/runtests.jl` mirroring `src/` functions.
- Run: `julia --project -e "using Pkg; Pkg.test()"`.
- Add unit tests for data parsing, layout computations, and file path handling. Rendering can be smoke‑tested (no error, files created).

## Commit & Pull Request Guidelines
- Commits: imperative, concise; group related changes. Prefer Conventional Commits, e.g., `feat: add summer chart wrapper`, `fix: prevent missing copies dir`.
- PRs: include summary, rationale, before/after screenshot or generated file path (e.g., `charts/FlowChartSummer.pdf`), and steps to reproduce.
- Link related issues and note any data/table name assumptions.

## Security & Configuration Tips
- Inputs: Ensure the Excel file exists at repo root and matches `filenameprefix`. Create `./copies/` if missing.
- Paths: Code reads `@__DIR__/../..` for source Excel; avoid absolute paths in code.
- Do not commit confidential spreadsheets; use `.gitignore` for `*.xlsx` if needed.

## Agent‑Specific Notes
- Do not rename existing public functions without discussion (`draw_summer_chart`, `getDSECourses`, etc.).
- Keep changes minimal and localized; prefer adding small helpers over large refactors.

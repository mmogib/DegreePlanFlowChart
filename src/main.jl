## Entry point
# Quick start:
# - Install deps: julia --project -e "using Pkg; Pkg.instantiate()"
# - Render PDF:   julia --project -e "include(\"src/main.jl\"); draw_summer_chart(output=:pdf, is_summer=true, filenameprefix=DEFAULT_FILENAME_PREFIX, data_table=DEFAULT_DATA_TABLE, degree_name=DEFAULT_DEGREE_NAME)"
# - Preview:      julia --project -e "include(\"src/main.jl\"); draw_summer_chart(output=:draw, is_summer=true, filenameprefix=DEFAULT_FILENAME_PREFIX, data_table=DEFAULT_DATA_TABLE, degree_name=DEFAULT_DEGREE_NAME)"
# Configuration lives in src/constants.jl (paths, layout, colors, fonts).

include("includes.jl")

draw_summer_chart(output=:pdf, is_summer=true,
    filenameprefix=DEFAULT_FILENAME_PREFIX,
    data_table=DEFAULT_DATA_TABLE,
    degree_name=DEFAULT_DEGREE_NAME,
    db_file=DEFAULT_FILENAME_LOCATION
)

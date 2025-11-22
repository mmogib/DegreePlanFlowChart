# Centralized constants for configuration and styling

# Data and paths
const DEFAULT_FILENAME_PREFIX = "Yazan_DegreePlan"
const DEFAULT_DEGREE_NAME="BS-X in Internet of Things & Data Analytics"
const DEFAULT_DATA_TABLE = "Data"
const EXCEL_SUFFIX = "xlsx"
const ROOT_RELATIVE = "../.."             # used with `joinpath(@__DIR__, ROOT_RELATIVE)`
const COPIES_DIR = "./copies"
const CHARTS_DIR = "./charts"
const SUMMER_CHART_FILENAME = "YazanFlowChartSummer.pdf"
const INTERNSHIP_CHART_FILENAME = "FlowChartInternship.pdf"

# Canvas and scene
const A4_CANVAS_NAME = "A4landscape"
const BACKGROUND_COLOR = "white"
const CANVAS_H_SUB = 100
const H_ADJUST_AFTER_SETUP = 20
const GUIDE_DOT_RADIUS_SMALL = 0.1
const GUIDE_DOT_RADIUS = 4
const YEAR_LABEL_X_OFFSET = 40
const YEAR_LABEL_Y_OFFSET = 35
const SUMMER_LABEL_X_OFFSET = 1

# DPCanvas presets (numbers only; main builds DPCanvas from these)
const DPCANVAS_TERM = (
	lane_width = 80,
	lane_height_sub = 100,
	x_inc = 80,
	x_left_margin = 70,
	y = 40,
	sem_gap = 5,
	year_gap = 10,
	tile_h = 35,
	tile_sep = 75,
)
const DPCANVAS_INTERNSHIP = (
	lane_width = 90,
	lane_height_sub = 100,
	x_inc = 80,
	x_left_margin = 70,
	y = 40,
	sem_gap = 20,
	year_gap = 25,
	tile_h = 35,
	tile_sep = 62,
)

# Layout calculations
const LANE_X_LEFT_PAD = 10
const TILE_Y_BASE_OFFSET = 80
const TILE_WIDTH_INNER_MARGIN = 15

# Year/term organization
const YEAR_TERMS_WITH_SUMMER = Dict(1 => [1, 2], 2 => [3, 4], 3 => [5, 6], 4 => ["s"], 5 => [7, 8])
const YEAR_TERMS_NO_SUMMER = Dict(1 => [1, 2], 2 => [3, 4], 3 => [5, 6], 4 => [7, 8])
const SUMMER_NUMERIC_TERM = 6.5
const TERM_COUNTER_SUMMER = Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "6.5" => 7, "7.0" => 8, "8.0" => 9)
const TERM_COUNTER_REGULAR = Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "7.0" => 7, "8.0" => 8)

# Theme colors (hex/rgba strings). Conversion to Color done at use-site.
const THEME_COLOR_RAW = Dict(
	:sem_border => "rgba(111,118,129,0.6)",
	:sem_title => "#54c45e",
	:primary => "black",
	:secondary => "#008a0e",
	:DF => "#F8CBAD",
	:GS => "#C6E0B4",
	:MS => "#FFE699",
	:CR => "#BDD7EE",
	:CE => "#DDEBF7",
	:TE => "#99FFCC",
)

# Fonts and sizes
const FONT_PRIMARY = "Liberation Sans"
const FONT_COURSE = "Rotis SansSerif Std"
const FONT_SIZE_BANNER = 15
const FONT_SIZE_TITLE = 14
const FONT_SIZE_CREDITS = 12
const FONT_SIZE_LEGEND = 8

# Semester lane styling
const SEMESTER_TITLE_HEIGHT = 20
const CREDIT_SUFFIX = " cr."
const SEMESTER_DIVIDER_Y_OFFSET = 40
const SEMESTER_DIVIDER_STROKE = 0.7
const SEMESTER_BOX_STROKE = 0.5

# Legends
const LEGEND_LABEL = "Legend: J = Junior Standing "
const LEGEND_MARGIN_X = 20
const LEGEND_MARGIN_Y = 10
const LEGEND_SECOND_X = 60
const LEGEND_TYPE_TEXT_BASE = 120
const LEGEND_TYPE_TEXT_PADDING = 95
const LEGEND_GRID_WIDTH = 110
const LEGEND_CIRCLE_RADIUS = 6

# Connector visuals and routing
const CONNECTOR_COLOR_HEX = [
	"#0a0c08",
	"#842bd7",
	"#ff206e",
	"#2c0735",
	"#5e2bff",
	"#2c0735",
	"#ff0202",
	"#ff8700",
	"#7364d2",
]
const CONNECTOR_LENGTHS = [0.9, 1.2, 0.9, 1.2]
const BRANCH_Y_THRESHOLD = 50
const CONNECTOR_ALPHA = 1.0               # 0..1 transparency for connectors
const CONNECTOR_THICKNESS_SCALE = 1.0    # scale factor for connector thickness

const TOP_RIGHT_INCREMENTS = [14, 8, 6]
const BOTTOM_RIGHT_INCREMENTS = [10, 12, 14]
const ROUTE_X_OFFSET = 10
const ROUTE_X_LEFT_DELTA = 10
const ROUTE_X_COLLISION_TOL = 6
const ROUTE_X_STACK_INCREMENT = 2
const ROUTE_Y_COLLISION_DELTA_UP = 5
const ROUTE_Y_COLLISION_DELTA_DOWN = 15

# Tile appearance and offsets
const TILE_POLY_SMOOTH = 0.2
const SIDE_BAR_COLOR_RGBA = "rgba(150,0,200,0.6)"
const SIDE_BAR_LINE_WIDTH = 2.0
const TILE_OUTLINE_LINE_WIDTH = 1.0
const NOTE_TEXT_OFFSET_Y = 5
const CODE_TEXT_OFFSET_Y = -10
const CREDITS_OFFSET_X = 20
const CREDITS_OFFSET_Y = 15

# Special course note boxes
const SPECIAL_COURSES = ["ICS 399", "DATA 398"]
const SUMMER_NOTE_Y_OFFSET = 150
const INTERNSHIP_NOTE_Y_OFFSET = 220
const PREQ_BOX_SCALE_W = 1.2
const PREQ_BOX_SCALE_H = 2.0
const PREQ_TEXTWRAP_OFFSET_X = -35
const PREQ_TEXTWRAP_OFFSET_Y = -35
const PREQ_ARROW_Y_OFFSET = -5
const PREQ_ARROW_X_FACTOR = 0.5

# Types/edges
const TILE_EDGE_OFFSET = 5

# Bus routing (connector “bus + stub”)
const USE_BUS_ROUTING = false
const DRAW_BUS_LINES = false
const BUS_OFFSET = 12                 # distance left of tile left edge
const BUS_LINE_WIDTH = 0.8
const BUS_COLOR = THEME_COLOR_RAW[:sem_border]
const BUS_TOP_MARGIN = 0              # extra margin at top of lane when drawing bus
const BUS_BOTTOM_MARGIN = 0           # extra margin at bottom of lane when drawing bus

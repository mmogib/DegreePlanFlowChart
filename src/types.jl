struct TileEdgePoint
    x::Number
    y::Number
    order::Int
    free::Bool
end
# TileEdgePoint(x::Number, y::Number, order::Int, free::Bool) = TileEdgePoint(x, y, order, free)
TileEdgePoint(t::TileEdgePoint, f::Bool) = TileEdgePoint(t.x, t.x, t.order, f)
Base.:(==)(t1::TileEdgePoint, t2::TileEdgePoint) = t1.x == t2.x && t1.y == t2.y
struct CourseTile
    code::String
    type::String
    credits::Int
    term::Float64
    PreReqTile::String
    Note::String
    Notes::String
    order::Int
    x::Number
    y::Number
    w::Number
    h::Number
    c::Color
    TRPoints::Vector{TileEdgePoint}
    BRPoints::Vector{TileEdgePoint}
    TLPoints::Vector{TileEdgePoint}
    BLPoints::Vector{TileEdgePoint}
    prereqs::Union{Nothing,Vector{CourseTile}}
end
CourseTile(code::String, type::String, credits::Int, term::Float64, pre::String, note::String, notes::String, order::Int, x::Number, y::Number, w::Number, h::Number, c::Color) = begin
    TR = [
        TileEdgePoint(x + w / 2 - TILE_EDGE_OFFSET, y - h / 2, 1, true),
        TileEdgePoint(x + w / 2, y - h / 2, 2, true),
        TileEdgePoint(x + w / 2, y - h / 2 + TILE_EDGE_OFFSET, 3, true),
    ]
    BR = [
        TileEdgePoint(x + w / 2, y + h / 2 - TILE_EDGE_OFFSET, 1, true),
        TileEdgePoint(x + w / 2, y + h / 2, 2, true),
        TileEdgePoint(x + w / 2 - TILE_EDGE_OFFSET, y + h / 2, 3, true),
    ]

    TL = [
        TileEdgePoint(x - w / 2 + TILE_EDGE_OFFSET, y - h / 2, 1, true),
        TileEdgePoint(x - w / 2, y - h / 2, 2, true),
        TileEdgePoint(x - w / 2, y - h / 2 + TILE_EDGE_OFFSET, 3, true),
    ]
    BL = [
        TileEdgePoint(x - w / 2 + TILE_EDGE_OFFSET, y + h / 2, 1, true),
        TileEdgePoint(x - w / 2, y + h / 2, 2, true),
        TileEdgePoint(x - w / 2, y + h / 2 - TILE_EDGE_OFFSET, 3, true),
    ]

    CourseTile(code, type, credits, term, pre, note, notes, order, x, y, w, h, c, TR, BR, TL, BL, nothing)
end
CourseTile(c::CourseTile, crs::Vector{CourseTile}) = CourseTile(c.code, c.type, c.credits, c.term, c.PreReqTile, c.Note, c.Notes, c.order, c.x, c.y, c.w, c.h, c.c, c.TRPoints, c.BRPoints,
    c.TLPoints, c.BLPoints, crs)

CourseTile(c::CourseTile, tiles::Vector{TileEdgePoint}, position::Symbol) = begin
    tr, br, tl, bl = if position == :TR
        tiles, c.BRPoints, c.TLPoints, c.BLPoints
    elseif position == :BR
        c.TRPoints, tiles, c.TLPoints, c.BLPoints
    elseif position == :TL
        c.TRPoints, c.BRPoints, tiles, c.BLPoints
    else
        c.TRPoints, c.BRPoints, c.TLPoints, tiles
    end
    CourseTile(c.code, c.type, c.credits, c.term, c.PreReqTile, c.Note, c.Notes, c.order, c.x, c.y, c.w, c.h, c.c, tr, br, tl, bl, c.prereqs)
end
Base.:(==)(c1::CourseTile, c2::CourseTile) = c1.code == c2.code && c1.term == c2.term && c1.order == c2.order

"""
Represents the layout configuration for a degree plan canvas, using vertical swimlanes to organize semester courses.

# Fields
- `lane_width::Number`: The height of a swimlane, containing the courses for a semester.
- `lane_height::Number`: The width of a swimlane, containing the courses for a semester.
- `x_inc::Number`: Small offset added to the x-coordinate for aligning course tiles within a lane.
- `x::Number`: The x-coordinate of the top-left corner of the first swimlane.
- `y::Number`: The y-coordinate of the top-left corner of the first swimlane, adjusted to accommodate a title tile.
- `sem_gap::Number`: The vertical distance between consecutive semester swimlanes.
- `year_gap::Number`: The vertical distance between the last semester lane of one year and the first semester lane of the next year.
- `tile_h::Number`: The height of individual course tiles within a swimlane.
- `tile_separator::Number`: The vertical distance between consecutive course tiles within the same swimlane.

# Description
`DPCanvas` provides the parameters needed to layout and render a degree plan flowchart. Vertical swimlanes represent semesters, with courses displayed as tiles inside these lanes. This structure ensures clarity in presenting the sequence and organization of courses across semesters and academic years.
"""
struct DPCanvas
    lane_width::Number      # height of swimlane (containing semester courses)
    lane_height::Number     # width of swimlane (containing semester courses)
    x_inc::Number           # increase in x (row dirction) small offest in x
    x::Number               # top left corner x-coordinate of the lane 
    y::Number               # top left corner yx-coordinate of the lane after the title tile
    sem_gap::Number         # distance between a semester lane and the next lane
    year_gap::Number        # distance between a semester lane (end of year) and the next lane (next year)
    tile_h::Number          # height of course tile
    tile_separator::Number  # distance between a course tile and the next
end

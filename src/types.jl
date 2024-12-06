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
        TileEdgePoint(x + w / 2 - 5, y - h / 2, 1, true),
        TileEdgePoint(x + w / 2, y - h / 2, 2, true),
        TileEdgePoint(x + w / 2, y - h / 2 + 5, 3, true),
    ]
    BR = [
        TileEdgePoint(x + w / 2, y + h / 2 - 5, 1, true),
        TileEdgePoint(x + w / 2, y + h / 2, 2, true),
        TileEdgePoint(x + w / 2 - 5, y + h / 2, 3, true),
    ]

    TL = [
        TileEdgePoint(x - w / 2 + 5, y - h / 2, 1, true),
        TileEdgePoint(x - w / 2, y - h / 2, 2, true),
        TileEdgePoint(x - w / 2, y - h / 2 + 5, 3, true),
    ]
    BL = [
        TileEdgePoint(x - w / 2 + 5, y + h / 2, 1, true),
        TileEdgePoint(x - w / 2, y + h / 2, 2, true),
        TileEdgePoint(x - w / 2, y + h / 2 - 5, 3, true),
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

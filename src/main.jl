include("includes.jl")

function get_fork_points(num_courses)
    used_corners = Vector{TileEdgePoint}(undef, 12 * num_courses)
    used_ys = Vector{Union{Nothing,Number}}(nothing, 12 * num_courses)
    used_xs = Vector{Union{Nothing,Number}}(nothing, 12 * num_courses)
    used_corners = repeat([TileEdgePoint(0, 0, 1, false)], 12 * num_courses)
    used_counter = 1
    top_right_increments = [14, 8, 6]
    bottom_right_increments = [10, 12, 14]
    Dict(
        :DownToUp => function (course, pre_req_c)
            tr_free = filter(x -> !(x in used_corners), pre_req_c.TRPoints)[1]
            tr_order = tr_free.order
            bl_free = filter(x -> !(x in used_corners), course.BLPoints)[1]

            bl_order = bl_free.order
            used_corners[used_counter] = tr_free
            used_counter += 1
            used_corners[used_counter] = bl_free
            used_counter += 1
            p1 = Point(tr_free.x, tr_free.y)
            next_indx = count(x -> !isnothing(x), used_ys)
            y_level = p1.y - top_right_increments[tr_order]
            y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
            y_l = if isnothing(y_level_indx)
                y_level
            else
                y_level - 10
            end
            used_ys[next_indx+1] = y_l

            p2 = Point(p1.x + 10, y_l)
            next_indx = count(x -> !isnothing(x), used_xs)
            x_level = course.x - course.w / 2 - 10
            x_level_indx = findlast(x -> !isnothing(x) && x_level + 6 >= x >= x_level, used_xs)
            x_l = if isnothing(x_level_indx)
                x_level
            else
                used_xs[x_level_indx] + 2
            end
            used_xs[next_indx+1] = x_l
            p3 = Point(x_l, p2.y)

            p4 = Point(x_l, course.y + course.h / 2 + top_right_increments[bl_order])
            p5 = Point(bl_free.x, bl_free.y)
            p1, p2, p3, p4, p5
        end,
        :SameLevel => function (course, pre_req_c)
            tr_free = filter(x -> !(x in used_corners), pre_req_c.TRPoints)[1]
            tr_order = tr_free.order
            tl_free = filter(x -> !(x in used_corners), course.TLPoints)[1]
            tl_order = tl_free.order
            used_corners[used_counter] = tr_free
            used_counter += 1
            used_corners[used_counter] = tl_free
            used_counter += 1
            p1 = Point(tr_free.x, tr_free.y)
            next_indx = count(x -> !isnothing(x), used_ys)
            y_level = p1.y - top_right_increments[tr_order]
            y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
            y_l = if isnothing(y_level_indx)
                y_level
            else
                y_level - 10
            end
            used_ys[next_indx+1] = y_l
            p2 = Point(p1.x + 10, y_l)
            p3 = Point(course.x - course.w / 2 - 10, p2.y)
            p4 = Point(tl_free.x, tl_free.y)
            p1, p2, p3, p4
        end,
        :UpToDown => function (course, pre_req_c)
            br_free = filter(x -> !(x in used_corners), pre_req_c.BRPoints)[1]
            br_order = br_free.order
            tl_free = filter(x -> !(x in used_corners), course.TLPoints)[1]
            tl_order = tl_free.order
            used_corners[used_counter] = br_free
            used_counter += 1
            used_corners[used_counter] = tl_free
            used_counter += 1
            p1 = Point(br_free.x, br_free.y)
            next_indx = count(x -> !isnothing(x), used_ys)
            y_level = p1.y + bottom_right_increments[br_order]
            y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
            y_l = if isnothing(y_level_indx)
                y_level
            else
                y_level + 10
            end
            used_ys[next_indx+1] = y_l
            p2 = Point(p1.x + 10, y_l)
            next_indx = count(x -> !isnothing(x), used_xs)
            x_level = course.x - course.w / 2 - 10
            x_level_indx = findlast(x -> !isnothing(x) && x_level + 6 >= x >= x_level, used_xs)
            x_l = if isnothing(x_level_indx)
                x_level
            else
                used_xs[x_level_indx] + 2
            end
            used_xs[next_indx+1] = x_l
            p3 = Point(x_l, p2.y)
            p4 = Point(p3.x, course.y - course.h / 2 - bottom_right_increments[tl_order])
            p5 = Point(tl_free.x, tl_free.y)
            p1, p2, p3, p4, p5
        end
    )
end

function draw_summer_chart(filename::Union{String,Nothing}, is_summer::Bool=true, term_field::Symbol=:Term)
    clrs = theme_colors()
    d = if isnothing(filename)
        Drawing("A4landscape")
    else
        Drawing("A4landscape", filename)
    end
    origin()
    w, h = d.width, d.height
    background("white")
    sethue("green")
    # setdash("dot")
    circle(O, 0.1, action=:fill)
    circle(Point(-d.width / 2, 0), 4, action=:fill)
    circle(Point(d.width / 2, 0), 4, action=:fill)
    circle(Point(0, -d.height / 2), 4, action=:fill)
    circle(Point(0, d.height / 2), 4, action=:fill)
    box(BoundingBox(), action=:stroke)
    sethue("black")
    text("Legend:     J = Junior Standing ", Point(-w / 2 + 100, (h / 2) - 5), halign=:left, valign=:middle)
    sethue("green")
    d
    h = h - 20
    df = getDSECourses(is_summer)
    all_courses = coursesToTiles(df, d, term_field)
    all_courses = addPreRequesites(df, all_courses)
    banner_center = Point(0, -h / 2 + 40)
    # top_left = Point(-w / 2, -h / 2)
    # center_left = Point(-w / 2, 20)
    box(banner_center, w - 20, 50, action=:fill)
    sethue("white")
    fontsize(15)
    fontface("Liberation Sans")
    text("DATA SCIENCE AND ENGINEERING (DSE) SUMMER TRAINING PRE-REQUISITES CHART (129 CREDIT HOURS)", banner_center, halign=:center, valign=:middle)
    sethue("black")

    y = 40
    lane_width = 80
    lane_height = h - 100
    # box(center_left + pnt, 80, h - 100, action=:stroke)
    x_inc = 80
    x = -w / 2 - 10 + x_inc
    sem_gap = 5
    year_gap = 10
    # sem_color = clrs[:sem_border]
    # year 1
    t1_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==1, [:Course, :Cr]]))
    text("Freshman Year", Point(x + 40, y - h / 2 + 35), halign=:center, valign=:middle)
    semester_lane(x, y, lane_width, lane_height, clrs, "First", t1_crs, all_courses)
    x = x + x_inc + sem_gap
    t2_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==2, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "Second", t2_crs, all_courses)

    # year 2
    x = x + x_inc + year_gap
    sethue("black")
    text("Sophomore Year", Point(x + 40, y - h / 2 + 35), halign=:center, valign=:middle)
    t3_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==3, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "First", t3_crs, all_courses)
    x = x + x_inc + sem_gap
    t4_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==4, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "Second", t4_crs, all_courses)

    # year 3
    x = x + x_inc + year_gap
    sethue("black")
    text("Junior Year", Point(x + 40, y - h / 2 + 35), halign=:center, valign=:middle)
    t5_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==5, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "First", t5_crs, all_courses)
    x = x + x_inc + sem_gap
    t6_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==6, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "Second", t6_crs, all_courses)

    # summer
    ts_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].=="s", [:Course, :Cr]]))
    if length(ts_crs) > 0
        x = x + x_inc + year_gap
        sethue("black")
        text("Summer", Point(x + 1, y - h / 2 + 35), halign=:center, valign=:middle)
        semester_lane(x, y, lane_width, lane_height, clrs, "Summer", ts_crs, all_courses)
    end

    # year 4
    x = x + x_inc + year_gap
    sethue("black")
    text("Senior Year", Point(x + 40, y - h / 2 + 35), halign=:center, valign=:middle)
    t7_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==7, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "First", t7_crs, all_courses)
    x = x + x_inc + sem_gap
    t8_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field].==8, [:Course, :Cr]]))
    semester_lane(x, y, lane_width, lane_height, clrs, "Second", t8_crs, all_courses)

    sethue("green")

    setline(1.5)

    term_counter = is_summer ?
                   Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "6.5" => 7, "7.0" => 8, "8.0" => 9) :
                   Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "7.0" => 7, "8.0" => 8)
    pre_arrows_fns = get_fork_points(length(all_courses))
    down_to_up = pre_arrows_fns[:DownToUp]
    same_level = pre_arrows_fns[:SameLevel]
    up_to_down = pre_arrows_fns[:UpToDown]
    connector_colors = [
        RGB(0.8, 0.2, 0.0),  # Dark Red
        # RGB(0.5, 0.6, 0.0),  # Dark Brick
        # RGB(0.5, 0.2, 0.0),  # Dark Burnt Orange
        # RGB(0.6, 0.3, 0.0),  # Dark Amber
        RGB(0.2, 0.0, 0.8),  # Dark Golden Orange
        # RGB(0.6, 0.3, 0.2),  # Dark Terra Cotta
        RGB(0.8, 0.0, 0.2),  # Dark Red Violet
        # RGB(0.6, 0.1, 0.2),  # Dark Rose
        # RGB(0.7, 0.0, 0.1),  # Dark Crimson
        # RGB(0.5, 0.0, 0.0),  # Dark Scarlet
        RGB(0.2, 0.0, 0.8)   # Dark Burgundy
    ]

    for course in all_courses
        clor_indx = 1 + (term_counter["$(course.term)"] % 4)
        clr = connector_colors[clor_indx]
        sethue(clr)
        if !isnothing(course.prereqs)
            ending_term = course.term
            ending_order = course.order
            for pre_req_c in course.prereqs
                starting_term = pre_req_c.term
                starting_order = pre_req_c.order
                term_gap = ending_term - starting_term

                if term_gap == 1
                    arrow(Point(pre_req_c.x + pre_req_c.w / 2, pre_req_c.y), Point(course.x - course.w / 2, course.y))
                else
                    if ending_order < starting_order # the ones that prererquisites are above them
                        p1, p2, p3, p4, p5 = down_to_up(course, pre_req_c)

                        # tr_free = filter(x -> !(x in used_corners), pre_req_c.TRPoints)[1]
                        # tr_order = tr_free.order
                        # bl_free = filter(x -> !(x in used_corners), course.BLPoints)[1]
                        # p1, p2, p3, p4, p5, used_corners, used_counter, used_xs, used_ys = up_to_down(course, pre_req_c, used_corners, used_counter, used_xs, used_ys)
                        # bl_order = bl_free.order
                        # used_corners[used_counter] = tr_free
                        # used_counter += 1
                        # used_corners[used_counter] = bl_free
                        # used_counter += 1
                        # p1 = Point(tr_free.x, tr_free.y)
                        # next_indx = count(x -> !isnothing(x), used_ys)
                        # y_level = p1.y - top_right_increments[tr_order]
                        # y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
                        # y_l = if isnothing(y_level_indx)
                        #     y_level
                        # else
                        #     y_level - 10
                        # end
                        # used_ys[next_indx+1] = y_l

                        # p2 = Point(p1.x + 10, y_l)
                        line(p1, p2, action=:stroke)

                        # next_indx = count(x -> !isnothing(x), used_xs)
                        # x_level = course.x - course.w / 2 - 10
                        # x_level_indx = findlast(x -> !isnothing(x) && x_level + 6 >= x >= x_level, used_xs)
                        # x_l = if isnothing(x_level_indx)
                        #     println(course.code)
                        #     println(next_indx)
                        #     x_level
                        # else
                        #     used_xs[x_level_indx] + 2
                        # end
                        # used_xs[next_indx+1] = x_l
                        # p3 = Point(x_l, p2.y)
                        line(p2, p3, action=:stroke)

                        # p4 = Point(x_l, course.y + course.h / 2 + top_right_increments[bl_order])
                        line(p3, p4, action=:stroke)
                        # p5 = Point(bl_free.x, bl_free.y)
                        arrow(p4, p5)
                    elseif ending_order == starting_order
                        p1, p2, p3, p4 = same_level(course, pre_req_c)
                        # tr_free = filter(x -> !(x in used_corners), pre_req_c.TRPoints)[1]
                        # tr_order = tr_free.order
                        # tl_free = filter(x -> !(x in used_corners), course.TLPoints)[1]
                        # tl_order = tl_free.order
                        # used_corners[used_counter] = tr_free
                        # used_counter += 1
                        # used_corners[used_counter] = tl_free
                        # used_counter += 1
                        # p1 = Point(tr_free.x, tr_free.y)
                        # next_indx = count(x -> !isnothing(x), used_ys)
                        # y_level = p1.y - top_right_increments[tr_order]
                        # y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
                        # y_l = if isnothing(y_level_indx)
                        #     y_level
                        # else
                        #     y_level - 10
                        # end
                        # used_ys[next_indx+1] = y_l
                        # p2 = Point(p1.x + 10, y_l)
                        line(p1, p2, action=:stroke)
                        # p3 = Point(course.x - course.w / 2 - 10, p2.y)
                        line(p2, p3, action=:stroke)
                        # p4 = Point(tl_free.x, tl_free.y)
                        arrow(p3, p4)
                    else
                        p1, p2, p3, p4, p5 = up_to_down(course, pre_req_c)
                        # br_free = filter(x -> !(x in used_corners), pre_req_c.BRPoints)[1]
                        # br_order = br_free.order
                        # tl_free = filter(x -> !(x in used_corners), course.TLPoints)[1]
                        # tl_order = tl_free.order
                        # used_corners[used_counter] = br_free
                        # used_counter += 1
                        # used_corners[used_counter] = tl_free
                        # used_counter += 1
                        # p1 = Point(br_free.x, br_free.y)
                        # next_indx = count(x -> !isnothing(x), used_ys)
                        # y_level = p1.y + bottom_right_increments[br_order]
                        # y_level_indx = findfirst(x -> !isnothing(x) && x == y_level, used_ys)
                        # y_l = if isnothing(y_level_indx)
                        #     y_level
                        # else
                        #     y_level + 10
                        # end
                        # used_ys[next_indx+1] = y_l
                        # p2 = Point(p1.x + 10, y_l)
                        line(p1, p2, action=:stroke)
                        # p3 = Point(course.x - course.w / 2 - 10, p2.y)
                        line(p2, p3, action=:stroke)
                        # p4 = Point(p3.x, course.y - course.h / 2 - bottom_right_increments[tl_order])
                        line(p3, p4, action=:stroke)
                        # p5 = Point(tl_free.x, tl_free.y)
                        arrow(p4, p5)
                    end

                end
            end
        end
        sethue(course.c)
        pt = Point(course.x, course.y)
        # draw_course_tile(course, pt)
        polysmooth(box(pt, course.w, course.h, vertices=true), 0.2, action=:fill)
        sethue(colorant"rgba(150,0,200,0.6)")
        setline(2)
        poly([Point(course.x - course.w / 2, course.y + course.h / 2), Point(course.x - course.w / 2, course.y - course.h / 2)], :stroke)
        setline(1)
        sethue("black")
        fontsize(14)
        fontface("Rotis SansSerif Std")
        course.Note !== "" && text("($(course.Note))", Point(pt.x, pt.y + 5), halign=:center, valign=:middle)
        text(course.code, Point(pt.x, pt.y - 10), halign=:center, valign=:middle)
        fontsize(12)
        text("$(course.credits)", Point(pt.x + 20, pt.y + 15), halign=:bottom, valign=:right)
        sethue(clrs[:sem_border])
        polysmooth(box(pt, course.w, course.h, vertices=true), 0.2, action=:stroke)
        if course.code == "DATA 399"
            sethue("black")
            pt_summer = Point(pt.x, pt.y + 140)
            polysmooth(box(pt_summer, 1.2course.w, 2course.h, vertices=true), 0.2, action=:stroke)
            fontsize(10)
            textwrap(course.PreReqTile, course.w, Point(pt_summer.x - 35, pt_summer.y - 35))
            arrow(Point(pt_summer.x, pt_summer.y - 0.5course.w), Point(course.x, course.y + course.h / 2))
            fontsize(14)
        end
    end
    finish()
end



draw_summer_chart(false, true, :Term)
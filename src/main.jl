include("includes.jl")

function draw_summer_chart(filename::Union{String,Nothing}, is_summer::Bool=true, term_field::Symbol=:Term)
    clrs = theme_colors()
    d = if isnothing(filename)
        Drawing("A4landscape")
    else
        Drawing("A4landscape", filename)
    end
    w, h = d.width, d.height
    df = getDSECourses(is_summer)
    course_types = unique(df[!, :Type])
    origin()
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
    draw_legends(String.(course_types), w, h)
    sethue("green")
    h = h - 20
    dp_canvas = term_field == :Term ? DPCanvas(80, h - 100, 80, -w / 2 + 70, 40, 5, 10, 35, 70) :
                DPCanvas(90, h - 100, 80, -w / 2 + 70, 40, 20, 25, 35, 60)
    all_courses = coursesToTiles(df, d, dp_canvas, term_field)
    all_courses = addPreRequesites(df, all_courses)
    total_credits = sum(map(x -> x.credits, all_courses))
    draw_banner(total_credits, w, h, is_summer)
    sethue("black")

    y, lane_width, lane_height = dp_canvas.y, dp_canvas.lane_width, dp_canvas.lane_height
    x_inc, x, sem_gap, year_gap = dp_canvas.x_inc, dp_canvas.x, dp_canvas.sem_gap, dp_canvas.year_gap
    # h = lane_height
    # y = 40
    # lane_width = 80
    # lane_height = h - 100
    # x_inc = 80
    # x = -w / 2 - 10 + x_inc
    # sem_gap = 5
    # year_gap = 10

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


    term_counter = is_summer ?
                   Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "6.5" => 7, "7.0" => 8, "8.0" => 9) :
                   Dict("1.0" => 1, "2.0" => 2, "3.0" => 3, "4.0" => 4, "5.0" => 5, "6.0" => 6, "7.0" => 7, "8.0" => 8)
    pre_arrows_fns = get_fork_points(length(all_courses))
    down_to_up = pre_arrows_fns[:DownToUp]
    same_level = pre_arrows_fns[:SameLevel]
    up_to_down = pre_arrows_fns[:UpToDown]
    connector_colors = [
        RGB(0.8, 0.2, 0.0),  # Dark Red
        RGB(0.2, 0.0, 0.8),  # Dark Golden Orange
        RGB(0.8, 0.0, 0.2),  # Dark Red Violet
        RGB(0.2, 0.0, 0.8)   # Dark Burgundy
    ]

    connector_lengths = [0.9, 1.2, 0.9, 1.2]

    for course in all_courses
        connector_indx = 1 + (term_counter["$(course.term)"] % 4)
        clr = connector_colors[connector_indx]
        lngth = connector_lengths[connector_indx]
        setline(lngth)
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
                        y_distance_p3_to_p4 = p3.y - p4.y
                        line(p1, p2, action=:stroke)
                        line(p2, p3, action=:stroke)
                        if y_distance_p3_to_p4 < 50
                            arrow(p3, p5)
                        else
                            line(p3, p4, action=:stroke)
                            arrow(p4, p5)
                        end

                    elseif ending_order == starting_order
                        p1, p2, p3, p4 = same_level(course, pre_req_c)
                        line(p1, p2, action=:stroke)
                        line(p2, p3, action=:stroke)
                        arrow(p3, p4)
                    else
                        p1, p2, p3, p4, p5 = up_to_down(course, pre_req_c)
                        y_distance_p3_to_p4 = p4.y - p3.y
                        line(p1, p2, action=:stroke)
                        line(p2, p3, action=:stroke)
                        if y_distance_p3_to_p4 < 50
                            arrow(p3, p5)
                        else
                            line(p3, p4, action=:stroke)
                            arrow(p4, p5)
                        end
                    end

                end
            end
        end
        setline(1.5)
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
        if course.code in ["DATA 399", "DATA 398"]
            sethue("black")
            pt_summer = is_summer ? Point(pt.x, pt.y + 140) : Point(pt.x, pt.y + 200)
            polysmooth(box(pt_summer, 1.2course.w, 2course.h, vertices=true), 0.2, action=:stroke)
            fontsize(10)
            textwrap(course.PreReqTile, course.w, Point(pt_summer.x - 35, pt_summer.y - 35))
            arrow(Point(pt_summer.x, pt_summer.y - 0.5course.w), Point(course.x, course.y + course.h / 2))
            fontsize(14)
        end
    end
    finish()
end



draw_summer_chart(true, true)
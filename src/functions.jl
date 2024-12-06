
function copyDegreePlanSpreadSheet()
    dp_dir = joinpath(@__DIR__, "../..")
    dp_files = filter(x -> endswith(x, "xlsx") && startswith(x, "DATA"), readdir(dp_dir))
    if length(dp_files) == 0
        @error "No Degree Plan File"
    elseif length(dp_files) > 1
        @error "More than one file can be source file"
        map(println, dp_files)
    else
        current_files = filter(x -> endswith(x, "xlsx") && startswith(x, "DATA"), readdir("./copies"))
        if dp_files[1] in current_files
            printstyled("returned same $(dp_files[1]) saved to ../copies\n")
            return "./copies/$(dp_files[1])"
        else
            cp(joinpath(@__DIR__, "../..", dp_files[1]), "./copies/$(dp_files[1])", force=true)
            printstyled("copied new $(dp_files[1]) to ../copies\n")
            return "./copies/$(dp_files[1])"
        end
    end
end

function getDSECourses(summer=true)
    # # copy degree plan
    copied_dp = copyDegreePlanSpreadSheet()

    df = XLSX.readtable(copied_dp, "DATA_LIST") |> DataFrame
    if summer
        return sort(filter(x -> !ismissing(x[:Term]) && x[:Term] .!= -1, df))
    else
        return sort(filter(x -> !ismissing(x[:INTERN_Term]) && x[:INTERN_Term] .!= -1, df), [:INTERN_Term, :Course])
    end
end

function addPreRequesites(df::DataFrame, courses::Vector{CourseTile})
    new_courses = map(courses) do course
        pre_reqs_str_arr = map(x -> ismissing(x[1]) ? nothing : split(x[1], ","), eachrow(df[df[!, :Course].==course.code, [:PreRequests]]))
        if nothing in pre_reqs_str_arr
            return course
        else
            pre_reqs_str_arr = stack(pre_reqs_str_arr)
            nc = if length(pre_reqs_str_arr) > 0
                pre_req = filter(x -> x.code in pre_reqs_str_arr, courses)
                c = CourseTile(course, pre_req)
                c
            else
                course
            end
            return nc
        end
    end
    new_courses

end

function coursesToTiles(df::DataFrame, canvas::Drawing, term_feild::Symbol=:Term)
    canvas_w, canvas_h = canvas.width, canvas.height
    type_colors = theme_colors()
    x_inc = 80
    base_y = 40
    tile_w = 80
    tile_h = 35
    h = canvas_h - 100
    lane_x = -canvas_w / 2 - 10 + x_inc
    sem_gap = 5
    year_gap = 10
    year_terms = term_feild == :Term ? Dict(1 => [1, 2], 2 => [3, 4], 3 => [5, 6], 4 => ["s"], 5 => [7, 8]) :
                 Dict(1 => [1, 2], 2 => [3, 4], 3 => [5, 6], 4 => [7, 8])
    all_crs = map(1:length(keys(year_terms))) do yr
        terms = year_terms[yr]
        t_cors = map(enumerate(terms)) do (term_i, term)
            t_crs = map(x -> (x[1], x[2], x[3], x[4], x[5], x[6], x[7]), eachrow(df[df[!, term_feild].==term, [:Course, :Cr, :Type, term_feild, :PreReqTile, :Note, :Notes]]))
            y = base_y
            term_courses = map(enumerate(t_crs)) do (i, course)
                code, cr, type, c_term, c_pretile, c_note, c_notes = course
                c_pretile, c_note, c_notes = ismissing(c_pretile) ? "" : c_pretile, ismissing(c_note) ? "" : c_note, ismissing(c_notes) ? "" : c_notes
                c_term = if c_term == "s"
                    6.5
                else
                    Float64(c_term)
                end
                type_clr = type_colors[Symbol(type)]
                ytemp = y - (h / 2) + 100 + (i - 1) * 70
                CourseTile(code, type, cr, c_term, c_pretile, c_note, c_notes, i, lane_x, ytemp, tile_w - 15, tile_h, type_clr)
            end
            lane_x = yr == 4 || term_i == 2 ? lane_x : lane_x + x_inc + sem_gap
            vcat(term_courses...)
        end
        lane_x = lane_x + x_inc + year_gap
        vcat(t_cors...)
    end |> d -> vcat(d...)
    all_crs
end

function theme_colors()
    Dict(
        :sem_border => colorant"rgba(111,118,129,0.6)",
        :sem_title => colorant"#54c45e",
        :primary => "black",
        :secondary => colorant"#008a0e",
        :DF => colorant"#F8CBAD",
        :GS => colorant"#C6E0B4",
        :MS => colorant"#FFE699",
        :CR => colorant"#BDD7EE",
        :CE => colorant"#DDEBF7",
        :TE => colorant"#99FFCC"
    )
end

function course_types_name(tp::Symbol)
    type_names = Dict(
        :DF => "Digital/Business foundation",
        :GS => "General Studies",
        :MS => "Math and Science",
        :CR => "Core Requirements",
        :CE => "Major Electives",
        :TE => "Technical Electives"
    )
    type_names[tp]
end

function draw_summer_chart(pdf::Bool, is_summer::Bool=true, term_field::Symbol=:Term)
    if pdf
        @pdf begin
            draw_summer_chart("./flow-charts/FlowChart.pdf", is_summer, term_field)
        end
    else
        @draw begin
            draw_summer_chart(nothing, is_summer, term_field)
        end
    end
end


function semester_lane(x, y, w, h, clrs=theme_colors(), title="", courses=[], all_crs=[])
    sethue(clrs[:sem_title])
    credits = sum(map(x -> x[2], courses))
    # green title background
    box(Point(x, y - h / 2 + 20), w, 40, action=:fill)
    sethue("white")
    fontsize(14)
    text(title, Point(x, y - h / 2 + 20), halign=:center, valign=:middle)

    sethue("black")
    fontsize(12)
    text("$credits cr.", Point(x, y - h / 2 + 50), halign=:center, valign=:middle)

    # lane
    sethue(clrs[:sem_border])
    setline(0.7)
    line(Point(x - w / 2, y - h / 2 + 60), Point(x + w / 2, y - h / 2 + 60), action=:stroke)
    setline(0.5)
    box(Point(x, y), w, h, action=:stroke)

    sethue(clrs[:primary])
    setline(2)
    fontsize(16)
    fontface("Liberation Sans")
end


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


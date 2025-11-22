

function copyDegreePlanSpreadSheet(; filenameprefix = DEFAULT_FILENAME_PREFIX)
	dp_dir = joinpath(@__DIR__, ROOT_RELATIVE)
	dp_files = filter(x -> endswith(x, EXCEL_SUFFIX) && startswith(x, filenameprefix), readdir(dp_dir))
	if length(dp_files) == 0
		@error "No Degree Plan File"
	elseif length(dp_files) > 1
		@error "More than one file can be source file"
		map(println, dp_files)
	else
		current_files = filter(x -> endswith(x, EXCEL_SUFFIX) && startswith(x, filenameprefix), readdir(COPIES_DIR))
		if dp_files[1] in current_files
			printstyled("returned same $(dp_files[1]) saved to ../copies\n")
			return "$(COPIES_DIR)/$(dp_files[1])"
		else
			cp(joinpath(@__DIR__, ROOT_RELATIVE, dp_files[1]), "$(COPIES_DIR)/$(dp_files[1])", force = true)
			printstyled("copied new $(dp_files[1]) to ../copies\n")
			return "$(COPIES_DIR)/$(dp_files[1])"
		end
	end
end

function getDSECourses(summer = true; filenameprefix = DEFAULT_FILENAME_PREFIX, data_table = DEFAULT_DATA_TABLE)
	# # copy degree plan
	copied_dp = copyDegreePlanSpreadSheet(; filenameprefix)

	df = XLSX.readtable(copied_dp, data_table) |> DataFrame
	if summer
		return sort(filter(x -> !ismissing(x[:Term]) && x[:Term] .!= -1, df))
	else
		return sort(filter(x -> !ismissing(x[:INTERN_Term]) && x[:INTERN_Term] .!= -1, df), [:INTERN_Term, :Course])
	end
end

function addPreRequesites(df::DataFrame, courses::Vector{CourseTile})
	new_courses = map(courses) do course
		pre_reqs_str_arr = map(x -> ismissing(x[1]) ? nothing : split(x[1], ","), eachrow(df[df[!, :Course] .== course.code, [:PreRequests]]))
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

function coursesToTiles(df::DataFrame, canvas::Drawing, dp_canvas::DPCanvas, term_feild::Symbol = :Term)
	canvas_w, canvas_h = canvas.width, canvas.height
	type_colors = theme_colors()
	x_inc = dp_canvas.x_inc
	# x_inc = 80
	base_y = dp_canvas.y
	# base_y = 40
	# tile_w = 80
	tile_w = dp_canvas.lane_width
	sem_gap = dp_canvas.sem_gap
	# sem_gap = 5
	year_gap = dp_canvas.year_gap
	# year_gap = 10
	h = canvas_h - CANVAS_H_SUB
	lane_x = -canvas_w / 2 - LANE_X_LEFT_PAD + x_inc
	tile_h = dp_canvas.tile_h
	# tile_h = 35
	tile_sep = dp_canvas.tile_separator
	# tile_sep = 70
	year_terms = term_feild == :Term ? YEAR_TERMS_WITH_SUMMER : YEAR_TERMS_NO_SUMMER
	all_crs = map(1:length(keys(year_terms))) do yr
		terms = year_terms[yr]
		t_cors = map(enumerate(terms)) do (term_i, term)
			t_crs = map(x -> (x[1], x[2], x[3], x[4], x[5], x[6], x[7]), eachrow(df[df[!, term_feild] .== term, [:Course, :Cr, :Type, term_feild, :PreReqTile, :Note, :Notes]]))
			y = base_y
			term_courses = map(enumerate(t_crs)) do (i, course)
				code, cr, type, c_term, c_pretile, c_note, c_notes = course
				c_pretile, c_note, c_notes = ismissing(c_pretile) ? "" : c_pretile, ismissing(c_note) ? "" : c_note, ismissing(c_notes) ? "" : c_notes
				c_term = if c_term == "s"
					SUMMER_NUMERIC_TERM
				else
					Float64(c_term)
				end
				type_clr = type_colors[Symbol(type)]
				ytemp = y - (h / 2) + TILE_Y_BASE_OFFSET + (i - 1) * tile_sep
				CourseTile(code, type, cr, c_term, c_pretile, c_note, c_notes, i, lane_x, ytemp, tile_w - TILE_WIDTH_INNER_MARGIN, tile_h, type_clr)
			end
			lane_x = (term_feild == :Term && yr == 4) || term_i == 2 ? lane_x : lane_x + x_inc + sem_gap
			vcat(term_courses...)
		end
		lane_x = lane_x + x_inc + year_gap
		vcat(t_cors...)
	end |> d -> vcat(d...)
	all_crs
end

function theme_colors()
    Dict(
        :sem_border => parse(Colorant, THEME_COLOR_RAW[:sem_border]),
        :sem_title => parse(Colorant, THEME_COLOR_RAW[:sem_title]),
        :primary => THEME_COLOR_RAW[:primary],
        :secondary => parse(Colorant, THEME_COLOR_RAW[:secondary]),
        :DF => parse(Colorant, THEME_COLOR_RAW[:DF]),
        :GS => parse(Colorant, THEME_COLOR_RAW[:GS]),
        :MS => parse(Colorant, THEME_COLOR_RAW[:MS]),
        :CR => parse(Colorant, THEME_COLOR_RAW[:CR]),
        :CE => parse(Colorant, THEME_COLOR_RAW[:CE]),
        :TE => parse(Colorant, THEME_COLOR_RAW[:TE]),
    )
end

function course_types_name(tp::Symbol)
	type_names = Dict(
		:DF => "Digital/Business foundation",
		:GS => "General Studies",
		:MS => "Math and Science",
		:CR => "Core Requirements",
		:CE => "Major Electives",
		:TE => "Technical Electives",
	)
	type_names[tp]
end

function draw_summer_chart(; output::Symbol, is_summer::Bool, kwargs...)
	charts_folder = mkpath(CHARTS_DIR)
	term_field, filename = is_summer ? (:Term, joinpath(charts_folder, SUMMER_CHART_FILENAME)) : (:INTERN_Term, joinpath(charts_folder, INTERNSHIP_CHART_FILENAME))
	if output == :pdf
		@pdf begin
			draw_summer_chart(filename, is_summer, term_field; kwargs...)
		end
	else
		@draw begin
			draw_summer_chart(nothing, is_summer, term_field; kwargs...)
		end
	end
end

function draw_summer_chart(filename::Union{String, Nothing}, is_summer::Bool = true, term_field::Symbol = :Term; data_table = "", filenameprefix = "", degree_name = "")
	clrs = theme_colors()
	d = if isnothing(filename)
		Drawing(A4_CANVAS_NAME)
	else
		Drawing(A4_CANVAS_NAME, filename)
	end
	w, h = d.width, d.height
	df = getDSECourses(is_summer; data_table = data_table, filenameprefix = filenameprefix)
	course_types = unique(df[!, :Type])
	origin()
	background(BACKGROUND_COLOR)
	sethue("green")
	# setdash("dot")
	circle(O, GUIDE_DOT_RADIUS_SMALL, action = :fill)
	circle(Point(-d.width / 2, 0), GUIDE_DOT_RADIUS, action = :fill)
	circle(Point(d.width / 2, 0), GUIDE_DOT_RADIUS, action = :fill)
	circle(Point(0, -d.height / 2), GUIDE_DOT_RADIUS, action = :fill)
	circle(Point(0, d.height / 2), GUIDE_DOT_RADIUS, action = :fill)
	box(BoundingBox(), action = :stroke)
	sethue("black")
	draw_legends(String.(course_types), w, h)
	sethue("green")
	h = h - H_ADJUST_AFTER_SETUP
	dp_canvas = if term_field == :Term
		DPCanvas(
			DPCANVAS_TERM.lane_width,
			h - DPCANVAS_TERM.lane_height_sub,
			DPCANVAS_TERM.x_inc,
			-w / 2 + DPCANVAS_TERM.x_left_margin,
			DPCANVAS_TERM.y,
			DPCANVAS_TERM.sem_gap,
			DPCANVAS_TERM.year_gap,
			DPCANVAS_TERM.tile_h,
			DPCANVAS_TERM.tile_sep,
		)
	else
		DPCanvas(
			DPCANVAS_INTERNSHIP.lane_width,
			h - DPCANVAS_INTERNSHIP.lane_height_sub,
			DPCANVAS_INTERNSHIP.x_inc,
			-w / 2 + DPCANVAS_INTERNSHIP.x_left_margin,
			DPCANVAS_INTERNSHIP.y,
			DPCANVAS_INTERNSHIP.sem_gap,
			DPCANVAS_INTERNSHIP.year_gap,
			DPCANVAS_INTERNSHIP.tile_h,
			DPCANVAS_INTERNSHIP.tile_sep,
		)
	end
	all_courses = coursesToTiles(df, d, dp_canvas, term_field)
	all_courses = addPreRequesites(df, all_courses)
	total_credits = sum(map(x -> x.credits, all_courses))
	draw_banner(total_credits, w, h, is_summer; degree_name = degree_name)
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
	t1_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 1, [:Course, :Cr]]))
	text("Freshman Year", Point(x + YEAR_LABEL_X_OFFSET, y - h / 2 + YEAR_LABEL_Y_OFFSET), halign = :center, valign = :middle)
	semester_lane(x, y, lane_width, lane_height, clrs, "First", t1_crs, all_courses)
	x = x + x_inc + sem_gap
	t2_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 2, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "Second", t2_crs, all_courses)

	# year 2
	x = x + x_inc + year_gap
	sethue("black")
	text("Sophomore Year", Point(x + YEAR_LABEL_X_OFFSET, y - h / 2 + YEAR_LABEL_Y_OFFSET), halign = :center, valign = :middle)
	t3_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 3, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "First", t3_crs, all_courses)
	x = x + x_inc + sem_gap
	t4_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 4, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "Second", t4_crs, all_courses)

	# year 3
	x = x + x_inc + year_gap
	sethue("black")
	text("Junior Year", Point(x + YEAR_LABEL_X_OFFSET, y - h / 2 + YEAR_LABEL_Y_OFFSET), halign = :center, valign = :middle)
	t5_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 5, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "First", t5_crs, all_courses)
	x = x + x_inc + sem_gap
	t6_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 6, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "Second", t6_crs, all_courses)

	# summer
	ts_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== "s", [:Course, :Cr]]))
	if length(ts_crs) > 0
		x = x + x_inc + year_gap
		sethue("black")
		text("Summer", Point(x + SUMMER_LABEL_X_OFFSET, y - h / 2 + YEAR_LABEL_Y_OFFSET), halign = :center, valign = :middle)
		semester_lane(x, y, lane_width, lane_height, clrs, "Summer", ts_crs, all_courses)
	end

	# year 4
	x = x + x_inc + year_gap
	sethue("black")
	text("Senior Year", Point(x + YEAR_LABEL_X_OFFSET, y - h / 2 + YEAR_LABEL_Y_OFFSET), halign = :center, valign = :middle)
	t7_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 7, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "First", t7_crs, all_courses)
	x = x + x_inc + sem_gap
	t8_crs = map(x -> (x[1], x[2]), eachrow(df[df[!, term_field] .== 8, [:Course, :Cr]]))
	semester_lane(x, y, lane_width, lane_height, clrs, "Second", t8_crs, all_courses)

	sethue("green")


	term_counter = is_summer ? TERM_COUNTER_SUMMER : TERM_COUNTER_REGULAR
	pre_arrows_fns = get_fork_points(length(all_courses))
	down_to_up = pre_arrows_fns[:DownToUp]
	same_level = pre_arrows_fns[:SameLevel]
	up_to_down = pre_arrows_fns[:UpToDown]
	# connector_colors = [
	#     RGB(0.8, 0.2, 0.0),  # Dark Red
	#     RGB(0.2, 0.0, 0.8),  # Dark Golden Orange
	#     RGB(0.8, 0.0, 0.2),  # Dark Red Violet
	#     RGB(0.2, 0.0, 0.8)   # Dark Burgundy
	# ]
	connector_colors = map(c -> parse(Colorant, c), CONNECTOR_COLOR_HEX)


	connector_lengths = CONNECTOR_LENGTHS

    # Compute bus positions and draw buses (if enabled)
    bus_x_by_term = Dict{Float64, Number}()
    if USE_BUS_ROUTING
        terms = sort(unique(map(c -> c.term, all_courses)))
        for t in terms
            xs_left = map(c -> c.x - c.w / 2, filter(c -> c.term == t, all_courses))
            if !isempty(xs_left)
                bus_x_by_term[t] = minimum(xs_left) - BUS_OFFSET
            end
        end
        if DRAW_BUS_LINES
            sethue(parse(Colorant, BUS_COLOR))
            setline(BUS_LINE_WIDTH)
            y_top = y - lane_height / 2 + SEMESTER_TITLE_HEIGHT + BUS_TOP_MARGIN
            y_bottom = y + lane_height / 2 - BUS_BOTTOM_MARGIN
            for t in keys(bus_x_by_term)
                bx = bus_x_by_term[t]
                line(Point(bx, y_top), Point(bx, y_bottom), action = :stroke)
            end
        end
    end

	for course in all_courses
		connector_indx = 1 + (term_counter["$(course.term)"] % 4)
		clr = connector_colors[term_counter["$(course.term)"]]
		lngth = connector_lengths[connector_indx]
		setline(lngth * CONNECTOR_THICKNESS_SCALE)
		sethue(RGBA(clr, CONNECTOR_ALPHA))
		if USE_BUS_ROUTING && !isnothing(course.prereqs)
            ending_term = course.term
            for pre_req_c in course.prereqs
                sx = pre_req_c.x + pre_req_c.w / 2
                sy = pre_req_c.y
                tx_left = course.x - course.w / 2
                bx_s = get(bus_x_by_term, pre_req_c.term, sx)
                bx_t = get(bus_x_by_term, ending_term, tx_left)
                line(Point(sx, sy), Point(bx_s, sy), action = :stroke)
                line(Point(bx_s, sy), Point(bx_s, course.y), action = :stroke)
                line(Point(bx_s, course.y), Point(bx_t, course.y), action = :stroke)
                arrow(Point(bx_t, course.y), Point(tx_left, course.y))
            end
        end
        if !isnothing(course.prereqs) && !USE_BUS_ROUTING
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
						line(p1, p2, action = :stroke)
						line(p2, p3, action = :stroke)
						if y_distance_p3_to_p4 < BRANCH_Y_THRESHOLD
							arrow(p3, p5)
						else
							line(p3, p4, action = :stroke)
							arrow(p4, p5)
						end

					elseif ending_order == starting_order
						p1, p2, p3, p4 = same_level(course, pre_req_c)
						line(p1, p2, action = :stroke)
						line(p2, p3, action = :stroke)
						arrow(p3, p4)
					else
						p1, p2, p3, p4, p5 = up_to_down(course, pre_req_c)
						y_distance_p3_to_p4 = p4.y - p3.y
						line(p1, p2, action = :stroke)
						line(p2, p3, action = :stroke)
						if y_distance_p3_to_p4 < BRANCH_Y_THRESHOLD
							arrow(p3, p5)
						else
							line(p3, p4, action = :stroke)
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
		polysmooth(box(pt, course.w, course.h, vertices = true), TILE_POLY_SMOOTH, action = :fill)
		sethue(parse(Colorant, SIDE_BAR_COLOR_RGBA))
		setline(SIDE_BAR_LINE_WIDTH)
		poly([Point(course.x - course.w / 2, course.y + course.h / 2), Point(course.x - course.w / 2, course.y - course.h / 2)], :stroke)
		setline(TILE_OUTLINE_LINE_WIDTH)
		sethue("black")
		fontsize(FONT_SIZE_TITLE)
		fontface(FONT_COURSE)
		course.Note !== "" && text("($(course.Note))", Point(pt.x, pt.y + NOTE_TEXT_OFFSET_Y), halign = :center, valign = :middle)
		text(course.code, Point(pt.x, pt.y + CODE_TEXT_OFFSET_Y), halign = :center, valign = :middle)
		fontsize(FONT_SIZE_CREDITS)
		text("$(course.credits)", Point(pt.x + CREDITS_OFFSET_X, pt.y + CREDITS_OFFSET_Y), halign = :bottom, valign = :right)
		sethue(clrs[:sem_border])
		polysmooth(box(pt, course.w, course.h, vertices = true), TILE_POLY_SMOOTH, action = :stroke)
		if course.code in SPECIAL_COURSES
			sethue("black")
			pt_summer = is_summer ? Point(pt.x, pt.y + SUMMER_NOTE_Y_OFFSET) : Point(pt.x, pt.y + INTERNSHIP_NOTE_Y_OFFSET)
			polysmooth(box(pt_summer, PREQ_BOX_SCALE_W * course.w, PREQ_BOX_SCALE_H * course.h, vertices = true), TILE_POLY_SMOOTH, action = :stroke)
			fontsize(10)
			textwrap(course.PreReqTile, course.w, Point(pt_summer.x + PREQ_TEXTWRAP_OFFSET_X, pt_summer.y + PREQ_TEXTWRAP_OFFSET_Y))
			arrow(Point(pt_summer.x, pt_summer.y + PREQ_ARROW_Y_OFFSET - PREQ_ARROW_X_FACTOR * course.w), Point(course.x, course.y + course.h / 2))
			fontsize(FONT_SIZE_TITLE)
		end
	end
	finish()
end


function semester_lane(x, y, w, h, clrs = theme_colors(), title = "", courses = [], all_crs = [])
	sethue(clrs[:sem_title])
	credits = sum(map(x -> x[2], courses))
	# title background
	title_tile_center_point = Point(x, y - h / 2 + 10)
	box(title_tile_center_point, w, SEMESTER_TITLE_HEIGHT, action = :fill)
	sethue("white")
	fontsize(FONT_SIZE_TITLE)
	text(title, title_tile_center_point, halign = :center, valign = :middle)

	credithours_tile_center_point = Point(title_tile_center_point.x, title_tile_center_point.y + SEMESTER_TITLE_HEIGHT)
	sethue("black")
	fontsize(FONT_SIZE_CREDITS)
	text("$credits$(CREDIT_SUFFIX)", credithours_tile_center_point, halign = :center, valign = :middle)

	line_below_title_start_point = Point(x - w / 2, y - h / 2 + SEMESTER_DIVIDER_Y_OFFSET)
	line_below_title_end_point = Point(x + w / 2, y - h / 2 + SEMESTER_DIVIDER_Y_OFFSET)
	# lane
	sethue(clrs[:sem_border])
	setline(SEMESTER_DIVIDER_STROKE)
	line(line_below_title_start_point, line_below_title_end_point, action = :stroke)
	setline(SEMESTER_BOX_STROKE)
	box(Point(x, y), w, h, action = :stroke)

	sethue(clrs[:primary])
	setline(2)
	fontsize(16)
	fontface(FONT_PRIMARY)
end


function get_fork_points(num_courses)
	used_corners = Vector{TileEdgePoint}(undef, 12 * num_courses)
	used_ys = Vector{Union{Nothing, Number}}(nothing, 12 * num_courses)
	used_xs = Vector{Union{Nothing, Number}}(nothing, 12 * num_courses)
	used_corners = repeat([TileEdgePoint(0, 0, 1, false)], 12 * num_courses)
	used_counter = 1
	top_right_increments = TOP_RIGHT_INCREMENTS
	bottom_right_increments = BOTTOM_RIGHT_INCREMENTS
	Dict(
		:DownToUp => function (course, pre_req_c)
			tr_candidates = filter(x -> !(x in used_corners), pre_req_c.TRPoints)
			tr_free = isempty(tr_candidates) ? pre_req_c.TRPoints[end] : tr_candidates[1]
			tr_order = tr_free.order
			bl_candidates = filter(x -> !(x in used_corners), course.BLPoints)
			bl_free = isempty(bl_candidates) ? course.BLPoints[end] : bl_candidates[1]

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
				y_level - ROUTE_Y_COLLISION_DELTA_UP
			end
			used_ys[next_indx+1] = y_l

			p2 = Point(p1.x + ROUTE_X_OFFSET, y_l)
			next_indx = count(x -> !isnothing(x), used_xs)
			x_level = course.x - course.w / 2 - ROUTE_X_LEFT_DELTA
			x_level_indx = findlast(x -> !isnothing(x) && x_level + ROUTE_X_COLLISION_TOL >= x >= x_level, used_xs)
			x_l = if isnothing(x_level_indx)
				x_level
			else
				used_xs[x_level_indx] + ROUTE_X_STACK_INCREMENT
			end
			used_xs[next_indx+1] = x_l
			p3 = Point(x_l, p2.y)

			p4 = Point(x_l, course.y + course.h / 2 + top_right_increments[bl_order])
			p5 = Point(bl_free.x, bl_free.y)
			p1, p2, p3, p4, p5
		end,
		:SameLevel => function (course, pre_req_c)
			tr_candidates = filter(x -> !(x in used_corners), pre_req_c.TRPoints)
			tr_free = isempty(tr_candidates) ? pre_req_c.TRPoints[end] : tr_candidates[1]
			tr_order = tr_free.order
			tl_frees_all = filter(x -> !(x in used_corners), course.TLPoints)
			tl_free = length(tl_frees_all) == 3 ? tl_frees_all[1] : TileEdgePoint(course.x, course.y - course.h / 2, 1, true)
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
				y_level - ROUTE_Y_COLLISION_DELTA_UP
			end
			used_ys[next_indx+1] = y_l
			p2 = Point(p1.x + ROUTE_X_OFFSET, y_l)
			p3 = Point(course.x - course.w / 2 - ROUTE_X_LEFT_DELTA, p2.y)
			p4 = Point(tl_free.x, tl_free.y)
			p1, p2, p3, p4
		end,
		:UpToDown => function (course, pre_req_c)
			br_candidates = filter(x -> !(x in used_corners), pre_req_c.BRPoints)
			br_free = isempty(br_candidates) ? pre_req_c.BRPoints[end] : br_candidates[1]
			br_order = br_free.order
			tl_candidates = filter(x -> !(x in used_corners), course.TLPoints)
			tl_free = isempty(tl_candidates) ? course.TLPoints[end] : tl_candidates[1]
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
				y_level + ROUTE_Y_COLLISION_DELTA_DOWN
			end
			used_ys[next_indx+1] = y_l
			p2 = Point(p1.x + ROUTE_X_OFFSET, y_l)
			next_indx = count(x -> !isnothing(x), used_xs)
			x_level = course.x - course.w / 2 - ROUTE_X_LEFT_DELTA
			x_level_indx = findlast(x -> !isnothing(x) && x_level + ROUTE_X_COLLISION_TOL >= x >= x_level, used_xs)
			x_l = if isnothing(x_level_indx)
				x_level
			else
				used_xs[x_level_indx] + ROUTE_X_STACK_INCREMENT
			end
			used_xs[next_indx+1] = x_l
			p3 = Point(x_l, p2.y)
			p4 = Point(p3.x, course.y - course.h / 2 - bottom_right_increments[tl_order])
			p5 = Point(tl_free.x, tl_free.y)
			p1, p2, p3, p4, p5
		end,
	)
end



function draw_banner(total_credits::Number, w::Number, h::Number, is_summer::Bool; degree_name::String = "")
	banner_center = Point(0, -h / 2 + SEMESTER_DIVIDER_Y_OFFSET)
	box(banner_center, w - 20, 50, action = :fill)
	sethue("white")
	fontsize(FONT_SIZE_BANNER)
	fontface(FONT_PRIMARY)
	title = is_summer ? "SUMMER TRAINING" : "INTERNSHIP"
	text("$degree_name $title PRE-REQUISITES CHART ($total_credits CREDIT HOURS)", banner_center, halign = :center, valign = :middle)
end
function draw_legends(course_types::Vector{String}, w::Number, h::Number)
	clrs = theme_colors()
	legend_point = Point(-w / 2 + LEGEND_MARGIN_X, (h / 2) - LEGEND_MARGIN_Y)
	text(LEGEND_LABEL, legend_point, halign = :left, valign = :middle)
	legend_point = Point(-w / 2 + LEGEND_SECOND_X, (h / 2) - LEGEND_MARGIN_Y)
	type_text_length = LEGEND_TYPE_TEXT_BASE
	l_p = Point(legend_point.x + type_text_length, legend_point.y)
	fontsize(FONT_SIZE_LEGEND)
	grid = GridRect(l_p, LEGEND_GRID_WIDTH, 0)
	for course_type_str in course_types
		course_type_sym = Symbol(course_type_str)
		type_text = course_types_name(course_type_sym)
		type_text_length = length(type_text) + LEGEND_TYPE_TEXT_PADDING
		sethue(clrs[course_type_sym])
		l_p = nextgridpoint(grid)
		circle(l_p, LEGEND_CIRCLE_RADIUS, action = :fill)
		sethue("black")
		text(type_text, Point(l_p.x + 5, l_p.y), halign = :left, valign = :middle)

	end
end


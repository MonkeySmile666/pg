#
# Main function for Hybrid A* Trailer 
# 
# Author: Atsushi Sakai(@Atsushi_twi)
#

using PyPlot

include("./lib/trailer_hybrid_a_star.jl")

function main()
    println(PROGRAM_FILE," start!!")

    # initial state
    sx = 14.0  # [m]
    sy = 10.0  # [m]
    syaw0 = deg2rad(00.0)
    syaw1 = deg2rad(00.0)

    # goal state
    gx = 0.0  # [m]
    gy = 0.0  # [m]
    gyaw0 = deg2rad(90.0)
    gyaw1 = deg2rad(90.0)

    # set obstacles
    ox = Float64[]
    oy = Float64[]

    for i in -25:25
        push!(ox, Float64(i))
        push!(oy, 15.0)
    end
    for i in -25:-4
        push!(ox, Float64(i))
        push!(oy, 4.0)
    end
    for i in -15:4
        push!(ox, -4.0)
        push!(oy, Float64(i))
    end
    for i in -15:4
        push!(ox, 4.0)
        push!(oy, Float64(i))
    end
    for i in 4:25
        push!(ox, Float64(i))
        push!(oy, 4.0)
    end
    for i in -4:4
        push!(ox, Float64(i))
        push!(oy, -15.0)
    end

    oox = ox[:]
    ooy = oy[:]

    # path generation
    @time path = trailer_hybrid_a_star.calc_hybrid_astar_path(sx, sy, syaw0, syaw1, gx, gy, gyaw0, gyaw1, ox, oy,
                                                               trailer_hybrid_a_star.XY_GRID_RESOLUTION,
                                                               trailer_hybrid_a_star.YAW_GRID_RESOLUTION
                                                               )

    # ====Animation=====
    show_animation(path, oox, ooy, sx, sy, syaw0, syaw1, gx, gy, gyaw0, gyaw1)

    println(PROGRAM_FILE," Done!!")
end


function show_animation(path, oox, ooy, sx, sy, syaw0, syaw1, gx, gy, gyaw0, gyaw1)
    plot(oox, ooy, ".k")
    trailer_hybrid_a_star.trailerlib.plot_trailer(sx, sy, syaw0, syaw1, 0.0)
    trailer_hybrid_a_star.trailerlib.plot_trailer(gx, gy, gyaw0, gyaw1, 0.0)
    x = path.x
    y = path.y
    yaw = path.yaw
    yaw1 = path.yaw1
    direction = path.direction

    steer = 0.0
    for ii in 1:length(x)
        cla()
        plot(oox, ooy, ".k")
        plot(x, y, "-r", label="Hybrid A* path")

        if ii < length(x)-1
            k = (yaw[ii+1] - yaw[ii])/trailer_hybrid_a_star.MOTION_RESOLUTION
            if !direction[ii]
                k *= -1
            end
            steer = atan2(trailer_hybrid_a_star.WB*k, 1.0)
        else
            steer = 0.0
        end
        trailer_hybrid_a_star.trailerlib.plot_trailer.(x[ii], y[ii], yaw[ii], yaw1[ii], steer)
        grid(true)
        axis("equal")
        pause(0.0001)
    end
end


if length(PROGRAM_FILE)!=0 &&
    contains(@__FILE__, PROGRAM_FILE)
    main()
end


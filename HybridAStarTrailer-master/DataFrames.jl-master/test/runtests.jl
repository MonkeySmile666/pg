#
# Correctness Tests
#

fatalerrors = length(ARGS) > 0 && ARGS[1] == "-f"
quiet = length(ARGS) > 0 && ARGS[1] == "-q"
anyerrors = false

using Compat, Compat.Test
using DataFrames

my_tests = ["utils.jl",
            "cat.jl",
            "data.jl",
            "index.jl",
            "dataframe.jl",
            "dataframerow.jl",
            "io.jl",
            "constructors.jl",
            "conversions.jl",
            "sort.jl",
            "grouping.jl",
            "join.jl",
            "iteration.jl",
            "duplicates.jl",
            "show.jl",
            "subdataframe.jl",
            "deprecated.jl"]

println("Running tests:")

for my_test in my_tests
    try
        include(my_test)
        println("\t\033[1m\033[32mPASSED\033[0m: $(my_test)")
    catch e
        global anyerrors = true
        println("\t\033[1m\033[31mFAILED\033[0m: $(my_test)")
        if fatalerrors
            rethrow(e)
        elseif !quiet
            showerror(stdout, e, backtrace())
            println()
        end
    end
end

if anyerrors
    throw("Tests failed")
end

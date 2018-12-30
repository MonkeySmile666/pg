module TestData
    using Compat, Compat.Test, DataFrames, Compat.Random
    const ≅ = isequal

    #test_group("constructors")
    df1 = DataFrame(Any[[1, 2, missing, 4], ["one", "two", missing, "four"]], [:Ints, :Strs])
    df2 = DataFrame(Any[[1, 2, missing, 4], ["one", "two", missing, "four"]])
    df3 = DataFrame(Any[[1, 2, missing, 4]])
    df4 = DataFrame(Any[Vector{Union{Int, Missing}}(1:4), Vector{Union{Int, Missing}}(1:4)])
    df5 = DataFrame(Any[Union{Int, Missing}[1, 2, 3, 4], ["one", "two", missing, "four"]])
    df6 = DataFrame(Any[[1, 2, missing, 4], [1, 2, missing, 4], ["one", "two", missing, "four"]],
                    [:A, :B, :C])
    df7 = DataFrame(x = [1, 2, missing, 4], y = ["one", "two", missing, "four"])
    @test size(df7) == (4, 2)
    @test df7[:x] ≅ [1, 2, missing, 4]

    #test_group("description functions")
    @test size(df6, 1) == 4
    @test size(df6, 2) == 3
    @test names(df6) == [:A, :B, :C]
    @test names(df2) == [:x1, :x2]
    @test names(df7) == [:x, :y]

    #test_group("ref")
    @test df6[2, 3] == "two"
    @test ismissing(df6[3, 3])
    @test df6[2, :C] == "two"
    @test df6[:B] ≅ [1, 2, missing, 4]
    @test size(df6[[2,3]], 2) == 2
    @test size(df6[2,:], 1) == 1
    @test size(df6[[1, 3], [1, 3]]) == (2, 2)
    @test size(df6[1:2, 1:2]) == (2, 2)
    @test size(head(df6,2)) == (2, 3)
    # lots more to do

    #test_group("assign")
    df6[3] = ["un", "deux", "trois", "quatre"]
    @test df6[1, 3] == "un"
    df6[:B] = [4, 3, 2, 1]
    @test df6[1,2] == 4
    df6[:D] = [true, false, true, false]
    @test df6[1,4]
    delete!(df6, :D)
    @test names(df6) == [:A, :B, :C]
    @test size(df6, 2) == 3

    #test_group("missing handling")
    @test nrow(df5[completecases(df5), :]) == 3
    @test nrow(dropmissing(df5)) == 3
    returned = dropmissing(df4)
    @test df4 == returned && df4 !== returned
    @test nrow(dropmissing!(df5)) == 3
    returned = dropmissing!(df4)
    @test df4 == returned && df4 === returned

    #test_context("SubDataFrames")

    #test_group("constructors")
    # single index is rows
    sdf6a = view(df6, 1)
    sdf6b = view(df6, 2:3)
    sdf6c = view(df6, [true, false, true, false])
    @test size(sdf6a) == (1,3)
    sdf6d = view(df6, [1,3], :B)
    @test size(sdf6d) == (2,1)
    sdf6e = view(df6, 0x01)
    @test size(sdf6e) == (1,3)
    sdf6f = view(df6, UInt64[1, 2])
    @test size(sdf6f) == (2,3)

    #test_group("ref")
    @test sdf6a[1,2] == 4

    #test_context("Within")
    #test_group("Associative")

    #test_group("DataFrame")
    srand(1)
    N = 20
    #Cast to Int64 as rand() behavior differs between Int32/64
    d1 = Vector{Union{Int64, Missing}}(rand(map(Int64, 1:2), N))
    d2 = CategoricalArray(["A", "B", missing])[rand(map(Int64, 1:3), N)]
    d3 = randn(N)
    d4 = randn(N)
    df7 = DataFrame(Any[d1, d2, d3], [:d1, :d2, :d3])

    #test_group("groupby")
    gd = groupby(df7, :d1)
    @test length(gd) == 2
    @test gd[2][:d2] ≅ ["B", missing, "A", missing, missing, missing, missing, missing, "A"]
    @test sum(gd[2][:d3]) == sum(df7[:d3][df7[:d1] .== 2])

    g1 = groupby(df7, [:d1, :d2])
    g2 = groupby(df7, [:d2, :d1])
    @test sum(g1[1][:d3]) == sum(g2[1][:d3])

    res = 0.0
    for x in g1
        res += sum(x[:d1])
    end
    @test res == sum(df7[:d1])

    @test aggregate(DataFrame(a=1), identity) == DataFrame(a_identity=1)

    df8 = aggregate(df7[[1, 3]], sum)
    @test df8[1, :d1_sum] == sum(df7[:d1])

    df8 = aggregate(df7, :d2, [sum, length], sort=true)
    @test df8[1:2, :d2] == ["A", "B"]
    @test size(df8, 1) == 3
    @test size(df8, 2) == 5
    @test sum(df8[:d1_length]) == N
    @test all(df8[:d1_length] .> 0)
    @test df8[:d1_length] == [4, 5, 11]
    @test df8 ≅ aggregate(groupby(df7, :d2, sort=true), [sum, length])
    @test df8[1, :d1_length] == 4
    @test df8[2, :d1_length] == 5
    @test df8[3, :d1_length] == 11
    @test df8 ≅ aggregate(groupby(df7, :d2), [sum, length], sort=true)

    df9 = aggregate(df7, :d2, [sum, length], sort=true)
    @test df9 ≅ df8

    df10 = DataFrame(
        Any[[1:4;], [2:5;], ["a", "a", "a", "b" ], ["c", "d", "c", "d"]],
        [:d1, :d2, :d3, :d4]
    )

    gd = groupby(df10, [:d3], sort=true)
    ggd = groupby(gd[1], [:d3, :d4], sort=true) # make sure we can groupby subDataFrames
    @test ggd[1][1, :d3] == "a"
    @test ggd[1][1, :d4] == "c"
    @test ggd[1][2, :d3] == "a"
    @test ggd[1][2, :d4] == "c"
    @test ggd[2][1, :d3] == "a"
    @test ggd[2][1, :d4] == "d"

    #test_group("reshape")
    d1 = DataFrame(a = Array{Union{Int, Missing}}(repeat([1:3;], inner = [4])),
                   b = Array{Union{Int, Missing}}(repeat([1:4;], inner = [3])),
                   c = Array{Union{Float64, Missing}}(randn(12)),
                   d = Array{Union{Float64, Missing}}(randn(12)),
                   e = Array{Union{String, Missing}}(map(string, 'a':'l')))

    stack(d1, :a)
    d1s = stack(d1, [:a, :b])
    d1s2 = stack(d1, [:c, :d])
    d1s3 = stack(d1)
    d1m = melt(d1, [:c, :d, :e])
    @test d1s[1:12, :c] == d1[:c]
    @test d1s[13:24, :c] == d1[:c]
    @test d1s2 == d1s3
    @test names(d1s) == [:variable, :value, :c, :d, :e]
    @test d1s == d1m
    d1m = melt(d1[[1,3,4]], :a)
    @test names(d1m) == [:variable, :value, :a]

    # Test naming of measure/value columns
    d1s_named = stack(d1, [:a, :b], variable_name=:letter, value_name=:someval)
    @test names(d1s_named) == [:letter, :someval, :c, :d, :e]
    d1m_named = melt(d1[[1,3,4]], :a, variable_name=:letter, value_name=:someval)
    @test names(d1m_named) == [:letter, :someval, :a]

    # test empty measures or ids
    dx = stack(d1, [], [:a])
    @test size(dx) == (0, 3)
    @test names(dx) == [:variable, :value, :a]
    dx = stack(d1, :a, [])
    @test size(dx) == (12, 2)
    @test names(dx) == [:variable, :value]
    dx = melt(d1, [], [:a])
    @test size(dx) == (12, 2)
    @test names(dx) == [:variable, :value]
    dx = melt(d1, :a, [])
    @test size(dx) == (0, 3)
    @test names(dx) == [:variable, :value, :a]

    stackdf(d1, :a)
    d1s = stackdf(d1, [:a, :b])
    d1s2 = stackdf(d1, [:c, :d])
    d1s3 = stackdf(d1)
    d1m = meltdf(d1, [:c, :d, :e])
    @test d1s[1:12, :c] == d1[:c]
    @test d1s[13:24, :c] == d1[:c]
    @test d1s2 == d1s3
    @test names(d1s) == [:variable, :value, :c, :d, :e]
    @test d1s == d1m
    d1m = meltdf(d1[[1,3,4]], :a)
    @test names(d1m) == [:variable, :value, :a]

    d1s_named = stackdf(d1, [:a, :b], variable_name=:letter, value_name=:someval)
    @test names(d1s_named) == [:letter, :someval, :c, :d, :e]
    d1m_named = meltdf(d1, [:c, :d, :e], variable_name=:letter, value_name=:someval)
    @test names(d1m_named) == [:letter, :someval, :c, :d, :e]

    d1s[:id] = Union{Int, Missing}[1:12; 1:12]
    d1s2[:id] =  Union{Int, Missing}[1:12; 1:12]
    d1us = unstack(d1s, :id, :variable, :value)
    d1us2 = unstack(d1s2)
    d1us3 = unstack(d1s2, :variable, :value)
    @test d1us[:a] == d1[:a]
    @test d1us2[:d] == d1[:d]
    @test d1us2[:3] == d1[:d]

    # test unstack with exactly one key column that is not passed
    df1 = melt(DataFrame(rand(10,10)))
    df1[:id] = 1:100
    @test size(unstack(df1, :variable, :value)) == (100, 11)

    # test empty keycol
    @test_throws ArgumentError unstack(melt(DataFrame(rand(3,2))), :variable, :value)

    #test_group("merge")
    srand(1)
    df1 = DataFrame(a = shuffle!(Vector{Union{Int, Missing}}(1:10)),
                    b = rand(Union{Symbol, Missing}[:A,:B], 10),
                    v1 = Vector{Union{Float64, Missing}}(randn(10)))

    df2 = DataFrame(a = shuffle!(Vector{Union{Int, Missing}}(1:5)),
                    b2 = rand(Union{Symbol, Missing}[:A,:B,:C], 5),
                    v2 = Vector{Union{Float64, Missing}}(randn(5)))

    m1 = join(df1, df2, on = :a, kind=:inner)
    @test m1[:a] == df1[:a][df1[:a] .<= 5] # preserves df1 order
    m2 = join(df1, df2, on = :a, kind = :outer)
    @test m2[:a] == df1[:a] # preserves df1 order
    @test m2[:b] == df1[:b] # preserves df1 order
    m2 = join(df1, df2, on = :a, kind = :outer)
    @test m2[:b2] ≅ [missing, :A, :A, missing, :C, missing, missing, :B, missing, :A]

    df1 = DataFrame(a = Union{Int, Missing}[1, 2, 3],
                    b = Union{String, Missing}["America", "Europe", "Africa"])
    df2 = DataFrame(a = Union{Int, Missing}[1, 2, 4],
                    c = Union{String, Missing}["New World", "Old World", "New World"])

    m1 = join(df1, df2, on = :a, kind = :inner)
    @test m1[:a] == [1, 2]

    m2 = join(df1, df2, on = :a, kind = :left)
    @test m2[:a] == [1, 2, 3]

    m3 = join(df1, df2, on = :a, kind = :right)
    @test m3[:a] == [1, 2, 4]

    m4 = join(df1, df2, on = :a, kind = :outer)
    @test m4[:a] == [1, 2, 3, 4]

    # test with missings (issue #185)
    df1 = DataFrame()
    df1[:A] = ["a", "b", "a", missing]
    df1[:B] = Union{Int, Missing}[1, 2, 1, 3]

    df2 = DataFrame()
    df2[:A] = ["a", missing, "c"]
    df2[:C] = Union{Int, Missing}[1, 2, 4]

    m1 = join(df1, df2, on = :A)
    @test size(m1) == (3,3)
    @test m1[:A] ≅ ["a","a", missing]

    m2 = join(df1, df2, on = :A, kind = :outer)
    @test size(m2) == (5,3)
    @test m2[:A] ≅ ["a", "b", "a", missing, "c"]

    srand(1)
    df1 = DataFrame(
        a = rand(Union{Symbol, Missing}[:x,:y], 10),
        b = rand(Union{Symbol, Missing}[:A,:B], 10),
        v1 = Vector{Union{Float64, Missing}}(randn(10))
    )

    df2 = DataFrame(
        a = Union{Symbol, Missing}[:x,:y][[1,2,1,1,2]],
        b = Union{Symbol, Missing}[:A,:B,:C][[1,1,1,2,3]],
        v2 = Vector{Union{Float64, Missing}}(randn(5))
    )
    df2[1,:a] = missing

    m1 = join(df1, df2, on = [:a,:b])
    @test m1[:a] == Union{Missings.Missing, Symbol}[:x, :x, :y, :y, :y, :x, :x, :x]
    m2 = join(df1, df2, on = [:a,:b], kind = :outer)
    @test ismissing(m2[10,:v2])
    @test m2[:a] ≅ [:x, :x, :y, :y, :y, :x, :x, :y, :x, :y, missing, :y]

    srand(1)
    function spltdf(d)
        d[:x1] = map(x -> x[1], d[:a])
        d[:x2] = map(x -> x[2], d[:a])
        d[:x3] = map(x -> x[3], d[:a])
        d
    end
    df1 = DataFrame(
        a = ["abc", "abx", "axz", "def", "dfr"],
        v1 = randn(5)
    )
    df1 = spltdf(df1)
    df2 = DataFrame(
        a = ["def", "abc","abx", "axz", "xyz"],
        v2 = randn(5)
    )
    df2 = spltdf(df2)

    m1 = join(df1, df2, on = :a, makeunique=true)
    m2 = join(df1, df2, on = [:x1, :x2, :x3], makeunique=true)
    @test sort(m1[:a]) == sort(m2[:a])

    # test nonunique() with extra argument
    df1 = DataFrame(a = Union{String, Missing}["a", "b", "a", "b", "a", "b"],
                    b = Vector{Union{Int, Missing}}(1:6),
                    c = Union{Int, Missing}[1:3;1:3])
    df = vcat(df1, df1)
    @test find(nonunique(df)) == collect(7:12)
    @test find(nonunique(df, :)) == collect(7:12)
    @test find(nonunique(df, Colon())) == collect(7:12)
    @test find(nonunique(df, :a)) == collect(3:12)
    @test find(nonunique(df, [:a, :c])) == collect(7:12)
    @test find(nonunique(df, [1, 3])) == collect(7:12)
    @test find(nonunique(df, 1)) == collect(3:12)

    # Test unique() with extra argument
    @test unique(df) == df1
    @test unique(df, :) == df1
    @test unique(df, Colon()) == df1
    @test unique(df, 2:3) == df1
    @test unique(df, 3) == df1[1:3,:]
    @test unique(df, [1, 3]) == df1
    @test unique(df, [:a, :c]) == df1
    @test unique(df, :a) == df1[1:2,:]

    #test unique!() with extra argument
    unique!(df, [1, 3])
    @test df == df1

    #test filter() and filter!()
    df = DataFrame(x = [3, 1, 2, 1], y = ["b", "c", "a", "b"])
    @test filter(r -> r[:x] > 1, df) == DataFrame(x = [3, 2], y = ["b", "a"])
    @test filter!(r -> r[:x] > 1, df) === df == DataFrame(x = [3, 2], y = ["b", "a"])
    df = DataFrame(x = [3, 1, 2, 1, missing], y = ["b", "c", "a", "b", "c"])
    @test_throws TypeError filter(r -> r[:x] > 1, df)
    @test_throws TypeError filter!(r -> r[:x] > 1, df)
end

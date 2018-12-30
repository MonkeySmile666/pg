# Database-Style Joins

We often need to combine two or more data sets together to provide a complete picture of the topic we are studying. For example, suppose that we have the following two data sets:

```jldoctest joins
julia> using DataFrames

julia> names = DataFrame(ID = [20, 40], Name = ["John Doe", "Jane Doe"])
2×2 DataFrames.DataFrame
│ Row │ ID │ Name     │
├─────┼────┼──────────┤
│ 1   │ 20 │ John Doe │
│ 2   │ 40 │ Jane Doe │

julia> jobs = DataFrame(ID = [20, 40], Job = ["Lawyer", "Doctor"])
2×2 DataFrames.DataFrame
│ Row │ ID │ Job    │
├─────┼────┼────────┤
│ 1   │ 20 │ Lawyer │
│ 2   │ 40 │ Doctor │

```

We might want to work with a larger data set that contains both the names and jobs for each ID. We can do this using the `join` function:

```jldoctest joins
julia> join(names, jobs, on = :ID)
2×3 DataFrames.DataFrame
│ Row │ ID │ Name     │ Job    │
├─────┼────┼──────────┼────────┤
│ 1   │ 20 │ John Doe │ Lawyer │
│ 2   │ 40 │ Jane Doe │ Doctor │

```

In relational database theory, this operation is generally referred to as a join. The columns used to determine which rows should be combined during a join are called keys.

There are seven kinds of joins supported by the DataFrames package:

-   Inner: The output contains rows for values of the key that exist in both the first (left) and second (right) arguments to `join`.
-   Left: The output contains rows for values of the key that exist in the first (left) argument to `join`, whether or not that value exists in the second (right) argument.
-   Right: The output contains rows for values of the key that exist in the second (right) argument to `join`, whether or not that value exists in the first (left) argument.
-   Outer: The output contains rows for values of the key that exist in the first (left) or second (right) argument to `join`.
-   Semi: Like an inner join, but output is restricted to columns from the first (left) argument to `join`.
-   Anti: The output contains rows for values of the key that exist in the first (left) but not the second (right) argument to `join`. As with semi joins, output is restricted to columns from the first (left) argument.
-   Cross: The output is the cartesian product of rows from the first (left) and second (right) arguments to `join`.

See [the Wikipedia page on SQL joins](https://en.wikipedia.org/wiki/Join_(SQL)) for more information.

You can control the kind of join that `join` performs using the `kind` keyword argument:

```jldoctest joins
julia> jobs = DataFrame(ID = [20, 60], Job = ["Lawyer", "Astronaut"])
2×2 DataFrames.DataFrame
│ Row │ ID │ Job       │
├─────┼────┼───────────┤
│ 1   │ 20 │ Lawyer    │
│ 2   │ 60 │ Astronaut │

julia> join(names, jobs, on = :ID, kind = :inner)
1×3 DataFrames.DataFrame
│ Row │ ID │ Name     │ Job    │
├─────┼────┼──────────┼────────┤
│ 1   │ 20 │ John Doe │ Lawyer │

julia> join(names, jobs, on = :ID, kind = :left)
2×3 DataFrames.DataFrame
│ Row │ ID │ Name     │ Job     │
├─────┼────┼──────────┼─────────┤
│ 1   │ 20 │ John Doe │ Lawyer  │
│ 2   │ 40 │ Jane Doe │ missing │

julia> join(names, jobs, on = :ID, kind = :right)
2×3 DataFrames.DataFrame
│ Row │ ID │ Name     │ Job       │
├─────┼────┼──────────┼───────────┤
│ 1   │ 20 │ John Doe │ Lawyer    │
│ 2   │ 60 │ missing  │ Astronaut │

julia> join(names, jobs, on = :ID, kind = :outer)
3×3 DataFrames.DataFrame
│ Row │ ID │ Name        │ Job       │
├─────┼────┼─────────────┼───────────┤
│ 1   │ 20 │ John Doe    │ Lawyer    │
│ 2   │ 40 │ Jane Doe    │ missing   │
│ 3   │ 60 │ missing     │ Astronaut │

julia> join(names, jobs, on = :ID, kind = :semi)
1×2 DataFrames.DataFrame
│ Row │ ID │ Name     │
├─────┼────┼──────────┤
│ 1   │ 20 │ John Doe │

julia> join(names, jobs, on = :ID, kind = :anti)
1×2 DataFrames.DataFrame
│ Row │ ID │ Name     │
├─────┼────┼──────────┤
│ 1   │ 40 │ Jane Doe │

```

Cross joins are the only kind of join that does not use a key:

```jldoctest joins
julia> join(names, jobs, kind = :cross)
4×4 DataFrames.DataFrame
│ Row │ ID │ Name     │ ID_1 │ Job       │
├─────┼────┼──────────┼──────┼───────────┤
│ 1   │ 20 │ John Doe │ 20   │ Lawyer    │
│ 2   │ 20 │ John Doe │ 60   │ Astronaut │
│ 3   │ 40 │ Jane Doe │ 20   │ Lawyer    │
│ 4   │ 40 │ Jane Doe │ 60   │ Astronaut │

```

In order to join data tables on keys which have different names, you must first rename them so that they match. This can be done using rename!:

```jldoctest joins
julia> a = DataFrame(ID = [20, 40], Name = ["John Doe", "Jane Doe"])
2×2 DataFrames.DataFrame
│ Row │ ID │ Name     │
├─────┼────┼──────────┤
│ 1   │ 20 │ John Doe │
│ 2   │ 40 │ Jane Doe │

julia> b = DataFrame(IDNew = [20, 40], Job = ["Lawyer", "Doctor"])
2×2 DataFrames.DataFrame
│ Row │ IDNew │ Job    │
├─────┼───────┼────────┤
│ 1   │ 20    │ Lawyer │
│ 2   │ 40    │ Doctor │

julia> rename!(b, :IDNew => :ID)
2×2 DataFrames.DataFrame
│ Row │ ID │ Job    │
├─────┼────┼────────┤
│ 1   │ 20 │ Lawyer │
│ 2   │ 40 │ Doctor │

julia> join(a, b, on = :ID, kind = :inner)
2×3 DataFrames.DataFrame
│ Row │ ID │ Name     │ Job    │
├─────┼────┼──────────┼────────┤
│ 1   │ 20 │ John Doe │ Lawyer │
│ 2   │ 40 │ Jane Doe │ Doctor │

```

Or renaming multiple columns at a time:

```jldoctest joins
julia> a = DataFrame(City = ["Amsterdam", "London", "London", "New York", "New York"],
                     Job = ["Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"],
                     Category = [1, 2, 3, 4, 5])
5×3 DataFrames.DataFrame
│ Row │ City      │ Job    │ Category │
├─────┼───────────┼────────┼──────────┤
│ 1   │ Amsterdam │ Lawyer │ 1        │
│ 2   │ London    │ Lawyer │ 2        │
│ 3   │ London    │ Lawyer │ 3        │
│ 4   │ New York  │ Doctor │ 4        │
│ 5   │ New York  │ Doctor │ 5        │

julia> b = DataFrame(Location = ["Amsterdam", "London", "London", "New York", "New York"],
                     Work = ["Lawyer", "Lawyer", "Lawyer", "Doctor", "Doctor"],
                     Name = ["a", "b", "c", "d", "e"])
5×3 DataFrames.DataFrame
│ Row │ Location  │ Work   │ Name │
├─────┼───────────┼────────┼──────┤
│ 1   │ Amsterdam │ Lawyer │ a    │
│ 2   │ London    │ Lawyer │ b    │
│ 3   │ London    │ Lawyer │ c    │
│ 4   │ New York  │ Doctor │ d    │
│ 5   │ New York  │ Doctor │ e    │

julia> rename!(b, :Location => :City, :Work => :Job)
5×3 DataFrames.DataFrame
│ Row │ City      │ Job    │ Name │
├─────┼───────────┼────────┼──────┤
│ 1   │ Amsterdam │ Lawyer │ a    │
│ 2   │ London    │ Lawyer │ b    │
│ 3   │ London    │ Lawyer │ c    │
│ 4   │ New York  │ Doctor │ d    │
│ 5   │ New York  │ Doctor │ e    │

julia> join(a, b, on = [:City, :Job])
9×4 DataFrames.DataFrame
│ Row │ City      │ Job    │ Category │ Name │
├─────┼───────────┼────────┼──────────┼──────┤
│ 1   │ Amsterdam │ Lawyer │ 1        │ a    │
│ 2   │ London    │ Lawyer │ 2        │ b    │
│ 3   │ London    │ Lawyer │ 2        │ c    │
│ 4   │ London    │ Lawyer │ 3        │ b    │
│ 5   │ London    │ Lawyer │ 3        │ c    │
│ 6   │ New York  │ Doctor │ 4        │ d    │
│ 7   │ New York  │ Doctor │ 4        │ e    │
│ 8   │ New York  │ Doctor │ 5        │ d    │
│ 9   │ New York  │ Doctor │ 5        │ e    │

```

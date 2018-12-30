##############################################################################
#
# Text output
#
##############################################################################

function escapedprint(io::IO, x::Any, escapes::AbstractString)
    ourshowcompact(io, x)
end

function escapedprint(io::IO, x::AbstractString, escapes::AbstractString)
    escape_string(io, x, escapes)
end

function printtable(io::IO,
                    df::AbstractDataFrame;
                    header::Bool = true,
                    separator::Char = ',',
                    quotemark::Char = '"',
                    nastring::AbstractString = "missing")
    n, p = size(df)
    etypes = eltypes(df)
    if header
        cnames = _names(df)
        for j in 1:p
            print(io, quotemark)
            print(io, cnames[j])
            print(io, quotemark)
            if j < p
                print(io, separator)
            else
                print(io, '\n')
            end
        end
    end
    quotestr = string(quotemark)
    for i in 1:n
        for j in 1:p
            if !ismissing(df[j][i])
                if ! (etypes[j] <: Real)
                    print(io, quotemark)
                    escapedprint(io, df[i, j], quotestr)
                    print(io, quotemark)
                else
                    print(io, df[i, j])
                end
            else
                print(io, nastring)
            end
            if j < p
                print(io, separator)
            else
                print(io, '\n')
            end
        end
    end
    return
end

function printtable(df::AbstractDataFrame;
                    header::Bool = true,
                    separator::Char = ',',
                    quotemark::Char = '"',
                    nastring::AbstractString = "missing")
    printtable(stdout,
               df,
               header = header,
               separator = separator,
               quotemark = quotemark,
               nastring = nastring)
    return
end
##############################################################################
#
# HTML output
#
##############################################################################

function html_escape(cell::AbstractString)
    cell = replace(cell, "&"=>"&amp;")
    cell = replace(cell, "<"=>"&lt;")
    cell = replace(cell, ">"=>"&gt;")
    return cell
end

function Base.show(io::IO, ::MIME"text/html", df::AbstractDataFrame)
    cnames = _names(df)
    write(io, "<table class=\"data-frame\">")
    write(io, "<thead>")
    write(io, "<tr>")
    write(io, "<th></th>")
    for column_name in cnames
        write(io, "<th>$column_name</th>")
    end
    write(io, "</tr>")
    write(io, "</thead>")
    write(io, "<tbody>")
    haslimit = get(io, :limit, true)
    n = size(df, 1)
    if haslimit
        tty_rows, tty_cols = displaysize(io)
        mxrow = min(n,tty_rows)
    else
        mxrow = n
    end
    for row in 1:mxrow
        write(io, "<tr>")
        write(io, "<th>$row</th>")
        for column_name in cnames
            cell = sprint(ourshowcompact, df[row, column_name])
            write(io, "<td>$(html_escape(cell))</td>")
        end
        write(io, "</tr>")
    end
    if n > mxrow
        write(io, "<tr>")
        write(io, "<th>&vellip;</th>")
        for column_name in cnames
            write(io, "<td>&vellip;</td>")
        end
        write(io, "</tr>")
    end
    write(io, "</tbody>")
    write(io, "</table>")
end

##############################################################################
#
# LaTeX output
#
##############################################################################

if VERSION ≥ v"0.7.0-DEV.4059"
    function latex_char_escape(char::Char)
        if char == '\\'
            return "\\textbackslash{}"
        elseif char == '~'
            return "\\textasciitilde{}"
        else
            return string('\\', char)
        end
    end
else
    function latex_char_escape(char::AbstractString)
        if char == "\\"
            return "\\textbackslash{}"
        elseif char == "~"
            return "\\textasciitilde{}"
        else
            return string("\\", char)
        end
    end
end

function latex_escape(cell::AbstractString)
    replace(cell, ['\\','~','#','$','%','&','_','^','{','}']=>latex_char_escape)
end

function Base.show(io::IO, ::MIME"text/latex", df::AbstractDataFrame)
    nrows = size(df, 1)
    ncols = size(df, 2)
    cnames = _names(df)
    alignment = repeat("c", ncols)
    write(io, "\\begin{tabular}{r|")
    write(io, alignment)
    write(io, "}\n")
    write(io, "\t& ")
    header = join(map(c -> latex_escape(string(c)), cnames), " & ")
    write(io, header)
    write(io, "\\\\\n")
    write(io, "\t\\hline\n")
    for row in 1:nrows
        write(io, "\t")
        write(io, @sprintf("%d", row))
        for col in 1:ncols
            write(io, " & ")
            cell = df[row,col]
            if !ismissing(cell)
                if showable(MIME("text/latex"), cell)
                    show(io, MIME("text/latex"), cell)
                else
                    print(io, latex_escape(sprint(ourshowcompact, cell)))
                end
            end
        end
        write(io, " \\\\\n")
    end
    write(io, "\\end{tabular}\n")
end

##############################################################################
#
# MIME
#
##############################################################################

function Base.show(io::IO, ::MIME"text/csv", df::AbstractDataFrame)
    printtable(io, df, true, ',')
end

function Base.show(io::IO, ::MIME"text/tab-separated-values", df::AbstractDataFrame)
    printtable(io, df, true, '\t')
end

##############################################################################
#
# DataStreams-based IO
#
##############################################################################

using DataStreams, WeakRefStrings

struct DataFrameStream{T}
    columns::T
    header::Vector{String}
end
DataFrameStream(df::DataFrame) = DataFrameStream(Tuple(df.columns), string.(names(df)))

# DataFrame Data.Source implementation
function Data.schema(df::DataFrame)
    return Data.Schema(Type[eltype(A) for A in df.columns],
                       string.(names(df)), length(df) == 0 ? 0 : length(df.columns[1]))
end

Data.isdone(source::DataFrame, row, col, rows, cols) = row > rows || col > cols
function Data.isdone(source::DataFrame, row, col)
    cols = length(source)
    return Data.isdone(source, row, col, cols == 0 ? 0 : length(source.columns[1]), cols)
end

Data.streamtype(::Type{DataFrame}, ::Type{Data.Column}) = true
Data.streamtype(::Type{DataFrame}, ::Type{Data.Field}) = true

Data.streamfrom(source::DataFrame, ::Type{Data.Column}, ::Type{T}, row, col) where {T} =
    source[col]
Data.streamfrom(source::DataFrame, ::Type{Data.Field}, ::Type{T}, row, col) where {T} =
    source[col][row]

# DataFrame Data.Sink implementation
Data.streamtypes(::Type{DataFrame}) = [Data.Column, Data.Field]
Data.weakrefstrings(::Type{DataFrame}) = true

allocate(::Type{T}, rows, ref) where {T} = Vector{T}(undef, rows)
allocate(::Type{CategoricalString{R}}, rows, ref) where {R} = CategoricalArray{String, 1, R}(undef, rows)
allocate(::Type{Union{CategoricalString{R}, Missing}}, rows, ref) where {R} = 
    CategoricalArray{Union{String, Missing}, 1, R}(undef, rows)
allocate(::Type{CategoricalValue{T, R}}, rows, ref) where {T, R} =
    CategoricalArray{T, 1, R}(undef, rows)
allocate(::Type{Union{Missing, CategoricalValue{T, R}}}, rows, ref) where {T, R} =
    CategoricalArray{Union{Missing, T}, 1, R}(undef, rows)
allocate(::Type{WeakRefString{T}}, rows, ref) where {T} =
    WeakRefStringArray(ref, WeakRefString{T}, rows)
allocate(::Type{Union{Missing, WeakRefString{T}}}, rows, ref) where {T} =
    WeakRefStringArray(ref, Union{Missing, WeakRefString{T}}, rows)
allocate(::Type{Missing}, rows, ref) = missings(rows)

# Construct or modify a DataFrame to be ready to stream data from a source with `sch`
function DataFrame(sch::Data.Schema{R}, ::Type{S}=Data.Field,
                   append::Bool=false, args...;
                   reference::Vector{UInt8}=UInt8[]) where {R, S <: Data.StreamType}
    types = Data.types(sch)
    if !isempty(args) && args[1] isa DataFrame && types == Data.types(Data.schema(args[1]))
        # passing in an existing DataFrame Sink w/ same types as source
        sink = args[1]
        sinkrows = size(Data.schema(sink), 1)
        # are we appending and either column-streaming or there are an unknown # of rows
        if append && (S == Data.Column || !R)
            sch.rows = sinkrows
            # dont' need to do anything because:
              # for Data.Column, we just append columns anyway (see Data.streamto! below)
              # for Data.Field, unknown # of source rows, so we'll just push! in streamto!
        else
            # need to adjust the existing sink
            # similar to above, for Data.Column or unknown # of rows for Data.Field,
                # we'll append!/push! in streamto!, so we empty! the columns
            # if appending, we want to grow our columns to be able to include every row
                # in source (sinkrows + sch.rows)
            # if not appending, we're just "re-using" a sink, so we just resize it
                # to the # of rows in the source
            newsize = ifelse(S == Data.Column || !R, 0,
                        ifelse(append, sinkrows + sch.rows, sch.rows))
            foreach(col->resize!(col, newsize), sink.columns)
            sch.rows = newsize
        end
        # take care of a possible reference from source by addint to WeakRefStringArrays
        if !isempty(reference)
            foreach(col-> col isa WeakRefStringArray && push!(col.data, reference),
                sink.columns)
        end
        sink = DataFrameStream(sink)
    else
        # allocating a fresh DataFrame Sink; append is irrelevant
        # for Data.Column or unknown # of rows in Data.Field, we only ever append!,
            # so just allocate empty columns
        rows = ifelse(S == Data.Column, 0, ifelse(!R, 0, sch.rows))
        names = Data.header(sch)
        sink = DataFrameStream(
                Tuple(allocate(types[i], rows, reference) for i = 1:length(types)), names)
        sch.rows = rows
    end
    return sink
end

DataFrame(sink, sch::Data.Schema, ::Type{S}, append::Bool;
          reference::Vector{UInt8}=UInt8[]) where {S} =
    DataFrame(sch, S, append, sink; reference=reference)

@inline Data.streamto!(sink::DataFrameStream, ::Type{Data.Field}, val,
                      row, col::Int) =
    (A = sink.columns[col]; row > length(A) ? push!(A, val) : setindex!(A, val, row))
@inline Data.streamto!(sink::DataFrameStream, ::Type{Data.Field}, val,
                       row, col::Int, ::Type{Val{false}}) =
    push!(sink.columns[col], val)
@inline Data.streamto!(sink::DataFrameStream, ::Type{Data.Field}, val,
                       row, col::Int, ::Type{Val{true}}) =
    sink.columns[col][row] = val
@inline function Data.streamto!(sink::DataFrameStream, ::Type{Data.Column}, column,
                       row, col::Int, knownrows)
    append!(sink.columns[col], column)
end
    
Data.close!(df::DataFrameStream) =
    DataFrame(collect(Any, df.columns), Symbol.(df.header), makeunique=true)


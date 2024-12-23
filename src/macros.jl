"""
WeaveLoggers Macro Utilities

This module provides macros for annotating function calls with logging, timing,
and API integration capabilities.
"""
module Macros

using ..WeaveLoggers: format_iso8601, PROJECT_ID, get_system_metadata
using ..WeaveLoggers.Calls: start_call, end_call
using ..WeaveLoggers.Tables: create_table
using ..WeaveLoggers.Files: create_file
using Dates, UUIDs, Tables, DataFrames

export @w, @wtable, @wfile

"""
    @w [op_name::String] [tags::Symbol...] expr

Annotate a function call with logging, timing, and API integration.

# Arguments
- `op_name::String`: Optional operation name for the call
- `tags::Symbol...`: Optional metadata tags (as QuoteNodes)
- `expr`: The function call expression to annotate

# Returns
- The result of the annotated function call

# Examples
```julia
# Basic usage
@w sqrt(16)

# With operation name
@w "sqrt_operation" sqrt(16)

# With metadata tags
@w :math :basic sqrt(16)

# With both
@w "sqrt_operation" :math :basic sqrt(16)
```
"""
macro w(args...)
    # Extract operation name (string) and tags (QuoteNodes) from args
    op_name = nothing
    tags = Symbol[]
    expr = nothing

    for (i, arg) in enumerate(args)
        if i == length(args)
            expr = arg  # Last argument is always the expression
        elseif arg isa String || (arg isa Expr && arg.head == :string)
            op_name = arg  # String literal is op_name
        elseif arg isa QuoteNode
            push!(tags, arg.value)  # QuoteNode is a tag
        end
    end

    # Default op_name if none provided
    if isnothing(op_name)
        if expr isa Expr && expr.head == :call
            op_name = string(expr.args[1])  # Use function name as op_name
        else
            op_name = "anonymous_operation"
        end
    end

    # Generate unique IDs for the call
    call_id = :(string(uuid4()))
    trace_id = :(string(uuid4()))

    # Get the expression as a string
    expr_str = string(expr)

    # Create the annotated expression
    quote
        # Capture start time with nanosecond precision
        local start_time_ns = time_ns()
        local start_time = now(UTC)

        # Extract and escape input arguments more carefully
        local input_args = try
            Any[$(map(arg -> :($(esc(arg))), expr.args[2:end])...)]
        catch
            Any[]  # Handle cases where argument extraction fails
        end

        local input_types = try
            Type[$(map(arg -> :(typeof($(esc(arg)))), expr.args[2:end])...)]
        catch
            Type[]  # Handle cases where type extraction fails
        end

        # Generate unique IDs for the call
        local call_id = $call_id
        local trace_id = $trace_id

        # Start the call
        start_call(
            call_id,
            trace_id=trace_id,
            op_name=let
                hash_value = bytes2hex(sha256(string($(esc(op_name))))[1:4])
                "weave:///$PROJECT_ID/op/$(esc(op_name)):$hash_value"
            end,
            started_at=format_iso8601(start_time),
            inputs=Dict(
                "args" => input_args,
                "types" => input_types,
                "code" => $expr_str
            ),
            attributes=merge(
                get_system_metadata(),
                Dict{String,Any}(
                    "tags" => $tags,
                    "expression" => $expr_str
                )
            )
        )

        # Execute the function with minimal error handling
        local result = try
            $(esc(expr))
        catch e
            # End the call and rethrow immediately without wrapping
            end_call(
                call_id,
                trace_id=trace_id,
                started_at=format_iso8601(start_time),
                error=e,  # Pass the error object directly without wrapping
                outputs=nothing  # No outputs on error
            )
            rethrow(e)  # Rethrow immediately without additional wrapping
        end

        # Calculate duration with nanosecond precision
        local end_time_ns = time_ns()
        local duration_ns = end_time_ns - start_time_ns

        # End the call successfully
        end_call(
            call_id,
            ended_at=format_iso8601(now(UTC)),
            outputs=Dict(
                "result" => result,
                "type" => typeof(result),
                "code" => $expr_str
            ),
            attributes=Dict{String,Any}(
                "expression" => $expr_str,
                "duration_ns" => duration_ns
            )
        )

        # Return the result
        result
    end # quote
end # macro w

"""
    @wtable(table_name::String, data, tags::Symbol...)

Log a Tables.jl-compatible object or DataFrame to Weights & Biases Weave service.

# Arguments
- `table_name::String`: Name under which the table will be logged
- `data`: A Tables.jl-compatible object or DataFrame to be logged
- `tags::Symbol...`: Optional tags to be associated with the table

# Example
```julia
df = DataFrame(a = 1:3, b = ["x", "y", "z"])
@wtable "my_table" df :tag1 :tag2  # Explicit name
@wtable df :tag1 :tag2             # Uses variable name
```
"""
macro wtable(args...)
    # Extract table name and data object
    if length(args) < 1
        return :(create_table(nothing, nothing, Symbol[]))  # Let API handle invalid cases
    end

    # Handle different calling patterns
    local table_name_expr
    local data_expr
    local start_idx

    # Check if first argument is a string (explicit name)
    if isa(args[1], String) || (isa(args[1], Expr) && args[1].head == :string)
        # Explicit string name provided: @wtable "name" data
        table_name_expr = args[1]
        data_expr = length(args) >= 2 ? args[2] : nothing  # Let API handle missing data
        start_idx = 3
    else
        # Use first argument as both name and data: @wtable data
        data_expr = args[1]
        table_name_expr = string(args[1])
        start_idx = 2
    end

    tag_values = [arg.value for arg in args[start_idx:end] if arg isa QuoteNode]

    return quote
        local data = $(esc(data_expr))
        local table_name = $(esc(table_name_expr))
        local tags = Symbol[]
        append!(tags, $tag_values)
        create_table(table_name, data, tags)  # Let API handle all validation
    end
end

"""
    @wfile(file_name::Union{String,Nothing}, file_path, tags::Symbol...)

Log a file to Weights & Biases Weave service.

# Arguments
- `file_name::Union{String,Nothing}`: Optional name for the file (if not provided, basename of file_path is used)
- `file_path`: Path to the file to be logged
- `tags::Symbol...`: Optional tags to be associated with the file

# Example
```julia
@wfile "config.yaml" "/path/to/config.yaml" :config :yaml
@wfile nothing "data.csv" :data :csv  # Uses "data.csv" as name
```
"""
macro wfile(args...)
    # Extract file name/path and let API handle validation
    if length(args) < 1
        return :(create_file(nothing, nothing, Symbol[]))  # Let API handle invalid cases
    end

    # Debug output (after length check)
    @info "Macro args" typeof(args[1]) args[1]

    # Handle optional file name
    local file_name_expr
    local file_path_expr
    local start_idx

    if length(args) >= 2 && (
        isa(args[1], String) ||
        (isa(args[1], Expr) && args[1].head == :string) ||
        args[1] === nothing ||
        (args[1] isa Symbol && args[1] === Symbol("nothing"))
    )
        # Convert nothing symbol to actual nothing during macro expansion
        file_name_expr = args[1] === Symbol("nothing") ? nothing : args[1]
        file_path_expr = args[2]
        start_idx = 3
    else
        file_name_expr = nothing
        file_path_expr = args[1]
        start_idx = 2
    end

    tag_values = [arg.value for arg in args[start_idx:end] if arg isa QuoteNode]

    return quote
        # Evaluate file path and name directly, letting API handle any errors
        local raw_path = $(esc(file_path_expr))
        local raw_name = $(file_name_expr === nothing ? :(nothing) : esc(file_name_expr))

        # Use basename if no name provided or if explicitly nothing
        local name = if raw_name === nothing
            basename(string(raw_path))
        else
            string(raw_name)
        end

        # Collect tags
        local tags = Symbol[]
        append!(tags, $tag_values)

        # Create the file entry - let create_file handle all validation
        create_file(name, raw_path, tags)
    end
end

end # module Macros

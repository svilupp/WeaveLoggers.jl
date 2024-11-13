"""
WeaveLoggers Macro Utilities

This module provides macros for annotating function calls with logging, timing,
and API integration capabilities.
"""
module Macros

using ..WeaveLoggers: format_iso8601
using ..WeaveLoggers.Calls: start_call, end_call
using Dates

export @w

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
        # Capture start time
        local start_time = now()

        # Prepare input logging
        local input_args = Any[$(map(arg -> :($arg), expr.args[2:end])...)]
        local input_types = Type[$(map(arg -> :(typeof($arg)), expr.args[2:end])...)]

        # Start the call
        local call_id = $call_id
        local trace_id = $trace_id
        start_call(
            id=call_id,
            trace_id=trace_id,
            op_name=$(esc(op_name)),
            started_at=format_iso8601(start_time),
            inputs=Dict(
                "args" => input_args,
                "types" => input_types,
                "code" => $expr_str  # Add the expression string
            ),
            attributes=Dict{String,Any}(
                "tags" => $tags,
                "expression" => $expr_str  # Also add to attributes for better visibility
            )
        )

        # Execute the function
        local result = try
            $(esc(expr))
        catch e
            # End the call with error
            end_call(
                id=call_id,
                error=sprint(showerror, e),
                ended_at=format_iso8601(now()),
                attributes=Dict{String,Any}(
                    "expression" => $expr_str  # Include expression in error case
                )
            )
            rethrow(e)
        end

        # End the call successfully
        end_call(
            id=call_id,
            outputs=Dict(
                "result" => result,
                "type" => typeof(result),
                "code" => $expr_str  # Add the expression string
            ),
            ended_at=format_iso8601(now()),
            attributes=Dict{String,Any}(
                "expression" => $expr_str  # Also add to attributes for better visibility
            )
        )

        # Return the result
        result
    end
end

end # module Macros

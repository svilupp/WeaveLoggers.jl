module TestUtils

using WeaveLoggers
using Dates

# Test data structures
struct TestType
    x::Int
    y::String
end

# Test setup function to initialize all test data
function setup_test_data()
    TEST_ARRAY_SIZE = 1_000_000
    test_obj = TestType(42, "hello")
    large_array = rand(TEST_ARRAY_SIZE)
    large_string = repeat("a", TEST_ARRAY_SIZE)
    return (
        TEST_ARRAY_SIZE = TEST_ARRAY_SIZE,
        test_obj = test_obj,
        large_array = large_array,
        large_string = large_string
    )
end

# Mock API call results for verification
mutable struct MockAPIResults
    start_calls::Vector{Dict{String,Any}}
    end_calls::Vector{Dict{String,Any}}
end

# Initialize mock results with explicit type parameters
const mock_results = MockAPIResults(Vector{Dict{String,Any}}(), Vector{Dict{String,Any}}())

# Mock API Module
module MockAPI
    using ..TestUtils: mock_results
    using UUIDs
    using Dates

    # Single method for start_call with keyword arguments
    function start_call(; op_name::String="", inputs::Dict{String,Any}=Dict{String,Any}(), attributes::Dict{String,Any}=Dict{String,Any}())
        call_id = string(uuid4())
        trace_id = string(uuid4())
        started_at = WeaveLoggers.format_iso8601(now(UTC))

        call_data = Dict{String,Any}(
            "id" => call_id,
            "trace_id" => trace_id,
            "op_name" => op_name,
            "started_at" => started_at,
            "inputs" => inputs,
            "attributes" => attributes
        )

        push!(mock_results.start_calls, call_data)
        return call_data  # Return full data for macro to use
    end

    function end_call(call_id::String; outputs::Dict{String,Any}=Dict{String,Any}(), error::Union{Nothing,Dict{String,Any}}=nothing)
        call_data = Dict{String,Any}(
            "id" => call_id,
            "outputs" => outputs,
            "ended_at" => WeaveLoggers.format_iso8601(now(UTC))
        )

        if !isnothing(error)
            call_data["error"] = error
        end

        push!(mock_results.end_calls, call_data)
        return call_data  # Return full data for consistency
    end
end

# Export everything
export TestType, setup_test_data, MockAPIResults, mock_results, MockAPI

end

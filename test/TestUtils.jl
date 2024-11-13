module TestUtils

using WeaveLoggers
using Dates
using UUIDs

# Test data structures
struct TestType
    value::Int
end

Base.string(t::TestType) = "TestType($(t.value))"

# Test setup function to initialize all test data
function setup_test_data()
    TEST_ARRAY_SIZE = 1_000_000
    test_obj = TestType(42)
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
    using WeaveLoggers: format_iso8601

    # Mock weave_api function to bypass actual API calls
    function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                      base_url::String="", query_params::Dict{String,String}=Dict{String,String}())
        # For start_call endpoint
        if endpoint == "/call/start"
            return start_call(
                body["op_name"];
                inputs=get(body, "inputs", nothing),
                display_name=get(body, "display_name", nothing),
                attributes=get(body, "attributes", nothing)
            )
        # For end_call endpoint
        elseif endpoint == "/call/end"
            return end_call(
                body["id"];
                outputs=get(body, "outputs", Dict{String,Any}()),
                error=get(body, "error", nothing)
            )
        end
        return Dict{String,Any}("status" => "mocked", "endpoint" => endpoint)
    end

    # Start call with both positional and keyword arguments
    function start_call(op_name::String; inputs=nothing, display_name=nothing, attributes=nothing)
        call_id = string(uuid4())
        trace_id = string(uuid4())
        started_at = format_iso8601(now(UTC))

        call_data = Dict{String,Any}(
            "id" => call_id,
            "trace_id" => trace_id,
            "op_name" => op_name,
            "started_at" => started_at
        )

        if !isnothing(inputs)
            call_data["inputs"] = inputs
        end
        if !isnothing(display_name)
            call_data["display_name"] = display_name
        end
        if !isnothing(attributes)
            call_data["attributes"] = attributes
        end

        push!(mock_results.start_calls, call_data)
        return call_data
    end

    function end_call(call_id::String; outputs::Dict{String,Any}=Dict{String,Any}(), error::Union{Nothing,Dict{String,Any}}=nothing)
        call_data = Dict{String,Any}(
            "id" => call_id,
            "outputs" => outputs,
            "ended_at" => format_iso8601(now(UTC))
        )

        if !isnothing(error)
            call_data["error"] = error
        end

        push!(mock_results.end_calls, call_data)
        return call_data
    end
end

# Override WeaveLoggers API functions with mock versions
const weave_api = MockAPI.weave_api
const start_call = MockAPI.start_call
const end_call = MockAPI.end_call

# Export everything
export TestType, setup_test_data, MockAPIResults, mock_results, MockAPI
export weave_api, start_call, end_call

end

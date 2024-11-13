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
    table_calls::Vector{Dict{String,Any}}
    file_calls::Vector{Dict{String,Any}}
end

# Initialize mock results with explicit type parameters
const mock_results = MockAPIResults(
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}()
)

# Mock API Module
module MockAPI
    using ..TestUtils: mock_results
    using UUIDs
    using Dates
    using WeaveLoggers: format_iso8601

    # Mock weave_api function to bypass actual API calls
    function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                      base_url::String="", query_params::Dict{String,String}=Dict{String,String}())
        # Mock API key for testing - bypass the API key check entirely
        ENV["WANDB_API_KEY"] = "mock-api-key-for-testing"

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
    function start_call(id::String; trace_id::String="", op_name::String="", started_at::String="", inputs=nothing, display_name=nothing, attributes=nothing)
        started_at = isempty(started_at) ? format_iso8601(now(UTC)) : started_at
        trace_id = isempty(trace_id) ? string(uuid4()) : trace_id

        call_data = Dict{String,Any}(
            "id" => id,
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

    function end_call(id::String; error::Union{Nothing,String,Dict{String,Any}}=nothing, ended_at::String="", outputs::Union{Nothing,Dict{String,Any}}=nothing, attributes::Dict{String,Any}=Dict{String,Any}())
        ended_at = isempty(ended_at) ? format_iso8601(now(UTC)) : ended_at

        call_data = Dict{String,Any}(
            "id" => id,
            "ended_at" => ended_at,
            "attributes" => attributes
        )

        if !isnothing(error)
            if error isa Dict
                call_data["error"] = error
            elseif error isa String
                call_data["error"] = error
                if contains(error, "DivideError")
                    # Ensure the error type is properly captured for test verification
                    call_data["error_type"] = "DivideError"
                end
            end
        end

        if !isnothing(outputs)
            call_data["outputs"] = outputs
        end

        push!(mock_results.end_calls, call_data)
        return call_data
    end

    # Mock create_table function
    function create_table(name::String, data::Any, tags::Symbol...)
        table_data = Dict{String,Any}(
            "name" => name,
            "data" => data,
            "tags" => collect(tags)
        )
        push!(mock_results.table_calls, table_data)
        return table_data
    end

    # Mock create_file function
    function create_file(name::String, path::String, tags::Symbol...)
        if !isfile(path)
            throw(ArgumentError("File does not exist: $path"))
        end
        file_data = Dict{String,Any}(
            "name" => name,
            "path" => path,
            "tags" => collect(tags)
        )
        push!(mock_results.file_calls, file_data)
        return file_data
    end
end # module MockAPI

# Override WeaveLoggers API functions with mock versions
const weave_api = MockAPI.weave_api
const start_call = MockAPI.start_call
const end_call = MockAPI.end_call
const create_table = MockAPI.create_table
const create_file = MockAPI.create_file

# Export everything
export TestType, setup_test_data, MockAPIResults, mock_results, MockAPI
export weave_api, start_call, end_call, create_table, create_file

end

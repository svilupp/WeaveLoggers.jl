module TestUtils

using WeaveLoggers
using Dates, UUIDs, Tables, DataFrames

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
    using DataFrames, Tables

    # Mock weave_api function to bypass actual API calls
    function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                      base_url::String="", query_params::Dict{String,String}=Dict{String,String}())
        # Mock API key for testing - bypass the API key check entirely
        ENV["WANDB_API_KEY"] = "mock-api-key-for-testing"

        # For start_call endpoint
        if endpoint == "/call/start"
            return start_call(
                model=get(body, "model", ""),
                inputs=get(body, "inputs", nothing),
                metadata=get(body, "metadata", nothing)
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
    function start_call(id::String; trace_id::Union{String,Nothing}=nothing, op_name::Union{String,Nothing}=nothing,
                       started_at::Union{String,Nothing}=nothing, inputs::Union{Dict,Nothing}=nothing,
                       attributes::Union{Dict,Nothing}=nothing, model::String="",
                       metadata::Union{Dict,Nothing}=nothing)
        # Store the full result in mock_results but return only the ID
        result = start_call(; trace_id=isnothing(trace_id) ? id : trace_id,
                             op_name=op_name, started_at=started_at,
                             inputs=inputs, attributes=attributes,
                             model=model, metadata=metadata)
        result["id"] = id  # Override the generated ID with the provided one
        push!(mock_results.start_calls, result)
        return id  # Return only the ID string
    end

    function start_call(; trace_id::Union{String,Nothing}=nothing, op_name::Union{String,Nothing}=nothing,
                       started_at::Union{String,Nothing}=nothing, inputs::Union{Dict,Nothing}=nothing,
                       attributes::Union{Dict,Nothing}=nothing, model::String="",
                       metadata::Union{Dict,Nothing}=nothing)
        id = string(uuid4())
        trace_id = isnothing(trace_id) ? string(uuid4()) : trace_id
        started_at = isnothing(started_at) ? format_iso8601(now(UTC)) : started_at

        call_data = Dict{String,Any}(
            "id" => id,
            "trace_id" => trace_id,
            "started_at" => started_at
        )

        # Support both old and new parameter sets
        if !isnothing(op_name)
            call_data["op_name"] = op_name
        end
        if !isempty(model)
            call_data["model"] = model
        end
        if !isnothing(inputs)
            call_data["inputs"] = inputs
        end
        if !isnothing(attributes)
            call_data["attributes"] = attributes
        end
        if !isnothing(metadata)
            call_data["metadata"] = metadata
        end

        push!(mock_results.start_calls, call_data)
        return call_data
    end

    function end_call(id::String; error::Union{Nothing,String,Dict{String,Any}}=nothing, ended_at::String="", outputs::Union{Nothing,Dict{String,Any}}=nothing, attributes::Dict{String,Any}=Dict{String,Any}())
        # Add a small sleep to ensure measurable time difference
        sleep(0.001)  # 1ms sleep

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

    # Mock create_table function with unified handling for all table types
    function create_table(name::String, data::Any, tags::Vector{Symbol}=Symbol[])
        # Handle non-Tables.jl-compatible data first
        if !(Tables.istable(data) || data isa DataFrame)
            throw(ArgumentError("Data must be Tables.jl-compatible"))
        end

        # Create table data dictionary
        table_data = Dict{String,Any}(
            "name" => name,
            "data" => data,
            "tags" => tags
        )
        push!(mock_results.table_calls, table_data)
        return table_data
    end

    # Convenience method for variadic tags
    function create_table(name::String, data::Any, tags::Symbol...)
        create_table(name, data, collect(tags))
    end

    # Method for handling non-Tables.jl-compatible data with explicit error
    function create_table(name::String, data::Symbol, tags::Vector{Symbol}=Symbol[])
        throw(ArgumentError("Data must be Tables.jl-compatible"))
    end

    # Mock create_file function with unified handling for all tag types
    function create_file(name::String, path::Union{String,Nothing}, tags::Vector{Symbol}=Symbol[])
        # Handle nothing path case by using a default temporary file
        if isnothing(path)
            path = tempname()
            write(path, "test content")  # Create a temporary file
        end

        # Check if file exists
        if !isfile(path)
            throw(ArgumentError("File does not exist: $path"))
        end

        # Convert empty vector to Symbol[] to avoid type issues
        actual_tags = isempty(tags) ? Symbol[] : convert(Vector{Symbol}, tags)
        file_data = Dict{String,Any}(
            "name" => isnothing(name) ? basename(path) : name,
            "path" => path,
            "tags" => actual_tags
        )
        push!(mock_results.file_calls, file_data)
        return file_data
    end

    # Convenience method for variadic tags
    function create_file(name::String, path::Union{String,Nothing}, tags::Symbol...)
        create_file(name, path, collect(tags))
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

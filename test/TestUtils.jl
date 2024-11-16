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
    object_calls::Vector{Dict{String,Any}}
    error_calls::Vector{Dict{String,Any}}  # Add error_calls tracking
end

# Initialize mock results with explicit type parameters
const mock_results = MockAPIResults(
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}(),
    Vector{Dict{String,Any}}()  # Initialize error_calls
)

# Mock API Module
module MockAPI
    using ..TestUtils: mock_results
    using UUIDs
    using Dates
    using WeaveLoggers: format_iso8601, WeaveAPIError
    using DataFrames, Tables

    # Error simulation state
    const error_states = Dict{Symbol,Bool}(
        :auth_error => false,
        :network_error => false,
        :rate_limit_error => false,
        :invalid_payload_error => false,
        :metadata_error => false
    )

    # Error simulation control functions
    function set_auth_error(state::Bool)
        error_states[:auth_error] = state
    end

    function set_network_error(state::Bool)
        error_states[:network_error] = state
    end

    function set_rate_limit_error(state::Bool)
        error_states[:rate_limit_error] = state
    end

    function set_invalid_payload_error(state::Bool)
        error_states[:invalid_payload_error] = state
    end

    function set_metadata_error(state::Bool)
        error_states[:metadata_error] = state
    end

    # Error handling helper function
    function check_for_errors(endpoint::String)
        if error_states[:auth_error]
            error_data = Dict{String,Any}(
                "error" => "Authentication failed",
                "error_type" => "AuthenticationError",
                "endpoint" => endpoint,
                "attributes" => Dict(
                    "weave" => Dict(
                        "client_version" => "0.1.0",
                        "source" => "julia-client",
                        "os" => string(Sys.KERNEL),
                        "arch" => string(Sys.ARCH),
                        "julia_version" => string(VERSION)
                    )
                )
            )
            push!(mock_results.error_calls, error_data)
            throw(WeaveAPIError("Authentication failed", 401))
        elseif error_states[:network_error]
            error_data = Dict{String,Any}(
                "error" => "Network connection failed",
                "error_type" => "NetworkError",
                "endpoint" => endpoint,
                "attributes" => Dict(
                    "weave" => Dict(
                        "client_version" => "0.1.0",
                        "source" => "julia-client",
                        "os" => string(Sys.KERNEL),
                        "arch" => string(Sys.ARCH),
                        "julia_version" => string(VERSION)
                    )
                )
            )
            push!(mock_results.error_calls, error_data)
            throw(WeaveAPIError("Network connection failed", 503))
        elseif error_states[:rate_limit_error]
            error_data = Dict{String,Any}(
                "error" => "Rate limit exceeded",
                "error_type" => "RateLimitError",
                "endpoint" => endpoint,
                "attributes" => Dict(
                    "weave" => Dict(
                        "client_version" => "0.1.0",
                        "source" => "julia-client",
                        "os" => string(Sys.KERNEL),
                        "arch" => string(Sys.ARCH),
                        "julia_version" => string(VERSION)
                    )
                )
            )
            push!(mock_results.error_calls, error_data)
            throw(WeaveAPIError("Rate limit exceeded", 429))
        elseif error_states[:invalid_payload_error]
            error_data = Dict{String,Any}(
                "error" => "Invalid payload format",
                "error_type" => "InvalidPayloadError",
                "endpoint" => endpoint,
                "attributes" => Dict(
                    "weave" => Dict(
                        "client_version" => "0.1.0",
                        "source" => "julia-client",
                        "os" => string(Sys.KERNEL),
                        "arch" => string(Sys.ARCH),
                        "julia_version" => string(VERSION)
                    )
                )
            )
            push!(mock_results.error_calls, error_data)
            throw(WeaveAPIError("Invalid payload format", 400))
        elseif error_states[:metadata_error]
            error_data = Dict{String,Any}(
                "error" => "Missing required metadata",
                "error_type" => "MetadataError",
                "endpoint" => endpoint,
                "attributes" => Dict(
                    "weave" => Dict(
                        "client_version" => "0.1.0",
                        "source" => "julia-client",
                        "os" => string(Sys.KERNEL),
                        "arch" => string(Sys.ARCH),
                        "julia_version" => string(VERSION)
                    )
                )
            )
            push!(mock_results.error_calls, error_data)
            throw(WeaveAPIError("Missing required metadata", 400))
        end
    end

    # Mock weave_api function to bypass actual API calls
    function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                      base_url::String="", query_params::Dict{String,String}=Dict{String,String}())
        # Check for simulated errors before processing any endpoint
        check_for_errors(endpoint)

        # Mock API key for testing - bypass the API key check entirely
        ENV["WANDB_API_KEY"] = "mock-api-key-for-testing"

        # For start_call endpoint
        if endpoint == "/call/start" && !isnothing(body)
            return start_call(
                id=get(body, "id", string(uuid4())),
                trace_id=get(body, "trace_id", string(uuid4())),
                op_name=get(body, "op_name", ""),
                started_at=get(body, "started_at", format_iso8601(now(UTC))),
                inputs=get(body, "inputs", Dict()),
                attributes=get(body, "attributes", Dict())
            )
        # For end_call endpoint
        elseif endpoint == "/call/end" && !isnothing(body)
            return end_call(
                body["id"];
                outputs=get(body, "outputs", Dict()),
                error=get(body, "error", nothing),
                trace_id=get(body, "trace_id", string(uuid4())),
                started_at=get(body, "started_at", format_iso8601(now(UTC)))
            )
        # For update_call endpoint
        elseif endpoint == "/call/update" && !isnothing(body)
            return Dict{String,Any}(
                "status" => "success",
                "id" => get(body, "id", ""),
                "project_id" => get(body, "project_id", "")
            )
        # For delete_call endpoint
        elseif endpoint == "/call/delete" && !isnothing(body)
            return Dict{String,Any}(
                "status" => "success",
                "id" => get(body, "id", ""),
                "project_id" => get(body, "project_id", "")
            )
        # For read_call endpoint
        elseif endpoint == "/call/read" && !isnothing(query_params)
            return Dict{String,Any}(
                "status" => "success",
                "id" => get(query_params, "id", ""),
                "project_id" => get(query_params, "project_id", "")
            )
        end
        return Dict{String,Any}("status" => "mocked", "endpoint" => endpoint)
    end

    # Mock start_call function to match the new API format
    function start_call(; op_name::String, inputs::Dict=Dict(), attributes::Dict=Dict(), display_name::String="")
        # Generate unique identifiers
        id = string(uuid4())
        trace_id = string(uuid4())
        started_at = format_iso8601(now(UTC))

        # Format op_name to include entity/project with weave:/// prefix
        formatted_op_name = "weave:///anim-mina/slide-comprehension-plain-ocr/$op_name"

        # Add system metadata
        system_metadata = Dict(
            "weave" => Dict(
                "client_version" => "0.1.0",  # Mock version for testing
                "source" => "julia-client",
                "os" => string(Sys.KERNEL),
                "arch" => string(Sys.ARCH),
                "julia_version" => string(VERSION)
            )
        )
        merged_attributes = merge(system_metadata, attributes)

        # Create call data with flattened structure
        call_data = Dict{String,Any}(
            "project_id" => "anim-mina/slide-comprehension-plain-ocr",
            "id" => id,
            "op_name" => formatted_op_name,
            "display_name" => isempty(display_name) ? op_name : display_name,
            "trace_id" => trace_id,
            "parent_id" => nothing,
            "started_at" => started_at,
            "inputs" => inputs,
            "attributes" => merged_attributes,
            "wb_user_id" => nothing,
            "wb_run_id" => nothing
        )

        push!(mock_results.start_calls, call_data)
        return id, trace_id, started_at
    end

    function end_call(id::String; error::Union{Nothing,String,Dict{String,Any}}=nothing, ended_at::String="",
                     outputs::Union{Nothing,Dict{String,Any}}=nothing,
                     attributes::Dict{String,Any}=Dict{String,Any}(),
                     trace_id::String=string(uuid4()),
                     started_at::String=format_iso8601(now(UTC)))
        # Add a small sleep to ensure measurable time difference
        sleep(0.001)  # 1ms sleep

        ended_at = isempty(ended_at) ? format_iso8601(now(UTC)) : ended_at

        call_data = Dict{String,Any}(
            "id" => id,
            "project_id" => "anim-mina/slide-comprehension-plain-ocr",
            "trace_id" => trace_id,
            "started_at" => started_at,
            "ended_at" => ended_at,
            "attributes" => attributes,
            "summary" => Dict(
                "input_type" => "function_input",
                "output_type" => "function_output",
                "result" => outputs,
                "status" => isnothing(error) ? "success" : "error",
                "duration" => nothing
            )
        )

        if !isnothing(error)
            if error isa Dict
                call_data["error"] = error
            elseif error isa String
                call_data["error"] = error
                if contains(error, "DivideError")
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

        # Add system metadata
        system_metadata = Dict(
            "weave" => Dict(
                "client_version" => "0.1.0",  # Mock version for testing
                "source" => "julia-client",
                "os" => string(Sys.KERNEL),
                "arch" => string(Sys.ARCH),
                "julia_version" => string(VERSION)
            )
        )

        # Create table data dictionary with proper formatting
        table_data = Dict{String,Any}(
            "name" => name,
            "id" => string(uuid4()),
            "project_id" => "anim-mina/slide-comprehension-plain-ocr",
            "op_name" => "weave:///anim-mina/slide-comprehension-plain-ocr/create_table",
            "data" => data,
            "tags" => tags,
            "attributes" => system_metadata,
            "created_at" => format_iso8601(now(UTC))
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

        # Add system metadata
        system_metadata = Dict(
            "weave" => Dict(
                "client_version" => "0.1.0",  # Mock version for testing
                "source" => "julia-client",
                "os" => string(Sys.KERNEL),
                "arch" => string(Sys.ARCH),
                "julia_version" => string(VERSION)
            )
        )

        file_data = Dict{String,Any}(
            "name" => isnothing(name) ? basename(path) : name,
            "id" => string(uuid4()),
            "project_id" => "anim-mina/slide-comprehension-plain-ocr",
            "op_name" => "weave:///anim-mina/slide-comprehension-plain-ocr/create_file",
            "path" => path,
            "tags" => actual_tags,
            "attributes" => system_metadata,
            "created_at" => format_iso8601(now(UTC))
        )
        push!(mock_results.file_calls, file_data)
        return file_data
    end

    # Convenience method for variadic tags
    function create_file(name::String, path::Union{String,Nothing}, tags::Symbol...)
        create_file(name, path, collect(tags))
    end

    # Mock create_object function with unified handling for all tag types
    function create_object(name::String, obj::Any, tags::Vector{Symbol}=Symbol[])
        # Convert empty vector to Symbol[] to avoid type issues
        actual_tags = isempty(tags) ? Symbol[] : convert(Vector{Symbol}, tags)

        # Add system metadata
        system_metadata = Dict(
            "weave" => Dict(
                "client_version" => "0.1.0",  # Mock version for testing
                "source" => "julia-client",
                "os" => string(Sys.KERNEL),
                "arch" => string(Sys.ARCH),
                "julia_version" => string(VERSION)
            )
        )

        # Create object data dictionary with proper formatting
        object_data = Dict{String,Any}(
            "name" => name,
            "id" => string(uuid4()),
            "project_id" => "anim-mina/slide-comprehension-plain-ocr",
            "op_name" => "weave:///anim-mina/slide-comprehension-plain-ocr/create_object",
            "data" => string(obj),  # Convert object to string representation
            "tags" => actual_tags,
            "attributes" => system_metadata,
            "created_at" => format_iso8601(now(UTC))
        )
        push!(mock_results.object_calls, object_data)
        return object_data
    end

    # Convenience method for variadic tags
    function create_object(name::String, obj::Any, tags::Symbol...)
        create_object(name, obj, collect(tags))
    end

end # module MockAPI

# Override WeaveLoggers API functions with mock versions
const weave_api = MockAPI.weave_api
const start_call = MockAPI.start_call
const end_call = MockAPI.end_call
const create_table = MockAPI.create_table
const create_file = MockAPI.create_file
const create_object = MockAPI.create_object

# Export everything
export TestType, setup_test_data, MockAPIResults, mock_results, MockAPI
export weave_api, start_call, end_call, create_table, create_file, create_object

end

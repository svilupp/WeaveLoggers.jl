using WeaveLoggers
using Test
using Dates
using JSON3
using HTTP
using SHA

# Mock API results structure
mutable struct MockWeaveAPI
    calls::Dict{String, Dict{String,Any}}
    last_request::Union{Nothing,Dict{String,Any}}
    auth_header::Union{Nothing,String}
end

# Initialize mock API
const mock_api = MockWeaveAPI(Dict{String,Any}(), nothing, nothing)

# Mock the weave_api function
function WeaveLoggers.weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                               base_url::String=WeaveLoggers.WEAVE_API_BASE_URL,
                               query_params::Dict{String,String}=Dict{String,String}())
    # Store the request for inspection
    mock_api.last_request = Dict(
        "method" => method,
        "endpoint" => endpoint,
        "body" => body,
        "base_url" => base_url,
        "query_params" => query_params
    )

    # Verify authentication
    auth_header = get(ENV, "WANDB_API_KEY", nothing)
    if isnothing(auth_header)
        throw(HTTP.ExceptionRequest.StatusError(401, method, endpoint, "Unauthorized: Missing API key"))
    end
    mock_api.auth_header = auth_header

    if method == "POST" && endpoint == "/call/start"
        # Verify required fields for start_call
        start_data = body["start"]
        required_fields = ["project_id", "id", "op_name", "started_at"]
        for field in required_fields
            if !haskey(start_data, field)
                throw(HTTP.ExceptionRequest.StatusError(400, method, endpoint, "Missing required field: $field"))
            end
        end

        # Verify op_name format
        if !occursin(r"^weave:///[^/]+/[^/]+/op/[^:]+:[a-f0-9]{8}", start_data["op_name"])
            throw(HTTP.ExceptionRequest.StatusError(400, method, endpoint, "Invalid op_name format"))
        end

        # Handle start_call
        call_id = start_data["id"]
        mock_api.calls[call_id] = Dict(
            "start" => start_data
        )
        return nothing

    elseif method == "POST" && occursin(r"/call/.+/end", endpoint)
        # Handle end_call
        call_id = split(endpoint, "/")[3]
        if !haskey(mock_api.calls, call_id)
            throw(HTTP.ExceptionRequest.StatusError(404, method, endpoint, "Call not found"))
        end

        # Verify required fields for end_call
        end_data = body["end"]
        required_fields = ["ended_at"]
        for field in required_fields
            if !haskey(end_data, field)
                throw(HTTP.ExceptionRequest.StatusError(400, method, endpoint, "Missing required field: $field"))
            end
        end

        mock_api.calls[call_id]["end"] = end_data
        return nothing

    elseif method == "GET" && endpoint == "/call/read"
        # Handle read_call
        if !haskey(query_params, "id")
            throw(HTTP.ExceptionRequest.StatusError(400, method, endpoint, "Missing required query parameter: id"))
        end

        call_id = query_params["id"]
        if !haskey(mock_api.calls, call_id)
            throw(HTTP.ExceptionRequest.StatusError(404, method, endpoint, "Call not found"))
        end

        return mock_api.calls[call_id]
    end

    throw(HTTP.ExceptionRequest.StatusError(404, method, endpoint, "Endpoint not found"))
end

@testset "Weave API Integration" begin
    # Reset mock API state
    empty!(mock_api.calls)
    mock_api.last_request = nothing
    mock_api.auth_header = nothing

    # Test complete call workflow
    entity = "anim-mina"
    project = "test-project"
    function_name = "test_function"
    hash = bytes2hex(sha256(function_name)[1:4])

    test_metadata = Dict{String,Any}(
        "project_id" => "$entity/$project",
        "display_name" => "Test Call",
        "wb_run_id" => "test-run-$(round(Int, time()))",
        "test" => true,
        "op_name" => "weave:///$entity/$project/op/$function_name:$hash",
        "attributes" => Dict{String,Any}(),
        "trace_id" => nothing,
        "parent_id" => nothing,
        "wb_user_id" => nothing
    )

    # Start a call with all required fields
    @info "Starting call with test data..."
    call_id = WeaveLoggers.start_call(
        model="test-model",
        inputs=Dict{String,Any}(
            "prompt" => "Hello, World!",
            "temperature" => 0.7
        ),
        metadata=test_metadata
    )

    # Verify call_id
    @test !isnothing(call_id)
    @test typeof(call_id) == String
    @test length(call_id) > 0

    # Verify the request structure
    @test !isnothing(mock_api.last_request)
    @test mock_api.last_request["method"] == "POST"
    @test mock_api.last_request["endpoint"] == "/call/start"

    # Verify authentication
    @test !isnothing(mock_api.auth_header)

    # End the call with complete information
    success = WeaveLoggers.end_call(
        call_id,
        outputs=Dict{String,Any}(
            "response" => "Test response",
            "tokens" => 10,
            "finish_reason" => "complete"
        ),
        error=nothing
    )
    @test success == true

    # Read and verify the call data
    call_data = WeaveLoggers.read_call(call_id)
    @test !isnothing(call_data)

    # Verify the structure matches our implementation
    @test haskey(call_data, "start")
    @test call_data["start"]["id"] == call_id
    @test haskey(call_data["start"], "inputs")
    @test call_data["start"]["inputs"]["prompt"] == "Hello, World!"
    @test call_data["start"]["inputs"]["temperature"] == 0.7

    # Verify metadata
    @test haskey(call_data["start"], "project_id")
    @test call_data["start"]["project_id"] == test_metadata["project_id"]
    @test haskey(call_data["start"], "display_name")
    @test call_data["start"]["display_name"] == test_metadata["display_name"]
    @test haskey(call_data["start"], "op_name")
    @test call_data["start"]["op_name"] == test_metadata["op_name"]

    # Verify timestamps exist and are in correct format
    @test haskey(call_data["start"], "started_at")
    @test !isnothing(DateTime(call_data["start"]["started_at"]))
    @test haskey(call_data, "end")
    @test haskey(call_data["end"], "ended_at")
    @test !isnothing(DateTime(call_data["end"]["ended_at"]))

    # Verify outputs
    @test haskey(call_data["end"], "outputs")
    @test call_data["end"]["outputs"]["response"] == "Test response"
    @test call_data["end"]["outputs"]["tokens"] == 10

    # Test error handling
    @test_throws HTTP.ExceptionRequest.StatusError WeaveLoggers.read_call("nonexistent-id")

    # Test missing required fields
    @test_throws HTTP.ExceptionRequest.StatusError WeaveLoggers.start_call(
        model="test-model",
        inputs=Dict{String,Any}(),
        metadata=Dict{String,Any}()
    )
end

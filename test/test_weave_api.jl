using WeaveLoggers
using Test
using Dates
using JSON3
using HTTP

# Mock API results structure
mutable struct MockWeaveAPI
    calls::Dict{String, Dict{String,Any}}
    last_request::Union{Nothing,Dict{String,Any}}
end

# Initialize mock API
const mock_api = MockWeaveAPI(Dict{String,Any}(), nothing)

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

    if method == "POST" && endpoint == "/call/start"
        # Handle start_call
        call_id = body["start"]["id"]
        mock_api.calls[call_id] = Dict(
            "start" => body["start"]
        )
        return nothing
    elseif method == "POST" && occursin(r"/call/.+/end", endpoint)
        # Handle end_call
        call_id = split(endpoint, "/")[3]
        if haskey(mock_api.calls, call_id)
            mock_api.calls[call_id]["end"] = body["end"]
            return nothing
        else
            throw(HTTP.ExceptionRequest.StatusError(404, "POST", endpoint, nothing))
        end
    elseif method == "GET" && endpoint == "/call/read"
        # Handle read_call
        call_id = query_params["id"]
        if haskey(mock_api.calls, call_id)
            return mock_api.calls[call_id]
        else
            throw(HTTP.ExceptionRequest.StatusError(404, "GET", endpoint, nothing))
        end
    end
end

@testset "Weave API Integration" begin
    # Reset mock API state
    empty!(mock_api.calls)
    mock_api.last_request = nothing

    # Test complete call workflow
    test_metadata = Dict{String,String}(
        "project_id" => "anim-mina/test-project",
        "display_name" => "Test Call",
        "wb_run_id" => "test-run-$(round(Int, time()))",
        "test" => "true"
    )

    # Start a call with all required fields
    @info "Starting call with test data..."
    call_id = start_call(
        model="test-model",
        inputs=Dict{String,String}(
            "prompt" => "Hello, World!",
            "temperature" => "0.7"
        ),
        metadata=test_metadata
    )

    # Verify call_id
    @test !isnothing(call_id)
    @test typeof(call_id) == String
    @test length(call_id) > 0

    # End the call with complete information
    success = end_call(
        call_id,
        outputs=Dict(
            "response" => "Test response",
            "tokens" => 10,
            "finish_reason" => "complete"
        ),
        error=nothing
    )
    @test success == true

    # Read and verify the call data
    call_data = read_call(call_id)
    @test !isnothing(call_data)

    # Verify the structure matches our implementation
    @test haskey(call_data, "start")
    @test call_data["start"]["id"] == call_id
    @test haskey(call_data["start"], "inputs")
    @test call_data["start"]["inputs"]["prompt"] == "Hello, World!"
    @test call_data["start"]["inputs"]["temperature"] == "0.7"

    # Verify metadata
    @test haskey(call_data["start"], "project_id")
    @test call_data["start"]["project_id"] == test_metadata["project_id"]
    @test haskey(call_data["start"], "display_name")
    @test call_data["start"]["display_name"] == test_metadata["display_name"]

    # Verify timestamps exist
    @test haskey(call_data["start"], "started_at")
    @test haskey(call_data, "end")
    @test haskey(call_data["end"], "ended_at")

    # Verify outputs
    @test haskey(call_data["end"], "outputs")
    @test call_data["end"]["outputs"]["response"] == "Test response"
    @test call_data["end"]["outputs"]["tokens"] == 10

    # Test error handling
    @test_throws HTTP.ExceptionRequest.StatusError read_call("nonexistent-id")
end

using WeaveLoggers
using Test
using Dates
using JSON3

@testset "Weave API Integration" begin
    # Test API connectivity first
    @test test_weave_api() == true

    # Test complete call workflow
    test_metadata = Dict{String,String}(
        "project_id" => "test-project",
        "display_name" => "Test Call",
        "wb_user_id" => "test-user",
        "wb_run_id" => "test-run",
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
    @info "Call started" call_id=call_id

    # Verify call_id
    @test !isnothing(call_id)
    @test typeof(call_id) == String
    @test length(call_id) > 0

    # Give the API a moment to process
    sleep(1)

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

    # Give the API a moment to process
    sleep(1)

    # Read and verify the call data
    call_data = read_call(call_id)
    @test !isnothing(call_data)

    # Verify the structure matches our implementation
    @test haskey(call_data, :id)
    @test call_data.id == call_id
    @test haskey(call_data, :inputs)
    @test call_data.inputs["prompt"] == "Hello, World!"
    @test call_data.inputs["temperature"] == 0.7

    # Verify metadata
    @test haskey(call_data, :project_id)
    @test call_data.project_id == test_metadata["project_id"]
    @test haskey(call_data, :display_name)
    @test call_data.display_name == test_metadata["display_name"]

    # Verify timestamps exist
    @test haskey(call_data, :started_at)
    @test haskey(call_data, :ended_at)

    # Test error handling
    @test_throws Exception read_call("nonexistent-id")
end

using WeaveLoggers
using Dates
using JSON3

# Set up WeaveLoggers with API key from environment
const WANDB_API_KEY = ENV["WANDB_API_KEY"]
WeaveLoggers.set_project_id("anim-mina/slide-comprehension-plain-ocr")

println("Starting API test...")

# Test function to demonstrate API lifecycle
function test_api_lifecycle()
    # 1. Start a call
    println("\nTesting start_call...")
    op_name = "test_function"
    call_id, trace_id, started_at = WeaveLoggers.Calls.start_call(
        op_name,
        inputs=Dict("test_input" => "hello"),
        display_name="Test API Call",
        attributes=Dict("test_attr" => "value")
    )
    println("Started call with ID: ", call_id)

    # 2. Update the call
    println("\nTesting update_call...")
    WeaveLoggers.Calls.update_call(
        call_id,
        attributes=Dict("status" => "running")
    )
    println("Updated call")

    # 3. End the call
    println("\nTesting end_call...")
    WeaveLoggers.Calls.end_call(
        call_id,
        outputs=Dict("test_output" => "world"),
        trace_id=trace_id,
        started_at=started_at
    )
    println("Ended call")

    # 4. Read the call
    println("\nTesting read_call...")
    call_details = WeaveLoggers.Calls.read_call(call_id)
    println("Read call details: ", JSON3.write(call_details, 2))

    println("\nTest completed successfully!")
end

# Run the test
try
    test_api_lifecycle()
catch e
    println("Error during test: ", e)
    rethrow(e)
end

using WeaveLoggers
using Dates

# Set up the project ID and operation name
const PROJECT_ID = "anim-mina/slide-comprehension-plain-ocr"
const OP_NAME = "test_operation"

function test_api_calls()
    println("Starting API verification test...")

    # Start a call
    println("\nTesting start_call...")
    call_id, trace_id, started_at = WeaveLoggers.start_call(
        op_name=OP_NAME,
        inputs=Dict("test_input" => "hello"),
        attributes=Dict("test_attribute" => "world")
    )
    println("Call started successfully: ", call_id)

    # Update the call
    println("\nTesting update_call...")
    WeaveLoggers.update_call(
        call_id,
        attributes=Dict("updated_attribute" => "updated_value")
    )
    println("Call updated successfully")

    # End the call
    println("\nTesting end_call...")
    WeaveLoggers.end_call(
        call_id,
        outputs=Dict("test_output" => "goodbye"),
        trace_id=trace_id,
        started_at=started_at
    )
    println("Call ended successfully")

    println("\nAPI verification test completed successfully!")
end

# Run the test
try
    test_api_calls()
catch e
    println("Error during API test: ", e)
    rethrow(e)
end

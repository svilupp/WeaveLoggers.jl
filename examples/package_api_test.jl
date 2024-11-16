using WeaveLoggers
using HTTP
using JSON3
using Dates
using UUIDs
using Base64

const PROJECT_ID = "anim-mina/slide-comprehension-plain-ocr"

# Enable debug logging
ENV["WEAVE_DEBUG_HTTP"] = "1"

println("\nStarting WeaveLoggers Package API Test...")

try
    # Initialize WeaveLoggers with project ID
    weave_init(PROJECT_ID)

    # Define a simple test function
    @weave_op function test_function(x::String)
        return uppercase(x)
    end

    # Call the function and capture the result
    println("\n=== Testing WeaveLoggers Operation ===")
    result = test_function("hello world")
    println("\nFunction Result: ", result)

    println("\nAPI test completed successfully!")
catch e
    println("\nError during API test: ", e)
    rethrow(e)
end

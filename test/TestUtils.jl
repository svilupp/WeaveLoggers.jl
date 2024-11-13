module TestUtils

using WeaveLoggers
using Dates

# Test data structures
struct TestType
    x::Int
    y::String
end

# Test setup function to initialize all test data
function setup_test_data()
    TEST_ARRAY_SIZE = 1_000_000
    test_obj = TestType(42, "hello")
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

# Initialize mock results
const mock_results = MockAPIResults(Dict{String,Any}[], Dict{String,Any}[])

# Mock API Module
module MockAPI
    using ..TestUtils: mock_results

    function start_call(; kwargs...)
        push!(mock_results.start_calls, Dict{String,Any}(string(k) => v for (k,v) in kwargs))
        return Dict{String,Any}("status" => "started")
    end

    function end_call(; kwargs...)
        push!(mock_results.end_calls, Dict{String,Any}(string(k) => v for (k,v) in kwargs))
        return Dict{String,Any}("status" => "completed")
    end
end

# Export everything
export TestType, setup_test_data, MockAPIResults, mock_results, MockAPI

end

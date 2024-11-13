"""
Test suite for WeaveLoggers macro functionality.

TODO List of Tests:
1. Basic Functionality
   - [x] Test basic function call without options
   - [x] Test with explicit operation name
   - [x] Test with metadata tags
   - [x] Test with both operation name and tags
   - [x] Test with nested function calls

2. Input/Output Logging
   - [x] Test logging of different input types (numbers, strings, arrays)
   - [x] Test logging of complex input types (structs, custom types)
   - [x] Test output value capture
   - [x] Test output type capture
   - [x] Test expression string capture

3. Time Measurement
   - [x] Test timing accuracy with sleep
   - [ ] Test timing with quick operations
   - [ ] Test timing with long-running operations
   - [ ] Test timing precision (milliseconds)

4. Error Handling
   - [x] Test error capture in try-catch
   - [x] Test error message formatting
   - [x] Test error stack trace
   - [x] Test error attributes
   - [x] Test error propagation

5. API Integration
   - [x] Mock start_call function
   - [x] Mock end_call function
   - [x] Test API call sequence
   - [x] Test API payload structure
   - [x] Test API error handling

6. Edge Cases
   - [ ] Test empty input arguments
   - [ ] Test very large inputs/outputs
   - [ ] Test unicode in strings
   - [ ] Test special characters in operation names
   - [ ] Test concurrent calls

7. Performance
   - [ ] Test overhead of macro vs direct calls
   - [ ] Test memory allocation
   - [ ] Test with multiple concurrent operations
"""

using Test
using WeaveLoggers
using Dates
using Statistics
using UUIDs

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
mock_results = MockAPIResults(Dict{String,Any}[], Dict{String,Any}[])

# Import WeaveLoggers API functions for mocking
import WeaveLoggers.Calls: start_call, end_call

# Define mock implementations
function start_call(; kwargs...)
    push!(mock_results.start_calls, Dict{String,Any}(string(k) => v for (k,v) in kwargs))
    return Dict{String,Any}("status" => "started")
end

function end_call(; kwargs...)
    push!(mock_results.end_calls, Dict{String,Any}(string(k) => v for (k,v) in kwargs))
    return Dict{String,Any}("status" => "completed")
end

@testset "WeaveLoggers.@w Macro Tests" begin
    let test_data = setup_test_data()

    @testset "Basic Functionality" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test basic function call without options
        result = @w sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Verify start_call contents
        @test haskey(start_call, "id")
        @test haskey(start_call, "trace_id")
        @test start_call["op_name"] == "sqrt"
        @test haskey(start_call, "started_at")
        @test haskey(start_call["inputs"], "args")
        @test haskey(start_call["inputs"], "types")
        @test haskey(start_call["inputs"], "code")
        @test start_call["inputs"]["args"] == [16]
        @test start_call["inputs"]["types"] == [Int]
        @test start_call["inputs"]["code"] == "sqrt(16)"

        # Verify end_call contents
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "ended_at")
        @test end_call["outputs"]["result"] == 4.0
        @test end_call["outputs"]["type"] == Float64
        @test end_call["outputs"]["code"] == "sqrt(16)"
        @test haskey(end_call["attributes"], "expression")

        # Test with explicit operation name
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w "square_root" sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        @test start_call["op_name"] == "square_root"

        # Test with metadata tags
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w :math :basic sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        @test start_call["attributes"]["tags"] == [:math, :basic]

        # Test with both operation name and tags
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w "square_root" :math :basic sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        @test start_call["op_name"] == "square_root"
        @test start_call["attributes"]["tags"] == [:math, :basic]
    end

    @testset "Error Handling" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test error capture and propagation
        @test_throws DivideError @w div(1, 0)
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Verify error information is captured
        @test haskey(end_call, "error")
        @test contains(end_call["error"], "DivideError")
        @test end_call["id"] == start_call["id"]
    end

    @testset "Time Measurement" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test timing accuracy with sleep
        result = @w "sleep_test" sleep(0.1)
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Parse timestamps
        start_time = DateTime(start_call["started_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        end_time = DateTime(end_call["ended_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        duration_ms = Dates.value(end_time - start_time)

        # Verify timing (should be at least 100ms)
        @test duration_ms >= 100
    end

    @testset "Complex Input Types" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test with custom type
        result = @w "custom_type" string(test_data.test_obj)
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        @test start_call["inputs"]["types"] == [TestType]
        @test start_call["op_name"] == "custom_type"
    end

    @testset "Nested Function Calls" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test nested function calls
        result = @w "nested" sqrt(abs(-16))
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Verify nested call is captured in expression
        @test contains(start_call["inputs"]["code"], "abs")
        @test contains(start_call["inputs"]["code"], "sqrt")
        @test end_call["outputs"]["result"] == 4.0
    end

    @testset "Additional Time Measurement Tests" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test quick operation timing precision
        result = @w "quick_op" sum([1,2,3])
        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Parse timestamps with millisecond precision
        start_time = DateTime(start_call["started_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        end_time = DateTime(end_call["ended_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        duration_ms = Dates.value(end_time - start_time)

        # Quick operation should take less than 100ms
        @test duration_ms < 100

        # Test long operation timing
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Use pre-defined large array for longer operation
        result = @w "long_op" sum(test_data.large_array)
        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        start_time = DateTime(start_call["started_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        end_time = DateTime(end_call["ended_at"][1:end-1], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
        duration_ms = Dates.value(end_time - start_time)

        # Long operation should take measurable time
        @test duration_ms > 0
    end

    @testset "Edge Cases" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test empty input arguments
        result = @w string()
        @test result == ""
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        # Test very large inputs (using pre-defined large_string)
        result = @w "large_input" length(test_data.large_string)
        @test result == test_data.TEST_ARRAY_SIZE

        # Test unicode in strings
        unicode_str = "Hello, 世界! 🌍"
        result = @w "unicode" length(unicode_str)
        @test result == 13

        # Test special characters in operation names
        result = @w "special!@#\$%^&*" identity(42)
        start_call = mock_results.start_calls[end]
        @test start_call["op_name"] == "special!@#\$%^&*"
    end

    @testset "Performance" begin
        # Test overhead by comparing direct calls vs macro calls
        direct_times = Float64[]
        macro_times = Float64[]

        for _ in 1:1000
            # Direct call timing
            start_time = time_ns()
            _ = sum([1,2,3])
            end_time = time_ns()
            push!(direct_times, (end_time - start_time) / 1e6)  # Convert to milliseconds

            # Macro call timing
            start_time = time_ns()
            _ = @w sum([1,2,3])
            end_time = time_ns()
            push!(macro_times, (end_time - start_time) / 1e6)  # Convert to milliseconds
        end

        # Calculate average overhead
        avg_direct = mean(direct_times)
        avg_macro = mean(macro_times)
        overhead = avg_macro - avg_direct

        # Log the overhead for inspection
        @info "Macro Overhead" overhead_ms=overhead

        # Test memory allocation
        direct_alloc = @allocated sum([1,2,3])
        macro_alloc = @allocated @w sum([1,2,3])

        # Log memory overhead
        @info "Memory Overhead" direct_bytes=direct_alloc macro_bytes=macro_alloc overhead_bytes=(macro_alloc - direct_alloc)

        # Concurrent operations test
        tasks = Task[]
        for i in 1:10
            t = @async begin
                @w "concurrent_$i" sleep(0.01)
            end
            push!(tasks, t)
        end

        # Wait for all tasks to complete
        foreach(wait, tasks)

        # Verify all calls were logged
        concurrent_calls = filter(call -> startswith(call["op_name"], "concurrent_"), mock_results.start_calls)
        @test length(concurrent_calls) == 10
    end
    end # end let block
end

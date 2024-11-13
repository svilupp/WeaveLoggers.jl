using Test
using WeaveLoggers
using Dates
using Statistics
using UUIDs
using .TestUtils  # Use TestUtils module that was included in runtests.jl

# Create local versions of the API functions that delegate to our mocks
const start_call = TestUtils.MockAPI.start_call
const end_call = TestUtils.MockAPI.end_call

@testset "WeaveLoggers.@w Macro Tests" begin
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
        let test_data = setup_test_data()
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
        let test_data = setup_test_data()
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

            # Quick operation should take less than 200ms
            @test duration_ms < 200

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
    end

    @testset "Edge Cases" begin
        let test_data = setup_test_data()
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
            result = @w "unicode" length(collect(unicode_str))
            @test result == 12

            # Test special characters in operation names
            result = @w "special!@#\$%^&*" identity(42)
            start_call = mock_results.start_calls[end]
            @test start_call["op_name"] == "special!@#\$%^&*"
        end
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
end

@testset "WeaveLoggers.@wtable Macro Tests" begin
    using DataFrames, Tables

    @testset "Basic Table Functionality" begin
        # Reset mock results
        empty!(mock_results.table_calls)

        # Test basic DataFrame logging
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        result = @wtable "test_table" df
        @test length(mock_results.table_calls) == 1

        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_table"
        @test table_call["data"] == df
        @test isempty(table_call["tags"])

        # Test with tags
        empty!(mock_results.table_calls)
        result = @wtable "test_table_tags" df :tag1 :tag2
        @test length(mock_results.table_calls) == 1

        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_table_tags"
        @test table_call["tags"] == [:tag1, :tag2]
    end

    @testset "Table Name Handling" begin
        # Reset mock results
        empty!(mock_results.table_calls)

        # Test with variable name when no string name provided
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        test_df = df
        result = @wtable test_df :data
        @test length(mock_results.table_calls) == 1

        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_df"
        @test table_call["tags"] == [:data]
    end

    @testset "Table Error Handling" begin
        # Reset mock results
        empty!(mock_results.table_calls)

        # Test with non-Tables-compatible object
        non_table = [1, 2, 3]
        @test_throws ArgumentError @wtable "invalid" non_table

        # Test with missing arguments - this should throw an ArgumentError
        @test_throws ArgumentError @wtable
        @test_throws ArgumentError @wtable "missing_data"
    end
end

@testset "WeaveLoggers.@wfile Macro Tests" begin
    @testset "Basic File Functionality" begin
        # Reset mock results
        empty!(mock_results.file_calls)

        # Create a temporary test file
        test_file = tempname()
        write(test_file, "test content")

        try
            # Test basic file logging with explicit name
            result = @wfile "test_file" test_file
            @test length(mock_results.file_calls) == 1

            file_call = mock_results.file_calls[1]
            @test file_call["name"] == "test_file"
            @test file_call["path"] == test_file
            @test isempty(file_call["tags"])

            # Test with tags
            empty!(mock_results.file_calls)
            result = @wfile "test_file_tags" test_file :config :test
            @test length(mock_results.file_calls) == 1

            file_call = mock_results.file_calls[1]
            @test file_call["name"] == "test_file_tags"
            @test file_call["tags"] == [:config, :test]
        finally
            rm(test_file, force=true)
        end
    end

    @testset "File Name Handling" begin
        # Reset mock results
        empty!(mock_results.file_calls)

        # Create a temporary test file
        test_file = tempname()
        write(test_file, "test content")

        try
            # Test without explicit name (should use basename)
            result = @wfile nothing test_file :test
            @test length(mock_results.file_calls) == 1

            file_call = mock_results.file_calls[1]
            @test file_call["name"] == basename(test_file)
            @test file_call["tags"] == [:test]

            # Test with just file path (should use basename)
            empty!(mock_results.file_calls)
            result = @wfile test_file :test
            @test length(mock_results.file_calls) == 1

            file_call = mock_results.file_calls[1]
            @test file_call["name"] == basename(test_file)
            @test file_call["tags"] == [:test]
        finally
            rm(test_file, force=true)
        end
    end

    @testset "File Error Handling" begin
        # Reset mock results
        empty!(mock_results.file_calls)

        # Test with non-existent file
        non_existent = tempname()
        @test_throws ArgumentError @wfile "error" non_existent

        # Test with missing arguments
        @test_throws ArgumentError @wfile
    end
end

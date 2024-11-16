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
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/sqrt"
        @test haskey(start_call, "started_at")
        @test haskey(start_call["inputs"], "args")
        @test haskey(start_call["inputs"], "types")
        @test haskey(start_call["inputs"], "code")
        @test start_call["inputs"]["args"] == [16]
        @test start_call["inputs"]["types"] == [Int]
        @test start_call["inputs"]["code"] == "sqrt(16)"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call contents
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "ended_at")
        @test end_call["outputs"]["result"] == 4.0
        @test end_call["outputs"]["type"] == Float64
        @test end_call["outputs"]["code"] == "sqrt(16)"
        @test haskey(end_call["attributes"], "expression")
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

        # Test with explicit operation name
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w "square_root" sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/square_root"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

        # Test with metadata tags
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w :math :basic sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/sqrt"
        @test start_call["attributes"]["tags"] == [:math, :basic]
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

        # Test with both operation name and tags
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @w "square_root" :math :basic sqrt(16)
        @test result == 4.0
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/square_root"
        @test start_call["attributes"]["tags"] == [:math, :basic]
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
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

        # Verify start_call contents
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/div"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call contents and error information
        @test haskey(end_call, "error")
        @test contains(end_call["error"], "DivideError")
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
    end

    @testset "API Error Handling" begin
        @testset "Authentication Errors" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Enable authentication error simulation
            TestUtils.MockAPI.set_auth_error(true)
            try
                # Test that API calls fail with authentication error
                @test_throws WeaveAPIError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["error_type"] == "AuthenticationError"
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test haskey(error_call["attributes"]["weave"], "source")
                @test haskey(error_call["attributes"]["weave"], "os")
                @test haskey(error_call["attributes"]["weave"], "arch")
                @test haskey(error_call["attributes"]["weave"], "julia_version")
            finally
                TestUtils.MockAPI.set_auth_error(false)
            end
        end

        @testset "Network Errors" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Enable network error simulation
            TestUtils.MockAPI.set_network_error(true)
            try
                # Test that API calls fail with network error
                @test_throws WeaveAPIError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["error_type"] == "NetworkError"
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test haskey(error_call["attributes"]["weave"], "source")
                @test haskey(error_call["attributes"]["weave"], "os")
                @test haskey(error_call["attributes"]["weave"], "arch")
                @test haskey(error_call["attributes"]["weave"], "julia_version")
            finally
                TestUtils.MockAPI.set_network_error(false)
            end
        end

        @testset "Rate Limit Errors" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Enable rate limit error simulation
            TestUtils.MockAPI.set_rate_limit_error(true)
            try
                # Test that API calls fail with rate limit error
                @test_throws WeaveAPIError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["error_type"] == "RateLimitError"
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test haskey(error_call["attributes"]["weave"], "source")
                @test haskey(error_call["attributes"]["weave"], "os")
                @test haskey(error_call["attributes"]["weave"], "arch")
                @test haskey(error_call["attributes"]["weave"], "julia_version")
            finally
                TestUtils.MockAPI.set_rate_limit_error(false)
            end
        end

        @testset "Invalid Payload Errors" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Enable invalid payload error simulation
            TestUtils.MockAPI.set_invalid_payload_error(true)
            try
                # Test that API calls fail with invalid payload error
                @test_throws WeaveAPIError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["error_type"] == "InvalidPayloadError"
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test haskey(error_call["attributes"]["weave"], "source")
                @test haskey(error_call["attributes"]["weave"], "os")
                @test haskey(error_call["attributes"]["weave"], "arch")
                @test haskey(error_call["attributes"]["weave"], "julia_version")
            finally
                TestUtils.MockAPI.set_invalid_payload_error(false)
            end
        end

        @testset "Metadata Errors" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Enable metadata error simulation
            TestUtils.MockAPI.set_metadata_error(true)
            try
                # Test that API calls fail with metadata error
                @test_throws WeaveAPIError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["error_type"] == "MetadataError"
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test haskey(error_call["attributes"]["weave"], "source")
                @test haskey(error_call["attributes"]["weave"], "os")
                @test haskey(error_call["attributes"]["weave"], "arch")
                @test haskey(error_call["attributes"]["weave"], "julia_version")
            finally
                TestUtils.MockAPI.set_metadata_error(false)
            end
        end
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

        # Verify start_call contents
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/sleep_test"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call contents
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

        # Parse timestamps and verify timing
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
            end_call = mock_results.end_calls[1]

            # Verify start_call contents
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/custom_type"
            @test start_call["inputs"]["types"] == [TestType]
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call contents
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
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

        # Verify start_call contents
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/nested"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify nested call is captured in expression
        @test contains(start_call["inputs"]["code"], "abs")
        @test contains(start_call["inputs"]["code"], "sqrt")

        # Verify end_call contents
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
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

            # Verify start_call contents
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/quick_op"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call contents
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

            # Get duration from attributes and verify timing
            duration_ns = end_call["attributes"]["duration_ns"]
            @test duration_ns > 0

            # Test long operation timing
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)

            # Use pre-defined large array for longer operation
            result = @w "long_op" sum(test_data.large_array)

            start_call = mock_results.start_calls[1]
            end_call = mock_results.end_calls[1]

            # Verify start_call contents for long operation
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/long_op"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call contents for long operation
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

            # Get duration from attributes and verify timing for long operation
            duration_ns = end_call["attributes"]["duration_ns"]
            @test duration_ns > 0
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
            start_call = mock_results.start_calls[1]
            end_call = mock_results.end_calls[1]

            # Verify start_call contents for empty input
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/string"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test very large inputs (using pre-defined large_string)
            result = @w "large_input" length(test_data.large_string)
            @test result == test_data.TEST_ARRAY_SIZE
            start_call = mock_results.start_calls[2]
            end_call = mock_results.end_calls[2]

            # Verify start_call contents for large input
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/large_input"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test unicode in strings
            unicode_str = "Hello, 世界! 🌍"
            result = @w "unicode" length(collect(unicode_str))
            @test result == 12
            start_call = mock_results.start_calls[3]
            end_call = mock_results.end_calls[3]

            # Verify start_call contents for unicode
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/unicode"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test special characters in operation names
            result = @w "special!@#\$%^&*" identity(42)
            start_call = mock_results.start_calls[4]
            end_call = mock_results.end_calls[4]

            # Verify start_call contents for special characters
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/special!@#\$%^&*"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify all end_calls have proper format
            for (i, end_call) in enumerate(mock_results.end_calls)
                start_call = mock_results.start_calls[i]
                @test end_call["id"] == start_call["id"]
                @test haskey(end_call, "project_id")
                @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
                @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
            end
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
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test basic DataFrame logging
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        result = @wtable "test_table" df
        @test length(mock_results.table_calls) == 1
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        # Verify table call
        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_table"
        @test table_call["data"] == df
        @test isempty(table_call["tags"])

        # Verify start_call format
        start_call = mock_results.start_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/test_table"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call format
        end_call = mock_results.end_calls[1]
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

        # Test with tags
        empty!(mock_results.table_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        result = @wtable "test_table_tags" df :tag1 :tag2
        @test length(mock_results.table_calls) == 1
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        # Verify table call with tags
        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_table_tags"
        @test table_call["tags"] == [:tag1, :tag2]

        # Verify start_call format with tags
        start_call = mock_results.start_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/test_table_tags"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call format with tags
        end_call = mock_results.end_calls[1]
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
    end

    @testset "Table Name Handling" begin
        # Reset mock results
        empty!(mock_results.table_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test with variable name when no string name provided
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        test_df = df
        result = @wtable test_df :data
        @test length(mock_results.table_calls) == 1
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        # Verify table call
        table_call = mock_results.table_calls[1]
        @test table_call["name"] == "test_df"
        @test table_call["tags"] == [:data]

        # Verify start_call format
        start_call = mock_results.start_calls[1]
        @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/test_df"
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"]["weave"], "source")
        @test haskey(start_call["attributes"]["weave"], "os")
        @test haskey(start_call["attributes"]["weave"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call format
        end_call = mock_results.end_calls[1]
        @test end_call["id"] == start_call["id"]
        @test haskey(end_call, "project_id")
        @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
    end

    @testset "Table Error Handling" begin
        # Reset mock results
        empty!(mock_results.table_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test with non-Tables-compatible object
        non_table = [1, 2, 3]
        @test_throws ArgumentError @wtable "invalid" non_table

        # Verify no calls were made before the error
        @test isempty(mock_results.table_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        # Test with valid table but invalid name to verify API format before error
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        @test_throws ArgumentError @wtable "" df

        # Verify that any successful calls before error maintain correct format
        @test length(mock_results.start_calls) == 1
        if !isempty(mock_results.start_calls)
            start_call = mock_results.start_calls[1]
            @test haskey(start_call, "op_name")
            @test startswith(start_call["op_name"], "weave:///anim-mina/slide-comprehension-plain-ocr/")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing
        end

        # Verify proper cleanup with end_call
        @test length(mock_results.end_calls) == 1
        if !isempty(mock_results.end_calls)
            end_call = mock_results.end_calls[1]
            @test haskey(end_call, "id")
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
        end

        # Test with missing arguments - this should throw an ArgumentError
        @test try
            eval(:(WeaveLoggers.@wtable))
            false
        catch e
            e isa LoadError && e.error isa ArgumentError
        end

        # Verify no calls were made
        @test isempty(mock_results.table_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        @test try
            eval(:(WeaveLoggers.@wtable "missing_data"))
            false
        catch e
            e isa LoadError && e.error isa ArgumentError
        end

        # Verify no calls were made
        @test isempty(mock_results.table_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)
    end

@testset "WeaveLoggers.@wfile Macro Tests" begin
    @testset "Basic File Functionality" begin
        # Reset mock results
        empty!(mock_results.file_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Create a temporary test file
        test_file = tempname()
        write(test_file, "test content")

        try
            # Test basic file logging with explicit name
            result = @wfile "test_file" test_file
            @test length(mock_results.file_calls) == 1
            @test length(mock_results.start_calls) == 1
            @test length(mock_results.end_calls) == 1

            # Verify file call
            file_call = mock_results.file_calls[1]
            @test file_call["name"] == "test_file"
            @test file_call["path"] == test_file
            @test isempty(file_call["tags"])

            # Verify start_call format
            start_call = mock_results.start_calls[1]
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/test_file"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call format
            end_call = mock_results.end_calls[1]
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

            # Test with tags
            empty!(mock_results.file_calls)
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)

            result = @wfile "test_file_tags" test_file :config :test
            @test length(mock_results.file_calls) == 1
            @test length(mock_results.start_calls) == 1
            @test length(mock_results.end_calls) == 1

            # Verify file call with tags
            file_call = mock_results.file_calls[1]
            @test file_call["name"] == "test_file_tags"
            @test file_call["path"] == test_file
            @test file_call["tags"] == [:config, :test]

            # Verify start_call format with tags
            start_call = mock_results.start_calls[1]
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/test_file_tags"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call format with tags
            end_call = mock_results.end_calls[1]
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
        finally
            rm(test_file, force=true)
        end
    end

    @testset "File Name Handling" begin
        # Reset mock results
        empty!(mock_results.file_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Create a temporary test file
        test_file = tempname()
        write(test_file, "test content")

        try
            # Test without explicit name (should use basename)
            result = @wfile nothing test_file :test
            @test length(mock_results.file_calls) == 1
            @test length(mock_results.start_calls) == 1
            @test length(mock_results.end_calls) == 1

            # Verify file call
            file_call = mock_results.file_calls[1]
            @test file_call["name"] == basename(test_file)
            @test file_call["tags"] == [:test]

            # Verify start_call format
            start_call = mock_results.start_calls[1]
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/$(basename(test_file))"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call format
            end_call = mock_results.end_calls[1]
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing

            # Test with just file path (should use basename)
            empty!(mock_results.file_calls)
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)

            result = @wfile test_file :test
            @test length(mock_results.file_calls) == 1
            @test length(mock_results.start_calls) == 1
            @test length(mock_results.end_calls) == 1

            # Verify file call
            file_call = mock_results.file_calls[1]
            @test file_call["name"] == basename(test_file)
            @test file_call["tags"] == [:test]

            # Verify start_call format
            start_call = mock_results.start_calls[1]
            @test start_call["op_name"] == "weave:///anim-mina/slide-comprehension-plain-ocr/$(basename(test_file))"
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"]["weave"], "source")
            @test haskey(start_call["attributes"]["weave"], "os")
            @test haskey(start_call["attributes"]["weave"], "arch")
            @test haskey(start_call["attributes"]["weave"], "julia_version")
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Verify end_call format
            end_call = mock_results.end_calls[1]
            @test end_call["id"] == start_call["id"]
            @test haskey(end_call, "project_id")
            @test end_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
        finally
            rm(test_file, force=true)
        end
    end

    @testset "File Error Handling" begin
        # Reset mock results
        empty!(mock_results.file_calls)
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test with non-existent file
        non_existent = tempname()
        @test_throws ArgumentError @wfile "error" non_existent

        # Verify no API calls were made
        @test isempty(mock_results.file_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        # Test with missing arguments
        @test try
            eval(:(WeaveLoggers.@wfile))
            false
        catch e
            e isa LoadError && e.error isa ArgumentError
        end

        # Verify no API calls were made
        @test isempty(mock_results.file_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)
    end

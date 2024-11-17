using Test
using WeaveLoggers
using Dates
using Statistics
using UUIDs
using SHA
using .TestUtils  # Use TestUtils module that was included in runtests.jl

# Create local versions of the API functions that delegate to our mocks
const start_call = TestUtils.MockAPI.start_call
const end_call = TestUtils.MockAPI.end_call

# Helper function to generate expected op_name format
function expected_op_name(name::String)
    hash_value = bytes2hex(sha256(name)[1:4])
    "weave:///anim-mina/slide-comprehension-plain-ocr/op/$name:$hash_value"
end

# Helper function to verify op_name format
function verify_op_name(op_name::String, base_name::String)
    expected = expected_op_name(base_name)
    @test op_name == expected
end

@testset "WeaveLoggers.@w Macro Tests" begin

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
        verify_op_name(start_call["op_name"], "sqrt")
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
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "square_root")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "sqrt")
        @test start_call["attributes"]["tags"] == [:math, :basic]
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"], "source")
        @test haskey(start_call["attributes"], "os")
        @test haskey(start_call["attributes"], "arch")
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
        verify_op_name(start_call["op_name"], "square_root")
        @test start_call["attributes"]["tags"] == [:math, :basic]
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"], "source")
        @test haskey(start_call["attributes"], "os")
        @test haskey(start_call["attributes"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", end_call["ended_at"]) !== nothing
    end

    @testset "Error Handling" begin
        # Reset mock results
        empty!(mock_results.start_calls)
        empty!(mock_results.end_calls)

        # Test error capture and propagation
        @test_throws HTTP.StatusError @w div(1, 0)
        @test length(mock_results.start_calls) == 1
        @test length(mock_results.end_calls) == 1

        start_call = mock_results.start_calls[1]
        end_call = mock_results.end_calls[1]

        # Verify start_call contents
        verify_op_name(start_call["op_name"], "div")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test haskey(start_call["attributes"], "source")
        @test haskey(start_call["attributes"], "os")
        @test haskey(start_call["attributes"], "arch")
        @test haskey(start_call["attributes"]["weave"], "julia_version")
        @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

        # Verify end_call contents and error information
        @test haskey(end_call, "detail")
        @test haskey(end_call, "status_code")
        @test end_call["status_code"] == 500
        @test contains(end_call["detail"], "DivideError")
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
                @test_throws HTTP.StatusError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 401
                @test contains(error_call["detail"], "Authentication failed")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])  # Verify OS string is not empty
                @test !isempty(error_call["attributes"]["arch"])  # Verify architecture string is not empty
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
                @test_throws HTTP.StatusError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 503
                @test contains(error_call["detail"], "Network error")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])  # Verify OS string is not empty
                @test !isempty(error_call["attributes"]["arch"])  # Verify architecture string is not empty
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
                @test_throws HTTP.StatusError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 429
                @test contains(error_call["detail"], "Rate limit exceeded")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])  # Verify OS string is not empty
                @test !isempty(error_call["attributes"]["arch"])  # Verify architecture string is not empty
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
                @test_throws HTTP.StatusError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 400
                @test contains(error_call["detail"], "Invalid payload")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])  # Verify OS string is not empty
                @test !isempty(error_call["attributes"]["arch"])  # Verify architecture string is not empty
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
            finally
                TestUtils.MockAPI.set_invalid_payload_error(false)
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
                @test_throws HTTP.StatusError @w sqrt(16)

                # Verify no successful API calls were made
                @test isempty(mock_results.start_calls)
                @test isempty(mock_results.end_calls)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 400
                @test contains(error_call["detail"], "Invalid metadata")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])  # Verify OS string is not empty
                @test !isempty(error_call["attributes"]["arch"])  # Verify architecture string is not empty
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
            finally
                TestUtils.MockAPI.set_metadata_error(false)
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
        verify_op_name(start_call["op_name"], "sleep_test")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            verify_op_name(start_call["op_name"], "custom_type")
            @test start_call["inputs"]["types"] == [TestType]
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "nested")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            verify_op_name(start_call["op_name"], "quick_op")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            verify_op_name(start_call["op_name"], "long_op")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            verify_op_name(start_call["op_name"], "string")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test very large inputs (using pre-defined large_string)
            result = @w "large_input" length(test_data.large_string)
            @test result == test_data.TEST_ARRAY_SIZE
            start_call = mock_results.start_calls[2]
            end_call = mock_results.end_calls[2]

            # Verify start_call contents for large input
            verify_op_name(start_call["op_name"], "large_input")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test unicode in strings
            unicode_str = "Hello, 世界! 🌍"
            result = @w "unicode" length(collect(unicode_str))
            @test result == 12
            start_call = mock_results.start_calls[3]
            end_call = mock_results.end_calls[3]

            # Verify start_call contents for unicode
            verify_op_name(start_call["op_name"], "unicode")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
            @test match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", start_call["started_at"]) !== nothing

            # Test special characters in operation names
            result = @w "special!@#\$%^&*" identity(42)
            start_call = mock_results.start_calls[4]
            end_call = mock_results.end_calls[4]

            # Verify start_call contents for special characters
            verify_op_name(start_call["op_name"], "special!@#\$%^&*")
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "test_table")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "test_table_tags")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        verify_op_name(start_call["op_name"], "test_df")
        @test haskey(start_call, "project_id")
        @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
        @test haskey(start_call, "attributes")
        @test haskey(start_call["attributes"], "weave")
        @test haskey(start_call["attributes"]["weave"], "client_version")
        @test start_call["attributes"]["source"] == "julia-client"
        @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
        @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
        @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        @test_throws HTTP.StatusError @wtable "invalid" non_table

        # Verify no calls were made before the error
        @test isempty(mock_results.table_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        # Test with valid table but invalid name to verify API format before error
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        @test_throws HTTP.StatusError @wtable "" df

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
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])
            @test !isempty(start_call["attributes"]["arch"])
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))
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

        # Test with missing arguments - this should throw an HTTP.StatusError
        @test try
            eval(:(WeaveLoggers.@wtable))
            false
        catch e
            e isa LoadError && e.error isa HTTP.StatusError
        end

        # Verify no calls were made
        @test isempty(mock_results.table_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        @test try
            eval(:(WeaveLoggers.@wtable "missing_data"))
            false
        catch e
            e isa LoadError && e.error isa HTTP.StatusError
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
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
            verify_op_name(start_call["op_name"], basename(test_file))
            @test haskey(start_call, "project_id")
            @test start_call["project_id"] == "anim-mina/slide-comprehension-plain-ocr"
            @test haskey(start_call, "attributes")
            @test haskey(start_call["attributes"], "weave")
            @test haskey(start_call["attributes"]["weave"], "client_version")
            @test haskey(start_call["attributes"], "source")
            @test haskey(start_call["attributes"], "os")
            @test haskey(start_call["attributes"], "arch")
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
            @test start_call["attributes"]["source"] == "julia-client"
            @test !isempty(start_call["attributes"]["os"])  # Verify OS string is not empty
            @test !isempty(start_call["attributes"]["arch"])  # Verify architecture string is not empty
            @test occursin("julia", lowercase(start_call["attributes"]["weave"]["julia_version"]))  # Verify Julia version string
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
        @test_throws HTTP.StatusError @wfile "error" non_existent

        # Verify no API calls were made
        @test isempty(mock_results.file_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)

        # Test with missing arguments
        @test try
            eval(:(WeaveLoggers.@wfile))
            false
        catch e
            e isa LoadError && e.error isa HTTP.StatusError
        end

        # Verify no API calls were made
        @test isempty(mock_results.file_calls)
        @test isempty(mock_results.start_calls)
        @test isempty(mock_results.end_calls)
    end

    @testset "API Operations" begin
        @testset "update_call Error Propagation" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Create a call first to get a valid ID
            result = @w sqrt(16)
            @test result == 4.0
            @test length(mock_results.start_calls) == 1
            call_id = mock_results.start_calls[1]["id"]

            # Enable error simulation for update operation
            TestUtils.MockAPI.set_update_error(true)
            try
                # Test that update call fails with appropriate error
                @test_throws HTTP.StatusError WeaveLoggers.Calls.update_call(
                    call_id,
                    Dict("test" => "value")
                )

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 400
                @test contains(error_call["detail"], "Update failed")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])
                @test !isempty(error_call["attributes"]["arch"])
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))
            finally
                TestUtils.MockAPI.set_update_error(false)
            end
        end

        @testset "delete_call Error Handling" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Create a call first to get a valid ID
            result = @w sqrt(16)
            @test result == 4.0
            @test length(mock_results.start_calls) == 1
            call_id = mock_results.start_calls[1]["id"]

            # Enable error simulation for delete operation
            TestUtils.MockAPI.set_delete_error(true)
            try
                # Test that delete call fails with appropriate error
                @test_throws HTTP.StatusError WeaveLoggers.Calls.delete_call(call_id)

                # Verify error was recorded with metadata
                @test length(mock_results.error_calls) == 1
                error_call = mock_results.error_calls[1]
                @test error_call["status_code"] == 400
                @test contains(error_call["detail"], "Delete failed")
                @test haskey(error_call, "attributes")
                @test haskey(error_call["attributes"], "weave")
                @test haskey(error_call["attributes"]["weave"], "client_version")
                @test error_call["attributes"]["source"] == "julia-client"
                @test !isempty(error_call["attributes"]["os"])
                @test !isempty(error_call["attributes"]["arch"])
                @test occursin("julia", lowercase(error_call["attributes"]["weave"]["julia_version"]))
            finally
                TestUtils.MockAPI.set_delete_error(false)
            end
        end

        @testset "read_call Query Parameters" begin
            # Reset mock results
            empty!(mock_results.start_calls)
            empty!(mock_results.end_calls)
            empty!(mock_results.error_calls)

            # Create a call first to get a valid ID
            result = @w sqrt(16)
            @test result == 4.0
            @test length(mock_results.start_calls) == 1
            call_id = mock_results.start_calls[1]["id"]

            # Test read call with query parameters
            try
                response = WeaveLoggers.Calls.read_call(
                    call_id,
                    Dict("include_metadata" => true)
                )

                # Verify response format
                @test haskey(response, "id")
                @test response["id"] == call_id
                @test haskey(response, "attributes")
                @test haskey(response["attributes"], "weave")
                @test haskey(response["attributes"]["weave"], "client_version")
                @test response["attributes"]["source"] == "julia-client"
                @test !isempty(response["attributes"]["os"])
                @test !isempty(response["attributes"]["arch"])
                @test occursin("julia", lowercase(response["attributes"]["weave"]["julia_version"]))
            catch e
                if e isa HTTP.StatusError
                    # Verify error contains proper metadata
                    error_data = JSON.parse(String(e.response.body))
                    @test haskey(error_data, "attributes")
                    @test haskey(error_data["attributes"], "weave")
                    @test haskey(error_data["attributes"]["weave"], "client_version")
                    @test error_data["attributes"]["source"] == "julia-client"
                    @test !isempty(error_data["attributes"]["os"])
                    @test !isempty(error_data["attributes"]["arch"])
                    rethrow(e)
                else
                    rethrow(e)
                end
            end
        end
    end
end

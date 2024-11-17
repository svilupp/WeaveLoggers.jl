using WeaveLoggers
using HTTP
using JSON3
using Dates
using UUIDs
using Base64

const PROJECT_ID = "anim-mina/slide-comprehension-plain-ocr"
const BASE_URL = "https://trace.wandb.ai"

# Enable debug logging
ENV["WEAVE_DEBUG_HTTP"] = "1"

function format_iso8601_with_ms(dt::DateTime)
    return Dates.format(dt, "yyyy-mm-ddTHH:MM:SS.sss") * "Z"
end

function print_request_details(url, headers, body)
    println("\nRequest Details:")
    println("URL: ", url)
    println("Headers:")
    for (key, value) in headers
        println("  $key: $value")
    end
    println("Body: ", JSON3.write(body))
end

function print_response_details(response)
    println("\nResponse Details:")
    println("Status: ", response.status)
    println("Headers:")
    for (key, value) in response.headers
        println("  $key: $value")
    end
    println("Body: ", String(response.body))
end

# Test a single operation flow with direct API calls
function test_direct_api_calls()
    println("\n=== Testing Direct API Calls ===")

    # Generate unique identifiers
    call_id = string(uuid4())
    trace_id = string(uuid4())
    started_at = format_iso8601_with_ms(now(UTC))

    # Prepare start call payload (matching SDK format exactly)
    start_payload = Dict{String,Any}(
        "start" => Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id,
            "op_name" => "weave:///anim-mina/slide-comprehension-plain-ocr/op/mock_function:lIlp5XoYMPTx5moqhS3toSOIZHi75sTFtprEBHG6SVA",
            "display_name" => "mock_function",
            "trace_id" => trace_id,
            "parent_id" => nothing,
            "started_at" => started_at,
            "attributes" => Dict(
                "weave" => Dict(
                    "client_version" => "0.1.0",
                    "source" => "julia-client",
                    "os" => string(Sys.KERNEL),
                    "arch" => string(Sys.ARCH),
                    "julia_version" => string(VERSION)
                )
            ),
            "inputs" => Dict("test_input" => "test_value"),
            "wb_user_id" => nothing,
            "wb_run_id" => nothing
        )
    )

    # Prepare headers and auth
    headers = [
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Basic " * base64encode("api:$(ENV["WANDB_API_KEY"])")
    ]

    # Make start call
    println("\n=== Testing call/start endpoint ===")
    start_url = "$BASE_URL/call/start"
    print_request_details(start_url, headers, start_payload)

    start_response = HTTP.post(
        start_url,
        headers,
        JSON3.write(start_payload);
        status_exception=false
    )
    print_response_details(start_response)
    @assert start_response.status == 200 "Start call failed"

    # Sleep to simulate work
    sleep(0.1)

    # Prepare end call payload
    end_payload = Dict{String,Any}(
        "end" => Dict{String,Any}(
            "id" => call_id,
            "project_id" => PROJECT_ID,
            "trace_id" => trace_id,
            "started_at" => started_at,
            "ended_at" => format_iso8601_with_ms(now(UTC)),
            "attributes" => Dict(
                "weave" => Dict(
                    "client_version" => "0.1.0",
                    "source" => "julia-client",
                    "os" => string(Sys.KERNEL),
                    "arch" => string(Sys.ARCH),
                    "julia_version" => string(VERSION)
                )
            ),
            "outputs" => Dict("result" => "test_output"),
            "summary" => Dict(
                "input_type" => "function_input",
                "output_type" => "function_output",
                "result" => Dict("test_output" => "value"),
                "status" => "success",
                "duration" => nothing
            )
        )
    )

    # Make end call
    println("\n=== Testing call/end endpoint ===")
    end_url = "$BASE_URL/call/end"
    print_request_details(end_url, headers, end_payload)

    end_response = HTTP.post(
        end_url,
        headers,
        JSON3.write(end_payload);
        status_exception=false
    )
    print_response_details(end_response)
    @assert end_response.status == 200 "End call failed"
end

# Run verification with error handling
println("\nStarting API verification...")
try
    test_direct_api_calls()
    println("\nAPI verification completed successfully!")
catch e
    println("\nError during API verification: ", e)
    rethrow(e)
end

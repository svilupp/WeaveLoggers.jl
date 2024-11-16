using WeaveLoggers
using Test
using Dates
using UUIDs
using HTTP
using JSON3

# Enable debug logging
ENV["WEAVE_DEBUG_HTTP"] = "1"

const PROJECT_ID = "anim-mina/slide-comprehension-plain-ocr"
const BASE_URL = "https://trace.wandb.ai"

function print_response_details(response)
    println("\nResponse Details:")
    println("Status: ", response.status)
    println("Headers:")
    for (key, value) in response.headers
        println("  $key: $value")
    end
    println("Body: ", String(response.body))
end

function test_direct_api_calls()
    println("\n=== Testing Direct API Calls ===")

    # Generate unique identifiers
    call_id = string(uuid4())
    trace_id = string(uuid4())
    started_at = Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")

    # Prepare start call payload (matching SDK format exactly)
    start_payload = Dict{String,Any}(
        "project_id" => PROJECT_ID,
        "id" => call_id,
        "op_name" => "weave:///$PROJECT_ID/test_operation",
        "display_name" => "test_operation",
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

    # Make start call
    println("\n=== Testing call/start endpoint ===")
    headers = [
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]
    auth = ("api", ENV["WANDB_API_KEY"])  # Use environment variable directly

    start_response = HTTP.post(
        "$BASE_URL/call/start",
        headers,
        JSON3.write(start_payload);
        basic_auth=auth,
        status_exception=false
    )
    print_response_details(start_response)
    @test start_response.status == 200

    # Sleep to simulate work
    sleep(0.1)

    # Prepare end call payload
    end_payload = Dict{String,Any}(
        "id" => call_id,
        "project_id" => PROJECT_ID,
        "trace_id" => trace_id,
        "started_at" => started_at,
        "ended_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
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

    # Make end call
    println("\n=== Testing call/end endpoint ===")
    end_response = HTTP.post(
        "$BASE_URL/call/end",
        headers,
        JSON3.write(end_payload);
        basic_auth=auth,
        status_exception=false
    )
    print_response_details(end_response)
    @test end_response.status == 200
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

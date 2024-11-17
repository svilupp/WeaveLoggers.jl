using HTTP
using JSON3
using SHA
using Dates
using UUIDs
using Base64

# Import specific HTTP utilities
import HTTP: request, StatusError, Response

# Configuration
const WEAVE_API_BASE_URL = "https://trace.wandb.ai"
const entity = "anim-mina"
const project = "slide-comprehension-plain-ocr"
const api_key = get(ENV, "WANDB_API_KEY", nothing)

# Verify API key
if isnothing(api_key)
    error("WANDB_API_KEY environment variable is not set")
end
println("API Key (first 4 chars): ", api_key[1:4], "...")

# Enable HTTP debugging
ENV["JULIA_DEBUG"] = "HTTP"

# Helper function to make API calls
function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing)
    # Prepare URL and headers
    url = WEAVE_API_BASE_URL * endpoint

    # Create authorization header
    auth_string = base64encode("api:$api_key")
    headers = HTTP.Headers([
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Basic $auth_string"
    ])

    # Print request details
    println("\n=== REQUEST ===")
    println("Method: ", method)
    println("URL: ", url)
    println("Headers: ", headers)
    println("Auth: Basic api:$(api_key[1:4])...")
    println("Body: ", isnothing(body) ? "None" : JSON3.write(body))

    # Make the request
    response = if isnothing(body)
        HTTP.request(method, url, headers; status_exception=false)
    else
        HTTP.request(method, url, headers, JSON3.write(body); status_exception=false)
    end

    # Print response details
    println("\n=== RESPONSE ===")
    println("Status: ", response.status)
    println("Headers: ", response.headers)
    println("Body: ", String(response.body))

    return response
end

# Generate a unique call ID
call_id = string(uuid4())

# Create the start call payload
function_name = "test_function"
hash = bytes2hex(sha256(function_name)[1:4])
op_name = "weave:///$entity/$project/op/$function_name:$hash"

start_payload = Dict(
    "start" => Dict(
        "project_id" => "$entity/$project",
        "id" => call_id,
        "op_name" => op_name,
        "display_name" => nothing,
        "trace_id" => string(uuid4()),
        "parent_id" => nothing,
        "started_at" => replace(string(now(UTC)), r"\+00:00$" => "Z"),
        "attributes" => Dict(
            "weave" => Dict(
                "client_version" => "0.51.19",
                "source" => "julia-sdk",
                "os_name" => get(ENV, "OS", "Linux"),
                "os_version" => readchomp(`uname -v`),
                "os_release" => readchomp(`uname -r`),
                "sys_version" => string(VERSION)
            )
        ),
        "inputs" => Dict(
            "prompt" => "Hello, World!",
            "temperature" => 0.7
        ),
        "wb_user_id" => nothing,
        "wb_run_id" => "test-run-$(round(Int, time()))"
    )
)

# Make the start call
println("\nStarting call...")
start_response = weave_api("POST", "/call/start", start_payload)

if start_response.status == 200
    println("\nCall started successfully!")

    # Create the end call payload
    end_payload = Dict(
        "end" => Dict(
            "project_id" => "$entity/$project",
            "id" => call_id,
            "ended_at" => replace(string(now(UTC)), r"\+00:00$" => "Z"),
            "outputs" => Dict(
                "response" => "Test response",
                "tokens" => 10,
                "finish_reason" => "complete"
            ),
            "exception" => nothing,
            "summary" => Dict()
        )
    )

    # Make the end call
    println("\nEnding call...")
    end_response = weave_api("POST", "/call/$call_id/end", end_payload)

    if end_response.status == 200
        println("\nCall ended successfully!")

        # Read the call data
        println("\nReading call data...")
        read_response = weave_api("GET", "/call/read?id=$call_id", nothing)

        if read_response.status == 200
            println("\nCall data retrieved successfully!")
        else
            println("\nFailed to read call data!")
        end
    else
        println("\nFailed to end call!")
    end
else
    println("\nFailed to start call!")
end

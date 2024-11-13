using HTTP
using JSON3
using Base64
using UUIDs
using Dates

# Get the W&B API key from environment
api_key = ENV["WANDB_API_KEY"]

# Base URL for trace API
url = "https://trace.wandb.ai/call/start"

# Generate unique IDs
call_id = string(uuid4())
trace_id = string(uuid4())

# Format timestamp correctly using UTC time
dt = now(UTC)
timestamp = string(
    lpad(year(dt), 4, '0'), '-',
    lpad(month(dt), 2, '0'), '-',
    lpad(day(dt), 2, '0'), 'T',
    lpad(hour(dt), 2, '0'), ':',
    lpad(minute(dt), 2, '0'), ':',
    lpad(second(dt), 2, '0'), '.',
    lpad(millisecond(dt), 3, '0'), 'Z'
)

# Create authorization header with explicit Base64 encoding
auth_string = base64encode("api:$api_key")
headers = [
    "Content-Type" => "application/json",
    "Authorization" => "Basic $auth_string"
]

# Prepare the request body
body = Dict(
    "start" => Dict{String,Any}(
        "project_id" => "svilupp/weave-loggers",  # Changed project ID format
        "id" => call_id,
        "op_name" => "test_connection",
        "display_name" => "API Test",
        "trace_id" => trace_id,
        "parent_id" => nothing,  # Changed from empty string to null
        "started_at" => timestamp,
        "attributes" => Dict{String,Any}(),  # Explicitly typed
        "inputs" => Dict{String,Any}(
            "message" => "Test connection",
            "metadata" => Dict{String,Any}(
                "version" => "1.0.0",
                "environment" => "test"
            )
        )
    )
)

println("Request URL: ", url)
println("Request Headers: ", headers)
println("Request Body: ", JSON3.write(body))

try
    # Send the request with explicit authorization header
    response = HTTP.post(
        url,
        headers,
        JSON3.write(body);
        verbose=1
    )

    # Check the response status and print the result
    if response.status == 200
        data = JSON3.read(String(response.body))
        println("Success! Response status: $(response.status)")
        println("Response data:")
        println(data)
    else
        println("Request failed with status code $(response.status)")
        println(String(response.body))
    end
catch e
    println("Error making request:")
    println(e)
    if e isa HTTP.Exceptions.StatusError
        println("\nResponse Headers:")
        for (k, v) in e.response.headers
            println("$k: $v")
        end
        println("\nResponse Body:")
        println(String(e.response.body))
    end
end

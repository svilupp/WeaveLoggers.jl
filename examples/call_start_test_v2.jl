using HTTP
using JSON3
using Base64
using UUIDs
using Dates

# Get the W&B API key from environment
api_key = ENV["WANDB_API_KEY"]

# Base URL for W&B API - using the same base URL as the working GraphQL example
url_base = "https://api.wandb.ai"

# Call start endpoint
endpoint = "/weave/api/call/start"  # Try the weave API path

# Generate unique IDs
call_id = string(uuid4())
trace_id = string(uuid4())

# Headers for the request - exactly matching the Python example
headers = [
    "Content-Type" => "application/json"
]

# Prepare the request body
body = Dict(
    "start" => Dict{String,Any}(
        "project_id" => "anim-mina/test-project",
        "id" => call_id,
        "op_name" => "test_connection",
        "display_name" => "API Test",
        "trace_id" => trace_id,
        "parent_id" => "",
        "started_at" => Dates.format(Dates.now(Dates.UTC), "yyyy-MM-ddTHH:mm:ss.000Z"),
        "attributes" => Dict(),
        "inputs" => Dict("test" => true)
    )
)

try
    # Send the request with Basic authentication - matching Python requests.auth.HTTPBasicAuth
    response = HTTP.post(
        url_base * endpoint,
        headers,
        JSON3.write(body);
        basic_auth=("api", api_key),
        verbose=1  # Add verbose output for debugging
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
    end
end

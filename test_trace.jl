using HTTP
using JSON3
using Base64
using UUIDs
using Dates

# Get the W&B API key from environment
api_key = ENV["WANDB_API_KEY"]

# Base URL for W&B API
url_base = "https://api.wandb.ai"

# Endpoint for GraphQL
endpoint = "/graphql"

# Generate unique IDs
trace_id = string(uuid4())

# GraphQL mutation for creating a trace
mutation = """
mutation CreateTrace {
  createTrace(input: {
    projectName: "test-project",
    entityName: "anim-mina",
    traceId: "$(trace_id)",
    operationName: "test_connection"
  }) {
    trace {
      id
      traceId
    }
  }
}
"""

# Headers for the request
headers = [
    "Content-Type" => "application/json"
]

try
    # Send the request with Basic authentication
    response = HTTP.post(
        url_base * endpoint,
        headers,
        JSON3.write(Dict("query" => mutation));
        basic_auth=("api", api_key)
    )

    # Check the response status and print the result
    if response.status == 200
        data = JSON3.read(String(response.body))
        println("Success! Response data:")
        println(data)
    else
        println("Request failed with status code $(response.status)")
        println(String(response.body))
    end
catch e
    println("Error making request:")
    println(e)
end

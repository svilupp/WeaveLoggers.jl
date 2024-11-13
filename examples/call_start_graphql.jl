using HTTP
using JSON3
using Base64
using UUIDs
using Dates

# Get the W&B API key from environment
api_key = ENV["WANDB_API_KEY"]

# Base URL for W&B API
url_base = "https://api.wandb.ai"
endpoint = "/graphql"

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

# GraphQL mutation for starting a call
mutation = """
mutation StartCall {
  startCall(input: {
    projectId: "anim-mina/test-project",
    callId: "$(call_id)",
    traceId: "$(trace_id)",
    operationName: "test_connection",
    displayName: "API Test",
    startedAt: "$(timestamp)",
    parentId: "",
    attributes: {},
    inputs: {
      test: true
    }
  }) {
    call {
      id
      traceId
      status
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
        basic_auth=("api", api_key),
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

using HTTP
using JSON3
using Base64

# Replace with your actual W&B API key
api_key = ENV["WANDB_API_KEY"]

# Base URL for W&B API
url_base = "https://api.wandb.ai"

# Endpoint for server information
endpoint = "/graphql"

# GraphQL query for server information
query = """
query ServerInfo {
    serverInfo {
        frontendHost
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
        JSON3.write(Dict("query" => query));
        basic_auth=("api", api_key)  # Using HTTP.jl's built-in basic auth
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

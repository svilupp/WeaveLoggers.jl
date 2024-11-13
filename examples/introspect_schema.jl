using HTTP
using JSON3
using Base64

# Get the W&B API key from environment
api_key = ENV["WANDB_API_KEY"]

# Base URL for W&B API
url_base = "https://api.wandb.ai"
endpoint = "/graphql"

# GraphQL introspection query to find mutations
query = """
query IntrospectionQuery {
  __schema {
    types {
      name
      fields {
        name
        description
      }
    }
    mutationType {
      name
      fields {
        name
        description
        args {
          name
          type {
            name
          }
        }
      }
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
        JSON3.write(Dict("query" => query));
        basic_auth=("api", api_key),
        verbose=1
    )

    # Check the response status and print the result
    if response.status == 200
        data = JSON3.read(String(response.body))
        println("Success! Response status: $(response.status)")
        println("\nAvailable Mutations:")
        if haskey(data, "data") && haskey(data["data"], "__schema") &&
           haskey(data["data"]["__schema"], "mutationType") &&
           !isnothing(data["data"]["__schema"]["mutationType"])
            mutations = data["data"]["__schema"]["mutationType"]["fields"]
            for mutation in mutations
                println("\nName: ", mutation["name"])
                println("Description: ", get(mutation, "description", "No description"))
                println("Arguments:")
                for arg in get(mutation, "args", [])
                    println("  - ", arg["name"], ": ", get(get(arg, "type", Dict()), "name", "Unknown"))
                end
            end
        else
            println("No mutation type found in schema")
        end
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

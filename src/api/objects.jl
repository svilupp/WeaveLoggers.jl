"""
WeaveLoggers Object API Functions

This module provides functions for interacting with the Weights & Biases Weave Object API.
All functions use the shared weave_api interface for making requests.

# Object Types
Common object types include:
- "model": Machine learning models
- "dataset": Training or evaluation datasets
- "experiment": Experimental configurations
- "artifact": Data files or model checkpoints
- "run": Training or evaluation runs

# Object Operations
1. create_object - Creates a new object with type and attributes
2. read_object - Retrieves object information and metadata

For more information, see: https://weave-docs.wandb.ai/reference/service-api
"""
module Objects

using ..WeaveLoggers: weave_api, PROJECT_ID
using UUIDs

export create_object, read_object

"""
    create_object(type::String; attributes::Dict=Dict())

Create a new object in the Weave service.

# Arguments
- `type::String`: Type of object to create. Common types include:
  - "model": For machine learning models
  - "dataset": For training or evaluation datasets
  - "experiment": For experimental configurations
  - "artifact": For data files or model checkpoints
  - "run": For training or evaluation runs
- `attributes::Dict`: Object attributes and metadata (optional). Common attributes:
  - "name": Display name of the object
  - "version": Version identifier
  - "description": Detailed description
  - "tags": Array of string tags
  - "metadata": Additional metadata as key-value pairs

# Returns
- `String`: The ID of the created object

# Response Structure
The API returns an object with:
- `id`: Unique identifier of the created object
- `type`: Object type as specified
- `project_id`: Project identifier
- `attributes`: Object attributes as provided
- `created_at`: Timestamp of creation

# Example
```julia
# Create a model object
model_id = create_object("model",
    attributes=Dict(
        "name" => "gpt-3",
        "version" => "1.0",
        "description" => "Language model",
        "tags" => ["nlp", "transformer"],
        "metadata" => Dict(
            "architecture" => "transformer",
            "parameters" => "175B"
        )
    )
)

# Create a dataset object
dataset_id = create_object("dataset",
    attributes=Dict(
        "name" => "training-data",
        "version" => "2.0",
        "description" => "Training dataset",
        "size" => "1GB",
        "records" => 1000000
    )
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/object-create-object-create-post
"""
function create_object(type::String; attributes::Dict=Dict())
    object_id = string(uuid4())

    body = Dict{String,Any}(
        "type" => type,
        "id" => object_id,
        "project_id" => PROJECT_ID,
        "attributes" => attributes
    )

    weave_api("POST", "/object/create", body)
    return object_id
end

"""
    read_object(object_id::String)

Read details of an object from the Weave service.

# Arguments
- `object_id::String`: ID of the object to read

# Returns
- `Dict`: Object details including:
  - `id`: Object's unique identifier
  - `type`: Object type (e.g., "model", "dataset")
  - `project_id`: Project identifier
  - `attributes`: Object attributes and metadata
  - `created_at`: Object creation timestamp
  - `updated_at`: Last update timestamp

# Response Structure
The API response includes:
```julia
Dict(
    "id" => "uuid",
    "type" => "model",
    "project_id" => "project/name",
    "attributes" => Dict(...),
    "created_at" => "2024-01-01T00:00:00.000Z",
    "updated_at" => "2024-01-01T00:00:00.000Z"
)
```

# Example
```julia
# Read object details
object_details = read_object(object_id)
println("Object type: ", object_details["type"])
println("Object name: ", get(object_details["attributes"], "name", "unnamed"))
println("Created at: ", object_details["created_at"])
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/object-read-object-read-get
"""
function read_object(object_id::String)
    weave_api("GET", "/object/read", nothing; query_params=Dict("id" => object_id))
end

end # module Objects

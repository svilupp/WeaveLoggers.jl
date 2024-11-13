"""
WeaveLoggers File API Functions

This module provides functions for interacting with the Weights & Biases Weave File API.
All functions use the shared weave_api interface for making requests.

# Supported File Types
- Text files (.txt, .log, .json, etc.)
- Binary files (.bin, .dat, etc.)
- Image files (.png, .jpg, .gif, etc.)
- Model files (.pt, .h5, .onnx, etc.)
- Archive files (.zip, .tar.gz, etc.)
- Any other file type up to 5GB in size

# File Operations
1. create_file - Creates a new file with content and metadata
2. get_file_content - Retrieves file content and attributes

For more information, see: https://weave-docs.wandb.ai/reference/service-api
"""
module Files

using ..WeaveLoggers: weave_api, PROJECT_ID
using UUIDs
using Base64

export create_file, get_file_content

"""
    create_file(name::String, content::Vector{UInt8}; description::String="", metadata::Dict=Dict())

Create a new file in the Weave service.

# Arguments
- `name::String`: Name of the file (including extension)
- `content::Vector{UInt8}`: Binary content of the file (max size 5GB)
- `description::String`: Optional description of the file
- `metadata::Dict`: Optional metadata about the file, such as:
  - `type`: File type or MIME type
  - `size`: File size in bytes
  - `created_by`: Creator information
  - `tags`: Array of string tags
  - `version`: Version identifier
  - `custom_attributes`: Any custom key-value pairs

# Returns
- `String`: The ID of the created file

# Response Structure
The API returns:
```julia
Dict(
    "id" => "file_uuid",
    "name" => "filename.ext",
    "project_id" => "project/name",
    "description" => "file description",
    "metadata" => Dict(...),
    "created_at" => "2024-01-01T00:00:00.000Z",
    "size" => 1234,
    "content_type" => "application/octet-stream"
)
```

# Examples
```julia
# Create a text file
text_content = Vector{UInt8}("Hello, World!")
text_file_id = create_file("greeting.txt",
    text_content,
    description="A simple text file",
    metadata=Dict(
        "type" => "text/plain",
        "version" => "1.0",
        "tags" => ["example", "text"]
    )
)

# Create a binary file
binary_data = rand(UInt8, 1000)
binary_file_id = create_file("data.bin",
    binary_data,
    description="Random binary data",
    metadata=Dict(
        "type" => "application/octet-stream",
        "size" => length(binary_data),
        "created_by" => "data_generator_v1"
    )
)

# Create a JSON file
json_content = Vector{UInt8}(\"\"\"
{
    "name": "example",
    "value": 42
}
\"\"\")
json_file_id = create_file("config.json",
    json_content,
    description="Configuration file",
    metadata=Dict(
        "type" => "application/json",
        "version" => "2.1",
        "schema" => "config-v2"
    )
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/file-create-file-create-post
"""
function create_file(name::String, content::Vector{UInt8}; description::String="", metadata::Dict=Dict())
    file_id = string(uuid4())

    body = Dict{String,Any}(
        "name" => name,
        "id" => file_id,
        "project_id" => PROJECT_ID,
        "content" => base64encode(content)
    )

    if !isempty(description)
        body["description"] = description
    end

    if !isempty(metadata)
        body["metadata"] = metadata
    end

    weave_api("POST", "/file/create", body)
    return file_id
end

"""
    get_file_content(file_id::String)

Get the content and metadata of a file from the Weave service.

# Arguments
- `file_id::String`: ID of the file to retrieve

# Returns
- `Vector{UInt8}`: Binary content of the file

# Response Structure
The API returns:
```julia
Dict(
    "content" => "base64_encoded_content",
    "metadata" => Dict(
        "name" => "filename.ext",
        "size" => 1234,
        "content_type" => "application/octet-stream",
        "created_at" => "2024-01-01T00:00:00.000Z",
        "description" => "file description",
        "custom_metadata" => Dict(...)
    )
)
```

# Examples
```julia
# Retrieve and process a text file
content = get_file_content(text_file_id)
text = String(content)
println(text)

# Retrieve and save a binary file
content = get_file_content(binary_file_id)
open("downloaded_data.bin", "w") do io
    write(io, content)
end

# Retrieve and parse a JSON file
content = get_file_content(json_file_id)
json_text = String(content)
parsed_json = JSON3.read(json_text)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/file-content-file-content-get
"""
function get_file_content(file_id::String)
    response = weave_api("GET", "/file/$file_id/content", nothing)
    return base64decode(response["content"])
end

end # module Files

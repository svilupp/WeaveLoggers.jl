# File API

The File API provides functions for managing files in the Weights & Biases Weave service. Files can be used to store and retrieve binary data, text files, or any other file content.

## Functions

### create_file

```julia
create_file(name::String; content::Union{String,Vector{UInt8}}, content_type::String="application/octet-stream")
```

Create a new file in the Weave service with the specified content.

#### Arguments
- `name::String`: Name of the file (including extension)
- `content::Union{String,Vector{UInt8}}`: File content as string or binary data
- `content_type::String`: MIME type of the file content (optional, defaults to "application/octet-stream")

#### Common Content Types
- `"text/plain"`: Plain text files
- `"application/json"`: JSON files
- `"application/pdf"`: PDF files
- `"image/jpeg"`: JPEG images
- `"image/png"`: PNG images
- `"application/octet-stream"`: Binary data

#### Returns
- `String`: The unique ID of the created file

#### Example
```julia
# Create a text file
text_file_id = create_file("example.txt",
    content="Hello, World!",
    content_type="text/plain"
)

# Create a JSON file
json_file_id = create_file("config.json",
    content="""
    {
        "model": "gpt-3",
        "temperature": 0.7,
        "max_tokens": 100
    }
    """,
    content_type="application/json"
)

# Create a binary file
binary_data = UInt8[0x00, 0x01, 0x02, 0x03]
binary_file_id = create_file("data.bin",
    content=binary_data,
    content_type="application/octet-stream"
)
```

For more details, see: [File Create API Documentation](https://weave-docs.wandb.ai/reference/service-api/file-create-file-create-post)

### get_file_content

```julia
get_file_content(file_id::String)
```

Retrieve the content of a file from the Weave service.

#### Arguments
- `file_id::String`: ID of the file to retrieve

#### Returns
- `Dict`: File information including:
  - `content`: File content (as string or base64-encoded for binary)
  - `content_type`: MIME type of the file
  - `name`: Original file name
  - `size`: File size in bytes

#### Example
```julia
# Retrieve file content
file_info = get_file_content(text_file_id)
println("File name: ", file_info["name"])
println("Content type: ", file_info["content_type"])
println("Content: ", file_info["content"])

# Handle binary content
binary_file_info = get_file_content(binary_file_id)
binary_content = base64decode(binary_file_info["content"])
```

For more details, see: [File Content API Documentation](https://weave-docs.wandb.ai/reference/service-api/file-content-file-content-get)

## Error Handling

All File API functions will throw an error if:
- The WANDB_API_KEY environment variable is not set
- The API request fails (network error, authentication error, etc.)
- Invalid arguments are provided
- File size exceeds limits
- Invalid content type is specified

It's recommended to wrap API calls in try-catch blocks for proper error handling:

```julia
try
    file_id = create_file("example.txt", content="Hello")
    file_info = get_file_content(file_id)
catch e
    @error "File operation failed" exception=e
end
```

## Best Practices

1. Use appropriate content types for files
2. Handle binary data properly using UInt8 arrays
3. Consider file size limits when uploading
4. Use meaningful file names with proper extensions
5. Implement error handling for robust file operations
6. Cache file content when appropriate to reduce API calls
7. Clean up unused files to manage storage

## File Size Limits

- Text files: Up to 10MB
- Binary files: Up to 100MB
- Consider chunking larger files if necessary

## Common Use Cases

1. Configuration Files
```julia
# Store configuration
config_id = create_file("model_config.json",
    content=JSON.json(Dict(
        "model_type" => "transformer",
        "layers" => 12,
        "heads" => 8
    )),
    content_type="application/json"
)
```

2. Log Files
```julia
# Store log output
log_id = create_file("training.log",
    content=join(log_lines, "\n"),
    content_type="text/plain"
)
```

3. Model Checkpoints
```julia
# Store model weights
checkpoint_data = serialize_model(model)
checkpoint_id = create_file("model_checkpoint.bin",
    content=checkpoint_data,
    content_type="application/octet-stream"
)
```

4. Dataset Samples
```julia
# Store dataset sample
sample_json = JSON.json(dataset_sample)
sample_id = create_file("dataset_sample.json",
    content=sample_json,
    content_type="application/json"
)
```

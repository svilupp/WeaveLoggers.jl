# Object API

The Object API provides functions for managing objects in the Weights & Biases Weave service. Objects represent persistent data entities that can be referenced and tracked across multiple calls.

## Functions

### create_object

```julia
create_object(object_type::String; attributes::Dict=Dict())
```

Create a new object in the Weave service. Objects can represent various types of data entities like models, datasets, or custom types.

#### Arguments
- `object_type::String`: Type of object to create (e.g., "model", "dataset")
- `attributes::Dict`: Object attributes and metadata. Can include:
  - `name`: Object name (optional)
  - `version`: Object version (optional)
  - `description`: Object description (optional)
  - `tags`: Array of string tags (optional)
  - `metadata`: Additional metadata as a dictionary (optional)
  - Custom attributes specific to your use case

#### Returns
- `String`: The unique ID of the created object

#### Example
```julia
# Create a model object
model_id = create_object("model",
    attributes=Dict(
        "name" => "gpt-classifier",
        "version" => "1.0.0",
        "description" => "Text classification model",
        "tags" => ["nlp", "classification"],
        "metadata" => Dict(
            "framework" => "transformers",
            "architecture" => "bert-base"
        )
    )
)

# Create a dataset object
dataset_id = create_object("dataset",
    attributes=Dict(
        "name" => "sentiment-data",
        "version" => "2023.1",
        "description" => "Twitter sentiment dataset",
        "tags" => ["nlp", "sentiment"],
        "metadata" => Dict(
            "size" => 10000,
            "split" => "train"
        )
    )
)
```

For more details, see: [Object Create API Documentation](https://weave-docs.wandb.ai/reference/service-api/object-create-object-create-post)

### read_object

```julia
read_object(object_id::String)
```

Retrieve details of an object from the Weave service. This includes all object attributes and metadata.

#### Arguments
- `object_id::String`: ID of the object to read

#### Returns
- `Dict`: Object details including:
  - `id`: Object ID
  - `type`: Object type
  - `attributes`: Object attributes including:
    - `name`: Object name (if set)
    - `version`: Object version (if set)
    - `description`: Object description (if set)
    - `tags`: Array of string tags (if set)
    - `metadata`: Additional metadata (if set)
    - Any custom attributes

#### Example
```julia
# Read object details
object_details = read_object(model_id)
println("Model name: ", get(object_details["attributes"], "name", "unnamed"))
println("Model version: ", get(object_details["attributes"], "version", "unknown"))
println("Tags: ", join(get(object_details["attributes"], "tags", String[]), ", "))
```

For more details, see: [Object Read API Documentation](https://weave-docs.wandb.ai/reference/service-api/object-read-object-read-get)

## Error Handling

All Object API functions will throw an error if:
- The WANDB_API_KEY environment variable is not set
- The API request fails (network error, authentication error, etc.)
- Invalid arguments are provided

It's recommended to wrap API calls in try-catch blocks for proper error handling:

```julia
try
    object_id = create_object("model", attributes=Dict("name" => "test-model"))
    object_details = read_object(object_id)
catch e
    @error "API call failed" exception=e
end
```

## Best Practices

1. Always provide meaningful names and versions for objects to make them easily identifiable
2. Use tags to categorize objects and make them searchable
3. Include relevant metadata to provide additional context
4. Use consistent naming conventions for object types across your project
5. Handle errors appropriately to ensure robust object management

## Object Types

Common object types include:
- `"model"`: Machine learning models
- `"dataset"`: Data collections
- `"experiment"`: Experimental configurations
- `"artifact"`: Generic artifacts or resources
- Custom types specific to your use case

You can define your own object types based on your needs, but it's recommended to use consistent types across your project for better organization.

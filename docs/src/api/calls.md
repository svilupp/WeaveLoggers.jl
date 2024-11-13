# Call API

The Call API provides functions for managing the lifecycle of calls in the Weights & Biases Weave service. Calls represent individual operations or tasks that can be tracked and monitored.

## Functions

### start_call

```julia
start_call(op_name::String; inputs::Dict=Dict(), display_name::String="", attributes::Dict=Dict())
```

Start a new call in the Weave service. This creates a new call record with the specified operation name and optional parameters.

#### Arguments
- `op_name::String`: Name of the operation being performed (e.g., "text_generation", "image_classification")
- `inputs::Dict`: Input data for the call. Can include any JSON-serializable data (optional)
- `display_name::String`: Human-readable name for the call. If not provided, defaults to op_name
- `attributes::Dict`: Additional attributes for the call. Can include any JSON-serializable data (optional)

#### Returns
- `String`: The unique ID of the created call

#### Example
```julia
call_id = start_call("text_generation",
    inputs=Dict("prompt" => "Hello, world!"),
    display_name="Greeting Generation",
    attributes=Dict("model" => "gpt-3", "temperature" => 0.7)
)
```

For more details, see: [Call Start API Documentation](https://weave-docs.wandb.ai/reference/service-api/call-start-call-start-post)

### end_call

```julia
end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing)
```

End an existing call in the Weave service. This marks the call as completed and records any outputs or errors.

#### Arguments
- `call_id::String`: ID of the call to end (obtained from start_call)
- `outputs::Dict`: Output data from the call. Can include any JSON-serializable data (optional)
- `error::Union{Nothing,Dict}`: Error information if the call failed. Should include "message" key if provided (optional)

#### Returns
- `Bool`: true if the call was ended successfully

#### Example
```julia
# Successful call
success = end_call(call_id,
    outputs=Dict("text" => "Hello, human!", "tokens" => 3),
    error=nothing
)

# Failed call
success = end_call(call_id,
    outputs=Dict(),
    error=Dict("message" => "Model unavailable", "code" => 503)
)
```

For more details, see: [Call End API Documentation](https://weave-docs.wandb.ai/reference/service-api/call-end-call-end-post)

### update_call

```julia
update_call(call_id::String; attributes::Dict)
```

Update attributes of an existing call. This allows you to modify or add attributes to a call while it's in progress.

#### Arguments
- `call_id::String`: ID of the call to update
- `attributes::Dict`: New attributes to set or update on the call. Can include any JSON-serializable data

#### Returns
- `Bool`: true if the call was updated successfully

#### Example
```julia
success = update_call(call_id,
    attributes=Dict(
        "status" => "processing",
        "progress" => 0.5,
        "step" => 2
    )
)
```

For more details, see: [Call Update API Documentation](https://weave-docs.wandb.ai/reference/service-api/call-update-call-update-post)

### delete_call

```julia
delete_call(call_id::String)
```

Delete a call from the Weave service. This permanently removes the call and all associated data.

#### Arguments
- `call_id::String`: ID of the call to delete

#### Returns
- `Bool`: true if the call was deleted successfully

#### Example
```julia
success = delete_call(call_id)
```

For more details, see: [Call Delete API Documentation](https://weave-docs.wandb.ai/reference/service-api/call-delete-call-delete)

### read_call

```julia
read_call(call_id::String)
```

Read details of a call from the Weave service. This retrieves all information about a call, including its inputs, outputs, attributes, and status.

#### Arguments
- `call_id::String`: ID of the call to read

#### Returns
- `Dict`: Call details including:
  - `id`: Call ID
  - `op_name`: Operation name
  - `display_name`: Human-readable name
  - `inputs`: Input data provided to the call
  - `outputs`: Output data (if call is completed)
  - `attributes`: Call attributes
  - `error`: Error information (if call failed)
  - `started_at`: Call start timestamp
  - `ended_at`: Call end timestamp (if completed)

#### Example
```julia
call_details = read_call(call_id)
println("Call status: ", get(call_details["attributes"], "status", "unknown"))
```

For more details, see: [Call Read API Documentation](https://weave-docs.wandb.ai/reference/service-api/call-read-call-read-get)

## Error Handling

All Call API functions will throw an error if:
- The WANDB_API_KEY environment variable is not set
- The API request fails (network error, authentication error, etc.)
- Invalid arguments are provided

It's recommended to wrap API calls in try-catch blocks for proper error handling:

```julia
try
    call_id = start_call("example_operation")
    # ... perform operations ...
    success = end_call(call_id, outputs=Dict("result" => "success"))
catch e
    @error "API call failed" exception=e
end
```

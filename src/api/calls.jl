"""
WeaveLoggers Call API Functions

This module provides functions for interacting with the Weights & Biases Weave Call API.
All functions use the shared weave_api interface for making requests.

# Call Lifecycle
1. start_call - Initiates a new call
2. update_call - Updates call attributes (optional)
3. end_call - Completes the call
4. read_call - Retrieves call information
5. delete_call - Removes the call (if needed)

For more information, see: https://weave-docs.wandb.ai/reference/service-api
"""
module Calls

using ..WeaveLoggers: weave_api, format_iso8601, PROJECT_ID
using Dates
using UUIDs

export start_call, end_call, update_call, delete_call, read_call

"""
    start_call(op_name::String=""; id::String=string(uuid4()), trace_id::String=string(uuid4()), started_at::String=format_iso8601(now(UTC)), inputs::Dict=Dict(), display_name::String="", attributes::Dict=Dict())

Start a new call in the Weave service.

# Arguments
- `op_name::String`: Name of the operation being performed
- `inputs::Dict`: Input data for the call (optional)
- `display_name::String`: Human-readable name for the call (defaults to op_name if not provided)
- `attributes::Dict`: Additional attributes for the call (optional)

# Returns
- `String`: The ID of the created call

# Example
```julia
call_id = start_call("test_operation",
    inputs=Dict("prompt" => "Hello"),
    display_name="Test Call",
    attributes=Dict("version" => "1.0")
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-start-call-start-post
"""
function start_call(op_name::String=""; id::String=string(uuid4()), trace_id::String=string(uuid4()), started_at::String=format_iso8601(now(UTC)), inputs::Dict=Dict(), display_name::String="", attributes::Dict=Dict())
    # Use provided values or generate new ones if not provided
    call_id = id
    trace_id = trace_id  # Use provided trace_id

    body = Dict(
        "start" => Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id,
            "op_name" => op_name,
            "display_name" => isempty(display_name) ? op_name : display_name,
            "trace_id" => trace_id,
            "parent_id" => nothing,
            "started_at" => started_at,
            "inputs" => inputs,
            "attributes" => attributes
        )
    )

    weave_api("POST", "/call/start", body)
    return call_id
end

"""
    end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing)

End an existing call in the Weave service.

# Arguments
- `call_id::String`: ID of the call to end
- `outputs::Dict`: Output data from the call (optional)
- `error::Union{Nothing,Dict}`: Error information if the call failed (optional)

# Returns
- `Bool`: true if the call was ended successfully

# Example
```julia
success = end_call(call_id,
    outputs=Dict("result" => "Success"),
    error=nothing
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-end-call-end-post
"""
function end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing)
    body = Dict(
        "end" => Dict{String,Any}(
            "id" => call_id,
            "outputs" => outputs,
            "ended_at" => format_iso8601(now(UTC))
        )
    )

    if !isnothing(error)
        body["end"]["error"] = error
    end

    weave_api("POST", "/call/$call_id/end", body)
    return true
end

"""
    update_call(call_id::String; attributes::Dict)

Update attributes of an existing call.

# Arguments
- `call_id::String`: ID of the call to update
- `attributes::Dict`: New attributes to set on the call

# Returns
- `Bool`: true if the call was updated successfully

# Example
```julia
success = update_call(call_id,
    attributes=Dict("status" => "processing")
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-update-call-update-post
"""
function update_call(call_id::String; attributes::Dict)
    body = Dict("attributes" => attributes)
    weave_api("POST", "/call/$call_id/update", body)
    return true
end

"""
    delete_call(call_id::String)

Delete a call from the Weave service.

# Arguments
- `call_id::String`: ID of the call to delete

# Returns
- `Bool`: true if the call was deleted successfully

# Example
```julia
success = delete_call(call_id)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-delete-call-delete
"""
function delete_call(call_id::String)
    weave_api("DELETE", "/call/$call_id", nothing)
    return true
end

"""
    read_call(call_id::String)

Read details of a call from the Weave service.

# Arguments
- `call_id::String`: ID of the call to read

# Returns
- `Dict`: Call details including inputs, outputs, and attributes

# Example
```julia
call_details = read_call(call_id)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-read-call-read-get
"""
function read_call(call_id::String)
    weave_api("GET", "/call/read", nothing; query_params=Dict("id" => call_id))
end

end # module Calls

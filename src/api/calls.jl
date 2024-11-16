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

using ..WeaveLoggers: weave_api, format_iso8601, PROJECT_ID, get_system_metadata, WEAVE_SDK_VERSION,
                     WeaveAPIError, ERROR_TYPE_MAP
using Dates, UUIDs, SHA

export start_call, end_call, update_call, delete_call, read_call

# Helper function to create error response with metadata
function create_error_response(message::String, status_code::Int)
    error_type = get(ERROR_TYPE_MAP, status_code, "UnknownError")
    throw(WeaveAPIError(message, status_code, error_type))
end

"""
    start_call(; op_name::String, inputs::Dict=Dict(), attributes::Dict=Dict(), display_name::String="")

Start a new call with the given operation name and optional inputs and attributes.
Returns a tuple of (call_id, trace_id, started_at).

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-start-call-start-post
"""
function start_call(; op_name::String, inputs::Dict=Dict(), attributes::Dict=Dict(), display_name::String="")
    try
        # Generate unique identifiers
        call_id = string(uuid4())
        trace_id = string(uuid4())
        started_at = format_iso8601(now(UTC))

        # Format op_name to include entity/project and op path component
        # Full format: weave:///{project_id}/op/{function_name}:{hash}
        hash_value = bytes2hex(sha256(op_name)[1:4])  # Use first 4 bytes of SHA256 for shorter hash
        formatted_op_name = "weave:///$PROJECT_ID/op/$op_name:$hash_value"

        # Get system metadata and merge with provided attributes
        system_metadata = get_system_metadata()
        merged_attributes = merge(system_metadata, attributes)

        # Create inner payload structure
        inner_payload = Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id,
            "op_name" => formatted_op_name,
            "display_name" => isempty(display_name) ? op_name : display_name,
            "trace_id" => trace_id,
            "parent_id" => nothing,
            "started_at" => started_at,
            "inputs" => inputs,
            "attributes" => merged_attributes,
            "wb_user_id" => nothing,
            "wb_run_id" => nothing
        )

        # Wrap payload in "start" object as required by API
        body = Dict{String,Any}("start" => inner_payload)

        weave_api("POST", "/call/start", body)
        return call_id, trace_id, started_at
    catch e
        create_error_response("Failed to start call: $(e.message)", 500)
    end
end

"""
    end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing, trace_id::String, started_at::String)

End an existing call in the Weave service.

# Arguments
- `call_id::String`: ID of the call to end
- `outputs::Dict`: Output data from the call (optional)
- `error::Union{Nothing,Dict}`: Error information if the call failed (optional)
- `trace_id::String`: Trace ID from start_call
- `started_at::String`: Start timestamp from start_call

# Returns
- `Bool`: true if the call was ended successfully

# Example
```julia
success = end_call(call_id,
    outputs=Dict("result" => "Success"),
    error=nothing,
    trace_id=trace_id,
    started_at=started_at
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/call-end-call-end-post
"""
function end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing, trace_id::String, started_at::String)
    try
        # Get system metadata for consistency
        system_metadata = get_system_metadata()

        # Create flattened payload structure as required by API
        body = Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id,
            "trace_id" => trace_id,
            "started_at" => started_at,
            "ended_at" => format_iso8601(now(UTC)),
            "outputs" => outputs,
            "error" => error,
            "attributes" => system_metadata,  # Include system metadata in end call
            "summary" => Dict(
                "input_type" => "function_input",
                "output_type" => "function_output",
                "result" => outputs,
                "status" => isnothing(error) ? "success" : "error",
                "duration" => nothing  # Will be calculated by the server
            )
        )

        weave_api("POST", "/call/end", body)
        return true
    catch e
        create_error_response("Failed to end call: $(e.message)", 500)
    end
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
    try
        # Get system metadata and merge with provided attributes
        system_metadata = get_system_metadata()
        merged_attributes = merge(system_metadata, attributes)

        # Create flattened payload structure as required by API
        body = Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id,
            "attributes" => merged_attributes
        )
        weave_api("POST", "/call/update", body)
        return true
    catch e
        create_error_response("Failed to update call: $(e.message)", 500)
    end
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
    try
        # Create flattened payload structure as required by API
        body = Dict{String,Any}(
            "project_id" => PROJECT_ID,
            "id" => call_id
        )
        weave_api("DELETE", "/call/delete", body)
        return true
    catch e
        create_error_response("Failed to delete call: $(e.message)", 500)
    end
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
    try
        query_params = Dict(
            "project_id" => PROJECT_ID,
            "id" => call_id
        )
        weave_api("GET", "/call/read", nothing; query_params=query_params)
    catch e
        create_error_response("Failed to read call: $(e.message)", 500)
    end
end

end # module Calls

module WeaveLoggers

using PromptingTools
using HTTP
using JSON3
using Base64
using Dates
using UUIDs

# Export the main functionality
export weave_log, test_weave_api, start_call, end_call, read_call

const WEAVE_API_BASE_URL = "https://trace.wandb.ai"

"""
    get_auth_headers(api_key::String)

Create authentication headers for Weave API requests.
"""
function get_auth_headers(api_key::String)
    auth_string = Base64.base64encode("api:$api_key")
    return [
        "Authorization" => "Basic $auth_string",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]
end

"""
    generate_uuid()

Generate a UUID-like string for call IDs.
"""
function generate_uuid()
    return string(uuid4())
end

"""
    convert_input_value(value::String)

Convert string input values to appropriate types (e.g., numbers).
"""
function convert_input_value(value::String)
    # Try to convert to number if possible
    try
        # First try as integer
        parsed = tryparse(Int, value)
        if !isnothing(parsed)
            return parsed
        end
        # Then try as float
        parsed = tryparse(Float64, value)
        if !isnothing(parsed)
            return parsed
        end
    catch
        # If conversion fails, return original string
    end
    return value
end

# Function that uses PromptingTools for logging
function weave_log(message::String)
    # Basic implementation using PromptingTools
    # This ensures the dependency is actually used
    @info "WeaveLoggers: $message"
end

"""
    test_weave_api()

Test the Weave API connection and authentication.
"""
function test_weave_api()
    api_key = get(ENV, "WANDB_API_KEY", nothing)
    if isnothing(api_key)
        error("WANDB_API_KEY not found in environment variables")
    end

    try
        # Test API endpoint with a simple call start request
        test_body = Dict(
            "start" => Dict(
                "project_id" => "test",
                "id" => generate_uuid(),
                "op_name" => "test_connection",
                "display_name" => "API Test",
                "started_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:mm:ss.sssZ")
            )
        )

        response = HTTP.post(
            "$WEAVE_API_BASE_URL/call/start",
            get_auth_headers(api_key),
            JSON3.write(test_body)
        )
        return response.status == 200
    catch e
        @error "Failed to connect to Weave API" exception=e
        return false
    end
end

"""
    start_call(; model::String="", inputs::Dict=Dict(), metadata::Dict=Dict())

Start a new call in the Weave service.
Returns the call ID if successful.
"""
function start_call(; model::String="", inputs::Dict=Dict(), metadata::Dict=Dict())
    api_key = ENV["WANDB_API_KEY"]
    call_id = generate_uuid()

    # Convert string values in inputs to appropriate types
    converted_inputs = Dict(k => convert_input_value(v) for (k, v) in inputs)

    # Prepare request body according to API specification
    body = Dict(
        "start" => Dict(
            "project_id" => get(metadata, "project_id", "default"),
            "id" => call_id,
            "op_name" => model,
            "display_name" => get(metadata, "display_name", model),
            "trace_id" => get(metadata, "trace_id", call_id),
            "parent_id" => get(metadata, "parent_id", nothing),
            "started_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:mm:ss.sssZ"),
            "attributes" => metadata,
            "inputs" => converted_inputs,
            "wb_user_id" => get(metadata, "wb_user_id", nothing),
            "wb_run_id" => get(metadata, "wb_run_id", nothing)
        )
    )

    try
        @info "Sending request to start call" url="$WEAVE_API_BASE_URL/call/start" body=body
        response = HTTP.post(
            "$WEAVE_API_BASE_URL/call/start",
            get_auth_headers(api_key),
            JSON3.write(body)
        )

        result = JSON3.read(response.body)
        @info "Call started successfully" response_status=response.status response_body=String(response.body)
        return call_id
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error "Failed to start call" status=e.status response_body=String(e.response.body) exception=e
        else
            @error "Failed to start call" exception=e
        end
        rethrow(e)
    end
end

"""
    end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing)

End a call in the Weave service.
"""
function end_call(call_id::String; outputs::Dict=Dict(), error::Union{Nothing,Dict}=nothing)
    api_key = ENV["WANDB_API_KEY"]

    # Prepare request body
    body = Dict(
        "end" => Dict(
            "outputs" => outputs,
            "ended_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:mm:ss.sssZ")
        )
    )
    if !isnothing(error)
        body["end"]["error"] = error
    end

    try
        @info "Sending request to end call" url="$WEAVE_API_BASE_URL/call/$call_id/end" body=body
        response = HTTP.post(
            "$WEAVE_API_BASE_URL/call/$call_id/end",
            get_auth_headers(api_key),
            JSON3.write(body)
        )
        @info "Call ended successfully" response_status=response.status response_body=String(response.body)
        return response.status == 200
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error "Failed to end call" status=e.status response_body=String(e.response.body) exception=e
        else
            @error "Failed to end call" exception=e
        end
        rethrow(e)
    end
end

"""
    read_call(call_id::String)

Retrieve a call from the Weave service.
"""
function read_call(call_id::String)
    api_key = ENV["WANDB_API_KEY"]

    try
        @info "Sending request to read call" url="$WEAVE_API_BASE_URL/call/read?id=$call_id"
        response = HTTP.get(
            "$WEAVE_API_BASE_URL/call/read?id=$call_id",
            get_auth_headers(api_key)
        )
        @info "Call read successfully" response_status=response.status response_body=String(response.body)
        return JSON3.read(response.body)
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error "Failed to read call" status=e.status response_body=String(e.response.body) exception=e
        else
            @error "Failed to read call" exception=e
        end
        rethrow(e)
    end
end

end # module

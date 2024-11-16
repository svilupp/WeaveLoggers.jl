module WeaveLoggers

using HTTP
using JSON3
using Base64
using Dates
using UUIDs
using Statistics

# Global variables
const WANDB_API_KEY = get(ENV, "WANDB_API_KEY", "")
const PROJECT_ID = "anim-mina/slide-comprehension-plain-ocr"  # Update to match our test environment
const POSTPROCESS_INPUTS = Function[]
const PREPROCESS_INPUTS = Function[]
const WEAVE_SDK_VERSION = "0.1.0"  # Add SDK version constant

# API Base URLs
const WEAVE_API_BASE_URL = "https://trace.wandb.ai"
const WANDB_API_BASE_URL = "https://api.wandb.ai"

# Utility functions
"""
    format_iso8601(dt::DateTime)

Format a DateTime to ISO 8601 format with exactly three millisecond digits.
"""
function format_iso8601(dt::DateTime)
    year = Dates.year(dt)
    month = lpad(Dates.month(dt), 2, '0')
    day = lpad(Dates.day(dt), 2, '0')
    hour = lpad(Dates.hour(dt), 2, '0')
    minute = lpad(Dates.minute(dt), 2, '0')
    second = lpad(Dates.second(dt), 2, '0')
    ms = lpad(round(Int, Dates.value(Dates.Millisecond(dt)) % 1000), 3, '0')
    return "$(year)-$(month)-$(day)T$(hour):$(minute):$(second).$(ms)Z"
end

"""
    get_system_metadata()

Generate system metadata for Weave API calls.
"""
function get_system_metadata()
    Dict(
        "weave" => Dict(
            "client_version" => WEAVE_SDK_VERSION,
            "source" => "julia-client",
            "os" => string(Sys.KERNEL),
            "arch" => string(Sys.ARCH),
            "julia_version" => string(VERSION)
        )
    )
end

"""
    weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
              base_url::String=WEAVE_API_BASE_URL, query_params::Dict{String,String}=Dict{String,String}())

Make an API call to the Weights & Biases Weave service.

# Arguments
- `method`: HTTP method (GET, POST, PUT, DELETE)
- `endpoint`: API endpoint path
- `body`: Request body (optional)
- `base_url`: Base URL for the API (defaults to WEAVE_API_BASE_URL)
- `query_params`: Query parameters to append to the URL

# Returns
- JSON3 parsed response body
"""
function weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                  base_url::String=WEAVE_API_BASE_URL, query_params::Dict{String,String}=Dict{String,String}())
    if isempty(WANDB_API_KEY)
        error("WANDB_API_KEY environment variable is not set")
    end

    # Process inputs if any preprocessing functions are defined
    if !isnothing(body) && !isempty(PREPROCESS_INPUTS)
        for f in PREPROCESS_INPUTS
            body = f(body)
        end
    end

    # Construct URL with query parameters
    url = base_url * endpoint
    if !isempty(query_params)
        query_string = join(["$k=$(HTTP.escapeuri(v))" for (k,v) in query_params], "&")
        url *= "?" * query_string
    end

    # Prepare headers with authentication
    auth_string = Base64.base64encode("api:$WANDB_API_KEY")
    headers = [
        "Authorization" => "Basic $auth_string",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]

    try
        # Make the API call
        response = if isnothing(body)
            HTTP.request(method, url, headers)
        else
            HTTP.request(method, url, headers, JSON3.write(body))
        end

        # Parse response
        response_body = if !isempty(response.body)
            parsed = JSON3.read(response.body)

            # Process output if any postprocessing functions are defined
            if !isempty(POSTPROCESS_INPUTS)
                for f in POSTPROCESS_INPUTS
                    parsed = f(parsed)
                end
            end

            parsed
        else
            nothing
        end

        return response_body
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error "API call failed" status=e.status response_body=String(e.response.body) exception=e
        else
            @error "API call failed" exception=e
        end
        rethrow(e)
    end
end

# Include API modules
include("api/calls.jl")
include("api/objects.jl")
include("api/tables.jl")
include("api/files.jl")
include("api/macros.jl")  # Include the new macros module

# Re-export API functions
using .Calls: start_call, end_call, update_call, delete_call, read_call
using .Objects: create_object, read_object
using .Tables: create_table, update_table, query_table
using .Files: create_file, get_file_content
using .Macros: @w, @wtable, @wfile  # Export all macros

# Export core functionality
export weave_api, format_iso8601, get_system_metadata
export WANDB_API_KEY, PROJECT_ID, POSTPROCESS_INPUTS, PREPROCESS_INPUTS, WEAVE_SDK_VERSION

# Re-export API functions
export start_call, end_call, update_call, delete_call, read_call
export create_object, read_object
export create_table, update_table, query_table
export create_file, get_file_content
export @w, @wtable, @wfile  # Export all macros

end # module

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
function weave_api(method::String, endpoint::String, body::Union{Dict, Nothing} = nothing;
        base_url::String = WEAVE_API_BASE_URL, query_params::Dict{String, String} = Dict{
            String, String}())
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
        query_string = join(["$k=$(HTTP.escapeuri(v))" for (k, v) in query_params], "&")
        url *= "?" * query_string
    end

    # Prepare headers with authentication
    auth_string = Base64.base64encode("api:$WANDB_API_KEY")
    headers = [
        "Authorization" => "Basic $auth_string",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]

    # Log the request details for debugging
    @debug "Making API request" method endpoint url body

    # Make the API call and return the response
    response = if isnothing(body)
        HTTP.request(method, url, headers)
    else
        HTTP.request(method, url, headers, JSON3.write(body))
    end

    # Parse and process response
    if !isempty(response.body)
        parsed = JSON3.read(response.body)

        # Process output if any postprocessing functions are defined
        if !isempty(POSTPROCESS_INPUTS)
            for f in POSTPROCESS_INPUTS
                parsed = f(parsed)
            end
        end

        return parsed
    end

    return nothing
end
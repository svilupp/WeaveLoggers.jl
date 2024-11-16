"""
WeaveLoggers Error Types and Handling

This module defines error types and mappings for the WeaveLoggers package.
"""

# Define the main error type for WeaveLoggers API calls
struct WeaveAPIError <: Exception
    message::String
    status_code::Int
    error_type::String
end

# Map HTTP status codes to error types
const ERROR_TYPE_MAP = Dict{Int, String}(
    400 => "InvalidRequestError",
    401 => "AuthenticationError",
    403 => "PermissionError",
    404 => "NotFoundError",
    429 => "RateLimitError",
    500 => "InternalServerError",
    503 => "ServiceUnavailableError"
)

# Base.showerror extension for pretty printing
function Base.showerror(io::IO, e::WeaveAPIError)
    print(io, "WeaveAPIError($(e.error_type)): $(e.message) (Status: $(e.status_code))")
end

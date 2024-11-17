module WeaveLoggers

using HTTP
using JSON3
using Base64
using Dates
using UUIDs
using Statistics

# Global variables
global WANDB_API_KEY::String = get(ENV, "WANDB_API_KEY", "")
global PROJECT_ID::String = "anim-mina/slide-comprehension-plain-ocr"  # Update to match our test environment, mock for testing
global POSTPROCESS_INPUTS::Vector{Function} = Function[]
global PREPROCESS_INPUTS::Vector{Function} = Function[]
global WEAVE_SDK_VERSION::String = string(pkgversion(WeaveLoggers))  # Add SDK version constant

# API Base URLs
const WEAVE_API_BASE_URL = "https://trace.wandb.ai"
const WANDB_API_BASE_URL = "https://api.wandb.ai"

export format_iso8601, get_system_metadata
include("utils.jl")

export weave_api
include("core_api.jl")

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

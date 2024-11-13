```@meta
CurrentModule = WeaveLoggers
```

# WeaveLoggers.jl

WeaveLoggers.jl is a Julia package for interacting with the Weights & Biases Weave service API. It provides a comprehensive set of functions for managing calls, objects, tables, and files through a unified interface.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/svilupp/WeaveLoggers.jl")
```

## Configuration

The library requires the following configuration:

### Environment Variables
- `WANDB_API_KEY`: Your Weights & Biases API key (required)

### Global Variables
- `PROJECT_ID`: Project identifier (default: "demo-weaveloggers")
- `POSTPROCESS_INPUTS`: Vector of functions for post-processing API responses (default: empty)
- `PREPROCESS_INPUTS`: Vector of functions for pre-processing API requests (default: empty)

## Core Interface

### weave_api Function
The `weave_api` function serves as the common interface for all API calls:

```julia
weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
          base_url::String=WEAVE_API_BASE_URL, query_params::Dict{String,String}=Dict{String,String}())
```

Arguments:
- `method`: HTTP method (GET, POST, PUT, DELETE)
- `endpoint`: API endpoint path
- `body`: Request body (optional)
- `base_url`: Base URL for the API
- `query_params`: Query parameters to append to the URL

## API Reference

### Call API
Functions for managing call lifecycle:
- [`start_call`](@ref): Initiate a new call
- [`end_call`](@ref): Complete a call
- [`update_call`](@ref): Update call attributes
- [`delete_call`](@ref): Remove a call
- [`read_call`](@ref): Retrieve call information

### Object API
Functions for managing objects:
- [`create_object`](@ref): Create a new object
- [`read_object`](@ref): Retrieve object information

### Table API
Functions for managing tables:
- [`create_table`](@ref): Create a new table with schema
- [`update_table`](@ref): Update table data
- [`query_table`](@ref): Query table data with filtering

### File API
Functions for managing files:
- [`create_file`](@ref): Create a new file
- [`get_file_content`](@ref): Retrieve file content

## Examples

See the [examples/api_examples.jl](examples/api_examples.jl) file for comprehensive examples of all API functions.

## API Documentation

```@contents
Pages = [
    "api/calls.md",
    "api/objects.md",
    "api/tables.md",
    "api/files.md"
]
Depth = 2
```

```@index
```

```@autodocs
Modules = [WeaveLoggers]
```

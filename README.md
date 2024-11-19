> [!WARNING]
> This package is under development, use at your own risk!
> 
> It was auto-generated with Cognition's Devin and requires manual cleanup!

# WeaveLoggers.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.
github.io/WeaveLoggers.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)]
(https://svilupp.github.io/WeaveLoggers.jl/dev/) [![Build Status](https://github.com/svilupp/
WeaveLoggers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/
WeaveLoggers.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/
svilupp/WeaveLoggers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/WeaveLoggers.
jl) [![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://
github.com/JuliaTesting/Aqua.jl)

WeaveLoggers.jl is an experimental Julia package for interacting with the Weights & Biases Weave service API (unofficial). It provides a comprehensive set of functions for managing calls, objects, tables, and files through a unified interface.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/svilupp/WeaveLoggers.jl")
```
## Quick Start

To help you get started with **WeaveLoggers.jl**, here are some examples using the macros provided by the package. These macros simplify the process of logging function calls, tables, and files to the Weave service.


The `@w` macro allows you to annotate function calls with logging, timing, and API integration. It captures input arguments, execution time, and output results.
```julia
using WeaveLoggers.Macros

# Basic usage
result = @w sqrt(16)  # Logs the call to sqrt(16)

# With operation name
result = @w "sqrt_operation" sqrt(16)

# With metadata tags
result = @w :math :basic sqrt(16)

# With both operation name and tags
result = @w "sqrt_operation" :math :basic sqrt(16)
```

The `@wtable` macro logs a Tables.jl-compatible object or DataFrame to the Weave service.
```julia
using DataFrames
using WeaveLoggers.Macros

df = DataFrame(a = 1:3, b = ["x", "y", "z"])

# Log the table with a specified name
@wtable "my_table" df

# Log the table, inferring the name from the variable
@wtable df

# Log the table with tags
@wtable df :example :test_data
```
The `@wfile` macro logs files to the Weave service with optional metadata tags.
```julia
using WeaveLoggers.Macros

# Log a file with a specified name
@wfile "config.yaml" "/path/to/config.yaml"

# Log a file, using the basename as the name
@wfile "/path/to/data.csv"

# Log a file with tags
@wfile "model.pt" "/path/to/model.pt" :model :pytorch
```
Here's a complete example that combines all the macros:
```julia
using WeaveLoggers.Macros
using DataFrames

# Annotate a function call
result = @w "compute_statistics" :analytics begin
    data = rand(100)
    mean(data)
end

# Log a DataFrame
df = DataFrame(value = rand(10))
@wtable df :random :sample_data

# Log a configuration file
@wfile "settings.json" "/path/to/settings.json" :config
```

## Configuration

The library requires the following configuration:

### Environment Variables

- `WANDB_API_KEY`: Your Weights & Biases API key (required)

### Global Variables

- `PROJECT_ID`: Project identifier (default: `"demo-weaveloggers"`)
- `POSTPROCESS_INPUTS`: Vector of functions for post-processing API responses (default: empty)
- `PREPROCESS_INPUTS`: Vector of functions for pre-processing API requests (default: empty)

## Core Interface

### `weave_api` Function

The `weave_api` function serves as the common interface for all API calls:

```julia
weave_api(method::String, endpoint::String, body::Union{Dict, Nothing}=nothing;
          base_url::String=WEAVE_API_BASE_URL, query_params::Dict{String, String}=Dict{String, String}())
```

**Arguments:**

- `method`: HTTP method (`"GET"`, `"POST"`, `"PUT"`, `"DELETE"`)
- `endpoint`: API endpoint path
- `body`: Request body (optional)
- `base_url`: Base URL for the API
- `query_params`: Query parameters to append to the URL

## API Reference

### Call API

Functions for managing call lifecycle:

- `start_call`: Initiate a new call
- `end_call`: Complete a call
- `update_call`: Update call attributes
- `delete_call`: Remove a call
- `read_call`: Retrieve call information

### Object API

Functions for managing objects:

- `create_object`: Create a new object
- `read_object`: Retrieve object information

### Table API

Functions for managing tables:

- `create_table`: Create a new table with schema
- `update_table`: Update table data
- `query_table`: Query table data with filtering

### File API

Functions for managing files:

- `create_file`: Create a new file
- `get_file_content`: Retrieve file content

## Examples

See the [examples/api_examples.jl](examples/api_examples.jl) file for comprehensive examples of all API functions.
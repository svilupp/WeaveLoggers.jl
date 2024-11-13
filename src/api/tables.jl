"""
WeaveLoggers Table API Functions

This module provides functions for interacting with the Weights & Biases Weave Table API.
All functions use the shared weave_api interface for making requests.

# Supported Column Types
- "string": Text data
- "number": Numeric values (integers or floats)
- "boolean": True/false values
- "datetime": Timestamp values
- "array": Lists of values
- "object": Nested JSON objects
- "reference": References to other objects

# Table Operations
1. create_table - Creates a new table with schema
2. update_table - Updates table data
3. query_table - Queries table data with filtering and pagination

For more information, see: https://weave-docs.wandb.ai/reference/service-api
"""
module Tables

using ..WeaveLoggers: weave_api, PROJECT_ID
using UUIDs

export create_table, update_table, query_table

"""
    create_table(name::String; schema::Dict, description::String="")

Create a new table in the Weave service.

# Arguments
- `name::String`: Name of the table
- `schema::Dict`: Schema definition for the table. Must include:
  - `columns`: Array of column definitions, each with:
    - `name`: Column identifier
    - `type`: Data type (see supported types below)
    - `nullable`: Optional boolean, if the column can be null
    - `description`: Optional column description
- `description::String`: Optional description of the table

# Supported Column Types
- "string": Text data
- "number": Numeric values (integers or floats)
- "boolean": True/false values
- "datetime": Timestamp values
- "array": Lists of values
- "object": Nested JSON objects
- "reference": References to other objects

# Returns
- `String`: The ID of the created table

# Response Structure
The API returns:
```julia
Dict(
    "id" => "table_uuid",
    "name" => "table_name",
    "project_id" => "project/name",
    "schema" => Dict(
        "columns" => [
            Dict("name" => "col1", "type" => "string", ...),
            Dict("name" => "col2", "type" => "number", ...)
        ]
    ),
    "description" => "table description",
    "created_at" => "2024-01-01T00:00:00.000Z"
)
```

# Examples
```julia
# Simple metrics table
table_id = create_table("metrics",
    schema=Dict(
        "columns" => [
            Dict("name" => "metric", "type" => "string"),
            Dict("name" => "value", "type" => "number"),
            Dict("name" => "timestamp", "type" => "datetime")
        ]
    ),
    description="Table for tracking metrics"
)

# Complex table with nested data
table_id = create_table("experiments",
    schema=Dict(
        "columns" => [
            Dict(
                "name" => "experiment_id",
                "type" => "string",
                "description" => "Unique experiment identifier"
            ),
            Dict(
                "name" => "parameters",
                "type" => "object",
                "description" => "Experiment parameters"
            ),
            Dict(
                "name" => "metrics",
                "type" => "array",
                "description" => "List of metric values"
            ),
            Dict(
                "name" => "model_ref",
                "type" => "reference",
                "description" => "Reference to model object"
            )
        ]
    ),
    description="Experiment tracking table"
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/table-create-table-create-post
"""
function create_table(name::String; schema::Dict, description::String="")
    table_id = string(uuid4())

    body = Dict{String,Any}(
        "name" => name,
        "id" => table_id,
        "project_id" => PROJECT_ID,
        "schema" => schema
    )

    if !isempty(description)
        body["description"] = description
    end

    weave_api("POST", "/table/create", body)
    return table_id
end

"""
    update_table(table_id::String; updates::Dict)

Update data in an existing table.

# Arguments
- `table_id::String`: ID of the table to update
- `updates::Dict`: Data updates to apply to the table. Must include:
  - `rows`: Array of row data matching the table schema
  - `operation`: Optional update operation ("insert", "update", "upsert")

# Update Operations
- "insert": Add new rows (default)
- "update": Modify existing rows
- "upsert": Insert or update based on primary key

# Returns
- `Bool`: true if the update was successful

# Response Structure
The API returns:
```julia
Dict(
    "success" => true,
    "rows_affected" => 2,
    "timestamp" => "2024-01-01T00:00:00.000Z"
)
```

# Examples
```julia
# Insert new metrics
success = update_table(table_id,
    updates=Dict(
        "rows" => [
            Dict(
                "metric" => "accuracy",
                "value" => 0.95,
                "timestamp" => "2024-01-01T00:00:00.000Z"
            ),
            Dict(
                "metric" => "loss",
                "value" => 0.05,
                "timestamp" => "2024-01-01T00:00:00.000Z"
            )
        ]
    )
)

# Update existing rows
success = update_table(table_id,
    updates=Dict(
        "operation" => "update",
        "rows" => [
            Dict(
                "experiment_id" => "exp1",
                "parameters" => Dict("learning_rate" => 0.01),
                "metrics" => [0.95, 0.96, 0.97]
            )
        ]
    )
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/table-update-table-update-post
"""
function update_table(table_id::String; updates::Dict)
    body = Dict{String,Any}(
        "id" => table_id,
        "updates" => updates
    )

    weave_api("POST", "/table/$table_id/update", body)
    return true
end

"""
    query_table(table_id::String; query::Dict)

Query data from a table with filtering, sorting, and pagination.

# Arguments
- `table_id::String`: ID of the table to query
- `query::Dict`: Query parameters including:
  - `filter`: Conditions for row selection
  - `sort`: Column sorting specifications
  - `limit`: Maximum number of rows to return
  - `offset`: Number of rows to skip
  - `columns`: Specific columns to return

# Query Operators
Filter operators:
- Comparison: "=", "!=", "<", "<=", ">", ">="
- Text: "like", "not_like", "in", "not_in"
- Null: "is_null", "is_not_null"
- Logic: "and", "or", "not"

# Returns
- `Dict`: Query results including:
  - `rows`: Matching table rows
  - `total`: Total number of matching rows
  - `has_more`: Boolean indicating if more rows exist

# Response Structure
The API returns:
```julia
Dict(
    "rows" => [
        Dict("col1" => "val1", "col2" => 42),
        Dict("col1" => "val2", "col2" => 43)
    ],
    "total" => 100,
    "has_more" => true
)
```

# Examples
```julia
# Simple filter query
results = query_table(table_id,
    query=Dict(
        "filter" => Dict("column" => "metric", "op" => "=", "value" => "accuracy"),
        "sort" => [Dict("column" => "timestamp", "order" => "desc")],
        "limit" => 10
    )
)

# Complex query with multiple conditions
results = query_table(table_id,
    query=Dict(
        "filter" => Dict(
            "op" => "and",
            "conditions" => [
                Dict("column" => "value", "op" => ">", "value" => 0.9),
                Dict("column" => "timestamp", "op" => ">=", "value" => "2024-01-01T00:00:00.000Z")
            ]
        ),
        "sort" => [
            Dict("column" => "value", "order" => "desc"),
            Dict("column" => "timestamp", "order" => "asc")
        ],
        "columns" => ["metric", "value", "timestamp"],
        "limit" => 100,
        "offset" => 0
    )
)

# Query with text search and pagination
results = query_table(table_id,
    query=Dict(
        "filter" => Dict("column" => "description", "op" => "like", "value" => "%success%"),
        "limit" => 20,
        "offset" => 40  # Skip first 40 rows
    )
)
```

For more details, see: https://weave-docs.wandb.ai/reference/service-api/table-query-table-query-post
"""
function query_table(table_id::String; query::Dict)
    body = Dict{String,Any}(
        "id" => table_id,
        "query" => query
    )

    weave_api("POST", "/table/$table_id/query", body)
end

end # module Tables

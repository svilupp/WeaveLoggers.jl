# Table API

The Table API provides functions for managing tables in the Weights & Biases Weave service. Tables are used to store structured data with defined schemas and support querying capabilities.

## Functions

### create_table

```julia
create_table(name::String; schema::Dict, description::String="")
```

Create a new table in the Weave service with a specified schema.

#### Arguments
- `name::String`: Name of the table
- `schema::Dict`: Table schema definition including:
  - `columns`: Array of column definitions, each with:
    - `name`: Column name
    - `type`: Column type (string, number, boolean, datetime)
    - `nullable`: Whether the column can contain null values (optional)
- `description::String`: Optional description of the table

#### Supported Column Types
- `"string"`: Text data
- `"number"`: Numeric data (integers or floating-point)
- `"boolean"`: True/false values
- `"datetime"`: Timestamp values (ISO 8601 format)

#### Returns
- `String`: The unique ID of the created table

#### Example
```julia
# Create a metrics table
table_id = create_table("training_metrics",
    schema=Dict(
        "columns" => [
            Dict("name" => "epoch", "type" => "number"),
            Dict("name" => "metric", "type" => "string"),
            Dict("name" => "value", "type" => "number"),
            Dict("name" => "timestamp", "type" => "datetime")
        ]
    ),
    description="Training metrics tracking table"
)
```

For more details, see: [Table Create API Documentation](https://weave-docs.wandb.ai/reference/service-api/table-create-table-create-post)

### update_table

```julia
update_table(table_id::String; updates::Dict)
```

Update a table by adding or modifying rows.

#### Arguments
- `table_id::String`: ID of the table to update
- `updates::Dict`: Update operations including:
  - `rows`: Array of row data to add/update
  - `upsert`: Boolean indicating whether to update existing rows (optional)

#### Returns
- `Bool`: true if the table was updated successfully

#### Example
```julia
# Add new rows to the table
success = update_table(table_id,
    updates=Dict(
        "rows" => [
            Dict(
                "epoch" => 1,
                "metric" => "loss",
                "value" => 0.5,
                "timestamp" => format_iso8601(now(UTC))
            ),
            Dict(
                "epoch" => 1,
                "metric" => "accuracy",
                "value" => 0.85,
                "timestamp" => format_iso8601(now(UTC))
            )
        ]
    )
)
```

For more details, see: [Table Update API Documentation](https://weave-docs.wandb.ai/reference/service-api/table-update-table-update-post)

### query_table

```julia
query_table(table_id::String; query::Dict)
```

Query data from a table using filters, sorting, and pagination.

#### Arguments
- `table_id::String`: ID of the table to query
- `query::Dict`: Query parameters including:
  - `filter`: Filter conditions (optional)
  - `sort`: Sorting specifications (optional)
  - `limit`: Maximum number of rows to return (optional)
  - `offset`: Number of rows to skip (optional)

#### Query Operators
Filter operators include:
- `"="`: Equal to
- `"!="`: Not equal to
- `">"`: Greater than
- `">="`: Greater than or equal to
- `"<"`: Less than
- `"<="`: Less than or equal to
- `"like"`: Pattern matching (string columns only)
- `"in"`: Value in array
- `"not in"`: Value not in array

#### Returns
- `Dict`: Query results including:
  - `rows`: Array of matching rows
  - `total`: Total number of matching rows
  - `schema`: Table schema

#### Example
```julia
# Query table with filtering and sorting
results = query_table(table_id,
    query=Dict(
        "filter" => Dict(
            "column" => "metric",
            "op" => "=",
            "value" => "accuracy"
        ),
        "sort" => [
            Dict("column" => "epoch", "order" => "desc")
        ],
        "limit" => 10
    )
)

# Complex query with multiple conditions
results = query_table(table_id,
    query=Dict(
        "filter" => Dict(
            "and" => [
                Dict("column" => "value", "op" => ">", "value" => 0.8),
                Dict("column" => "metric", "op" => "in", "value" => ["accuracy", "f1"])
            ]
        ),
        "sort" => [
            Dict("column" => "timestamp", "order" => "desc")
        ],
        "limit" => 20,
        "offset" => 0
    )
)
```


For more details, see: [Table Query API Documentation](https://weave-docs.wandb.ai/reference/service-api/table-query-table-query-post)

## Error Handling

All Table API functions will throw an error if:
- The WANDB_API_KEY environment variable is not set
- The API request fails (network error, authentication error, etc.)
- Invalid arguments are provided
- Schema validation fails
- Query syntax is invalid

It's recommended to wrap API calls in try-catch blocks for proper error handling:

```julia
try
    table_id = create_table("example_table", schema=Dict(...))
    success = update_table(table_id, updates=Dict(...))
    results = query_table(table_id, query=Dict(...))
catch e
    @error "Table operation failed" exception=e
end
```

## Best Practices

1. Design schemas carefully to match your data structure
2. Use appropriate column types for better query performance
3. Include timestamps for time-series data
4. Use meaningful table and column names
5. Add descriptions to tables for better documentation
6. Use batch updates when adding multiple rows
7. Implement pagination for large query results
8. Include error handling for robust applications

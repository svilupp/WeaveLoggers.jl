"""
WeaveLoggers.jl API Examples

This script demonstrates the usage of all WeaveLoggers.jl API functions.
All examples use the demo-weaveloggers project.
"""

using WeaveLoggers
using Dates

# Ensure WANDB_API_KEY is set
if isempty(ENV["WANDB_API_KEY"])
    error("Please set WANDB_API_KEY environment variable")
end

println("Starting API Examples...")

# Call API Examples
println("\n=== Call API Examples ===")

# Start a call
call_id = start_call("example_operation",
    inputs=Dict("prompt" => "Test prompt"),
    display_name="Example Call",
    attributes=Dict("version" => "1.0")
)
println("Created call: $call_id")

# Update call
update_call(call_id,
    attributes=Dict("status" => "processing")
)
println("Updated call attributes")

# Read call
call_details = read_call(call_id)
println("Read call details: ", call_details)

# End call
end_call(call_id,
    outputs=Dict("result" => "Success"),
    error=nothing
)
println("Ended call")

# Delete call (cleanup)
delete_call(call_id)
println("Deleted call")

# Object API Examples
println("\n=== Object API Examples ===")

# Create object
object_id = create_object("model",
    attributes=Dict(
        "name" => "example-model",
        "version" => "1.0",
        "description" => "Example model object",
        "tags" => ["example", "test"],
        "metadata" => Dict(
            "framework" => "julia",
            "type" => "test"
        )
    )
)
println("Created object: $object_id")

# Read object
object_details = read_object(object_id)
println("Read object details: ", object_details)

# Table API Examples
println("\n=== Table API Examples ===")

# Create table
table_id = create_table("example_metrics",
    schema=Dict(
        "columns" => [
            Dict("name" => "metric", "type" => "string"),
            Dict("name" => "value", "type" => "number"),
            Dict("name" => "timestamp", "type" => "datetime")
        ]
    ),
    description="Example metrics table"
)
println("Created table: $table_id")

# Update table with data
update_table(table_id,
    updates=Dict(
        "rows" => [
            Dict(
                "metric" => "accuracy",
                "value" => 0.95,
                "timestamp" => format_iso8601(now(UTC))
            ),
            Dict(
                "metric" => "loss",
                "value" => 0.05,
                "timestamp" => format_iso8601(now(UTC))
            )
        ]
    )
)
println("Updated table with data")

# Query table
results = query_table(table_id,
    query=Dict(
        "filter" => Dict("column" => "metric", "op" => "=", "value" => "accuracy"),
        "sort" => [Dict("column" => "timestamp", "order" => "desc")],
        "limit" => 10
    )
)
println("Query results: ", results)

# File API Examples
println("\n=== File API Examples ===")

# Create text file
text_content = "Example file content"
file_id = create_file(
    content=text_content,
    metadata=Dict(
        "name" => "example.txt",
        "type" => "text",
        "description" => "Example text file"
    )
)
println("Created file: $file_id")

# Get file content
file_content = get_file_content(file_id)
println("Retrieved file content: ", file_content)

println("\nAll examples completed successfully!")

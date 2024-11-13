# WeaveLoggers.jl API Implementation Todo List

## Core API
- [x] `weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing)` - Common interface for all API calls

## Call API (`src/calls.jl`)
- [x] `start_call(op_name::String; inputs::Dict=Dict(), display_name::String="")` - Start a new call
  - Endpoint: POST /call/start
  - Required: project_id, op_name
  - Optional: display_name, inputs, attributes

- [x] `end_call(call_id::String; outputs::Dict=Dict())` - End an existing call
  - Endpoint: POST /call/{call_id}/end
  - Required: call_id
  - Optional: outputs, error

- [x] `update_call(call_id::String; attributes::Dict=Dict())` - Update call attributes
  - Endpoint: POST /call/{call_id}/update
  - Required: call_id
  - Optional: attributes

- [x] `delete_call(call_id::String)` - Delete a call
  - Endpoint: DELETE /call/{call_id}
  - Required: call_id

- [x] `read_call(call_id::String)` - Read call details
  - Endpoint: GET /call/read
  - Required: call_id

## Object API (`src/objects.jl`)
- [x] `create_object(type::String; attributes::Dict=Dict())` - Create a new object
  - Endpoint: POST /object/create
  - Required: type
  - Optional: attributes

- [x] `read_object(object_id::String)` - Read object details
  - Endpoint: GET /object/read
  - Required: object_id

## Table API (`src/tables.jl`)
- [x] `create_table(name::String; schema::Dict)` - Create a new table
  - Endpoint: POST /table/create
  - Required: name, schema
  - Optional: description

- [x] `update_table(table_id::String; updates::Dict)` - Update table data
  - Endpoint: POST /table/{table_id}/update
  - Required: table_id, updates

- [x] `query_table(table_id::String; query::Dict)` - Query table data
  - Endpoint: POST /table/{table_id}/query
  - Required: table_id, query

## File API (`src/files.jl`)
- [x] `create_file(name::String, content::Vector{UInt8})` - Create a new file
  - Endpoint: POST /file/create
  - Required: name, content
  - Optional: description

- [x] `get_file_content(file_id::String)` - Get file content
  - Endpoint: GET /file/{file_id}/content
  - Required: file_id

## Implementation Notes
- All functions will use the global `PROJECT_ID = "demo-weaveloggers"`
- Authentication handled by global `WANDB_API_KEY`
- Input processing through global `PREPROCESS_INPUTS` vector
- Output processing through global `POSTPROCESS_INPUTS` vector

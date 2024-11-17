using Test
using Aqua
using Statistics
using Dates
using DataFrames
using Tables

# Import WeaveLoggers first to ensure error types are available
using WeaveLoggers

# Load test utilities after WeaveLoggers to ensure all types are available
include("TestUtils.jl")
using .TestUtils

# Re-import WeaveLoggers to allow proper mocking
using WeaveLoggers

# Define test-specific methods for WeaveLoggers functions
function WeaveLoggers.weave_api(
        method::String, endpoint::String, body::Union{Dict, Nothing} = nothing;
        base_url::String = "", query_params::Dict{String, String} = Dict{String, String}())
    TestUtils.MockAPI.weave_api(
        method, endpoint, body; base_url = base_url, query_params = query_params)
end

# Define test-specific methods for API functions used by macros
function WeaveLoggers.Calls.start_call(id::String; kwargs...)
    TestUtils.MockAPI.start_call(id; kwargs...)
end

function WeaveLoggers.Calls.end_call(id::String; kwargs...)
    TestUtils.MockAPI.end_call(id; kwargs...)
end

function WeaveLoggers.create_table(
        name::String, data::DataFrame, tags::Vector{Symbol} = Symbol[])
    TestUtils.MockAPI.create_table(name, data, tags)
end

function WeaveLoggers.create_table(
        name::String, data::T, tags::Vector{Symbol} = Symbol[]) where {T}
    if Tables.istable(data)
        TestUtils.MockAPI.create_table(name, data, tags)
    else
        throw(ArgumentError("Data must be Tables.jl-compatible"))
    end
end

# Convenience method for variadic tags
function WeaveLoggers.create_table(name::String, data::Any, tags::Symbol...)
    WeaveLoggers.create_table(name, data, collect(tags))
end

function WeaveLoggers.create_table(
        name::String, data::Symbol, tags::Vector{Symbol} = Symbol[])
    throw(ArgumentError("Data must be Tables.jl-compatible"))
end

function WeaveLoggers.Files.create_file(
        name::String, path::Union{String, Nothing}, tags::Vector{Symbol} = Symbol[])
    TestUtils.MockAPI.create_file(name, path, tags)
end

# Reset mock results before running tests
empty!(mock_results.start_calls)
empty!(mock_results.end_calls)
empty!(mock_results.table_calls)
empty!(mock_results.file_calls)

@testset "WeaveLoggers.jl" begin
    include("test_utils.jl")

    # Run macro tests first (these use mock API functions)
    @testset "Macro Tests" begin
        include("test_macros.jl")
    end

    # Then run API integration tests if API key is available
    if haskey(ENV, "WANDB_API_KEY")
        @testset "API Integration Tests" begin
            include("test_weave_api.jl")
        end
    else
        @warn "Skipping API integration tests: WANDB_API_KEY not set"
    end

    # Then run code quality tests
    @testset "Code quality (Aqua.jl)" begin
        # Skip ambiguities test as they are in external packages
        Aqua.test_all(WeaveLoggers; ambiguities = false)
    end
end

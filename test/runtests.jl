using Test
using Aqua
using Statistics
using Dates

# Load test utilities first to ensure mock implementations are available
include("TestUtils.jl")
using .TestUtils

# Import WeaveLoggers after TestUtils to allow proper mocking
using WeaveLoggers

# Define test-specific methods for WeaveLoggers functions
function WeaveLoggers.weave_api(method::String, endpoint::String, body::Union{Dict,Nothing}=nothing;
                               base_url::String="", query_params::Dict{String,String}=Dict{String,String}())
    TestUtils.MockAPI.weave_api(method, endpoint, body; base_url=base_url, query_params=query_params)
end

@testset "WeaveLoggers.jl" begin
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
        Aqua.test_all(WeaveLoggers)
    end
end

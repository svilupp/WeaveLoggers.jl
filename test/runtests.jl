using WeaveLoggers
using Test
using Aqua

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

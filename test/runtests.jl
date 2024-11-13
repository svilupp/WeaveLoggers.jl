using WeaveLoggers
using Test
using Aqua

# First check if we have the required API key
if !haskey(ENV, "WANDB_API_KEY")
    error("WANDB_API_KEY environment variable is required for testing")
end

@testset "WeaveLoggers.jl" begin
    # First run the API integration tests
    @testset "API Integration Tests" begin
        include("test_weave_api.jl")
    end

    # Then run code quality tests
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(WeaveLoggers)
    end
end

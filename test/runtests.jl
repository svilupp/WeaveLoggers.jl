using WeaveLoggers
using Test
using Aqua

@testset "WeaveLoggers.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(WeaveLoggers)
    end
    # Write your tests here.
end

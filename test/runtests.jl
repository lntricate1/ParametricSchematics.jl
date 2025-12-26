using ParametricSchematics
using Test
using Aqua
using JET

@testset "ParametricSchematics.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ParametricSchematics)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(ParametricSchematics; target_defined_modules = true)
    end
    # Write your tests here.
end

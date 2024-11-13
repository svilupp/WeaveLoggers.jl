using Test
using WeaveLoggers
using DataFrames
using Tables

@testset "Table and File Macros" begin
    @testset "@wtable macro" begin
        # Test data
        df = DataFrame(a = 1:3, b = ["x", "y", "z"])
        nt = [(a=1, b="x"), (a=2, b="y"), (a=3, b="z")]

        # Test with DataFrame
        @test_nowarn @wtable "test_table" df :tag1 :tag2
        @test_nowarn @wtable df :tag1 :tag2

        # Test with NamedTuple
        @test_nowarn @wtable "test_nt" nt :tag1
        @test_nowarn @wtable nt :tag1

        # Test error cases
        @test_throws ArgumentError @wtable
        @test_throws ArgumentError @wtable "name_only"
        @test_throws ArgumentError @wtable [1, 2, 3]  # Not Tables.jl-compatible
    end

    @testset "@wfile macro" begin
        # Create test files
        test_file = "test_file.txt"
        write(test_file, "test content")

        try
            # Test with explicit name
            @test_nowarn @wfile "custom_name.txt" test_file :test :file

            # Test with nothing as name (uses basename)
            @test_nowarn @wfile nothing test_file :test

            # Test without name (uses basename)
            @test_nowarn @wfile test_file :test

            # Test error cases
            @test_throws ArgumentError @wfile
            @test_throws ArgumentError @wfile "nonexistent.txt"

            # Test with various file types
            json_file = "test.json"
            write(json_file, """{"test": true}""")
            try
                @test_nowarn @wfile json_file :json
            finally
                rm(json_file, force=true)
            end

            # Test with spaces in filename
            space_file = "test file.txt"
            write(space_file, "test content")
            try
                @test_nowarn @wfile "custom name.txt" space_file :test
            finally
                rm(space_file, force=true)
            end
        finally
            # Cleanup
            rm(test_file, force=true)
        end
    end
end

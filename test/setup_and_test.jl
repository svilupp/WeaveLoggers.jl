using Pkg
Pkg.develop(path="..")
Pkg.instantiate()
Pkg.test("WeaveLoggers")

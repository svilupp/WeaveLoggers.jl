using WeaveLoggers
using Documenter

DocMeta.setdocmeta!(WeaveLoggers, :DocTestSetup, :(using WeaveLoggers); recursive=true)

makedocs(;
    modules=[WeaveLoggers],
    authors="J S <49557684+svilupp@users.noreply.github.com> and contributors",
    sitename="WeaveLoggers.jl",
    format=Documenter.HTML(;
        canonical="https://svilupp.github.io/WeaveLoggers.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/svilupp/WeaveLoggers.jl",
    devbranch="main",
)

using ParametricSchematics
using Documenter

DocMeta.setdocmeta!(ParametricSchematics, :DocTestSetup, :(using ParametricSchematics); recursive=true)

makedocs(;
    modules=[ParametricSchematics],
    authors="Ellie <intricatebread@gmail.com> and contributors",
    sitename="ParametricSchematics.jl",
    format=Documenter.HTML(;
        canonical="https://lntricate1.github.io/ParametricSchematics.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/lntricate1/ParametricSchematics.jl",
    devbranch="main",
)

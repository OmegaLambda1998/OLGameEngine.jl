using Documenter
push!(LOAD_PATH, "../src/")
using OLGameEngine

DocMeta.setdocmeta!(OLGameEngine, :DocTestSetup, :(using OLGameEngine); recursive=true)

makedocs(
    sitename="OLGameEngine Documentation",
    modules = [OLGameEngine],
    pages = [
        "OLGameEngine" => "index.md",
        "API" => "api.md"
    ],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
    )
)

deploydocs(
    repo = "github.com/OmegaLambda1998/OLGameEngine.jl.git"
)

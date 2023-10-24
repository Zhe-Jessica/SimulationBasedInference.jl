module SimulationBasedInference

using Reexport

# Utility
@reexport using ComponentArrays
using Dates
using FileIO
using LinearAlgebra
using Requires

# SciML/DiffEq
using CommonSolve
using DiffEqBase, SciMLBase

# Stats
using Bijectors
@reexport using Distributions
using LogDensityProblems
using MCMCChains
using Random
using StatsBase
using Statistics

export logprob

"""
    logprob(d::Distribution, x)

Calculate the log probability of `x` under the given distribution `d`.
"""
logprob(d::Distribution, x) = logpdf(d, x)

export SimulatorInferenceAlgorithm

abstract type SimulatorInferenceAlgorithm end

export autoprior, from_moments
include("utils.jl")

export SimulatorObservable, BufferedObservable
export samplepoints, observe!, retrieve
include("observables.jl")

export ParameterMapping
include("param_map.jl")

export AbstractPrior, PriorDistribution
include("priors.jl")

export MvGaussianLikelihood, IsotropicGaussianLikelihood, DiagonalGaussianLikelihood
include("likelihoods.jl")

export SimulatorForwardProblem, SimulatorForwardSolution, SimulatorInferenceProblem, SimulatorInferenceSolution
include("problems.jl")

export SimulatorForwardDEIntegrator
include("forward_diffeq.jl")

include("Ensemble/Ensemble.jl")
@reexport using .Ensemble

# include("Emulators/Emulators.jl")
# @reexport using .Emulators

function __init__()
    # Extension loading;
    # We use Requires.jl instead of built-in extensions for now (v1.9.3).
    # This is due to built-in extensions having the incredibly unfortunate limitation
    # of not being loadable or exportable at precompile time... so there is no way to
    # re-export types defined within them.
    @require Turing="fce5fe82-541a-59a6-adf8-730c64b5f9a0" begin
        include("../ext/SimulationBasedInferenceTuringExt/SimulationBasedInferenceTuringExt.jl")
        @reexport using .SimulationBasedInferenceTuringExt
    end
    @require OrdinaryDiffEq="1dea7af3-3e70-54e6-95c3-0bf5283fa5ed" begin
        include("../ext/SimulationBasedInferenceOrdinaryDiffEqExt/SimulationBasedInferenceOrdinaryDiffEqExt.jl")
    end
end

end

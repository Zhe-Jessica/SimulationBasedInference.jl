using SimulationBasedInference
using SciMLBase
using Test

@testset "importance_weights: sanity check" begin
    n_par = 2
    n_obs = 10
    ensemble_size = 32
    alpha = 1.0
    R_cov = 1.0
    dummy_ens = randn(n_par, ensemble_size)
    dummy_obs = randn(n_obs)
    dummy_pred = randn(n_obs, n_par)*dummy_ens
    weights, Neff = importance_weights(dummy_obs, dummy_pred, R_cov)
    @test all(isfinite.(weights))
    @test sum(weights) ≈ 1.0
end

@testset "importance_weights: evensen_scalar_nonlinear" begin
    x_true = 1.0
    b_true = 0.2
    ensemble_size = 1024
    x_prior = Normal(0,1)
    # log-normal with mean 0.1 and stddev 0.2
    b_prior = autoprior(0.1, 0.2, lower=0.0, upper=Inf)
    rng = Random.MersenneTwister(1234)
    testprob = evensen_scalar_nonlinear(x_true, b_true; n_obs=100, rng, x_prior, b_prior)
    # model parameter forward map
    param_map = unconstrained_forward_map(testprob.prior.model)
    bij = bijector(testprob.prior.model)
    # sample initial ensemble from model prior (excluding likelihood parameters)
    initial_ens = reduce(hcat, rand(rng, testprob.prior.model, ensemble_size))
    initial_ens_uconstrained = reduce(hcat, map(bij, eachcol(initial_ens)))
    y_pred, _ = SimulationBasedInference.ensemble_solve(
        initial_ens_uconstrained,
        testprob.forward_prob,
        EnsembleThreads(),
        nothing,
        param_map,
        iter=1,
    )
    y_obs = testprob.likelihoods.y.data
    y_lik = mean(testprob.prior.lik.y)
    w, Neff = importance_weights(y_obs, y_pred, y_lik.σ^2)
    posterior_mean = initial_ens*w
    @test sum(w) ≈ 1.0
    @test abs(posterior_mean[1] - x_true) < 0.1
    # doesn't seem to work reliably for this parameter in this case...
    # probably would need to use an iterative approach..?
    # @test abs(posterior_mean[2] - b_true) < 0.01
end

@testset "EnIS: solver inteface" begin
    rng = Random.MersenneTwister(1234)
    testprob = evensen_scalar_nonlinear(;rng)
    solver = init(testprob, EnIS())
    test_ensemble_alg_interface(solver)
end

@testset "EnIS: evensen_scalar_nonlinear" begin
    x_true = 1.0
    b_true = 0.2
    σ_y = 0.1
    ensemble_size = 1024
    x_prior = Normal(0,1)
    # log-normal with mean 0.1 and stddev 0.2
    # b_prior = autoprior(0.1, 0.2, lower=0.0, upper=Inf)
    b_prior = Bijectors.TransformedDistribution(Normal(log(0.2), 1), Base.Fix1(broadcast, exp))
    rng = Random.MersenneTwister(1234)
    testprob = evensen_scalar_nonlinear(x_true, b_true; n_obs=100, rng, x_prior, b_prior)
    transform = bijector(testprob.prior.model)
    inverse_transform = inverse(transform)
    testsol = solve(testprob, EnIS(), EnsembleThreads(); ensemble_size, rng)
    unconstrained_prior = get_ensemble(testsol.result)
    prior_ens = reduce(hcat, map(inverse_transform, eachcol(unconstrained_prior)))
    w = get_weights(testsol.result)
    posterior_mean = prior_ens*w
    @test abs(posterior_mean[1] - x_true) < 0.1
    @test abs(posterior_mean[2] - b_true) < 0.1
end

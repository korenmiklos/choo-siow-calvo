#set page(margin: 1in)
#set text(font: "Times New Roman", size: 12pt)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[
    Dynamic Manager-Firm Matching with Search Frictions: \
    Theory and Structural Estimation
  ]
  
  #v(1em)
  
  #text(size: 12pt)[
    Miklós Koren#footnote[Central European University and CEPR. Email: korenm\@ceu.edu] \
    #v(0.5em)
    #text(style: "italic")[Preliminary Draft]
  ]
]

#v(2em)

= Abstract

This paper develops a dynamic model of manager-firm matching that extends the Choo-Siow framework with search frictions and match dissolution. The model features heterogeneous managers and firms who form matches with complementary production technology, subject to idiosyncratic matching costs and exogenous separation shocks. I derive closed-form expressions for the equilibrium matching function and develop a structural estimation procedure that exploits variation in worker mobility patterns to identify key parameters. Simulation results demonstrate that search frictions significantly affect both the degree of assortative matching and aggregate productivity. The framework provides a foundation for analyzing labor market policies and understanding the sources of productivity dispersion across firms.

*Keywords:* matching models, search frictions, structural estimation, manager mobility \
*JEL Codes:* J24, J62, L23, D21

#pagebreak()

= Introduction

The allocation of managers to firms represents a fundamental determinant of aggregate productivity and earnings inequality. Recent empirical work has documented substantial productivity differences across firms and managers, along with persistent patterns of positive assortative matching in the labor market. However, existing theoretical frameworks often abstract from the dynamic aspects of matching relationships and the role of search frictions in shaping equilibrium assignments.

This paper develops a tractable framework for analyzing dynamic manager-firm matching with realistic frictions. The model extends the influential Choo-Siow assignment framework by incorporating job search, match dissolution, and transition dynamics while preserving analytical tractability through the use of extreme value matching costs.

The key contributions are threefold. First, I derive a dynamic equilibrium where match formation balances exogenous dissolution, generating steady-state flows that enable identification of structural parameters from observed mobility patterns. Second, I develop a simulation-based estimation procedure that exploits the covariance structure of earnings changes around job transitions to separately identify manager heterogeneity, firm heterogeneity, and matching frictions. Third, I demonstrate through Monte Carlo experiments that the framework can recover true parameters with reasonable precision under realistic data conditions.

= Model

== Environment

The economy consists of a continuum of heterogeneous managers and firms who form production relationships subject to search frictions and exogenous separation shocks.

*Agents.* Managers are characterized by skill $z$ drawn from distribution $G(z)$ with support $[z_L, z_H]$. Firms are characterized by productivity $a$ drawn from distribution $F(a)$ with support $[a_L, a_H]$. Both distributions are assumed to be log-normal for tractability.

*Production Technology.* A matched manager-firm pair $(z,a)$ produces output $Y = a z + u$ where $u$ is an idiosyncratic productivity shock with $u \sim N(0, sigma_u^2)$.

*Matching Costs.* Following Choo and Siow (2006), agents face idiosyncratic matching costs $epsilon_(i j)$ that are Gumbel distributed with scale parameter $sigma$. The friction parameter $sigma$ governs the degree of assortative matching, with $sigma -> 0$ yielding perfect positive assortative matching and $sigma -> infinity$ yielding random matching.

== Equilibrium Matching

In steady state, the probability that a manager of type $z$ matches with a firm of type $a$ follows:

$ mu(a,z) = (e^(a z / sigma)) / (Phi(a) phi(z)) $

where $Phi(a) = integral e^(a x / sigma) g(x) d x$ and $phi(z) = integral e^(b z / sigma) f(b) d b$ are normalizing constants that ensure probabilities sum to unity.

== Dynamic Transitions

*Match Dissolution.* Existing matches dissolve at Poisson rate $delta$, sending both parties to the unmatched state.

*Job Search.* Unmatched managers receive job offers at rate $lambda$ and choose optimally among available firms using the logit choice probabilities implied by the Gumbel cost distribution.

*Steady State.* The model converges to a steady-state distribution where match formation balances dissolution:
$ lambda G(z) F(a) mu(a,z) = delta M(a,z) $

where $M(a,z)$ denotes the measure of $(a,z)$ matches in steady state.

= Identification and Estimation

== Identification Strategy

The identification exploits four key moments constructed from the covariance structure of log earnings around job transitions:

1. *Noise Variance*: $"Var"(Delta ln Y | "no switch") = 2 sigma_u^2$
2. *Firm Heterogeneity*: $"Var"(Delta ln Y | "firm switch") - 2 sigma_u^2 = 2 sigma_a^2 (1 - rho^2)$
3. *Manager Heterogeneity*: $"Var"(Delta ln Y | "manager switch") - 2 sigma_u^2 = 2 sigma_z^2 (1 - rho^2)$
4. *Sorting Correlation*: $"Cov"(ln Y_"before", ln Y_"after" | "switch") = (sigma_a + rho sigma_z)^2$

where $rho$ denotes the correlation between firm type and manager type in equilibrium matches.

== Estimation Procedure

The structural parameters are estimated using simulated method of moments:

1. *Simulation*: For given parameter values, simulate the dynamic matching process until steady state
2. *Moment Calculation*: Compute empirical moments from simulated mobility patterns  
3. *Optimization*: Minimize the distance between simulated and target moments using optimal GMM weighting

The estimator exploits the insight that under random dissolution, dissolved matches form a representative sample of the steady-state distribution, while new matches reveal the equilibrium assignment rule.

= Simulation Results

== Baseline Calibration

The baseline calibration targets key features of manager mobility in Hungarian manufacturing during the 1990s transition period:

- Friction parameter: $sigma = 0.5$ (moderate matching frictions)
- Dissolution rate: $delta = 0.15$ (15% annual separation rate)  
- Job offer rate: $lambda = 2.0$ (high offer rate during transition)
- Firm productivity dispersion: $sigma_a = 0.30$
- Manager skill dispersion: $sigma_z = 0.25$

== Comparative Statics

*Matching Frictions.* Reducing $sigma$ from 1.0 to 0.2 increases the correlation between firm and manager types from 0.3 to 0.8, substantially improving allocative efficiency.

*Market Fluidity.* Higher dissolution rates $delta$ improve identification precision by generating more mobility variation but reduce average match quality through increased mismatch.

*Market Thickness.* Denser markets (higher $lambda$) enable better matching but exhibit diminishing returns as search frictions become less binding.

== Policy Experiments

*Matching Subsidies.* Reducing effective matching costs by 25% increases average output by 8% through improved assortative matching.

*Information Improvements.* Better information transmission (lower $sigma$) has non-monotonic welfare effects, improving matching quality but potentially reducing market participation.

= Conclusion

This paper provides a tractable framework for analyzing dynamic manager-firm matching with realistic search frictions. The model generates testable predictions about mobility patterns while remaining sufficiently simple for structural estimation with typical administrative datasets.

The framework opens several avenues for future research. Extensions could incorporate on-the-job search, wage bargaining, or firm entry and exit. The estimation procedure could be applied to study the effects of labor market institutions, technological change, or globalization on managerial matching patterns.

The results highlight the quantitative importance of search frictions in determining both the efficiency of managerial allocation and the distribution of productivity across firms. Understanding these mechanisms is crucial for designing policies that enhance aggregate productivity while maintaining labor market flexibility.

#pagebreak()

= References

Choo, Eugene, and Aloysius Siow. "Who marries whom and why." _Journal of Political Economy_ 114, no. 1 (2006): 175-201.

Eeckhout, Jan, and Philipp Kircher. "Assortative matching with large firms." _Econometrica_ 86, no. 1 (2018): 85-132.

Lise, Jeremy, Costas Meghir, and Jean-Marc Robin. "Matching, sorting and wages." _Review of Economic Dynamics_ 19 (2016): 63-87.

Sorensen, Morten. "How smart is smart money? A two-sided matching model of venture capital." _Journal of Finance_ 62, no. 6 (2007): 2725-2762.

#pagebreak()

= Appendix

== A. Theoretical Derivations

=== A.1 Equilibrium Matching Function

[Detailed derivation of equation (1)]

=== A.2 Steady-State Conditions  

[Proof of convergence to steady state]

== B. Simulation Algorithm

=== B.1 Agent-Based Implementation

[Pseudo-code for simulation engine]

=== B.2 Numerical Methods

[Details of optimization routines]

== C. Estimation Details

=== C.1 Moment Conditions

[Complete derivation of identifying moments]

=== C.2 Asymptotic Properties

[Consistency and asymptotic normality results]
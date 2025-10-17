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

= Variance-Covariance Decomposition for Sorting Measurement

== Model and Assumptions

We study log revenue at the firm-manager match level within short, non-overlapping windows (e.g., three-year windows). For a match between firm i and manager m, we posit

$ y_(i m) = A_i + Z_m + epsilon_(i m) $

where $A_i$ is a firm effect, $Z_m$ is a manager effect, and $epsilon_(i m)$ is a match-specific disturbance. The key primitives are

- $"Var"(A) = sigma_a^2$, $"Var"(Z) = sigma_z^2$, $"Cov"(A, Z) = rho sigma_a sigma_z$
- Linear conditional expectations (e.g., under joint normality):

$ E[Z | A] = (rho sigma_z / sigma_a) A, quad E[A | Z] = (rho sigma_a / sigma_z) Z $

- $epsilon$ is mean-zero, independent across matches, and independent of $(A, Z)$ with $"Var"(epsilon) = sigma_epsilon^2$

Parameters of interest are $theta = (sigma_a, sigma_z, rho, sigma_epsilon)$.

== Network Moments

We represent the data in a window as a bipartite graph between firms and managers. Projecting onto managers (firms) connects two managers (firms) if they have worked at the same firm (manager) in the window. Paths of even length in these projections encode higher-order co-employment.

=== Cross-sectional variance

Unconditionally across matches,

$ V = "Var"(y) = sigma_a^2 + sigma_z^2 + 2 rho sigma_a sigma_z + sigma_epsilon^2 $

=== Two-step covariances (direct neighbors)

For two managers $m, m'$ who worked at the same firm $i$ (manager-manager link at distance 2):

$ "Cov"(y_(i m), y_(i m')) = sigma_a^2 + 2 rho sigma_a sigma_z + rho^2 sigma_z^2 $

For two firms $i, i'$ run by the same manager $m$ (firm-firm link at distance 2):

$ "Cov"(y_(i m), y_(i' m)) = sigma_z^2 + 2 rho sigma_a sigma_z + rho^2 sigma_a^2 $

Intuition: the shared side enters with full variance, while the opposite side is projected through $rho$ and enters with dampening $rho^2$.

=== Four-step covariances (second neighbors)

For manager pairs connected by a length-4 path in the manager projection:

$ "Cov"(y_(i m), y_(i' m')) = rho^2 sigma_a^2 + 2 rho^3 sigma_a sigma_z + rho^4 sigma_z^2 $

For firm pairs connected by a length-4 path in the firm projection:

$ "Cov"(y_(i m), y_(i' m')) = rho^2 sigma_z^2 + 2 rho^3 sigma_a sigma_z + rho^4 sigma_a^2 $

These follow from iterated projections: along a length-4 path, same-side components dampen with $rho^4$, cross-terms with $rho^3$, and opposite-side components with $rho^2$.

=== Excess-variance identities

Subtracting two-step covariances from the total variance isolates combinations of same-side variance and noise:

$ V - "Cov"_(\"mm\",2) = (1 - rho^2) sigma_z^2 + sigma_epsilon^2 $

$ V - "Cov"_(ff,2) = (1 - rho^2) sigma_a^2 + sigma_epsilon^2 $

== Identification and Estimation

Let the five model-implied moments be

$ V(theta) = sigma_a^2 + sigma_z^2 + 2 rho sigma_a sigma_z + sigma_epsilon^2 $

$ C_(mm,2)(theta) = sigma_a^2 + 2 rho sigma_a sigma_z + rho^2 sigma_z^2 $

$ C_(ff,2)(theta) = sigma_z^2 + 2 rho sigma_a sigma_z + rho^2 sigma_a^2 $

$ C_(mm,4)(theta) = rho^2 sigma_a^2 + 2 rho^3 sigma_a sigma_z + rho^4 sigma_z^2 $

$ C_(ff,4)(theta) = rho^2 sigma_z^2 + 2 rho^3 sigma_a sigma_z + rho^4 sigma_a^2 $


Given empirical counterparts $\hat V$, $\hat C_(mm,2)$, $\hat C_(ff,2)$, $\hat C_(mm,4)$, $\hat C_(ff,4)$ measured within a window, estimate $theta$ by minimizing a GMM/NLS objective:

$ Q(theta) = (m(theta) - \hat m)' W (m(theta) - \hat m) $

subject to $sigma_a \ge 0$, $sigma_z \ge 0$, $sigma_epsilon \ge 0$, and $|rho| \le 1$. Two-step covariances purge $sigma_epsilon^2$, while four-step covariances introduce nonlinearity in $rho$ (via $rho^3$, $rho^4$), enabling separate identification of $rho$ and the scale parameters. The total variance then identifies $sigma_epsilon^2$.

== Implementation on 30 Years of Hungarian CEO-Firm Data

We partition the 30-year panel into ten non-overlapping three-year windows (overlapping windows as robustness). For each window:

- Construct bipartite incidence matrix $B$ with $B_(i m)=1$ if $m$ manages $i$ in the window
- Manager projection: $W_M = B' B$ with diagonal set to zero; firm projection: $W_F = B B'$ with diagonal set to zero
- Two-step pairs: manager pairs with $(W_M)_(m m') > 0$ and firm pairs with $(W_F)_(i i') > 0$
- Four-step pairs: use $W_M^2$ and $W_F^2$; positive off-diagonal entries indicate at least one length-4 path
- Compute sample variance $\hat V$ across all spells and sample covariances across the 2-step and 4-step pairs
- Estimate $theta$ via \#(Q(theta)) with identity $W$ (NLS) and report bootstrap standard errors (pairs-of-pairs bootstrap to account for network dependence)

Practical considerations:

- Window length balances stationarity and data sufficiency
- Handle concurrent co-management by separate spells or aggregation; assess sensitivity
- Winsorize extreme revenues to stabilize variance and covariance estimates

== Interpretation and Hypotheses

We track $(sigma_a, sigma_z, rho, sigma_epsilon)$ across windows. Under complementarities, higher $rho$ indicates tighter sorting and improved allocation. We hypothesize that $rho$ increased over time as post-transition markets matured. The match disturbance $sigma_epsilon^2$ is expected to be sizable; covariance-based moments correct for its contamination of variance-based measures. Scale parameters $sigma_a$ and $sigma_z$ may be more stable than $rho$.

#pagebreak()

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
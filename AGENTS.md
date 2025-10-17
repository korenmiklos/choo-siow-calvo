# Agent-Based Simulation and Structural Estimation of Manager-Firm Matching

This project develops an agent-based simulation and structural estimation framework for studying manager-firm matching with frictions. The model extends the Choo-Siow assignment framework with Calvo-style match dissolution to create a dynamic matching environment suitable for both theoretical analysis and empirical estimation.

## Model Overview

### Core Framework

The model features heterogeneous agents on both sides of the market:
- **Managers** with skill distribution $z \sim G(z)$
- **Firms** with productivity distribution $a \sim F(a)$  
- **Match production** following $Y = az$ (multiplicative complementarity)
- **Gumbel-distributed idiosyncratic matching costs** with scale parameter $\sigma$

### Matching Technology

Following Choo and Siow (2006), the equilibrium matching probability between firm type $a$ and manager type $z$ is:

$$\mu(a,z) = \frac{e^{az/\sigma}}{\int e^{ax/\sigma}dx \int e^{by/\sigma}dy} = e^{az/\sigma}\Phi(a)\phi(z)$$

The friction parameter $\sigma$ controls the degree of assortative matching:
- As $\sigma \to 0$: Perfect positive assortative matching
- As $\sigma \to \infty$: Random matching

### Dynamic Extensions

**Calvo Match Dissolution**: Existing matches dissolve at exogenous Poisson rate $\delta$, creating flows of unmatched agents who re-enter the matching market.

**Job Search**: Unemployed managers receive job offers at rate $\lambda$ and choose optimally among available firms using logit choice probabilities.

**Steady State**: The model converges to a steady-state distribution where match formation balances match dissolution, enabling identification of structural parameters from mobility patterns.

## Implementation Architecture

### Agent Classes

**Manager Agents**:
- Unique identifier
- Skill level (continuous)
- Employment status (employed/unemployed)
- Current firm assignment
- Unemployment duration
- Value function

**Firm Agents**:
- Unique identifier
- Productivity level (continuous)
- Employment status (matched/vacant)
- Current manager assignment
- Vacancy duration
- Value function

### Market Structure

**Matching Market**:
- Collections of managers and firms
- Active matches with associated values
- Pools of unmatched agents
- Model parameters
- Time tracking

**Model Parameters**:
- Friction parameter σ
- Match dissolution rate δ
- Job offer arrival rate λ
- Discount rate ρ
- Market size (number of agents)

### Simulation Engine

The simulation follows these key steps each period:

1. **Match Dissolution**: Randomly dissolve existing matches with probability $\delta \Delta t$
2. **Job Search**: Generate job offers for unemployed managers with rate $\lambda$
3. **Optimal Choice**: Managers choose among offers using logit probabilities
4. **Market Clearing**: Form new matches and update agent states
5. **Data Collection**: Record match formations, dissolutions, and outcomes

### Equilibrium Computation

Iterative algorithm to compute steady-state equilibrium:
- Update value functions for managers and firms
- Check convergence of assignment probabilities
- Iterate until tolerance threshold met

## Structural Estimation Framework

### Moment Conditions from Mobility Networks

The estimation exploits variance-covariance decomposition across manager-firm pairs at different path lengths in the projected mobility network. Log revenue decomposes as $y_{im} = a_i + z_m + \varepsilon_{im}$ where $a_i$ is log firm effect and $z_m$ is log manager effect:

1. **Total Variance**: $V = \sigma_a^2 + \sigma_z^2 + 2\rho\sigma_a\sigma_z + \sigma_\varepsilon^2$
2. **Manager-Manager 2-step Covariance**: $C_{\text{mm},2} = \sigma_a^2 + 2\rho\sigma_a\sigma_z + \rho^2\sigma_z^2$
3. **Firm-Firm 2-step Covariance**: $C_{\text{ff},2} = \sigma_z^2 + 2\rho\sigma_a\sigma_z + \rho^2\sigma_a^2$
4. **Manager-Manager 4-step Covariance**: $C_{\text{mm},4} = \rho^2 \cdot C_{\text{mm},2}$
5. **Firm-Firm 4-step Covariance**: $C_{\text{ff},4} = \rho^2 \cdot C_{\text{ff},2}$

The key insight is that each additional step in the network path introduces a factor of $\rho$, so 4-step covariances are simply $\rho^2$ times the 2-step covariances. This permits constructive identification.

### Constructive Estimation via Covariance Ratios

**Direct Identification**:
The ratio of 4-step to 2-step covariances directly identifies $\rho^2$:
$$\rho^2 = \frac{C_{\text{mm},4}}{C_{\text{mm},2}} = \frac{C_{\text{ff},4}}{C_{\text{ff},2}}$$

This ratio cancels all variance and cross-product terms, isolating the sorting parameter. The two ratios provide consistency checks.

**Path Attenuation Interpretation**:
The ratio measures how correlation decays as we move further in the mobility network. A 4-step path $m_1 \leftrightarrow i \leftrightarrow m_2 \leftrightarrow i' \leftrightarrow m_3$ requires two additional "hops" through the matching process compared to a 2-step connection. Each hop introduces one factor of $\rho$, giving $\rho^2$ attenuation. This provides transparent identification: observe how quickly covariances decay with network distance to infer the strength of sorting.

**Sequential Estimation Procedure**:
1. Construct bipartite manager-firm graph from mobility data
2. Compute sample moments: $\widehat{V}$, $\widehat{C}_{\text{mm},2}$, $\widehat{C}_{\text{ff},2}$, $\widehat{C}_{\text{mm},4}$, $\widehat{C}_{\text{ff},4}$
3. Estimate $\widehat{\rho}^2$ from covariance ratios, averaging manager and firm estimates
4. Solve for $\widehat{\sigma}_a$ and $\widehat{\sigma}_z$ using difference and sum of 2-step covariances
5. Recover $\widehat{\sigma}_\varepsilon$ as residual from total variance
6. Bootstrap standard errors resampling by firm and manager blocks

**Concentrated GMM Alternative**:
For robustness and efficiency with higher-order paths (6-step, 8-step), use concentrated GMM:
- For any candidate $\rho$, solve analytically for $(\sigma_a(\rho), \sigma_z(\rho), \sigma_\varepsilon(\rho))$
- Minimize weighted distance between observed and predicted higher-order covariances
- Computational complexity remains 1D optimization over $\rho \in [-1,1]$
- Useful for testing overidentifying restrictions and combining multiple path lengths

**Estimation Results Structure**:
- Standard deviation of log firm effect (σ_a)
- Standard deviation of log manager effect (σ_z)
- Correlation between firm and manager types (ρ)
- Match-specific noise standard deviation (σ_ε)
- Objective function value and convergence status

### Identification Strategy

Identification relies on path-length decay in the mobility network:
- **2-step covariances** (same firm/manager): Identify linear combinations of variances without noise contamination
- **4-step covariances** (second-degree connections): Scale 2-step covariances by exactly $\rho^2$, enabling direct identification via ratios
- **Total variance**: Recovers match-specific noise after controlling for systematic components
- **Overidentification**: Two 4-step moments (manager and firm sides) provide consistency checks and specification testing

## Simulation Experiments

### Baseline Calibration

Based on Hungarian manufacturing data (1990s transition period):
- Friction parameter σ = 0.5 (moderate matching frictions)
- Dissolution rate δ = 0.15 (15% annual separation rate)
- Job offer rate λ = 2.0 (high offer rate during transition)
- Discount rate ρ = 0.05 (5% annual rate)
- Market size: 1000 managers, 800 firms

### Comparative Statics

**Friction Parameter Effects**:
- Vary $\sigma \in [0.1, 2.0]$ to study sorting strength
- Measure resulting correlation between firm and manager types
- Analyze welfare implications of improved matching

**Dissolution Rate Effects**:
- Vary $\delta \in [0.05, 0.30]$ to study market fluidity
- Examine how turnover affects identification precision
- Compare static vs. dynamic efficiency

**Market Thickness**:
- Study markets with different manager/firm ratios
- Analyze congestion effects in matching
- Examine entry/exit dynamics

### Policy Experiments

**Matching Subsidies**: Reduce effective matching costs to simulate job placement programs
**Information Improvements**: Reduce $\sigma$ to study effects of better information transmission
**Market Regulation**: Impose minimum/maximum wages to study distortions to optimal assignment

## Computational Implementation

### Performance Optimization

**Data Structures**:
- Sparse matrices for large markets
- Efficient storage of agent relationships
- Optimized data access patterns

**Parallel Computing**:
- Monte Carlo experiments across multiple cores
- Shared memory for large datasets
- Distributed simulation for parameter sweeps

**Algorithms**:
- Fast random number generation
- Efficient matching algorithms (Hungarian variants)
- Numerical optimization routines

### Memory Management

For large-scale simulations (N > 10,000 agents):
- Memory pools for agent creation/destruction
- Efficient matching algorithms
- Just-in-time compilation for performance

### Validation Framework

**Model Validation**:
- Compare simulated moments to theoretical predictions
- Statistical tests for moment matching
- Sensitivity analysis for parameter robustness
- Cross-validation using held-out data

## Output and Reporting

### Data Export

Simulation results export to standardized formats:
- **CSV files** for time series of aggregate outcomes
- **Parquet files** for large panel datasets of individual matches
- **JSON files** for model parameters and metadata

### Visualization

**Time Series Analysis**:
- Matching rates and average match quality over time
- Evolution of unemployment and vacancy rates
- Parameter stability across simulation periods

**Cross-Sectional Analysis**:
- Heatmaps of the equilibrium matching function $\mu(a,z)$
- Scatter plots of firm productivity vs. manager skill in observed matches
- Distribution plots of unmatched agent characteristics

### Reporting with Typst

Results compile to professional reports using Typst:

```typst
#import "@preview/tablex:0.0.6": tablex, rowspanx, colspanx

#let results_table(data) = tablex(
  columns: 4,
  align: center + horizon,
  auto-vlines: false,
  repeat-header: true,
  
  [Parameter], [Baseline], [Sensitivity Range], [Identification],
  [Friction σ], [0.50], [0.10 - 2.00], [Match quality variance],
  [Dissolution δ], [0.15], [0.05 - 0.30], [Turnover rates],
  [Correlation ρ], [0.65], [0.40 - 0.85], [Switching covariances],
  [Firm heterogeneity σ_a], [0.30], [0.20 - 0.45], [Firm mobility variance],
  [Manager heterogeneity σ_z], [0.25], [0.15 - 0.40], [Manager mobility variance]
)
```

### Integration with Workflow

Results integrate with the broader project workflow:
- **Input data** from `input/` folder managed by `bead`
- **Simulation code** in `code/simulate/` subfolder
- **Estimation routines** in `code/estimate/` subfolder  
- **Final outputs** to `output/` folder for computational results
- **Research papers** in `papers/` subfolder with separate folders per paper
- **Temporary files** (large simulation datasets) in `temp/`

## Papers

### Random Effects Identification Paper (`papers/random-effects/`)

**Status**: Active development  
**Format**: LaTeX (PNAS submission format)  
**Target**: PNAS or similar high-impact journal (≤12 citations)

**Main Contribution**: Novel identification strategy for random effects models using variance-covariance decomposition across mobility network paths. The key insight is that 4-step covariances equal ρ² times 2-step covariances, enabling direct identification of the sorting parameter via simple ratios.

**Empirical Application**: Hungarian manufacturing data (1985-2018) showing very strong CEO-firm sorting (ρ ≈ 0.89-0.96), with firm effects dominating manager effects (σ_a/σ_z ≈ 10).

**Compilation**: Run `make paper` from project root. Requires pdflatex and bibtex.

This framework provides a comprehensive platform for studying manager-firm matching with realistic frictions, enabling both theoretical insights and robust empirical estimation using modern computational methods.
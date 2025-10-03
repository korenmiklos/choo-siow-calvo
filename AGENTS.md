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

### Moment Conditions

The estimation exploits four key moments from switching patterns:

1. **Noise Variance**: $\text{Var}(\Delta\ln Y | \text{no switch}) = 2\sigma_u^2$
2. **Firm Heterogeneity**: $\text{Var}(\Delta\ln Y | \text{firm switch}) - 2\sigma_u^2 = 2\sigma_a^2(1-\rho^2)$
3. **Manager Heterogeneity**: $\text{Var}(\Delta\ln Y | \text{manager switch}) - 2\sigma_u^2 = 2\sigma_z^2(1-\rho^2)$
4. **Sorting Correlation**: $\text{Cov}(\ln Y_{\text{before}}, \ln Y_{\text{after}} | \text{switch}) = (\sigma_a + \rho\sigma_z)^2$

### GMM Estimation

**Estimation Results Structure**:
- Standard deviation of log firm productivity (σ_a)
- Standard deviation of log manager skill (σ_z)
- Correlation between firm and manager types (ρ)
- Noise standard deviation (σ_u)
- Matching friction parameter (σ_friction)
- Objective function value and convergence status

**Estimation Procedure**:
- Define moment conditions from theoretical model
- Construct GMM objective function using optimal weighting matrix
- Optimize using numerical methods (BFGS or similar)
- Return parameter estimates with standard errors

### Identification Strategy

The identification exploits the insight that under random dissolution:
- **Dissolved matches** form a representative sample of the population
- **New matches** follow the equilibrium assignment rule
- **Correlation structure** in old vs. new manager quality reveals sorting strength

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
- **Final outputs** to `output/` folder for inclusion in papers
- **Temporary files** (large simulation datasets) in `temp/`

This framework provides a comprehensive platform for studying manager-firm matching with realistic frictions, enabling both theoretical insights and robust empirical estimation using modern computational methods.
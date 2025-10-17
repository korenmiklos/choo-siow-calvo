# Dynamic Manager-Firm Matching with Search Frictions: Theory and Structural Estimation

This project develops an agent-based simulation and structural estimation framework for studying manager-firm matching with search frictions. The model extends the Choo-Siow assignment framework with Calvo-style match dissolution to create a dynamic matching environment suitable for both theoretical analysis and empirical estimation.

## Project Overview

### Research Questions

- How do search frictions affect the degree of assortative matching between managers and firms?
- What are the welfare implications of improving matching efficiency in managerial labor markets?
- How can we identify and estimate key structural parameters using observed mobility patterns?

### Model Features

- **Heterogeneous agents**: Managers with skill distribution G(z) and firms with productivity distribution F(a)
- **Multiplicative production**: Output follows Y = az (complementarity between manager skill and firm productivity)
- **Gumbel matching costs**: Friction parameter σ controls degree of assortative matching
- **Dynamic transitions**: Calvo dissolution at rate δ and job search at rate λ
- **Equilibrium matching**: Closed-form matching probabilities μ(a,z) = exp(az/σ)/[Φ(a)φ(z)]

### Key Contributions

1. **Theoretical framework**: Tractable dynamic matching model with analytical solutions
2. **Identification strategy**: Novel approach using mobility patterns to identify structural parameters
3. **Computational implementation**: Efficient agent-based simulation for large-scale markets
4. **Policy analysis**: Framework for evaluating matching subsidies and information improvements

## Repository Structure

```
├── code/               # Organized by purpose
│   ├── simulate/      # Agent-based simulation engine
│   ├── estimate/      # Structural estimation routines
│   ├── create/        # Data creation and manipulation
│   └── plot/          # Visualization and reporting
├── docs/              # Research documentation and notes
│   ├── choo-siow-framework-notes.md
│   ├── steady-state-switching-dynamics.md
│   └── empirical-identification-switching.md
├── papers/            # Research papers
│   └── random-effects/  # Random effects identification paper
│       └── paper.tex    # LaTeX source (PNAS format)
├── input/             # External datasets (managed by bead)
├── output/            # Final computational results
├── temp/              # Temporary computation files
└── Makefile           # Workflow automation
```

## Software Dependencies

### Required Tools

- **Make**: Workflow automation (all targets runnable from root)
- **Bead**: Data dependency management (`bead input load <name>`)
- **Git**: Version control with appropriate .gitignore
- **LaTeX**: TeX Live 2024 with pdflatex and bibtex for paper compilation

### Optional Tools (for future implementation)

- **Julia 1.10+**: High-performance simulation and numerical methods
- **Python 3.11+**: Data analysis with `uv` package management, prefer `polars` over pandas
- **DuckDB 1.2**: Large-scale data processing via SQL
- **Stata 18**: Traditional econometric analysis with .do files

## Usage

### Quick Start

Run the complete workflow:
```bash
make all
```

### Individual Components

```bash
make setup      # Create directory structure
make simulate   # Run agent-based simulation (placeholder)
make estimate   # Structural parameter estimation (placeholder)
make paper      # Compile research paper to PDF
make clean      # Remove temporary files
make help       # Show all available targets
```

### Data Management

External data dependencies are managed by `bead`:
```bash
bead input list           # Show available datasets
bead input load <name>    # Load missing datasets
bead input update <name>  # Update existing datasets
```

## Implementation Status

### Completed Components

- [x] Theoretical framework documentation
- [x] Random effects identification paper (LaTeX, PNAS format)
- [x] Variance-covariance decomposition methodology
- [x] Project organization and workflow automation
- [x] Git repository with proper .gitignore
- [x] Makefile with complete workflow targets

### Research Framework (Planned Implementation)

- [ ] **Agent-based simulation engine**
  - [ ] Manager and firm agent classes with heterogeneous types
  - [ ] Market clearing mechanism with Gumbel matching costs
  - [ ] Calvo dissolution and job search dynamics
  - [ ] Steady-state convergence algorithms

- [ ] **Structural estimation procedures**
  - [ ] Moment conditions from mobility covariances
  - [ ] GMM estimation with optimal weighting matrix
  - [ ] Bootstrap standard errors and model validation
  - [ ] Comparative statics and policy experiments

- [ ] **Data analysis pipeline**
  - [ ] Synthetic data generation for Monte Carlo validation
  - [ ] Integration with administrative datasets
  - [ ] Robustness checks and sensitivity analysis

## Model Specification

### Equilibrium Conditions

The steady-state matching probability between firm type a and manager type z:

```
μ(a,z) = exp(az/σ) / [Φ(a)φ(z)]
```

where Φ(a) and φ(z) are normalizing constants ensuring probabilities sum to unity.

### Identification Strategy

Five moments from mobility network covariances identify four structural parameters (θ = σ_a, σ_z, ρ, σ_ε). Log revenue decomposes as y = a + z + ε where a is log firm effect and z is log manager effect:

1. **Total variance**: V = σ²_a + σ²_z + 2ρσ_aσ_z + σ²_ε
2. **Manager-manager 2-step covariance**: C_mm,2 = σ²_a + 2ρσ_aσ_z + ρ²σ²_z (same firm)
3. **Firm-firm 2-step covariance**: C_ff,2 = σ²_z + 2ρσ_aσ_z + ρ²σ²_a (same manager)
4. **Manager-manager 4-step covariance**: C_mm,4 = ρ² · C_mm,2 (second-degree connections)
5. **Firm-firm 4-step covariance**: C_ff,4 = ρ² · C_ff,2 (second-degree connections)

**Constructive Estimation**: The ratio C_mm,4/C_mm,2 = ρ² directly identifies the sorting parameter by measuring how correlation attenuates with network distance. Moving from 2-step to 4-step paths adds two "hops" through the matching process, each contributing factor ρ, yielding ρ² attenuation.

**Sequential Steps**: (1) Estimate ρ² from covariance ratios, (2) solve for σ_a and σ_z using 2-step covariance differences, (3) recover σ_ε from total variance. All parameters have closed-form solutions.

**Concentrated GMM Alternative**: For higher-order paths (6-step, 8-step) or efficiency gains, fix ρ and solve analytically for other parameters, then search over ρ ∈ [-1,1] to minimize distance between observed and predicted higher-order covariances.

### Policy Applications

The framework enables analysis of:
- **Matching subsidies**: Reduced effective search costs
- **Information improvements**: Lower friction parameter σ
- **Market thickness**: Effects of changing manager/firm ratios
- **Regulatory constraints**: Minimum/maximum wage policies

## Research Context

This project contributes to the growing literature on two-sided matching with frictions. Key references include:

- **Choo and Siow (2006)**: Foundation assignment model with extreme value costs
- **Eeckhout and Kircher (2018)**: Large firm extensions and market thickness
- **Lise, Meghir, and Robin (2016)**: Dynamic matching with wage bargaining

The model bridges theoretical matching theory with empirical identification, providing a practical framework for policy analysis in managerial labor markets.

## Contact

This research framework is developed as part of ongoing work on manager-firm matching dynamics. For questions about the theoretical model or computational implementation, please refer to the documentation in the `docs/` folder or examine the planned code structure in `code/`.

The project follows rigorous computational social science practices with reproducible workflows, version control, and clear documentation standards.
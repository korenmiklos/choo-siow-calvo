# CLAUDE.md - AI Assistant Memory

## Project Summary

**Dynamic Manager-Firm Matching with Search Frictions**: Agent-based simulation and structural estimation framework extending Choo-Siow with Calvo dissolution. Features heterogeneous agents, multiplicative production Y=az, Gumbel matching costs, and dynamic transitions for policy analysis.

## Workflow Commands

### Make Targets
```bash
make all       # Complete workflow: setup + simulate + estimate + paper  
make setup     # Create directory structure
make simulate  # Agent-based simulation (placeholder)
make estimate  # Structural estimation (placeholder) 
make paper     # Compile paper.typ to PDF using Typst
make clean     # Remove temporary files
make help      # Show available targets
```

### Data Management (Bead)
```bash
bead input list           # Show available datasets
bead input load <name>    # Load missing datasets  
bead input update <name>  # Update existing datasets
```

## Project Structure

```
├── code/
│   ├── simulate/    # Agent-based simulation engine
│   ├── estimate/    # Structural estimation routines
│   ├── create/      # Data creation and manipulation
│   └── plot/        # Visualization and reporting
├── docs/            # Research documentation (8 files)
├── input/           # External datasets (bead-managed, gitignored)
├── output/          # Final results (paper.pdf, paper.typ)
├── temp/            # Temporary files (gitignored)
├── .bead-meta/      # Bead metadata
├── Makefile         # Complete workflow automation
├── README.md        # Comprehensive project documentation
└── .gitignore       # Follows user conventions (input/, temp/, generated files)
```

## Key Technologies

- **Typst**: Document compilation (paper.typ → paper.pdf)
- **Bead**: Data dependency management  
- **Make**: Workflow automation from root directory
- **Git**: Version control with korenmiklos/choo-siow-calvo
- **Future**: Julia (simulation), Python+polars (analysis), DuckDB (large data)

## Model Specifications

### Core Framework
- **Agents**: Managers z~G(z), firms a~F(a)
- **Production**: Y = az + u (multiplicative complementarity)  
- **Matching costs**: Gumbel(σ) controls assortative matching
- **Dynamics**: Calvo dissolution (δ), job search (λ)

### Equilibrium Matching
```
μ(a,z) = exp(az/σ) / [Φ(a)φ(z)]
```

### Identification Strategy
Four moments from mobility patterns:
1. Noise variance: Var(Δln Y | no switch) = 2σ²ᵤ
2. Firm heterogeneity: Var(Δln Y | firm switch) - 2σ²ᵤ = 2σ²ₐ(1-ρ²)  
3. Manager heterogeneity: Var(Δln Y | manager switch) - 2σ²ᵤ = 2σ²ᵢ(1-ρ²)
4. Sorting correlation: Cov(ln Y_before, ln Y_after | switch) = (σₐ + ρσᵢ)²

## Implementation Status

### ✅ Completed
- Theoretical framework and documentation (8 files in docs/)
- Paper outline (output/paper.typ) with complete academic structure
- Project organization and Makefile workflow  
- README.md with comprehensive documentation
- Git repository setup with proper .gitignore
- GitHub repository: https://github.com/korenmiklos/choo-siow-calvo

### 📋 Planned (Research Framework)
- Agent-based simulation engine with continuous distributions
- Structural estimation via simulated method of moments
- Monte Carlo validation and robustness checks
- Policy experiments (matching subsidies, information improvements)

## Special Notes

- Project follows Social Science Data Editors standards
- All scripts runnable from root with relative paths
- Input/temp folders managed by bead and gitignored
- Typst compilation tested and working
- Repository structure ready for future Julia/Python implementation
- Documentation covers both theory and computational implementation
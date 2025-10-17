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
make paper     # Compile papers/random-effects/paper.tex to PDF using pdflatex
make clean     # Remove temporary and LaTeX auxiliary files
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
├── docs/            # Research notes and documentation
├── papers/          # Research papers
│   └── random-effects/  # Random effects identification paper (LaTeX)
│       └── paper.tex    # PNAS format, ≤12 citations
├── input/           # External datasets (bead-managed, gitignored)
├── output/          # Final computational results
├── temp/            # Temporary files (gitignored)
├── .bead-meta/      # Bead metadata
├── Makefile         # Complete workflow automation
├── README.md        # Comprehensive project documentation
└── .gitignore       # Follows user conventions (input/, temp/, generated files)
```

## Key Technologies

- **LaTeX**: Document compilation (pdflatex + bibtex, TeX Live 2024)
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

### Identification Strategy (Random Effects Paper)
Five moments from mobility network covariances (y = a + z + ε):
1. Total variance: V = σ²_a + σ²_z + 2ρσ_aσ_z + σ²_ε
2. Manager-manager 2-step covariance: C_mm,2 = σ²_a + 2ρσ_aσ_z + ρ²σ²_z
3. Firm-firm 2-step covariance: C_ff,2 = σ²_z + 2ρσ_aσ_z + ρ²σ²_a
4. Manager-manager 4-step covariance: C_mm,4 = ρ² · C_mm,2
5. Firm-firm 4-step covariance: C_ff,4 = ρ² · C_ff,2

**Key Insight**: 4-step covariances = ρ² × 2-step covariances (path attenuation)
**Constructive Estimation**: ρ² = C_mm,4/C_mm,2 (direct identification via ratios)

## Implementation Status

### ✅ Completed
- Theoretical framework and documentation (docs/)
- Random effects identification paper (papers/random-effects/paper.tex)
  - Variance-covariance decomposition methodology
  - Hungarian manufacturing data (1985-2018): ρ ≈ 0.89-0.96
  - PNAS format with ≤12 citations
- Project organization and Makefile workflow  
- README.md and AGENTS.md with comprehensive documentation
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
- LaTeX compilation tested and working (pdflatex -interaction=nonstopmode)
- Repository structure supports multiple papers in papers/ subfolder
- Papers use embedded bibliography (thebibliography environment, no .bib files)
- Documentation covers both theory and computational implementation

## Recent Changes (2025-10-17)

- **Reorganized paper structure**: Moved variance-covariance paper from docs/ to papers/random-effects/
- **Fixed critical bugs**: 4-step path construction and projection matrix swap (ρ: 0.99 → 0.89-0.96)
- **Updated methodology**: Removed incorrect IV interpretation, added path attenuation explanation
- **Improved Makefile**: Now compiles LaTeX papers with proper auxiliary file cleanup
- **Updated documentation**: AGENTS.md, README.md, CLAUDE.md reflect new papers/ structure
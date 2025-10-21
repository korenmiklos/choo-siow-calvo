# Dynamic Manager-Firm Matching Model
# Makefile for complete workflow

.PHONY: all setup data edgelist simulate estimate paper clean help

# Julia command with project environment
JULIA := julia --project=.
DUCKDB := duckdb

# Default target - complete workflow
all: setup data estimate paper

# Setup project structure
setup:
	@mkdir -p input temp output
	@mkdir -p code/simulate code/estimate code/create code/plot

# Data processing pipeline
data: setup temp/edgelist.parquet temp/large_component_managers.csv

# Create edgelist from Hungarian data via individual steps
temp/edgelist.parquet: temp/merged-panel.parquet src/create/edgelist.jl
	$(JULIA) src/create/edgelist.jl

temp/merged-panel.parquet: temp/ceo-panel.parquet temp/balance.parquet src/create/merged-panel.jl
	$(JULIA) src/create/merged-panel.jl

temp/ceo-panel.parquet: input/manager-db-ceo-panel/ceo-panel.dta src/create/ceo-panel.sql
	$(DUCKDB) < src/create/ceo-panel.sql

temp/balance.parquet: input/merleg-LTS-2023-patch/balance/balance_sheet_80_22.dta src/create/balance.sql
	$(DUCKDB) < src/create/balance.sql

# Find connected components in manager network
temp/large_component_managers.csv: temp/edgelist.parquet src/create/connected_component.jl
	$(JULIA) src/create/connected_component.jl

# Simulation (placeholder for future implementation)
simulate: setup
	@touch temp/simulation_results.csv

# Estimation (placeholder for future implementation)  
estimate: data
	@touch temp/estimation_results.csv

# Compile papers
paper: papers/random-effects/paper.pdf

# Alias for clarity
paper-latex: paper

# Watch LaTeX file and recompile on changes
paper-watch:
	@while true; do \
		inotifywait -e modify papers/random-effects/paper.tex 2>/dev/null || sleep 2; \
		make paper; \
	done

papers/random-effects/paper.pdf: papers/random-effects/paper.tex lib/pnas-template/pnas-new.cls
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex

# Clean temporary files
clean:
	rm -f papers/random-effects/paper.pdf papers/random-effects/*.aux papers/random-effects/*.log papers/random-effects/*.bbl papers/random-effects/*.blg papers/random-effects/*.out
	rm -rf temp/*

# Show help
help:
	@echo "Dynamic Manager-Firm Matching Model"
	@echo "=================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all       - Run complete workflow (setup + data + estimate + paper)"
	@echo "  setup     - Create project directory structure"
	@echo "  data      - Process Hungarian CEO-firm data to create edgelist"
	@echo "  edgelist  - Create manager-firm edgelist with spell lengths"
	@echo "  simulate  - Run agent-based simulation (placeholder)"
	@echo "  estimate  - Run structural estimation (placeholder)"
	@echo "  paper     - Compile papers/random-effects/paper.tex to PDF using pdflatex"
	@echo "  clean     - Remove temporary files"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Individual data processing steps:"
	@echo "  ceo-panel - Process CEO panel data"
	@echo "  balance   - Process balance sheet data"
	@echo "  merge     - Merge CEO and balance data"
	@echo ""
	@echo "Data dependencies managed by bead:"
	@echo "  bead input list    - Show available datasets"
	@echo "  bead input load    - Load missing datasets"
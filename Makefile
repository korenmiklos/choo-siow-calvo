# Dynamic Manager-Firm Matching Model
# Makefile for complete workflow

.PHONY: all setup data edgelist simulate estimate paper clean help

# Julia command with project environment
JULIA := julia --project=.

# Default target - complete workflow
all: setup data estimate paper

# Setup project structure
setup:
	@echo "Setting up project structure..."
	@mkdir -p input temp output
	@mkdir -p code/simulate code/estimate code/create code/plot
	@echo "Project structure ready."

# Data processing pipeline
data: setup temp/edgelist.csv

# Create edgelist from Hungarian data via individual steps
temp/edgelist.csv: temp/merged-panel.parquet src/create/edgelist.jl
	$(JULIA) src/create/edgelist.jl

temp/merged-panel.parquet: temp/ceo-panel.parquet temp/balance.parquet src/create/merged-panel.jl
	$(JULIA) src/create/merged-panel.jl

temp/ceo-panel.parquet: src/create/ceo-panel.jl
	$(JULIA) src/create/ceo-panel.jl

temp/balance.parquet: src/create/balance.jl
	$(JULIA) src/create/balance.jl

# Simulation (placeholder for future implementation)
simulate: setup
	@echo "Running agent-based simulation..."
	@echo "Simulation module not yet implemented - this is a research framework."
	@touch temp/simulation_results.csv

# Estimation (placeholder for future implementation)  
estimate: data
	@echo "Running structural estimation..."
	@echo "Estimation module not yet implemented - this is a research framework."
	@touch temp/estimation_results.csv

# Compile papers
paper: papers/random-effects/paper.pdf

# Alias for clarity
paper-latex: paper

# Watch LaTeX file and recompile on changes
paper-watch:
	@echo "Watching LaTeX sources..."
	@while true; do \
		inotifywait -e modify papers/random-effects/paper.tex 2>/dev/null || sleep 2; \
		make paper; \
	done

papers/random-effects/paper.pdf: papers/random-effects/paper.tex lib/pnas-template/pnas-new.cls
	@echo "Compiling PNAS LaTeX paper to PDF..."
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex
	@echo "Paper compiled successfully."

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -f papers/random-effects/paper.pdf papers/random-effects/*.aux papers/random-effects/*.log papers/random-effects/*.bbl papers/random-effects/*.blg papers/random-effects/*.out
	rm -rf temp/*
	@echo "Clean complete."

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
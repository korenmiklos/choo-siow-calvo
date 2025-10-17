# Dynamic Manager-Firm Matching Model
# Makefile for complete workflow

.PHONY: all setup simulate estimate paper clean help

# Default target - complete workflow
all: setup simulate estimate paper

# Setup project structure
setup:
	@echo "Setting up project structure..."
	@mkdir -p input temp output
	@mkdir -p code/simulate code/estimate code/create code/plot
	@echo "Project structure ready."

# Simulation (placeholder for future implementation)
simulate: setup
	@echo "Running agent-based simulation..."
	@echo "Simulation module not yet implemented - this is a research framework."
	@touch temp/simulation_results.csv

# Estimation (placeholder for future implementation)  
estimate: simulate
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

papers/random-effects/paper.pdf: papers/random-effects/paper.tex
	@echo "Compiling LaTeX paper to PDF..."
	cd papers/random-effects && pdflatex -interaction=nonstopmode paper.tex
	cd papers/random-effects && pdflatex -interaction=nonstopmode paper.tex
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
	@echo "  all       - Run complete workflow (setup + simulate + estimate + paper)"
	@echo "  setup     - Create project directory structure"
	@echo "  simulate  - Run agent-based simulation (placeholder)"
	@echo "  estimate  - Run structural estimation (placeholder)"
	@echo "  paper     - Compile papers/random-effects/paper.tex to PDF using pdflatex"
	@echo "  clean     - Remove temporary files"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Data dependencies managed by bead:"
	@echo "  bead input list    - Show available datasets"
	@echo "  bead input load    - Load missing datasets"
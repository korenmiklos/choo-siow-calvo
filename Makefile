.PHONY: all setup data simulate estimate paper clean

JULIA := julia --project=.
DUCKDB := duckdb

all: setup data estimate paper

setup:
	mkdir -p input temp output
	mkdir -p code/simulate code/estimate code/create code/plot

data: setup temp/edgelist.parquet temp/large_component_managers.parquet temp/mm_pure_2hop.csv temp/ff_pure_2hop.csv

temp/edgelist.parquet: temp/merged-panel.parquet src/create/edgelist.jl
	$(JULIA) src/create/edgelist.jl

temp/merged-panel.parquet: temp/ceo-panel.parquet temp/balance.parquet src/create/merged-panel.jl
	$(JULIA) src/create/merged-panel.jl

temp/ceo-panel.parquet: input/manager-db-ceo-panel/ceo-panel.dta src/create/ceo-panel.sql
	$(DUCKDB) < src/create/ceo-panel.sql

temp/balance.parquet: input/merleg-LTS-2023-patch/balance/balance_sheet_80_22.dta src/create/balance.sql
	$(DUCKDB) < src/create/balance.sql

temp/large_component_managers.parquet: temp/edgelist.parquet src/create/connected_component.jl
	$(JULIA) src/create/connected_component.jl

temp/mm_pure_2hop.csv temp/ff_pure_2hop.csv: temp/edgelist.parquet src/create/n_hop_edgelist.jl
	$(JULIA) src/create/n_hop_edgelist.jl

simulate: setup
	touch temp/simulation_results.csv

estimate: data
	touch temp/estimation_results.csv

paper: papers/random-effects/paper.pdf

papers/random-effects/paper.pdf: papers/random-effects/paper.tex lib/pnas-template/pnas-new.cls
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex
	cd papers/random-effects && TEXINPUTS=.:../../lib/pnas-template//:${TEXINPUTS} pdflatex -interaction=nonstopmode paper.tex

clean:
	rm -f papers/random-effects/paper.pdf papers/random-effects/*.aux papers/random-effects/*.log papers/random-effects/*.bbl papers/random-effects/*.blg papers/random-effects/*.out
	rm -rf temp/*

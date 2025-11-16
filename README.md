# ME6401-Part2

A compact workspace of data, figures, and outputs for ME6401 (Part 2). This README explains how to reproduce and visualize results from the provided `.mat` datasets.

## Contents
- `Images/`: Reference figures (deformation sequences, load snapshots, CAD/analysis screenshots, schematic).
- `output/`: Generated outputs (animations and study reports). New plots will be saved to `output/plots/`.
- `Test_case/`: MATLAB `.mat` datasets (`T1.mat`, `T2.mat`, `T3.mat`, `T4.mat`, `T5-25.mat`).
- `Initial_setup.mat`: Initial MATLAB setup/state for the study.
- `ME6401_Report_vishal_1.pdf`: Project report.
- `scripts/`: Utility scripts for visualization and reproduction.

## Requirements
- MATLAB R2021b or newer (earlier versions may work).
- No special toolbox is assumed. If your datasets contain Simscape/struct objects, base MATLAB plotting is used where possible.

## Quick start
1. Open MATLAB and set the project root as your current folder 

2. Run each dataset separately as needed:
   - Run all test cases found in `Test_case/`:
     ```
     visualize_test_cases
     ```
   - Run a specific dataset:
     ```
     visualize_test_cases('Test_case/T1.mat')
     ```
   - Run multiple specific datasets:
     ```
     visualize_test_cases('Test_case/T1.mat', 'Test_case/T3.mat')
     ```

     ```
3 What it does:
   - Loads the specified `.mat` files and attempts to visualize common numeric variables.`.

## How the visualization works
- Each `.mat` file is loaded with `load`. The script inspects variable names and:


## Reproducing results
This workspace primarily contains result artifacts (figures, animations, PDFs) and datasets. 


- This repository currently does not include the original simulation code; it focuses on data and outputs.
- Animations are under `output/` as `.mov`. You can export frames using MATLAB or your preferred video tool if needed.
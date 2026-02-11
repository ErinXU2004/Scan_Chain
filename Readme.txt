// Step 1: module load
module load vscode/1.70.2
module load matlab/2022a
module load vcs/2023.12-SP2-1
module load verdi/2023.12-SP2-1

// Step 2
// Run simulation under vsim folder
cd vsim
make sim
// Check waveforms 
make verdi

// Step 3: Check DOUT
// Under matlab folder
DOUT_check.m

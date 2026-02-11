clear all 
close all
clc

scan_data_output = '../vsim/scan_data_out.txt';

% Read the contents of the file into a string
scan_data_out = fileread(scan_data_output);

% scan chain clock (us)
scan_clk = 5 * 500 / 1000;

% bit number 
bit_N = 32;

ref1 = hex_str2bit_str("32'h87654321",bit_N);
ref1 = reverse(ref1);

ref2 = hex_str2bit_str("32'h12345678",bit_N);
ref2 = reverse(ref2);

ref3 = hex_str2bit_str("32'h54324567",bit_N);
ref3 = reverse(ref3);

ref4 = hex_str2bit_str("32'hf1f2f3ff",bit_N);
ref4 = reverse(ref4);

% data detected 
disp(['data detected at ', num2str(strfind(scan_data_out,ref1) * scan_clk),' us'])
disp(['data detected at ', num2str(strfind(scan_data_out,ref2) * scan_clk),' us'])
disp(['data detected at ', num2str(strfind(scan_data_out,ref3) * scan_clk),' us'])
disp(['data detected at ', num2str(strfind(scan_data_out,ref4) * scan_clk),' us'])
function bit_str = hex_str2bit_str(hex_str, N)

% Extract the hex part
hex_str = extractAfter(hex_str, "h");

% Convert hex string to number
num = hex2dec(char(hex_str));  % convert to uint32

% Convert to N-bit binary string
bit_str = dec2bin(num, N);

end
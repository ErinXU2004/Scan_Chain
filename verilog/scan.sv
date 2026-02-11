module scan (
    // Inputs & outputs to the chip
    static_wen,
    static_ren,
    static_addr,
    static_wdata,
    static_rdata,
    static_ready,

    // To the pads
    scan_phi,
    scan_phi_bar,
    scan_data_in,
    scan_data_out,
    scan_load_chip,
    scan_load_chain
);

// Ports
input  scan_phi;
input  scan_phi_bar;
input  scan_data_in;
output scan_data_out;
input  scan_load_chain;
input  scan_load_chip;

output reg [1-1:0] static_wen;
output reg [1-1:0] static_ren;
output reg [16-1:0] static_addr;   // Changed: 12-bit -> 16-bit address for SIMD
output reg [16-1:0] static_wdata;  // Changed: 32-bit -> 16-bit data width
input [16-1:0] static_rdata;       // Changed: 32-bit -> 16-bit data width
input [1-1:0]  static_ready;

// Implementation

// The scan chain is comprised of two sets of latches: scan_master and scan_slave.
// Changed: 79-bit -> 51-bit scan chain (due to smaller data width)

reg  [50:0] scan_master;  // Changed: 79 -> 51 bits
reg  [50:0] scan_slave;   // Changed: 79 -> 51 bits

reg  [50:0] scan_load;    // Changed: 79 -> 51 bits
wire [50:0] scan_next;    // Changed: 79 -> 51 bits

always @* begin
    // Bit mapping for SIMD engine scan chain (51 bits total):
    // [0:0]   - static_wen (write enable)
    // [1:1]   - static_ren (read enable)  
    // [17:2]  - static_addr (16-bit address: [17:7]=addr, [6:3]=lane_id, [2:2]=i/d_sel)
    // [33:18] - static_wdata (16-bit write data)
    // [49:34] - static_rdata (16-bit read data)
    // [50:50] - static_ready (ready signal)
    
    scan_load[0:0] = static_wen;
    scan_load[1:1] = static_ren;
    scan_load[17:2]  = static_addr;   // Changed: [13:2] -> [17:2] (16-bit address)
    scan_load[33:18] = static_wdata;  // Changed: [45:14] -> [33:18] (16-bit data)
    scan_load[49:34] = static_rdata;  // Changed: [77:46] -> [49:34] (16-bit data)
    scan_load[50:50] = static_ready;  // Changed: [78:78] -> [50:50]
end

//scan_load -> from chip to scan chain
//!scan_data_in -> from pads to scan chain
assign scan_next = scan_load_chain ? scan_load : {scan_data_in, scan_slave[50:1]};  // Changed: [78:1] -> [50:1]

// synopsys one_hot "scan_phi, scan_phi_bar"
always @* begin
    if (scan_phi)
        scan_master = scan_next;
    if (scan_phi_bar)
        scan_slave = scan_master;
end

// static_xx refers to the Data latches in the slides
// (M + 1) bits have been removed for read operation, where M = 16 (changed from 32)
always @* if (scan_load_chip) begin
    static_wen   = scan_slave[0];
    static_ren   = scan_slave[1];
    static_addr  = scan_slave[17:2];   // Changed: [13:2] -> [17:2] (16-bit address)
    static_wdata = scan_slave[33:18];  // Changed: [45:14] -> [33:18] (16-bit data)
end

assign scan_data_out = scan_slave[0];

endmodule

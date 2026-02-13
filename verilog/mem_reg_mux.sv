// Mem and reg mux - Modified for SIMD Engine
// This module selects the interface between the SRAM and the control registers.
// Address bit [15] is used to select: 0=SRAM, 1=Register
// Address bits [4:1] contain Lane ID, bit [0] contains I/D select for SIMD

module mem_reg_mux (
    // to rwctr - Changed: address and data width for SIMD
    input  scan_ren,
    input  scan_wen,
    input  [15:0] scan_addr,   // Changed: 12-bit -> 16-bit address
    input  [15:0] scan_wdata,  // Changed: 32-bit -> 16-bit data
    output reg [15:0] scan_rdata,  // Changed: 32-bit -> 16-bit data
    output reg scan_ready,

    // to sram - Changed: data width only (address kept at 11-bit)
    output reg sram_ren,
    output reg sram_wen,
    output reg [10:0] sram_addr,   // Keep 11-bit address (from scan_addr[14:4])
    output reg [15:0] sram_wdata,  // Changed: 32-bit -> 16-bit data
    input [15:0] sram_rdata,       // Changed: 32-bit -> 16-bit data
    input sram_ready,
    
    // to ctrl registers - Simplified to single 16-bit register 
    output reg ctr_ren,
    output reg ctr_wen,
    output reg [15:0] ctr_wdata,   // Changed: split registers -> single 16-bit 
    input  [15:0] ctr_rdata,       // Changed: split registers -> single 16-bit
    input  ctr_ready,

    // to status register
    input stat_ready, 
    input reg [15:0] stat_rdata, 
    
    // SIMD control signals - New outputs for SIMD engine
    output reg [3:0] lane_id,      // Lane ID extracted from scan_addr[4:1]
    output reg id_sel              // Instruction/Data select from scan_addr[0]
);

    // TODO: add status register stuff

    // Extract SIMD control signals from address
    // scan_addr layout: [15]=SRAM/Reg, [14:5]=addr, [4:1]=lane_id, [0]=i/d_sel
    always @* begin
        lane_id = scan_addr[4:1];  // Extract Lane ID (4 bits for 16 lanes)
        id_sel  = scan_addr[0];    // Extract Instruction/Data select
    end

    // Ready and read data multiplexing
    always @* begin
        scan_ready = ctr_ready | sram_ready;  // Ready when either source is ready
        scan_rdata = ctr_ready ? ctr_rdata : (sram_ready ? sram_rdata : 16'h0);
        // Changed: simplified from concatenating ctr1+ctr2 to single register
    end

    // Control signal routing based on address bit[15]
    // scan_addr[15]=0: route to SRAM, scan_addr[15]=1: route to registers
    always @* begin
        ctr_wen    =  scan_addr[15] ? scan_wen : 0;  // Changed: bit[11] -> bit[15]
        ctr_ren    =  scan_addr[15] ? scan_ren : 0;
        sram_wen   = !scan_addr[15] ? scan_wen : 0;
        sram_ren   = !scan_addr[15] ? scan_ren : 0;
    end

    // Data and address routing
    always @* begin
        ctr_wdata  =  scan_addr[15] ? scan_wdata : 16'h0;
        // Changed: simplified from splitting into ctr1/ctr2 to single register
        
        sram_wdata = !scan_addr[15] ? scan_wdata : 16'h0;
        
        // SRAM address uses bits[14:4] (11 bits), ignoring lower bits (lane_id, i/d_sel)
        sram_addr  = !scan_addr[15] ? scan_addr[14:4] : 11'h0;
        // Changed: [10:0] -> [14:4] to account for 16-bit address space
    end

endmodule

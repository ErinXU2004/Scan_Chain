module scan_full( 
    // input signal
    input clk,
    input rst_n,

    // To the pads - No change needed for pad signals
    input scan_id,
    input scan_phi,
    input scan_phi_bar,
    input scan_data_in,
    output reg scan_data_out,
    input scan_load_chip,
    input scan_load_chain,

    // To 128-bit SRAM - Segmented access interface
    output reg sram_ren,
    output reg sram_wen,
    output reg [10:0] sram_addr,   // 11-bit word address (2048 words)
    output reg [2:0] sram_seg_sel, // 3-bit segment select (8×16-bit segments)
    output reg [15:0] sram_wdata,  // 16-bit data segment
    input [15:0] sram_rdata,       // 16-bit data segment
    input sram_ready,
    
    // To control registers - Simplified to single 16-bit register
    output reg  ctr_ren,
    output reg ctr_wen,
    output reg [15:0] ctr_wdata,   // Changed: split ctr1/ctr2 -> single 16-bit
    input [15:0] ctr_rdata,        // Changed: split ctr1/ctr2 -> single 16-bit
    input ctr_ready,

    // to status register
    input stat_ready, 
    input reg [15:0] stat_rdata, 
    
    // SIMD control signal - I/D memory select
    output reg id_sel              // Instruction/Data memory select
);
   // Internal wires between rwctr and scan - Changed: address and data width
   reg static_wen;
   reg static_ren;
   reg [15:0]  static_addr;   // Changed: 12-bit -> 16-bit address
   reg [15:0]  static_wdata;  // Changed: 32-bit -> 16-bit data
   reg [15:0]  static_rdata;  // Changed: 32-bit -> 16-bit data
   reg   static_ready;

   // Internal wires between rwctr and mem_reg_mux - Changed: address and data width
   reg   scan_wen;
   reg   scan_ren;
   reg [15:0]  scan_addr;     // Changed: 12-bit -> 16-bit address
   reg [15:0]  scan_wdata;    // Changed: 32-bit -> 16-bit data
   reg [15:0]  scan_rdata;    // Changed: 32-bit -> 16-bit data
   reg         scan_ready;

   // syn and pulse generator
   reg id_valid;

   // Instantiate mem_reg_mux - Address decoder and data router
   mem_reg_mux mem_reg_mux_inst (
        .scan_ren(scan_ren),
        .scan_wen(scan_wen),
        .scan_addr(scan_addr),
        .scan_wdata(scan_wdata),
        .scan_rdata(scan_rdata),
        .scan_ready(scan_ready),
        .sram_ren(sram_ren),
        .sram_wen(sram_wen),
        .sram_addr(sram_addr),          // 11-bit word address
        .sram_seg_sel(sram_seg_sel),    // 3-bit segment select
        .sram_wdata(sram_wdata),
        .sram_rdata(sram_rdata),
        .sram_ready(sram_ready),
        .ctr_ren(ctr_ren),
        .ctr_wen(ctr_wen),
        .ctr_wdata(ctr_wdata),
        .ctr_rdata(ctr_rdata),
        .ctr_ready(ctr_ready),
        .id_sel(id_sel)                 // I/D select output
    );

    // Instantiate rwctr - Read/Write controller with clock domain crossing
    rwctr rwctr_inst(
        .clk(clk),
        .rst_n(rst_n),
        .id_valid(id_valid),
        .static_wen(static_wen),
        .static_ren(static_ren),
        .static_addr(static_addr),
        .static_wdata(static_wdata),
        .static_ready(static_ready),
        .static_rdata(static_rdata),
        .scan_wen(scan_wen),
        .scan_ren(scan_ren),
        .scan_addr(scan_addr),
        .scan_wdata(scan_wdata),
        .scan_rdata(scan_rdata),
        .scan_ready(scan_ready)
    );


     // Instantiate scan - Scan chain shift register (51 bits for SIMD)
     scan scan_inst (
        .static_wen(static_wen),
        .static_ren(static_ren),
        .static_addr(static_addr),
        .static_wdata(static_wdata),
        .static_rdata(static_rdata),
        .static_ready(static_ready),
        .scan_phi(scan_phi),
        .scan_phi_bar(scan_phi_bar),
        .scan_data_in(scan_data_in),
        .scan_data_out(scan_data_out),
        .scan_load_chip(scan_load_chip),
        .scan_load_chain(scan_load_chain)
    );

    // Instantiate syn_pulse_gen - Synchronizer and edge detector
    syn_pulse_gen syn_pulse_gen_inst(
        .clk(clk),
        .rst_n(rst_n),
        .scan_id(scan_id),
        .id_valid(id_valid)
    );

endmodule 

//`timescale 1ns/1ps
`timescale 1ns/1ps
// SIMD Engine Scan Chain Testbench
module tb_test_scan;
   // universal
    int file;
    logic clk;
    logic rst_n;
    logic scan_id;

     // To the pads
    logic  scan_phi;
    logic  scan_phi_bar;
    logic  scan_data_in;
    logic  scan_data_out;
    logic  scan_load_chip;
    logic  scan_load_chain;

    // to sram - Changed: data width for SIMD engine
    logic sram_ren;
    logic sram_wen;
    logic [15:0] sram_wdata;     // Changed: 32-bit -> 16-bit
    logic [15:0] sram_rdata;     // Changed: 32-bit -> 16-bit
    logic [10:0] sram_addr;
    logic sram_ready;
    
    // to ctr - Simplified to single 16-bit register
    logic ctr_ren;
    logic ctr_wen;
    logic [15:0] ctr_wdata;      // Changed: split registers -> single 16-bit
    logic [15:0] ctr_rdata;      // Changed: split registers -> single 16-bit
    logic [15:0] ctr;            // Changed: single register
    logic ctr_ready;
    
    // SIMD control signals - New for SIMD engine
    logic [3:0] lane_id;         // Lane ID output
    logic id_sel;                // Instruction/Data select output
   
   // Clock generator
   clk_gen c1 (.clk(clk), .rst_n(rst_n));

   // SRAM instance - Uses parameterized width (changed to 16-bit in spram.sv)
   spram s1 (.clk(clk),
                .rst_n(rst_n), 
                .wen(sram_wen),
                .ren(sram_ren),
                .waddr(sram_addr),
                .raddr(sram_addr),
                .wdata(sram_wdata), 
                .rdata(sram_rdata), 
                .ready(sram_ready)); 

   // Test stimulus module
   test_scan ts1 (.*);

   // Control register instance - Changed to single 16-bit register
   ctr_reg cr1 (
        .clk(clk),
        .rst_n(rst_n),
        .ctr_wen(ctr_wen),
        .ctr_ren(ctr_ren),
        .ctr_wdata(ctr_wdata),      // Changed: ctr1_wdata -> ctr_wdata
        .ctr_rdata(ctr_rdata),      // Changed: ctr1_rdata -> ctr_rdata
        .ctr(ctr),                  // Changed: ctr1, ctr2 -> ctr
        .ctr_ready(ctr_ready)
    );

   // Scan chain top module - Updated for SIMD engine
   scan_full sf1(
    .clk(clk),
    .rst_n(rst_n),
    .scan_id(scan_id),
    .scan_phi(scan_phi),
    .scan_phi_bar(scan_phi_bar),
    .scan_data_in(scan_data_in),
    .scan_data_out(scan_data_out),
    .scan_load_chip(scan_load_chip),
    .scan_load_chain(scan_load_chain),
    .sram_ren(sram_ren),
    .sram_wen(sram_wen),
    .sram_wdata(sram_wdata),
    .sram_rdata(sram_rdata),
    .sram_ready(sram_ready),
    .sram_addr(sram_addr),
    .ctr_ren(ctr_ren),
    .ctr_wen(ctr_wen),
    .ctr_wdata(ctr_wdata),          // Changed: ctr1_wdata -> ctr_wdata
    .ctr_rdata(ctr_rdata),          // Changed: ctr1_rdata -> ctr_rdata
    .ctr_ready(ctr_ready),
    .lane_id(lane_id),              // Added: SIMD Lane ID
    .id_sel(id_sel)                 // Added: Instruction/Data select
    );

   initial begin
      file = $fopen("scan_data_out.txt", "w");
      $fsdbDumpfile("tb_test_scan.fsdb");
      $fsdbDumpvars(0, tb_test_scan, "+struct");
      $fsdbDumpvars("+mda");
      #(5000*`CLK_CYCLE)
      $finish();
   end

   always begin
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      $fwrite(file, "%b", scan_data_out);
      end

endmodule

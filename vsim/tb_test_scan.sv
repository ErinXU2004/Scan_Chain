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

    // to 128-bit SRAM - Segmented access interface
    logic sram_ren;
    logic sram_wen;
    logic [10:0] sram_addr;      // 11-bit word address (2048 words)
    logic [2:0] sram_seg_sel;    // 3-bit segment select (8 segments)
    logic [15:0] sram_wdata;     // 16-bit data segment
    logic [15:0] sram_rdata;     // 16-bit data segment
    logic sram_ready;
    
    // to ctr - Simplified to single 16-bit register
    logic ctr_ren;
    logic ctr_wen;
    logic [15:0] ctr_wdata;      // Changed: split registers -> single 16-bit
    logic [15:0] ctr_rdata;      // Changed: split registers -> single 16-bit
    logic [15:0] ctr;            // Changed: single register
    logic ctr_ready;
    
    // SIMD control signal - I/D memory select
    logic id_sel;                // Instruction/Data select output
   
   // Clock generator
   clk_gen c1 (.clk(clk), .rst_n(rst_n));

   // 128-bit SRAM instance - Segmented access for scan chain
   spram_128b s1 (.clk(clk),
                .rst_n(rst_n), 
                .wen(sram_wen),
                .ren(sram_ren),
                .addr(sram_addr),          // 4-bit word address
                .seg_sel(sram_seg_sel),    // 3-bit segment select
                .wdata(sram_wdata),        // 16-bit segment write
                .rdata(sram_rdata),        // 16-bit segment read
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

   // Scan chain top module - Updated for 128-bit segmented SRAM
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
    .sram_addr(sram_addr),         // 4-bit word address
    .sram_seg_sel(sram_seg_sel),   // 3-bit segment select
    .sram_wdata(sram_wdata),
    .sram_rdata(sram_rdata),
    .sram_ready(sram_ready),
    .ctr_ren(ctr_ren),
    .ctr_wen(ctr_wen),
    .ctr_wdata(ctr_wdata),
    .ctr_rdata(ctr_rdata),
    .ctr_ready(ctr_ready),
    .id_sel(id_sel)                // I/D select signal
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

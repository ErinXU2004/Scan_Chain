`timescale 1ns/1ps
`define SCAN_DELAY #500

module test_scan(
   input               clk,
   input               rst_n,
   output   logic      scan_phi,
   output   logic      scan_phi_bar,
   output   logic      scan_data_in,
   output   logic      scan_load_chip,
   output   logic      scan_load_chain,
   input               scan_data_out,
   output   logic      scan_id
);
   
   // Scan
   initial scan_phi = 0;
   initial scan_phi_bar = 0;
   initial scan_data_in = 0;
   initial scan_load_chip = 0;
   initial scan_load_chain = 0;
   initial scan_id = 0;
   //-----------------------------------------
   //  Scan Chain Registers and Tasks
   //-----------------------------------------

   // Scan Registers and Initializations - Changed for SIMD engine
   
`define SCAN_CHAIN_LENGTH 51   // Changed: 79 -> 51 bits for SIMD engine

   reg [1-1:0] static_wen;
   reg [1-1:0] static_wen_read;
   initial static_wen      = 1'd0;
   initial static_wen_read = 1'd0;
   reg [1-1:0] static_ren;
   reg [1-1:0] static_ren_read;
   initial static_ren      = 1'd0;
   initial static_ren_read = 1'd0;
   reg [16-1:0] static_addr;        // Changed: 12-bit -> 16-bit address
   reg [16-1:0] static_addr_read;
   initial static_addr      = 16'd0;
   initial static_addr_read = 16'd0;
   reg [16-1:0] static_wdata;       // Changed: 32-bit -> 16-bit data
   reg [16-1:0] static_wdata_read;
   initial static_wdata      = 16'd0;
   initial static_wdata_read = 16'd0;
   reg [16-1:0] static_rdata;       // Changed: 32-bit -> 16-bit data
   reg [16-1:0] static_rdata_read;
   initial static_rdata      = 16'd0;
   initial static_rdata_read = 16'd0;
   reg [1-1:0] static_ready;
   reg [1-1:0] static_ready_read;
   initial static_ready      = 1'd0;
   initial static_ready_read = 1'd0;
   // Scan chain tasks
   
   task load_chip;
      begin
         `SCAN_DELAY scan_load_chip = 1;
         `SCAN_DELAY scan_load_chip = 0;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
      end
   endtask

   task load_chain;
      begin
         `SCAN_DELAY scan_load_chain = 1;
         `SCAN_DELAY scan_phi = 1;
         `SCAN_DELAY scan_phi = 0;
         `SCAN_DELAY scan_phi_bar = 1;
         `SCAN_DELAY scan_phi_bar = 0;
         `SCAN_DELAY scan_load_chain = 0;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
      end
   endtask

   task rotate_chain;
      
      integer i;
      
      reg [`SCAN_CHAIN_LENGTH-1:0] data_in;
      reg [`SCAN_CHAIN_LENGTH-1:0] data_out;
      
      begin
         // Pack data into scan chain - Changed bit mapping for SIMD engine
         data_in[0:0] = static_wen;
         data_in[1:1] = static_ren;
         data_in[17:2] = static_addr;    // Changed: [13:2] -> [17:2] (16-bit address)
         data_in[33:18] = static_wdata;  // Changed: [45:14] -> [33:18] (16-bit data)
         data_in[49:34] = static_rdata;  // Changed: [77:46] -> [49:34] (16-bit data)
         data_in[50:50] = static_ready;  // Changed: [78:78] -> [50:50]

         // Shift data through scan chain
         for (i = 0; i < `SCAN_CHAIN_LENGTH; i=i+1) begin
            scan_data_in = data_in[0];
            data_out     = {scan_data_out, data_out[`SCAN_CHAIN_LENGTH-1:1]};
            `SCAN_DELAY scan_phi = 1;
            `SCAN_DELAY scan_phi = 0;
            `SCAN_DELAY scan_phi_bar = 1;
            `SCAN_DELAY scan_phi_bar = 0;
            `SCAN_DELAY data_in = data_in >> 1;
         end

         // Unpack data from scan chain - Changed bit mapping
         static_wen_read = data_out[0:0];
         static_ren_read = data_out[1:1];
         static_addr_read = data_out[17:2];    // Changed: 16-bit address
         static_wdata_read = data_out[33:18];  // Changed: 16-bit data
         static_rdata_read = data_out[49:34];  // Changed: 16-bit data
         static_ready_read = data_out[50:50];  // Changed: bit position
      end
      
   endtask

   task write_stuff ();
      input [15:0]   addr_in;   // Changed: 12-bit -> 16-bit address
      input [15:0]  wdata_in;   // Changed: 32-bit -> 16-bit data
      begin
         static_wen = 1;
         static_ren = 0;
         static_addr = addr_in;
         static_wdata = wdata_in;
         static_rdata = 0;
         static_ready = 0;
         rotate_chain();
         load_chip();
         @(negedge clk)
         @(negedge clk)
         @(negedge clk)
         @(negedge clk)
         @(negedge clk)
         scan_id = ~scan_id;  // Toggle scan_id to trigger operation
      end 
   endtask
   
   logic dummy;

   task read_stuff ();
      input [15:0]  addr_in;    // Changed: 12-bit -> 16-bit address
      begin
         static_wen = 0;
         static_ren = 1;
         static_addr = addr_in;
         static_wdata = 0;
         static_rdata = 0;
         static_ready = 0;
         rotate_chain();
         load_chip();
         repeat(4) begin
         @(negedge clk)
         dummy = 1;
         end
         scan_id = ~scan_id;
         repeat(20) begin
         @(negedge clk)
         dummy = 1;
         end
         load_chain();
         rotate_chain();
      end 
   endtask
  
   initial begin
      #(`RESET_CYCLE*`CLK_CYCLE);
      dummy = 1;
      // write data to sram
      write_stuff (12'h001, 32'h87654321);
      #(10*`CLK_CYCLE)

      // write data to sram     
      write_stuff (12'h007, 32'h12345678);
      #(10*`CLK_CYCLE)

      // write data to ctr register
      write_stuff (12'h800, 32'h54324567);
      #(10*`CLK_CYCLE)

      // write data to sram
      write_stuff (12'h011, 32'hf1f2f3ff);
      #(10*`CLK_CYCLE)




      // read data from sram
      read_stuff (12'h001);
      #(10*`CLK_CYCLE)

      // read data from sram
      read_stuff (12'h007);
       #(10*`CLK_CYCLE)

      // read data from ctr register
      read_stuff (12'h800);
      #(10*`CLK_CYCLE)
      
      // read data from sram
      read_stuff (12'h011);
   end
 
endmodule // tbench	

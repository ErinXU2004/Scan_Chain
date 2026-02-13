module rwctr(
   input          clk,
   input          rst_n,

   // syn and pulse generator
   input          id_valid,

   // from scan - Changed: address and data width for SIMD engine
   input          static_wen,
   input          static_ren,
   input  [15:0]  static_addr,   // Changed: 12-bit -> 16-bit address
   input  [15:0]  static_wdata,  // Changed: 32-bit -> 16-bit data
   output reg     static_ready,
   output reg [15:0] static_rdata,  // Changed: 32-bit -> 16-bit data

   // to mem_reg_mux - Changed: address and data width for SIMD engine
   output reg   scan_wen,
   output reg   scan_ren,
   output reg [15:0]  scan_addr,   // Changed: 12-bit -> 16-bit address
   output reg [15:0]  scan_wdata,  // Changed: 32-bit -> 16-bit data
   input  [15:0]  scan_rdata,      // Changed: 32-bit -> 16-bit data
   input  scan_ready

); 

   reg holding, holding_w;
   reg read_hold, read_hold_w;
   wire request_valid; 
   reg request_finish;
   reg static_ready_w;
   reg scan_wen_w, scan_ren_w;
   reg [15:0] scan_addr_w;         // Changed: 12-bit -> 16-bit
   reg [15:0] static_rdata_w, scan_wdata_w;  // Changed: 32-bit -> 16-bit

   // Generate a pulse during write and read operation
   // id_valid is the output of the pulse generator
   assign request_valid = (static_wen || static_ren) && !holding && id_valid;
  
   always @* begin
   //   holding_w = holding;
      if (request_valid == 1) begin
         holding_w = 1;
      end
      else begin
         holding_w = 0;
      end
   end

   // Read and write operation
   always @* begin
      read_hold_w = read_hold;
      request_finish = 0;
      if (request_valid == 1 && static_ren == 1) begin
         read_hold_w = 1;
      end
      else if (scan_ready == 1) begin
         read_hold_w = 0;
         request_finish = 1;
      end
   end

   always @* begin
      static_ready_w = (request_valid)  ? 0 : (request_finish) ? 1 : static_ready;
      static_rdata_w = (request_finish) ? scan_rdata : static_rdata;
   end

   always @* begin
      scan_wen_w   = (request_valid) ? static_wen   : 0;
      scan_ren_w   = (request_valid) ? static_ren   : 0;
      scan_addr_w  = (request_valid) ? static_addr  : 0;
      scan_wdata_w = (request_valid) ? static_wdata : 0;
   end

   always @(posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         holding    <= 0;
         read_hold  <= 0;
         scan_wen   <= 0;
         scan_ren   <= 0;
         scan_addr  <= 0;
         scan_wdata <= 0;
         static_ready <= 0;
         static_rdata <= 0;
      end
      else begin
         holding   <= holding_w;
         read_hold <= read_hold_w;
         scan_wen  <= scan_wen_w;
         scan_ren  <= scan_ren_w;
         scan_addr <= scan_addr_w;
         scan_wdata   <= scan_wdata_w;
         static_ready <= static_ready_w;
         static_rdata <= static_rdata_w;
      end
   end

endmodule

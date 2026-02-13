/*
   128-bit Single Port RAM with Segmented Access
   - Full word width: 128 bits
   - Accessed via 16-bit segments (8 segments total)
   - Segment selection for scan chain compatibility
   
   Interface:
   - addr: 4-bit word address (16 words)
   - seg_sel: 3-bit segment select (8 segments × 16-bit = 128-bit)
   - wdata/rdata: 16-bit segment data
   
   Created: 02/13/26 for SIMD vector accelerator
*/

module spram_128b 
#( parameter  WORD_WIDTH = 128,  // Full word width
   parameter  SEG_WIDTH  = 16,   // Segment width (for scan chain)
   parameter  NUM_SEGS   = 8,    // Number of segments (128/16 = 8)
   parameter  SIZE       = 2048, // Number of 128-bit words
   parameter  ADDR_WIDTH = 11    // log2(2048) = 11
)
(
   input                          clk,
   input                          rst_n,
   input                          wen,
   input                          ren,
   input  [ADDR_WIDTH - 1 : 0]    addr,      // Word address
   input  [2:0]                   seg_sel,   // Segment select (0-7)
   input  [SEG_WIDTH - 1 : 0]     wdata,     // Write data (16-bit segment)
   output logic [SEG_WIDTH - 1 : 0] rdata,   // Read data (16-bit segment)
   output logic                   ready
);
   
   // Internal storage: array of 128-bit words
   logic [SIZE - 1 : 0][WORD_WIDTH - 1 : 0] memory, memory_w;
   logic [SEG_WIDTH - 1 : 0] rdata_pre;
   logic real_ren, real_wen;
 
   // SRAM write - write to selected segment only
   assign real_wen = (wen == 1);

   always_comb begin
      memory_w = memory;
      if (real_wen) begin
         // Write to the selected 16-bit segment of the 128-bit word
         case (seg_sel)
            3'd0: memory_w[addr][15:0]    = wdata;
            3'd1: memory_w[addr][31:16]   = wdata;
            3'd2: memory_w[addr][47:32]   = wdata;
            3'd3: memory_w[addr][63:48]   = wdata;
            3'd4: memory_w[addr][79:64]   = wdata;
            3'd5: memory_w[addr][95:80]   = wdata;
            3'd6: memory_w[addr][111:96]  = wdata;
            3'd7: memory_w[addr][127:112] = wdata;
            default: memory_w[addr] = memory[addr]; // No change
         endcase
      end
   end

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         memory <= 0;
      end
      else begin
         memory <= memory_w;
      end
   end 

   // SRAM read - read from selected segment only
   assign real_ren = (ren == 1);
   
   always_comb begin
      if (real_ren) begin
         // Read the selected 16-bit segment from the 128-bit word
         case (seg_sel)
            3'd0: rdata_pre = memory[addr][15:0];
            3'd1: rdata_pre = memory[addr][31:16];
            3'd2: rdata_pre = memory[addr][47:32];
            3'd3: rdata_pre = memory[addr][63:48];
            3'd4: rdata_pre = memory[addr][79:64];
            3'd5: rdata_pre = memory[addr][95:80];
            3'd6: rdata_pre = memory[addr][111:96];
            3'd7: rdata_pre = memory[addr][127:112];
            default: rdata_pre = 16'h0;
         endcase
      end else begin
         rdata_pre = 16'h0;
      end
   end

   logic ready_w;
   assign ready_w = real_ren;
  
   // Output registers
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         rdata <= 0;
         ready <= 0;
      end
      else begin
         rdata <= rdata_pre;
         ready <= ready_w;
      end
   end

endmodule

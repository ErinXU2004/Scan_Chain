// Status register module - Simplified for SIMD engine (single 16-bit register)
module status_reg (
    input             clk,
    input             rst_n,

    // Core interface todo: do we have io to the core yet
    input             core_wen, 
    input      [15:0] core_wdata, 
    
    // External interface
    output reg [15:0] stat_rdata, 
    output reg        stat_ready
); 

    logic [15:0] stat_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: clear all registers
            stat_reg     <= '0;
            stat_rdata   <= '0;
            stat_ready   <=  0;
        end 
        else begin
            if (core_wen) begin
                // Write operation: update register
                stat_reg  <= core_wdata;
            end 
            else begin 
                stat_rdata <= stat_reg; 
                stat_ready <= 1'b1; 
            end
        end
    end

endmodule

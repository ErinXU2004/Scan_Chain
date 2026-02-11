// Control register module - Simplified for SIMD engine (single 16-bit register)
module ctr_reg (
    input      [15:0] ctr_wdata,   // Changed: split registers -> single 16-bit write data
    input             clk,
    input             rst_n,
    input             ctr_wen,
    input             ctr_ren,
    output     reg [15:0] ctr,     // Changed: single 16-bit control register
    output     reg [15:0] ctr_rdata,  // Changed: single 16-bit read data
    output     reg        ctr_ready   // Handshake ready signal
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: clear all registers
            ctr         <= 16'h0;
            ctr_rdata   <= 16'h0;
            ctr_ready    <= 0;
        end 
        else begin
            if (ctr_wen) begin
                // Write operation: update register
                ctr      <= ctr_wdata;
                ctr_ready <= 0;
            end 
            else begin 
                if (ctr_ren) begin
                    // Read operation: output current register value
                    ctr_rdata <= ctr;
                    ctr_ready  <= 1;
                end  
                else begin
                    // Idle: clear outputs
                    ctr_rdata <= 0;
                    ctr_ready  <= 0;
                end
            end
        end
    end

endmodule

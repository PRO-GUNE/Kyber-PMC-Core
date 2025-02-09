module modular_subtraction_pipelined #(parameter WIDTH = 24) (
    input clk,
    input rst,  // Active high reset
    input [WIDTH-1:0] x, y, q,
    output reg [WIDTH-1:0] z
);
    // Pipeline registers
    reg [WIDTH:0] diff_stage1, adjusted_diff_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            diff_stage1 <= 0;
            adjusted_diff_stage2 <= 0;
            z <= 0;
        end else begin
            // Stage 1: Compute difference
            diff_stage1 <= x - y;

            // Stage 2: Adjust difference and determine result
            adjusted_diff_stage2 <= diff_stage1 + q;
            if (diff_stage1[WIDTH])  // Borrow occurred
                z <= adjusted_diff_stage2[WIDTH-1:0];
            else
                z <= diff_stage1[WIDTH-1:0];
        end
    end
endmodule

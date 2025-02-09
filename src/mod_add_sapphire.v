module modular_addition_pipelined #(parameter WIDTH = 24) (
    input clk,
    input rst,  // Active high reset
    input [WIDTH-1:0] x, y, q,
    output reg [WIDTH-1:0] z
);
    // Pipeline registers
    reg [WIDTH:0] sum_stage1, diff_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_stage1 <= 0;
            diff_stage2 <= 0;
            z <= 0;
        end else begin
            // Stage 1: Compute sum
            sum_stage1 <= x + y;

            // Stage 2: Compute difference and determine result
            diff_stage2 <= sum_stage1 - q;
            if (sum_stage1[WIDTH] || diff_stage2[WIDTH-1:0] == 0)
                z <= diff_stage2[WIDTH-1:0];
            else
                z <= sum_stage1[WIDTH-1:0];
        end
    end
endmodule

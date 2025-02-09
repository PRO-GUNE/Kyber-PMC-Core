module testbench;
    reg clk, rst;
    reg [23:0] x, y, q;
    wire [23:0] z_add, z_sub;

    // Instantiate the pipelined modules
    modular_addition_pipelined #(24) mod_add (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .q(q),
        .z(z_add)
    );

    modular_subtraction_pipelined #(24) mod_sub (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .q(q),
        .z(z_sub)
    );

    // Clock generation
    initial begin
        clk = 1;
        forever #5 clk = ~clk;  // 10 time units clock period
    end

    initial begin
        // Initialize signals
        rst = 1;
        x = 0; y = 0; q = 0;
        #10 rst = 0;

        // Test case 1
        x = 24'd1; y = 24'd3328; q = 24'd3329;
        #20;  // Wait for 2 clock cycles
        $display("Addition: x = %d, y = %d, q = %d, z = %d", x, y, q, z_add);
        $display("Subtraction: x = %d, y = %d, q = %d, z = %d", x, y, q, z_sub);
        
        // Test case 2
        x = 24'd3328; y = 24'd1; q = 24'd3329;
        #20;  // Wait for 2 clock cycles
        $display("Addition: x = %d, y = %d, q = %d, z = %d", x, y, q, z_add);
        $display("Subtraction: x = %d, y = %d, q = %d, z = %d", x, y, q, z_sub);

        // Test case 3
        x = 24'd1; y = 24'd1; q = 24'd3329;
        #20;  // Wait for 2 clock cycles
        $display("Addition: x = %d, y = %d, q = %d, z = %d", x, y, q, z_add);
        $display("Subtraction: x = %d, y = %d, q = %d, z = %d", x, y, q, z_sub);

        // Test case 4
        x = 24'd100; y = 24'd100; q = 24'd3329;
        #20;  // Wait for 2 clock cycles
        $display("Addition: x = %d, y = %d, q = %d, z = %d", x, y, q, z_add);
        $display("Subtraction: x = %d, y = %d, q = %d, z = %d", x, y, q, z_sub);

        $stop;
    end
endmodule

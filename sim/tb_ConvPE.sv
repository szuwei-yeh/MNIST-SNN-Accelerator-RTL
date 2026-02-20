`timescale 1ns/1ps

module tb_ConvPE;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 18;
    parameter V_THRESH   = 1000; 

    logic clk, rst_n, i_valid, i_clear_mem;
    logic signed [ACC_WIDTH-1:0] i_vmem_read;
    logic [8:0][DATA_WIDTH-1:0]  i_window;
    logic signed [8:0][DATA_WIDTH-1:0] i_weights;
    logic o_spike, o_vmem_valid;
    logic signed [ACC_WIDTH-1:0] o_vmem_write;

    
    ConvPE #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH), .V_THRESH(V_THRESH)) dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        
        rst_n = 0; i_valid = 0; i_clear_mem = 0; i_vmem_read = 0;
        i_window = '0; i_weights = '0;
        repeat(2) @(posedge clk);
        rst_n = 1;

        $display("=== Starting Test: ConvPE Signed Multiplication & LIF Accumulation ===");

        // --- Test 1: Negative Weight Accumulation (Verification for signed logic) ---
        // Assume Window inputs are all 1, Weights are all -10 (8'hF6)
        i_valid = 1; i_clear_mem = 1; 
        for(int k=0; k<9; k++) begin
            i_window[k]  = 8'd1;
            i_weights[k] = -8'sd10; 
        end
        @(posedge clk); 
        #1; $display("Test 1 (Frame 0): Vmem Write = %d (Expected: -90)", o_vmem_write);

        // --- Test 2: Potential Accumulation and Leakage ---
        i_clear_mem = 0;
        i_vmem_read = o_vmem_write; // Feed back the previously written potential
        @(posedge clk);
        // Expected: (Vmem_prev >> 1) + Input_Current
        // Calculation: (-90 >>> 1) + (-90) = -45 - 90 = -135
        #1; $display("Test 2 (Frame 1): Vmem Write = %d (Expected: -135)", o_vmem_write);

        // --- Test 3: Positive Accumulation until Spike Firing ---
        i_clear_mem = 1;
        for(int k=0; k<9; k++) i_weights[k] = 8'sd100; 
        @(posedge clk); // Frame 0: Vmem = 900
        i_clear_mem = 0;
        i_vmem_read = o_vmem_write; 
        @(posedge clk); // Frame 1: Vmem = (900 >>> 1) + 900 = 450 + 900 = 1350
        
        #1;
        if (o_spike) begin
            $display("Test 3: ★ Spike fired successfully! Vmem reset to zero");
        end else begin
            $display("Test 3: ❌ Spike failed to fire. Please check V_THRESH or comparison logic");
        end

        repeat(5) @(posedge clk);
        $finish;
    end
endmodule
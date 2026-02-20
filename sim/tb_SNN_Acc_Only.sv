// 274final_2.0/sim/tb_SNN_Acc_Only.sv
// Unit test for the first SNN layer only.
`timescale 1ns/1ps

module tb_SNN_Acc_Only;
    logic clk, rst_n, frame_rst_n, s_axis_valid, s_axis_ready, m_axis_valid, m_frame_done;
    logic [7:0] s_axis_data;
    logic [7:0] m_axis_spike;

    SNN_Accelerator dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    int valid_count = 0;
    int frame_count = 0;

    // Monitor the pulses
    always @(posedge clk) begin
        if (m_axis_valid) valid_count <= valid_count + 1;
        if (m_frame_done) frame_count <= frame_count + 1;
    end

    initial begin
        rst_n = 0; frame_rst_n = 0; s_axis_valid = 0; s_axis_data = 0;
        repeat(5) @(posedge clk);
        rst_n = 1; frame_rst_n = 1;

        $display("--- Testing SNN_Accelerator Pulse Counting ---");
        for (int f = 0; f < 16; f++) begin
            if (f > 0) begin
                frame_rst_n <= 0; @(posedge clk); frame_rst_n <= 1; @(posedge clk);
            end
            
            for (int i = 0; i < 784; i++) begin
                s_axis_valid <= 1;
                s_axis_data  <= 8'hA5; // Dummy data
                @(posedge clk);
            end
            s_axis_valid <= 0;
            repeat(10) @(posedge clk); // Pipeline flush
            $display("End of Frame %0d: Pulses so far = %0d", f, valid_count);
        end

        if (valid_count == 676 * 16) $display("✅ SUCCESS: Correct number of pulses!");
        else $display("❌ FAIL: Expected %0d, but got %0d", 676*16, valid_count);
        
        $finish;
    end
endmodule
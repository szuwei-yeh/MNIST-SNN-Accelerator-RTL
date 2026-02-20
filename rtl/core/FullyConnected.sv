module FullyConnected #(
    parameter int INPUT_LEN   = 169, 
    parameter int NUM_CLASSES = 10,
    parameter int DATA_WIDTH  = 8,
    parameter int ACC_WIDTH   = 32,
    parameter int FC_V_THRESH = 1024 
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    s_axis_valid,
    input  logic [7:0][2:0]         s_axis_pool, 
    
    output logic                    done,
    output logic [319:0]            flat_spike_counts 
);

    // --- 1. Memory and State Declarations ---
    logic signed [7:0] weights_mem [0 : 13519]; 
    initial begin
        $readmemh("weights_fc.hex", weights_mem);
    end

    logic [7:0] input_cnt; 
    logic [4:0] frame_cnt;

    logic signed [ACC_WIDTH-1:0] partial_sum [0:9]; 
    logic signed [ACC_WIDTH-1:0] v_mem       [0:9]; 
    logic [31:0]                 spike_count [0:9]; 

    // --- 2. Combinatorial Dot Product ---
    logic signed [ACC_WIDTH-1:0] cycle_dot_product [0:9];
    int mem_idx; 

    always_comb begin
        for (int k = 0; k < 10; k++) begin
            cycle_dot_product[k] = 0;
            for (int c = 0; c < 8; c++) begin
                mem_idx = (k * 1352) + (input_cnt * 8) + c;
                cycle_dot_product[k] = cycle_dot_product[k] + ($signed({1'b0, s_axis_pool[c]}) * weights_mem[mem_idx]);
            end
        end
    end

    // --- 3. Sequential LIF Logic & State Machine ---
    logic signed [ACC_WIDTH-1:0] v_mem_leaked_tmp;
    logic signed [ACC_WIDTH-1:0] v_mem_next_tmp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_cnt <= '0;
            frame_cnt <= '0;
            done      <= 1'b0;
            for (int k = 0; k < 10; k++) begin
                partial_sum[k] <= '0;
                v_mem[k]       <= '0;
                spike_count[k] <= '0;
                flat_spike_counts[k*32 +: 32] <= '0;
            end
        end else begin
            done <= 1'b0; 

            if (s_axis_valid && frame_cnt < 16) begin
                for (int k = 0; k < 10; k++) begin
                    partial_sum[k] <= partial_sum[k] + cycle_dot_product[k];
                end
                
                if (input_cnt == INPUT_LEN - 1) begin
                    input_cnt <= '0;

                    for (int k = 0; k < 10; k++) begin
                        // 1. Calculate leaked membrane potential (beta = 0.5)
                        v_mem_leaked_tmp = $signed(v_mem[k]) >>> 1;
                        // 2. Accumulate all input contributions for the current frame
                        v_mem_next_tmp   = v_mem_leaked_tmp + partial_sum[k] + cycle_dot_product[k];

                        // 3. LIF Threshold Comparison
                        if ($signed(v_mem_next_tmp) >= $signed(FC_V_THRESH)) begin
                            // --- Case: Spike Fired ---
                            if (frame_cnt == 15) begin
                                // Final frame: Output total spike count and reset state
                                flat_spike_counts[k*32 +: 32] <= spike_count[k] + 1;
                                spike_count[k] <= '0;
                                v_mem[k]       <= '0;
                            end else begin
                                spike_count[k] <= spike_count[k] + 1;
                                v_mem[k]       <= '0; // Reset-to-Zero
                            end
                        end else begin
                            // --- Case: No Spike Fired ---
                            if (frame_cnt == 15) begin
                                flat_spike_counts[k*32 +: 32] <= spike_count[k];
                                spike_count[k] <= '0;
                                v_mem[k]       <= '0;
                            end else begin
                                // Retain membrane potential
                                v_mem[k]       <= v_mem_next_tmp;
                            end
                        end

                        // Clear current frame accumulator
                        partial_sum[k] <= '0;
                    end

                    // Frame count control logic
                    if (frame_cnt == 15) begin
                        frame_cnt <= '0;
                        done      <= 1'b1;
                    end else begin
                        frame_cnt <= frame_cnt + 1;
                    end
                end else begin
                    input_cnt <= input_cnt + 1;
                end
            end
        end
    end
endmodule
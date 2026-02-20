module ConvPE #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 18,
    parameter int V_THRESH   = 59723
) (
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             i_valid,
    input  logic                             i_clear_mem,
    input  logic signed [ACC_WIDTH-1:0]      i_vmem_read,
    input  logic        [8:0][DATA_WIDTH-1:0] i_window,
    input  logic signed [8:0][DATA_WIDTH-1:0] i_weights,
    output logic                             o_spike,
    output logic                             o_vmem_valid,
    output logic signed [ACC_WIDTH-1:0]      o_vmem_write
);
    logic signed [ACC_WIDTH-1:0] current_sum;
    always_comb begin
        current_sum = 0;
        for (int i = 0; i < 9; i++) begin
            //current_sum = current_sum + ($signed({1'b0, i_window[i]}) * i_weights[i]);
            current_sum = current_sum + ($signed({1'b0, i_window[i]}) * $signed(i_weights[i]));
        end
    end

    logic signed [ACC_WIDTH-1:0] v_mem_current;
    logic signed [ACC_WIDTH-1:0] v_mem_next;
    logic spike_comb;

   always_comb begin
        
        if (i_clear_mem) begin
            v_mem_current = 0; 
        end else begin
            v_mem_current = i_vmem_read >>> 1;
        end

        v_mem_next = v_mem_current + current_sum;
        
        
        spike_comb = (i_valid && ($signed(v_mem_next) >= $signed(V_THRESH)));
        
        if (spike_comb) begin
            v_mem_next = '0; 
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_spike      <= 1'b0;
            o_vmem_valid <= 1'b0;
            o_vmem_write <= '0;
        end else begin
            o_spike      <= spike_comb;
            o_vmem_valid <= i_valid;
            o_vmem_write <= v_mem_next;
        end
    end
endmodule
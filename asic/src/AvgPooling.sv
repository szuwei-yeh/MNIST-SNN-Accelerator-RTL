// 274final_2.0/rtl/core/AvgPooling.sv

module AvgPooling #(
    parameter int INPUT_WIDTH  = 26,
    parameter int NUM_CHANNELS = 8
) (
    input  logic                                clk,
    input  logic                                rst_n,
    input  logic                                s_axis_valid,
    input  logic [NUM_CHANNELS-1:0]             s_axis_spike, 
    output logic                                m_axis_valid,
    output logic [NUM_CHANNELS-1:0][2:0]        m_axis_pool   
);

    logic [NUM_CHANNELS-1:0] linebuf [0:INPUT_WIDTH-1];
    

    logic [1:0] hstore [0:NUM_CHANNELS-1]; 

    logic [$clog2(INPUT_WIDTH)-1:0] col_cnt;
    logic [$clog2(INPUT_WIDTH)-1:0] row_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < INPUT_WIDTH; i++) linebuf[i] <= '0;
            for (int i = 0; i < NUM_CHANNELS; i++) hstore[i] <= '0;
            col_cnt      <= '0;
            row_cnt      <= '0;
            m_axis_valid <= 1'b0;
            m_axis_pool  <= '0;
        end else begin
            m_axis_valid <= 1'b0;

            if (s_axis_valid) begin
                if (col_cnt == INPUT_WIDTH - 1) begin
                    col_cnt <= '0;
                    row_cnt <= (row_cnt == INPUT_WIDTH - 1) ? '0 : row_cnt + 1'b1;
                end else begin
                    col_cnt <= col_cnt + 1'b1;
                end

                for (int c = 0; c < NUM_CHANNELS; c++) begin
                    if (col_cnt[0] == 1'b0) begin
                        linebuf[col_cnt][c] <= s_axis_spike[c];
                        hstore[c]           <= s_axis_spike[c] + linebuf[col_cnt][c];
                    end else begin
                        if (row_cnt[0] == 1'b1) begin
                            m_axis_pool[c] <= hstore[c] + s_axis_spike[c] + linebuf[col_cnt][c];
                            m_axis_valid   <= (c == NUM_CHANNELS - 1); 
                        end
                        linebuf[col_cnt][c] <= s_axis_spike[c];
                    end
                end
            end
        end
    end
endmodule
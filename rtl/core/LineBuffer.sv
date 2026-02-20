module LineBuffer #(
  parameter int IMG_WIDTH  = 28,
  parameter int DATA_WIDTH = 8
) (
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  i_valid,
  input  logic [DATA_WIDTH-1:0] i_data,
  output logic                  o_valid,
  output logic [8:0][DATA_WIDTH-1:0] o_window
);

  logic [DATA_WIDTH-1:0] lb0 [0:IMG_WIDTH-1];
  logic [DATA_WIDTH-1:0] lb1 [0:IMG_WIDTH-1];
  logic [DATA_WIDTH-1:0] w0, w1, w2, w3, w4, w5, w6, w7, w8;


  assign o_window[0] = w0; assign o_window[1] = w1; assign o_window[2] = w2;
  assign o_window[3] = w3; assign o_window[4] = w4; assign o_window[5] = w5;
  assign o_window[6] = w6; assign o_window[7] = w7; assign o_window[8] = w8;

  integer col_cnt;
  integer row_cnt;
  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < IMG_WIDTH; i = i + 1) begin
        lb0[i] <= 8'd0;
        lb1[i] <= 8'd0;
      end
      w0 <= 0; w1 <= 0; w2 <= 0;
      w3 <= 0; w4 <= 0; w5 <= 0; w6 <= 0; w7 <= 0; w8 <= 0;
      col_cnt <= 0;
      row_cnt <= 0;
      o_valid <= 0;
    end else begin
      
     
      if (i_valid) begin
        // 1. Shift Logic
        for (i = IMG_WIDTH-1; i > 0; i = i - 1) begin
          lb0[i] <= lb0[i-1];
          lb1[i] <= lb1[i-1];
        end
        lb0[0] <= i_data;
        lb1[0] <= lb0[IMG_WIDTH-1];

        // Update Window
        w8 <= i_data;
        w7 <= w8; w6 <= w7;
        w5 <= lb0[IMG_WIDTH-1]; w4 <= w5; w3 <= w4;
        w2 <= lb1[IMG_WIDTH-1]; w1 <= w2; w0 <= w1;

        // 2. Counters Logic
        if (col_cnt == IMG_WIDTH-1) begin
          col_cnt <= 0;
          if (row_cnt < IMG_WIDTH + 2) 
             row_cnt <= row_cnt + 1;
        end else begin
          col_cnt <= col_cnt + 1;
        end

        // 3. Valid Logic (update o_valid)
        if (row_cnt >= 2 && col_cnt >= 2)
          o_valid <= 1;
        else
          o_valid <= 0;
      end else begin 
          o_valid <= 0; 
      end
      
    end
  end
endmodule
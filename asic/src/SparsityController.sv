module SparsityController #(
  parameter bit SKIP_CENTER_ZERO_ONLY = 1'b0
) (
  input  logic [8:0][7:0] i_window,
  input  logic            i_valid,
  output logic            o_skip,
  output logic            o_fire_enable
);

  logic all_zero;
  logic center_zero;

  assign all_zero = (i_window[0] == 8'h00) && (i_window[1] == 8'h00) && (i_window[2] == 8'h00) &&
                    (i_window[3] == 8'h00) && (i_window[4] == 8'h00) && (i_window[5] == 8'h00) &&
                    (i_window[6] == 8'h00) && (i_window[7] == 8'h00) && (i_window[8] == 8'h00);
                    
  assign center_zero = (i_window[4] == 8'h00);

  assign o_skip = (i_valid && (SKIP_CENTER_ZERO_ONLY ? center_zero : all_zero)) ? 1'b1 : 1'b0;
  
  assign o_fire_enable = (i_valid && !(SKIP_CENTER_ZERO_ONLY ? center_zero : all_zero)) ? 1'b1 : 1'b0;

endmodule
// =============================================================
// SNN_Conv_Top.sv  —  ASIC synthesis top (Conv + Pool only)
// FC layer excluded: 13,520 weights require SRAM macro,
// not suitable for standard-cell-only flow.
// Original full system: rtl/top/Top_System.sv
// =============================================================
module SNN_Conv_Top #(
    parameter int IMG_WIDTH   = 28,
    parameter int NUM_FILTERS = 8,
    parameter int DATA_WIDTH  = 8,
    parameter int ACC_WIDTH   = 24,
    parameter int V_THRESH    = 59723,
    parameter int POOL_WIDTH  = 26
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     frame_rst_n,

    // Input pixel stream
    input  logic                     s_axis_valid,
    output logic                     s_axis_ready,
    input  logic [DATA_WIDTH-1:0]    s_axis_data,

    // Output: pooled feature map (ready for off-chip FC)
    output logic                     pool_valid,
    output logic [NUM_FILTERS-1:0][2:0] pool_data,

    // Frame done pulse
    output logic                     frame_done
);

    logic                        l1_valid;
    logic [NUM_FILTERS-1:0]      l1_spike;

    SNN_Accelerator #(
        .IMG_WIDTH   (IMG_WIDTH),
        .NUM_FILTERS (NUM_FILTERS),
        .DATA_WIDTH  (DATA_WIDTH),
        .ACC_WIDTH   (ACC_WIDTH),
        .V_THRESH    (V_THRESH)
    ) u_conv (
        .clk          (clk),
        .rst_n        (rst_n),
        .frame_rst_n  (frame_rst_n),
        .s_axis_valid (s_axis_valid),
        .s_axis_ready (s_axis_ready),
        .s_axis_data  (s_axis_data),
        .m_axis_valid (l1_valid),
        .m_axis_spike (l1_spike),
        .m_frame_done (frame_done)
    );

    AvgPooling #(
        .INPUT_WIDTH  (POOL_WIDTH),
        .NUM_CHANNELS (NUM_FILTERS)
    ) u_pool (
        .clk          (clk),
        .rst_n        (frame_rst_n),
        .s_axis_valid (l1_valid),
        .s_axis_spike (l1_spike),
        .m_axis_valid (pool_valid),
        .m_axis_pool  (pool_data)
    );

endmodule

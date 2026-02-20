module Vmem_Array #(
    parameter int ACC_WIDTH = 18,
    parameter int MAP_SIZE  = 676 // 26x26 valid pixels
) (
    input  logic                 clk,
    input  logic                 i_we,     // Write Enable
    input  logic [9:0]           i_raddr,  // Read Address (Current pixel)
    input  logic [9:0]           i_waddr,  // Write Address (Delayed by 1 cycle)
    input  logic [ACC_WIDTH-1:0] i_wdata,  // New Vmem to write back
    output logic [ACC_WIDTH-1:0] o_rdata   // Old Vmem for current pixel
);

    // Distributed RAM inference
    logic [ACC_WIDTH-1:0] ram [0:MAP_SIZE-1];

    // Asynchronous Read: Data is available in the same cycle address is provided
    assign o_rdata = ram[i_raddr];

    // Synchronous Write: Update Vmem on the clock edge
    always_ff @(posedge clk) begin
        if (i_we) begin
            ram[i_waddr] <= i_wdata;
        end
    end

endmodule
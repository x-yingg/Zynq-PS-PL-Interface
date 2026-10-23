`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2026 03:16:54 PM
// Design Name: 
// Module Name: axi_stream_xor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_stream_xor(
    // System Signals
    input  logic        aclk,
    input  logic        aresetn,
    
    // Configurable XOR Mask (from AXI4-Lite Slave)
    input  logic [31:0] xor_mask,
    
    // --------------------------------------------------------
    // S_AXIS: AXI4-Stream Slave Interface (Receives from DMA)
    // --------------------------------------------------------
    input  logic [31:0] s_axis_tdata,
    input  logic [3:0]  s_axis_tkeep,
    input  logic        s_axis_tvalid,
    input  logic        s_axis_tlast,
    output logic        s_axis_tready, // Notice this is an output
    
    // --------------------------------------------------------
    // M_AXIS: AXI4-Stream Master Interface (Sends back to DMA)
    // --------------------------------------------------------
    output logic [31:0] m_axis_tdata,
    output logic [3:0]  m_axis_tkeep,
    output logic        m_axis_tvalid,
    output logic        m_axis_tlast,
    input  logic        m_axis_tready  // Notice this is an input
);

    // 1. Data Modification (The Payload)
    // Apply the combinational XOR mask directly to the 32-bit data stream.
    assign m_axis_tdata = s_axis_tdata ^ xor_mask;

    // 2. Control Signal Passthrough
    // The valid, keep, and last signals travel forward with the data.
    // They are passed completely unmodified.
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tkeep  = s_axis_tkeep;
    assign m_axis_tlast  = s_axis_tlast;

    // 3. Backpressure Handling (The Handshake)
    // The ready signal travels backwards up the pipeline.
    // We tell the upstream sender (DMA MM2S) that we are only ready 
    // to receive data if the downstream receiver (DMA S2MM) is also ready.
    assign s_axis_tready = m_axis_tready;
endmodule

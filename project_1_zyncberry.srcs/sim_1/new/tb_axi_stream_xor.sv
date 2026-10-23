`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2026 04:01:09 PM
// Design Name: 
// Module Name: tb_axi_stream_xor
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

module tb_axi_stream_xor();

    // System Signals
    logic aclk = 0;
    logic aresetn = 0;
    
    // S_AXIS Inputs to DUT (Device Under Test)
    logic [31:0] s_axis_tdata = 0;
    logic [3:0]  s_axis_tkeep = 4'hF;
    logic        s_axis_tvalid = 0;
    logic        s_axis_tlast = 0;
    logic        s_axis_tready; // Output from DUT
    
    // M_AXIS Outputs from DUT
    logic [31:0] m_axis_tdata;
    logic [3:0]  m_axis_tkeep;
    logic        m_axis_tvalid;
    logic        m_axis_tlast;
    logic        m_axis_tready = 1; // Driven by testbench (acting as downstream DMA)

    // Instantiate the custom RTL module using SystemVerilog wildcard connections
    axi_stream_xor dut (.*);

    // Generate a 100 MHz clock
    always #5 aclk = ~aclk; 

    initial begin
        // 1. Apply Reset
        #20 aresetn = 1;
        
        // Wait for next clock edge
        @(posedge aclk);
        
        // 2. Start a Data Burst (Sender is valid, Receiver is ready)
        s_axis_tvalid <= 1;
        s_axis_tdata  <= 32'h00000000; // Expect output: DEADBEEF
        
        @(posedge aclk);
        s_axis_tdata  <= 32'hFFFFFFFF; // Expect output: 21524110 (Inverted mask)
        
        // 3. Test Backpressure (Receiver suddenly not ready)
        @(posedge aclk);
        m_axis_tready <= 0;            // Downstream DMA drops ready
        s_axis_tdata  <= 32'h11111111; // Send next word
        
        // Hold for 3 clock cycles to verify DUT freezes data and drops s_axis_tready
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        
        // 4. Resume Transfer
        m_axis_tready <= 1;
        
        // 5. End of Packet
        @(posedge aclk);
        s_axis_tlast  <= 1;
        s_axis_tdata  <= 32'h12345678;
        
        // 6. Stop sending
        @(posedge aclk);
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
        
        // Wait 50ns and end simulation
        #50 $finish;
    end

endmodule

module Clock(
    input sys_clk, //H11 3.3V 27Mhz Input
    input manual_clk, //T3
    input sys_rst_n, //T10 3.3V negative reset Also S0 key at dock board 
    input clk_select, //T5
    input HLT, //Hold the timer 
    output c_clk
);

parameter cycle_count = 1_350_000;

reg [24:0] counter = 0;
reg manual_clk_old = 0;
wire manual_clk_inverted = !manual_clk;
wire m_clk_rising = (!manual_clk_old && manual_clk_inverted);

reg a_clk = 0;
reg m_clk = 0;

assign c_clk = (clk_select)? a_clk:m_clk;

always@(posedge sys_clk or negedge sys_rst_n) begin

    if (!sys_rst_n) begin
        counter <= 0;
        a_clk <= 0;
        m_clk <= 0;
        manual_clk_old <= 0;
    end
    
    else begin
        counter <= counter + 1;
        manual_clk_old <= manual_clk_inverted;
        if (counter >= cycle_count) begin 
            counter <= 0;
            if (!HLT) a_clk <= !a_clk;
        end
        
        if (m_clk_rising && !HLT) m_clk <= !m_clk;
    end
end

endmodule
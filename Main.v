module Main_Computer(
    input sys_clk, //H11 3.3V 27Mhz Input
    input sys_rst_n, //T10 3.3V negative reset Also S0 key at dock board 
    input manual_clk, //T3 
    input clk_select, //T5
    output TX,
    output clk_led
    
);

wire c_clk; //Computer Clock 
wire c_clk_inverted = !c_clk; //Inverted Clock

wire HLT; //Stop the clock

Clock main_clock(.sys_clk(sys_clk),.manual_clk(manual_clk),.clk_select(clk_select),.HLT(HLT),.sys_rst_n(sys_rst_n),.c_clk(c_clk));
assign clk_led = c_clk_inverted;

reg[7:0] BUS = 8'b0000_0000;

reg[7:0] REG_A = 8'b0000_0000;
wire REG_A_ENABLE;
wire REG_A_LOAD;

wire ZERO_FLAG = (REG_A == 8'b0);

reg[7:0] REG_B = 8'b0000_0000;
wire REG_B_ENABLE = 0;
wire REG_B_LOAD;


reg[7:0] REG_I = 8'b0000_0000;
wire REG_I_ENABLE;
wire REG_I_LOAD;

//ALU Design -------------------

assign SUBSTRACT = (REG_I[7:4] == 4'b0011);
wire [7:0]REG_B_XORED = REG_B ^ {8{SUBSTRACT}};

wire[8:0] REG_SUM = REG_A + REG_B_XORED + SUBSTRACT;
wire [7:0] AND_RESULT = REG_A & REG_B;
wire [7:0] OR_RESULT  = REG_A | REG_B;
wire [7:0] XOR_RESULT = REG_A ^ REG_B;

reg [7:0] ALU_RESULT;

always @(*) begin
    case (REG_I[7:4])
        4'b0010: ALU_RESULT = REG_SUM[7:0]; // ADD
        4'b1101: ALU_RESULT = REG_SUM[7:0]; // SHL (Uses Adder)
        4'b0011: ALU_RESULT = REG_SUM[7:0]; // SUB (Needs Subtract on)
        4'b1010: ALU_RESULT = AND_RESULT;   // AND
        4'b1011: ALU_RESULT = OR_RESULT;    // OR
        4'b1100: ALU_RESULT = XOR_RESULT;   // XOR
        default: ALU_RESULT = REG_SUM[7:0]; // Default to Adder
    endcase
end

wire is_add = (REG_I[7:4] == 4'b0010);
wire is_sub = (REG_I[7:4] == 4'b0011);
wire is_shl = (REG_I[7:4] == 4'b1101); // SHL uses the adder, so Carry is valid (Bit shifted out)

wire is_math_op = (is_add || is_sub || is_shl);


wire REG_SUM_ENABLE;

//---------------------------

reg CARRY_STORED = 0;
wire CARRY_FLAG = CARRY_STORED;

reg[3:0] RAM_ADDRESS = 4'b0000;
wire RAM_ADDRESS_LOAD;
wire RAM_LOAD;
wire [7:0]RAM_DOUT;
wire RAM_ENABLE;

reg [3:0] P_COUNTER = 4'b0000;
wire P_COUNTER_ENABLE;
wire INCREMENT_ENABLE; //Counter Enable
wire P_COUNTER_LOAD; //Also Jump 

reg [7:0]REG_OUT = 8'b0000_0000;
wire REG_OUT_LOAD;

reg [2:0]MICRO_I_COUNTER = 3'b000;
//wire [7:0]MICRO_I_SIGNALS = 1'b1 << MICRO_I_COUNTER; //3 to 8 Decoder For Micro Instructions 


//{HLT,RAM_ADDRESS_LOAD,RAM_LOAD,RAM_ENABLE,REG_I_ENABLE,REG_I_LOAD,REG_A_LOAD,REG_A_ENABLE,REG_SUM_ENABLE,SUBSTRACT,REG_B_LOAD,REG_OUT_LOAD,INCREMENT_ENABLE,P_COUNTER_ENABLE,P_COUNTER_LOAD}
//All control signals
Main_SRAM sram1(
    .address(RAM_ADDRESS),   // 4 bits for 16 bytes
    .data_in(BUS),
    .write_enable(RAM_LOAD),    //High Write
    .clk(c_clk),
    .sys_rst_n(sys_rst_n),
    .data_out(RAM_DOUT)
);
// Never write to first 8 address they are reserved for program.

// If Step < 2, force Opcode to 0. Otherwise use real Opcode.
wire [3:0] clean_opcode = (MICRO_I_COUNTER < 2) ? 4'b0000 : REG_I[7:4];
wire [6:0] rom_address = {clean_opcode, MICRO_I_COUNTER}; //4 bit instruction 3 bit micro step


wire [15:0]control_signals;
wire extra_bit, extra_bit_2;

wire JUMP;

assign {HLT,RAM_ADDRESS_LOAD,RAM_LOAD,RAM_ENABLE,REG_I_ENABLE,REG_I_LOAD,REG_A_LOAD,REG_A_ENABLE,extra_bit,REG_SUM_ENABLE,extra_bit_2,REG_B_LOAD,REG_OUT_LOAD,INCREMENT_ENABLE,P_COUNTER_ENABLE,JUMP} = control_signals;


wire is_jc_instruction = (REG_I[7:4] == 4'b0111); // Assuming 0111 is JC (Jump if carry)
wire is_jz_instruction = (REG_I[7:4] == 4'b1000); // Assuming 1000 is JZ (Jump if zero)
wire is_jnc_instruction = (REG_I[7:4] == 4'b1001); //Assuming 1001 is JNC (Jump if not carry)


assign P_COUNTER_LOAD = (is_jz_instruction && ZERO_FLAG) || (is_jc_instruction && CARRY_FLAG) || (is_jnc_instruction && !CARRY_FLAG) || (JUMP);


Gowin_pROM_Control_Logic control_pROM(
        .dout(control_signals), //output [15:0] dout
        .clk(sys_clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(!sys_rst_n), //input reset
        .ad(rom_address) //input [6:0] ad
    );


reg uart_wr_en = 0;
reg [7:0] uart_data = 0;
wire uart_write_done;

UART_Controller #(
        .BAUD_RATE(9600),
        .CLOCK_FREQ(27000000)
)debug_uart (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .write_enable(uart_wr_en),
        .data_to_send(uart_data),
        .RX(1'b1), // Unused
        .TX(TX),
        .write_done(uart_write_done),
        .read_done(),
        .data_readed()
);

reg [4:0] debug_state = 0;
reg [1:0] c_clk_edge = 0;
wire c_clk_rising = (c_clk_edge == 2'b01);

always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            debug_state <= 0;
            uart_wr_en <= 0;
            c_clk_edge <= 0;
        end
        else begin
            // Detect Rising Edge of Computer Clock (c_clk)
            c_clk_edge <= {c_clk_edge[0], c_clk};
            case (debug_state)
                // IDLE: Wait for Computer Step
                0: if (c_clk_rising) debug_state <= 1;

                // --- SEND BYTE 0 (Header 0xAA) ---
                1: begin uart_data <= 8'hAA; uart_wr_en <= 1; debug_state <= 2; end
                2: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 3; end // Wait Done
                3: if (!uart_write_done) debug_state <= 4; // Wait Reset

                // --- SEND BYTE 1 (PC) ---
                4: begin uart_data <= {4'b0, P_COUNTER}; uart_wr_en <= 1; debug_state <= 5; end
                5: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 6; end
                6: if (!uart_write_done) debug_state <= 7;

                // --- SEND BYTE 2 (Instruction) ---
                7: begin uart_data <= REG_I; uart_wr_en <= 1; debug_state <= 8; end
                8: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 9; end
                9: if (!uart_write_done) debug_state <= 10;

                // --- SEND BYTE 3 (REG A) ---
                10: begin uart_data <= REG_A; uart_wr_en <= 1; debug_state <= 11; end
                11: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 12; end
                12: if (!uart_write_done) debug_state <= 13;

                // --- SEND BYTE 4 (REG B) ---
                13: begin uart_data <= REG_B; uart_wr_en <= 1; debug_state <= 14; end
                14: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 15; end
                15: if (!uart_write_done) debug_state <= 16;

                // --- SEND BYTE 5 (REG OUT) ---
                16: begin uart_data <= REG_OUT; uart_wr_en <= 1; debug_state <= 17; end
                17: if (uart_write_done) begin uart_wr_en <= 0; debug_state <= 18; end
                18: if (!uart_write_done) debug_state <= 0; // Finished! Return to IDLE.

                default: debug_state <= 0;
            endcase
        end
end
// ============================================================


always@(posedge c_clk or negedge sys_rst_n) begin //Sequential Part
    if (!sys_rst_n) begin

        REG_A <= 8'b0000_0000;

        REG_B <= 8'b0000_0000;

        REG_I <= 8'b0000_0000;

        RAM_ADDRESS <= 4'b0000;

        P_COUNTER <= 4'b0000;

        REG_OUT <= 8'b0000_0000;
        
        CARRY_STORED <= 0;
        
    end

    else begin
        if (REG_A_LOAD) REG_A <= BUS;

        if (REG_B_LOAD) REG_B <= BUS;
        
        if (REG_I_LOAD) REG_I <= BUS;

        if(RAM_ADDRESS_LOAD) RAM_ADDRESS <= BUS[3:0];

        if(INCREMENT_ENABLE) P_COUNTER <= P_COUNTER + 1;
        
        if(P_COUNTER_LOAD) P_COUNTER <= BUS[3:0];

        if(REG_OUT_LOAD) REG_OUT <= BUS;

        if (REG_A_LOAD && REG_SUM_ENABLE && is_math_op) begin
            CARRY_STORED <= REG_SUM[8]; 
        end

    end
end


always@(posedge c_clk_inverted or negedge sys_rst_n) begin //Sequential Part Inverted Clock For Control Part
    if (!sys_rst_n) begin        
        MICRO_I_COUNTER <= 3'b000;
    end

    else begin
        MICRO_I_COUNTER <= MICRO_I_COUNTER + 1;        
    end
end

always@(*) begin //BUS Control
        if (REG_A_ENABLE) BUS = REG_A;
        else if (REG_B_ENABLE) BUS = REG_B;
        else if (REG_I_ENABLE) BUS = {4'b0000,REG_I[3:0]};
        else if (REG_SUM_ENABLE) BUS = ALU_RESULT;
        else if (RAM_ENABLE) BUS = RAM_DOUT;
        else if (P_COUNTER_ENABLE) BUS = {4'b0000,P_COUNTER}; 
        else BUS = 8'b0000_0000;       
end


endmodule
module Main_SRAM(
    input [3:0] address,   // 4 bits for 16 bytes
    input [7:0] data_in,
    input write_enable,    //High Write / Low Read
    input clk,
    input sys_rst_n,
    output [7:0] data_out
);
    reg [7:0] memory [0:15];

    initial begin
        $readmemb("16byte_ram.mi", memory);
    end

    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            //memory[8] <= 8'b0000_0000;
            //memory[9] <= 8'b0000_0000;
            //memory[10] <= 8'b0000_0000;
            //memory[11] <= 8'b0000_0000;
            //memory[12] <= 8'b0000_0000;
            memory[13] <= 8'b0000_0000;
            memory[14] <= 8'b0000_0000;
            memory[15] <= 8'b0000_0000;
        end

        else begin
            if (write_enable && address >= 4'd13) begin //Hardcore write protection to first 8 byte (Code Memory)
                memory[address] <= data_in;
            end
        end
    end

    assign data_out = memory[address];

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:18:39 11/16/2008 
// Design Name: 
// Module Name:    datamux 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module datamux(
	input clk,
	input reset,
	input [15:0] cpu_next_addr,
	input cpu_next_rd,
	input cpu_next_we,
   output reg [7:0] cpu_di,
	output reg cpu_enable,
	
	// ram
	output reg ram_we,
	input [7:0] ram_data,
	
	// rom
	input [7:0] rom_data,
	
	// uart
	input [7:0] uart_data,
	input [7:0] uart_status,
	output reg uart_rd,
	output reg uart_load,
		
	// SDCard spi controller
	input spi_ack,
	input [7:0] spi_data,
	output reg spi_wr,
	output reg spi_stb,
	
	//maxII SPI
	input [7:0] maxspi_data,
	output reg maxspi_wr,
	output reg maxspi_rd,

	//gpio
	input [7:0] gpio_data,
	output reg gpio_wr,
	output reg gpio_rd,

	//steppers
	input [7:0] steppers_data,
	output reg steppers_wr,
	output reg steppers_rd
);

reg [3:0] input_select;
reg [3:0] next_input_select;
reg [7:0] uart_data_reg;
reg next_cpu_enable;

always @(cpu_next_addr, cpu_next_rd, cpu_next_we, cpu_enable)
	begin
		ram_we <= 0;
		uart_rd <= 0;
		uart_load <= 0;
		next_input_select <= 0;
		spi_wr <= 0;
		spi_stb <= 0;
		maxspi_wr <= 0;
		maxspi_rd <= 0;
		gpio_wr <= 0;
		gpio_rd <= 0;
		steppers_wr <= 0;
		steppers_rd <= 0;
		if (cpu_next_addr[15] == 0) // RAM 0x0000 - 0x7FFF
			begin
				if (cpu_next_we == 1)
					ram_we <= 1;
				else
					next_input_select <= 1;
			end
		else if (cpu_next_addr[15:13] == 7) // ROM 0xE000 - 0xFFFF
			next_input_select <= 2;
		else if (cpu_next_addr[15:8] == 8'hD0) // UART 0xD000 - 0xD0FF
			begin
				if (cpu_next_addr[0] == 0) // 0xD000 - UART_DATA, read - read rx data, write - write tx data
					begin
						if (cpu_next_we == 0)
							begin
								next_input_select <= 3;
								uart_rd <= 1;
							end
						else
							uart_load <= 1;
					end
				else  // 0xD001 - UART_STATUS
					if (cpu_next_we == 0)
						next_input_select <= 4;
			end
		else if (cpu_next_addr[15:8] == 8'hD1) // SPI 0xD100 - 0xD1FF
			begin
				spi_stb <= 1;
				next_input_select <= 5;
				if (cpu_next_we == 1)
					begin
						spi_wr <= 1;
					end
			end
		else if (cpu_next_addr[15:8] == 8'hD2) // MAXII SPI 0xD200 - 0xD2FF
			begin
				next_input_select <= 6;
				if (cpu_next_we == 1)
					begin
						maxspi_wr <= 1;
					end
				if (cpu_next_rd == 1)
					begin
						maxspi_rd <= 1;
					end
			end
		else if (cpu_next_addr[15:8] == 8'hD3) // GPIO 0xD300 - 0xD3FF
			begin
				next_input_select <= 7;
				if (cpu_next_we == 1)
					begin
						gpio_wr <= 1;
					end
				if (cpu_next_rd == 1)
					begin
						gpio_rd <= 1;
					end
			end
		else if (cpu_next_addr[15:8] == 8'hD4) // steppers 0xD400 - 0xD4FF
			begin
				next_input_select <= 8;
				if (cpu_next_we == 1)
					begin
						steppers_wr <= 1;
					end
				if (cpu_next_rd == 1)
					begin
						steppers_rd <= 1;
					end
			end
	end
	
always @(posedge clk)
	begin
		input_select <= next_input_select;
		uart_data_reg <= uart_data;
	end
	
always @(input_select, ram_data, rom_data, uart_data_reg, uart_status, spi_data, maxspi_data, gpio_data, steppers_data)
	begin
		if (input_select == 1)
			cpu_di <= ram_data;
		else if (input_select == 2)
			cpu_di <= rom_data;
		else if (input_select == 3)
			cpu_di <= uart_data_reg;
		else if (input_select == 4)
			cpu_di <= uart_status;
		else if (input_select == 5)
			cpu_di <= spi_data;
		else if (input_select == 6)
			cpu_di <= maxspi_data;
		else if (input_select == 7)
			cpu_di <= gpio_data;
		else if (input_select == 8)
			cpu_di <= steppers_data;
		else
			cpu_di <= 0;
	end

always @(next_input_select, spi_ack)
	begin
		if (next_input_select == 5)
			cpu_enable <= spi_ack;
		else
			cpu_enable <= 1;
	end
	
endmodule

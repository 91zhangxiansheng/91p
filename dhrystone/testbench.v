`timescale 1 ns / 1 ps

module testbench;
	reg clk = 1;
	reg resetn = 0;
	wire trap;

	always #5 clk = ~clk;

	initial begin
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;

	picorv32 uut (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.trap     (trap     ),
		.mem_valid(mem_valid),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),
		.mem_addr (mem_addr ),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata)
	);

	reg [31:0] memory [0:64*1024/4-1];
	initial $readmemh("dhry.hex", memory);

	always @(posedge clk) begin
		mem_ready <= 0;
		mem_rdata <= 'bx;
		if (resetn && mem_valid && !mem_ready) begin
			mem_ready <= 1;
			if (mem_addr == 32'h1000_0000) begin
				$write("%c", mem_wdata);
				$fflush();
			end else
			if (mem_wstrb) begin
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
			end else begin
				mem_rdata <= memory[mem_addr >> 2];
			end
		end
	end

	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);
	end

	always @(posedge clk) begin
		if (resetn && trap) begin
			repeat (10) @(posedge clk);
			$display("TRAP");
			$finish;
		end
	end
endmodule

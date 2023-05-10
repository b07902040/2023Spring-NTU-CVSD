`timescale 1ns/100ps
`define CYCLE       22     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   2


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
    `define OP_NUM 41
    `define GOLDEN_NUM 80
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
    `define OP_NUM 41
    `define GOLDEN_NUM 320
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERN/indata3.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
    `define OP_NUM 41
    `define GOLDEN_NUM 320
`elsif tb4
    `define INFILE "../00_TESTBED/PATTERN/indata4.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode4.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden4.dat"
    `define OP_NUM 121
    `define GOLDEN_NUM 708
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
    `define OP_NUM 41
    `define GOLDEN_NUM 1984
`endif

`define SDFFILE "core_syn.sdf"  // Modify your sdf file name


module testbed;

reg        clk, rst_n;
reg        op_valid;
reg [3:0]  op_mode;
reg [3:0]  op_mode_aaa;
wire       op_ready;
reg        in_valid;
reg [7:0]  in_data;
wire       in_ready;
wire       out_valid;
wire signed [13:0] out_data;

reg  [7:0] indata_mem [0:2047];
reg  [3:0] opmode_mem [0:1023];
reg signed [13:0] golden_mem [0:4095];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
integer i;
integer j;
integer k;
integer error;
integer cycle_count;

// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_core);
    initial #1 $display("SDF File %s    .", `SDFFILE);
`endif

// Write out waveform file
//initial begin
//  $fsdbDumpfile("core.fsdb");
//  $fsdbDumpvars(3, "+mda");
//end


core u_core (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_op_valid(op_valid),
	.i_op_mode(op_mode),
    .o_op_ready(op_ready),
	.i_in_valid(in_valid),
	.i_in_data(in_data),
	.o_in_ready(in_ready),
	.o_out_valid(out_valid),
	.o_out_data(out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

initial begin
    cycle_count = 0;
end

//========== cycle count ==========//
	always@(posedge clk) begin
			cycle_count <= cycle_count + 1;
	end

// Clock generation
initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

// Reset generation
initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

// ==============================================
// TODO: Check pattern after process finish
// ==============================================

reg signed [13:0] golden_data;
// give input
initial begin
    op_valid = 0;
    in_valid = 0;
    i = 0;
    while (i < `OP_NUM) begin
        @(negedge clk);
        if (op_ready) begin
            @(negedge clk);
            op_valid = 1;
            op_mode = opmode_mem[i][3:0];
            op_mode_aaa = opmode_mem[i][3:0];
            $display("YA,Correct! mode = %d , %d",op_mode, i);
            @(negedge clk);
            op_valid = 0;
            op_mode = 0;
            if (op_mode_aaa == 0) begin
                j = 0;
                while (j < 2048) begin
                    in_valid = 1;
                    in_data = indata_mem[j][7:0];
                    if (in_ready) begin
                        j = j + 1;
                    end
                    @(negedge clk);
                end
                in_valid = 0;
            end
            i = i + 1;
        end
    end
end
//
initial begin
    k = 0;
    error = 0;
    while (k < `GOLDEN_NUM) begin
        @(negedge clk);
        if (out_valid) begin
            golden_data = golden_mem[k][13:0];
            //$display("%d %d %d",k, golden_data, out_data);
            if (out_data !== golden_data) begin
            //        $display ("Test[%4d]: Error! GOLDEN=(%d), yours=(%d)", k, golden_data, out_data);
                    error = error+1;
            end     
            //else begin
            //    $display("Test[%4d]: Right! GOLDEN=(%d), yours=(%d)", k, golden_data, out_data);
            //end 
            k = k + 1;
        end
    end
    if(error == 0) begin
            $display("----------------------------------------------");
            $display("-                 ALL PASS!                  -");
            $display("----------------------------------------------");
        end else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total error: %d                      ", error);
            $display("----------------------------------------------");
        end
        # ( 2 * `CYCLE);
        $display("End of Process, total cycle = %d",cycle_count);
        $finish;
end

endmodule

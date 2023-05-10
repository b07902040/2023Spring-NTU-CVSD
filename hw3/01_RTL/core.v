module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
	output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// ====================== wire/reg ========================= //
reg [10:0] counter_2047;
reg  [7:0] counter_256;
reg  [4:0] counter_9;
reg  [5:0] dis_size, dis_size_nxt;

reg  [7:0] in_data;
reg  [3:0] op, op_mode;
reg  [2:0] origin_row, origin_col;
reg        in_ready, op_ready, op_ready_nxt, op_valid;

// ====================== read-in ========================= //
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		in_data	<= 0;
		op_valid <= 0;
		op_mode	<= 0;
		op	<= 0;	
	end 
	else begin
		in_data  <= i_in_data;
		op_valid <= i_op_valid;
		op_mode  <= i_op_mode;
		if(op_valid) op <= op_mode;
	end
end

parameter OP_LOAD    = 4'b0000;//0
parameter OP_RIGHT   = 4'b0001;//1
parameter OP_LEFT    = 4'b0010;//2
parameter OP_UP      = 4'b0011;//3
parameter OP_DOWN    = 4'b0100;//4
parameter OP_CN_DOWN = 4'b0101;//5
parameter OP_CN_UP   = 4'b0110;//6
parameter OP_DIS     = 4'b0111;//7
parameter OP_CONV    = 4'b1000;//8
parameter OP_MED     = 4'b1001;//9
parameter OP_HAM     = 4'b1010;//10
// ========================= FSM =========================== //
parameter S_IDLE  = 5'd0;
parameter S_READY = 5'd1;
parameter S_BUF1  = 5'd2;
parameter S_BUF2  = 5'd3;
parameter S_LOAD  = 5'd4;
parameter S_FIRE  = 5'd5;
parameter S_BUF3  = 5'd6;
parameter S_GOP   = 5'd7;
parameter S_BUF4  = 5'd8;
parameter S_DIS4  = 5'd9;
parameter S_DIS2  = 5'd10;
parameter S_DIS1  = 5'd11;
parameter S_BUF6  = 5'd12;
parameter S_BUF7  = 5'd13;
parameter S_BUF8  = 5'd14;
parameter S_BUF5  = 5'd15;
parameter S_DIS_HAM = 5'd16;
parameter S_DIS_MED = 5'd17;


parameter DIS_8x4 = 6'd32;
parameter DIS_8x2 = 6'd16;
parameter DIS_8x1 = 6'd8;

reg [4:0] state, state_nxt;

always@(*) begin
	state_nxt = state;
	case(state)
		S_IDLE : state_nxt = S_READY;
		S_READY: state_nxt = S_BUF1;
		S_BUF1 : state_nxt = S_BUF2;
		S_BUF2 : state_nxt = S_LOAD;
		S_LOAD : if(counter_2047 == 2047) state_nxt = S_BUF5;
		S_FIRE : state_nxt = S_BUF3;
		S_BUF3 : state_nxt = S_GOP;
		S_GOP  : state_nxt = S_BUF4;
		S_BUF4 : begin
			if(op != OP_DIS && op != OP_CONV && op != OP_HAM && op != OP_MED)	state_nxt = S_BUF5;
			else if (op == OP_HAM)			state_nxt = S_DIS_HAM;
			else if (op == OP_MED)			state_nxt = S_DIS_MED;
			else if(dis_size == DIS_8x4)	state_nxt = S_DIS4;
			else if(dis_size == DIS_8x2)	state_nxt = S_DIS2;
			else if(dis_size == DIS_8x1)	state_nxt = S_DIS1;
			end
		S_DIS4 : begin
			if	(op == OP_DIS  && counter_256 == (4*dis_size-1)) state_nxt = S_BUF6;
			else if	(op == OP_CONV && counter_256 == (4*dis_size+2)) state_nxt = S_BUF6;
		end
		S_DIS2 : begin
			if	(op == OP_DIS  && counter_256 == (4*dis_size-1)) state_nxt = S_BUF6;
			else if	(op == OP_CONV && counter_256 == (4*dis_size+2)) state_nxt = S_BUF6;
		end
		S_DIS1 : begin
			if	(op == OP_DIS  && counter_256 == (4*dis_size-1)) state_nxt = S_BUF6;
			else if	(op == OP_CONV && counter_256 == (4*dis_size+2)) state_nxt = S_BUF6;
		end
		S_DIS_HAM : begin
			if (op == OP_HAM && counter_256 == 34) state_nxt = S_BUF6;
		end
		S_DIS_MED : begin
			if (op == OP_MED && counter_256 == 43) state_nxt = S_BUF6;
		end
		S_BUF6 : state_nxt = S_BUF7;
		S_BUF7 : state_nxt = S_BUF8;
		S_BUF8 : state_nxt = S_BUF5;
		S_BUF5 : state_nxt = S_FIRE;
	endcase
end

always@(*) begin
	op_ready_nxt = 0;
	case(state)
		S_IDLE : op_ready_nxt = 1;
		S_READY: op_ready_nxt = 0;
		S_FIRE : op_ready_nxt = 0;
		S_BUF5 : op_ready_nxt = 1;
	endcase
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state	<= S_IDLE;
		op_ready	<= 0;
	end 
	else begin
		state	<= state_nxt;
		op_ready	<= op_ready_nxt;
	end
end

// ============= counter 2047 (for S_LOAD) ================= //
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n)		counter_2047 <= 0;	
	else if(state == S_BUF2)	counter_2047 <= 0;
	else if(state == S_LOAD)	counter_2047 <= counter_2047+1;
end

// ============= counter 256 (for S_DIS?) ================== //
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n)		counter_256	<= 0;
	else if(state == S_BUF4)	counter_256	<= 0;
	else if(state == S_DIS4 || state == S_DIS2 || state == S_DIS1 || state == S_DIS_HAM || state == S_DIS_MED) begin
		counter_256	<= counter_256+1;
	end
end

// =============== display size ================== //
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		dis_size		<= DIS_8x4;
		dis_size_nxt	<= DIS_8x4;
	end
	else if(state == S_BUF4 && op == OP_CN_DOWN && dis_size == DIS_8x4) 
		dis_size_nxt	<= DIS_8x2;
	else if(state == S_BUF4 && op == OP_CN_DOWN && dis_size == DIS_8x2) 
		dis_size_nxt	<= DIS_8x1;
	else if(state == S_BUF4 && op == OP_CN_UP && dis_size == DIS_8x2) 
		dis_size_nxt	<= DIS_8x4;
	else if(state == S_BUF4 && op == OP_CN_UP && dis_size == DIS_8x1) 
		dis_size_nxt	<= DIS_8x2;
	else if(state == S_BUF5) 
		dis_size 	<= dis_size_nxt;
end


// ============= origin_coordinate =================== //
wire [4:0] ori_R, ori_L, ori_D, ori_U;
wire       R_vio, L_vio, D_vio, U_vio;

assign ori_R = origin_col+1;
assign ori_L = origin_col-1;
assign ori_D = origin_row+1;
assign ori_U = origin_row-1;

assign R_vio = (origin_col==6);
assign L_vio = (origin_col==0);
assign D_vio = (origin_row==6);
assign U_vio = (origin_row==0);

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		origin_col <= 0;
		origin_row <= 0;
	end 
	else if(state == S_BUF4) begin
		if(op == OP_RIGHT && !R_vio)     origin_col <= ori_R;
		else if(op == OP_LEFT && !L_vio) origin_col <= ori_L;
		else if(op == OP_DOWN && !D_vio) origin_row <= ori_D;
		else if(op == OP_UP && !U_vio)   origin_row <= ori_U;
	end
end

// ============= conv_coordinate =================== //
wire [2:0] conv_row [3:0];
wire [2:0] conv_col [3:0];
wire [1:0] order	[3:0];

assign conv_row[0] = origin_row-1;
assign conv_row[1] = origin_row;
assign conv_row[2] = origin_row+1;
assign conv_row[3] = origin_row+2;

assign conv_col[0] = origin_col-1;
assign conv_col[1] = origin_col;
assign conv_col[2] = origin_col+1;
assign conv_col[3] = origin_col+2;

assign order[0] = conv_col[0][1:0];
assign order[1] = conv_col[1][1:0];
assign order[2] = conv_col[2][1:0];
assign order[3] = conv_col[3][1:0]; 

// ================= sram ====================== //
reg [10:0] sram_addr	[3:0]; 
wire [7:0] q		[3:0];
wire sram_wen_0 = (state == S_LOAD)? (sram_addr[0][1:0]!=0) : 1;
wire sram_wen_1 = (state == S_LOAD)? (sram_addr[1][1:0]!=1) : 1;
wire sram_wen_2 = (state == S_LOAD)? (sram_addr[2][1:0]!=2) : 1;
wire sram_wen_3 = (state == S_LOAD)? (sram_addr[3][1:0]!=3) : 1;

always@(*) begin
	sram_addr[0] = counter_2047; // load images
	sram_addr[1] = counter_2047; // load images
	sram_addr[2] = counter_2047; // load images
	sram_addr[3] = counter_2047; // load images
	if(((op == OP_DIS) && (state==S_DIS4||state==S_DIS2||state==S_DIS1)) || ((op == OP_HAM) && (state==S_DIS_HAM))) begin
		case(counter_256[1:0])
			2'b00: begin
				sram_addr[0] = {counter_256[6:2], origin_row, origin_col};
				sram_addr[1] = {counter_256[6:2], origin_row, origin_col};
				sram_addr[2] = {counter_256[6:2], origin_row, origin_col};
				sram_addr[3] = {counter_256[6:2], origin_row, origin_col};
			end
			2'b01: begin
				sram_addr[0] = {counter_256[6:2], origin_row, origin_col}+1;
				sram_addr[1] = {counter_256[6:2], origin_row, origin_col}+1;
				sram_addr[2] = {counter_256[6:2], origin_row, origin_col}+1;
				sram_addr[3] = {counter_256[6:2], origin_row, origin_col}+1;
			end
			2'b10: begin
				sram_addr[0] = {counter_256[6:2], origin_row, origin_col}+8;
				sram_addr[1] = {counter_256[6:2], origin_row, origin_col}+8;
				sram_addr[2] = {counter_256[6:2], origin_row, origin_col}+8;
				sram_addr[3] = {counter_256[6:2], origin_row, origin_col}+8;
			end
			2'b11: begin
				sram_addr[0] = {counter_256[6:2], origin_row, origin_col}+9;
				sram_addr[1] = {counter_256[6:2], origin_row, origin_col}+9;
				sram_addr[2] = {counter_256[6:2], origin_row, origin_col}+9;
				sram_addr[3] = {counter_256[6:2], origin_row, origin_col}+9;
			end
		endcase 
	end
    else if(((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1)) || ((op == OP_MED) && (state==S_DIS_MED))) begin
		case(counter_256[1:0])
			2'b00: begin
				sram_addr[conv_col[0][1:0]] = {counter_256[6:2], conv_row[0], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {counter_256[6:2], conv_row[0], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {counter_256[6:2], conv_row[0], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {counter_256[6:2], conv_row[0], conv_col[3]};
			end
			2'b01: begin
				sram_addr[conv_col[0][1:0]] = {counter_256[6:2], conv_row[1], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {counter_256[6:2], conv_row[1], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {counter_256[6:2], conv_row[1], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {counter_256[6:2], conv_row[1], conv_col[3]};
			end
			2'b10: begin
				sram_addr[conv_col[0][1:0]] = {counter_256[6:2], conv_row[2], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {counter_256[6:2], conv_row[2], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {counter_256[6:2], conv_row[2], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {counter_256[6:2], conv_row[2], conv_col[3]};
			end
			2'b11: begin
				sram_addr[conv_col[0][1:0]] = {counter_256[6:2], conv_row[3], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {counter_256[6:2], conv_row[3], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {counter_256[6:2], conv_row[3], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {counter_256[6:2], conv_row[3], conv_col[3]};
			end
		endcase
	end
end

sram_512x8 number_0 (.Q(q[0]), .CLK(i_clk), .CEN(1'b0), .WEN(sram_wen_0), .A(sram_addr[0][10:2]), .D(in_data));
sram_512x8 number_1 (.Q(q[1]), .CLK(i_clk), .CEN(1'b0), .WEN(sram_wen_1), .A(sram_addr[1][10:2]), .D(in_data));
sram_512x8 number_2 (.Q(q[2]), .CLK(i_clk), .CEN(1'b0), .WEN(sram_wen_2), .A(sram_addr[2][10:2]), .D(in_data));
sram_512x8 number_3 (.Q(q[3]), .CLK(i_clk), .CEN(1'b0), .WEN(sram_wen_3), .A(sram_addr[3][10:2]), .D(in_data));

// ===================== Median ======================== //
reg [7:0]  x [15:0];
reg [7:0]  x_m [63:0];
reg [16:0] y [3:0];
reg [12:0] z [3:0]; 
wire conv_row_ok [3:0]; 
wire conv_col_ok [3:0];

assign conv_row_ok[0] = (origin_row!=0);
assign conv_row_ok[1] = 1;
assign conv_row_ok[2] = 1;
assign conv_row_ok[3] = (origin_row!=6);

assign conv_col_ok[0] = (origin_col!=0);
assign conv_col_ok[1] = 1;
assign conv_col_ok[2] = 1;
assign conv_col_ok[3] = (origin_col!=6);

integer i, j;
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<64 ; i=i+1)
			x_m[i] <= 0;
	end
	else if(state==S_BUF4) begin
		for(i=0 ; i<64 ; i=i+1)
			x_m[i] <= 0;
	end
	else if((op == OP_MED) && (state==S_DIS_MED) && (counter_256>0) && (counter_256<=16)) begin	
		case(counter_256[3:0])
			4'b0001: begin
				x_m[0] <= (conv_row_ok[0] && conv_col_ok[0])? q[order[0]]:0;
				x_m[1] <= (conv_row_ok[0] && conv_col_ok[1])? q[order[1]]:0;
				x_m[2] <= (conv_row_ok[0] && conv_col_ok[2])? q[order[2]]:0;
				x_m[3] <= (conv_row_ok[0] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0010: begin
				x_m[4] <= (conv_row_ok[1] && conv_col_ok[0])? q[order[0]]:0;
				x_m[5] <= (conv_row_ok[1] && conv_col_ok[1])? q[order[1]]:0;
				x_m[6] <= (conv_row_ok[1] && conv_col_ok[2])? q[order[2]]:0;
				x_m[7] <= (conv_row_ok[1] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0011: begin
				x_m[8]  <= (conv_row_ok[2] && conv_col_ok[0])? q[order[0]]:0;
				x_m[9]  <= (conv_row_ok[2] && conv_col_ok[1])? q[order[1]]:0;
				x_m[10] <= (conv_row_ok[2] && conv_col_ok[2])? q[order[2]]:0;
				x_m[11] <= (conv_row_ok[2] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0100: begin
				x_m[12] <= (conv_row_ok[3] && conv_col_ok[0])? q[order[0]]:0;
				x_m[13] <= (conv_row_ok[3] && conv_col_ok[1])? q[order[1]]:0;
				x_m[14] <= (conv_row_ok[3] && conv_col_ok[2])? q[order[2]]:0;
				x_m[15] <= (conv_row_ok[3] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0101: begin
				x_m[16] <= (conv_row_ok[0] && conv_col_ok[0])? q[order[0]]:0;
				x_m[17] <= (conv_row_ok[0] && conv_col_ok[1])? q[order[1]]:0;
				x_m[18] <= (conv_row_ok[0] && conv_col_ok[2])? q[order[2]]:0;
				x_m[19] <= (conv_row_ok[0] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0110: begin
				x_m[20] <= (conv_row_ok[1] && conv_col_ok[0])? q[order[0]]:0;
				x_m[21] <= (conv_row_ok[1] && conv_col_ok[1])? q[order[1]]:0;
				x_m[22] <= (conv_row_ok[1] && conv_col_ok[2])? q[order[2]]:0;
				x_m[23] <= (conv_row_ok[1] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0111: begin
				x_m[24]  <= (conv_row_ok[2] && conv_col_ok[0])? q[order[0]]:0;
				x_m[25]  <= (conv_row_ok[2] && conv_col_ok[1])? q[order[1]]:0;
				x_m[26] <= (conv_row_ok[2] && conv_col_ok[2])? q[order[2]]:0;
				x_m[27] <= (conv_row_ok[2] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1000: begin
				x_m[28] <= (conv_row_ok[3] && conv_col_ok[0])? q[order[0]]:0;
				x_m[29] <= (conv_row_ok[3] && conv_col_ok[1])? q[order[1]]:0;
				x_m[30] <= (conv_row_ok[3] && conv_col_ok[2])? q[order[2]]:0;
				x_m[31] <= (conv_row_ok[3] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1001: begin
				x_m[32] <= (conv_row_ok[0] && conv_col_ok[0])? q[order[0]]:0;
				x_m[33] <= (conv_row_ok[0] && conv_col_ok[1])? q[order[1]]:0;
				x_m[34] <= (conv_row_ok[0] && conv_col_ok[2])? q[order[2]]:0;
				x_m[35] <= (conv_row_ok[0] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1010: begin
				x_m[36] <= (conv_row_ok[1] && conv_col_ok[0])? q[order[0]]:0;
				x_m[37] <= (conv_row_ok[1] && conv_col_ok[1])? q[order[1]]:0;
				x_m[38] <= (conv_row_ok[1] && conv_col_ok[2])? q[order[2]]:0;
				x_m[39] <= (conv_row_ok[1] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1011: begin
				x_m[40]  <= (conv_row_ok[2] && conv_col_ok[0])? q[order[0]]:0;
				x_m[41]  <= (conv_row_ok[2] && conv_col_ok[1])? q[order[1]]:0;
				x_m[42] <= (conv_row_ok[2] && conv_col_ok[2])? q[order[2]]:0;
				x_m[43] <= (conv_row_ok[2] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1100: begin
				x_m[44] <= (conv_row_ok[3] && conv_col_ok[0])? q[order[0]]:0;
				x_m[45] <= (conv_row_ok[3] && conv_col_ok[1])? q[order[1]]:0;
				x_m[46] <= (conv_row_ok[3] && conv_col_ok[2])? q[order[2]]:0;
				x_m[47] <= (conv_row_ok[3] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1101: begin
				x_m[48] <= (conv_row_ok[0] && conv_col_ok[0])? q[order[0]]:0;
				x_m[49] <= (conv_row_ok[0] && conv_col_ok[1])? q[order[1]]:0;
				x_m[50] <= (conv_row_ok[0] && conv_col_ok[2])? q[order[2]]:0;
				x_m[51] <= (conv_row_ok[0] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1110: begin
				x_m[52] <= (conv_row_ok[1] && conv_col_ok[0])? q[order[0]]:0;
				x_m[53] <= (conv_row_ok[1] && conv_col_ok[1])? q[order[1]]:0;
				x_m[54] <= (conv_row_ok[1] && conv_col_ok[2])? q[order[2]]:0;
				x_m[55] <= (conv_row_ok[1] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b1111: begin
				x_m[56]  <= (conv_row_ok[2] && conv_col_ok[0])? q[order[0]]:0;
				x_m[57]  <= (conv_row_ok[2] && conv_col_ok[1])? q[order[1]]:0;
				x_m[58] <= (conv_row_ok[2] && conv_col_ok[2])? q[order[2]]:0;
				x_m[59] <= (conv_row_ok[2] && conv_col_ok[3])? q[order[3]]:0;
			end
			4'b0000: begin
				x_m[60] <= (conv_row_ok[3] && conv_col_ok[0])? q[order[0]]:0;
				x_m[61] <= (conv_row_ok[3] && conv_col_ok[1])? q[order[1]]:0;
				x_m[62] <= (conv_row_ok[3] && conv_col_ok[2])? q[order[2]]:0;
				x_m[63] <= (conv_row_ok[3] && conv_col_ok[3])? q[order[3]]:0;
			end
		endcase
	end	
end

wire median_clear = ((counter_256 == 17) || (counter_256 == 0) || (counter_256 == 28));
wire median_active = ((counter_256 >= 17) && (counter_256 <= 27));


wire [7:0] in_mod_w [15:0];
wire [7:0] out_mod_w [15:0];
reg [7:0] in_mod_r [15:0];
reg [7:0] out_mod_r [15:0]; 

generate
	genvar idx;
	for (idx=0; idx<16; idx=idx+1) begin: med
		assign in_mod_w[idx] = in_mod_r[idx];
		Median sorter(
			.i_clk(i_clk),
			.i_clear(median_clear), // one cycle
			.i_data(in_mod_w[idx]),
			.i_active(median_active),
			.o_median(out_mod_w[idx])
		);
	end
endgenerate

always@(posedge i_clk or negedge i_rst_n) begin //pass argv to Median module
	if(!i_rst_n) begin
		for(i=0 ; i<16 ; i=i+1) begin
			in_mod_r[i] <= 0;
		end
	end
	else if( (op == OP_MED) && (state==S_DIS_MED) && (counter_256==17||counter_256==18||counter_256==19||counter_256==20||counter_256==21||
	counter_256==22||counter_256==23||counter_256==24||counter_256==25) ) begin
		for(i=0 ; i<4 ; i=i+1) begin
			for(j=0 ; j<2 ; j=j+1) begin
				in_mod_r[(i<<2)+(j<<1)] <= x_m[(i<<4)+(j<<2)+(counter_256-17)+((counter_256-17)/3)];
				in_mod_r[(i<<2)+(j<<1)+1] <= x_m[(i<<4)+(j<<2)+1+(counter_256-17)+((counter_256-17)/3)];
			end
		end
	end 
end

always@(posedge i_clk or negedge i_rst_n) begin //pass argv to Median module
	if(!i_rst_n) begin
		for(i=0 ; i<16 ; i=i+1) begin
			out_mod_r[i] <= 0;
		end
	end
	else if( (op == OP_MED) && (state==S_DIS_MED) && (counter_256==27) ) begin
		for(i=0 ; i<16 ; i=i+1) begin
			out_mod_r[i] <= out_mod_w[i];
		end
	end 
end

// ================= CONV Compute ====================== // 
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<16 ; i=i+1)
			x[i] <= 0;
	end
	else if(state==S_BUF4) begin
		for(i=0 ; i<16 ; i=i+1)
			x[i] <= 0;
	end
	else if((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) && (counter_256>0)) begin	
		case(counter_256[1:0])
			2'b01: begin
				x[0] <= (conv_row_ok[0] && conv_col_ok[0])? q[order[0]]:0;
				x[1] <= (conv_row_ok[0] && conv_col_ok[1])? q[order[1]]:0;
				x[2] <= (conv_row_ok[0] && conv_col_ok[2])? q[order[2]]:0;
				x[3] <= (conv_row_ok[0] && conv_col_ok[3])? q[order[3]]:0;
			end
			2'b10: begin
				x[4] <= (conv_row_ok[1] && conv_col_ok[0])? q[order[0]]:0;
				x[5] <= (conv_row_ok[1] && conv_col_ok[1])? q[order[1]]:0;
				x[6] <= (conv_row_ok[1] && conv_col_ok[2])? q[order[2]]:0;
				x[7] <= (conv_row_ok[1] && conv_col_ok[3])? q[order[3]]:0;
			end
			2'b11: begin
				x[8]  <= (conv_row_ok[2] && conv_col_ok[0])? q[order[0]]:0;
				x[9]  <= (conv_row_ok[2] && conv_col_ok[1])? q[order[1]]:0;
				x[10] <= (conv_row_ok[2] && conv_col_ok[2])? q[order[2]]:0;
				x[11] <= (conv_row_ok[2] && conv_col_ok[3])? q[order[3]]:0;
			end
			2'b00: begin
				x[12] <= (conv_row_ok[3] && conv_col_ok[0])? q[order[0]]:0;
				x[13] <= (conv_row_ok[3] && conv_col_ok[1])? q[order[1]]:0;
				x[14] <= (conv_row_ok[3] && conv_col_ok[2])? q[order[2]]:0;
				x[15] <= (conv_row_ok[3] && conv_col_ok[3])? q[order[3]]:0;
			end
		endcase
	end	
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		y[0] <= 0;
		y[1] <= 0;
		y[2] <= 0;
		y[3] <= 0;
	end	
	else if(state==S_BUF4) begin
		y[0] <= 0;
		y[1] <= 0;
		y[2] <= 0;
		y[3] <= 0;
	end	
	else if((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) 
		&& (counter_256[1:0]==0) && (counter_256>0) ) begin
		y[0] <= y[0]+(x[5]<<2)+((x[1]+x[4]+x[6]+x[9])<<1)+(x[0]+x[2]+x[8]+x[10]);
		y[1] <= y[1]+(x[6]<<2)+((x[2]+x[5]+x[7]+x[10])<<1)+(x[1]+x[3]+x[9]+x[11]);	
	end
	else if((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) 
		&& (counter_256[1:0]==1) && (counter_256>1) ) begin
		y[2] <= y[2]+(x[9]<<2)+((x[5]+x[8]+x[10]+x[13])<<1)+(x[4]+x[6]+x[12]+x[14]);
		y[3] <= y[3]+(x[10]<<2)+((x[6]+x[9]+x[11]+x[14])<<1)+(x[5]+x[7]+x[13]+x[15]);
	end
end	

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		z[0] <= 0;
		z[1] <= 0;
		z[2] <= 0;
		z[3] <= 0;
	end	
	else if(state==S_BUF4) begin
		z[0] <= 0;
		z[1] <= 0;
		z[2] <= 0;
		z[3] <= 0;
	end	
	else if((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) 
		&& (counter_256 == ((dis_size<<2)+1)) ) begin
			z[0] <= y[0][16:4]+y[0][3];
			z[1] <= y[1][16:4]+y[1][3];
	end
	else if((op == OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) 
		&& (counter_256 == ((dis_size<<2)+2)) ) begin
			z[2] <= y[2][16:4]+y[2][3];
			z[3] <= y[3][16:4]+y[3][3];
	end	
end

// ============= Haar wavelet transform ================= //
reg [7:0] x_h[3:0];
reg signed [15:0] z_h[3:0];
reg signed [13:0] ham_out[15:0];
reg [10:0]	sram_addr_prev;
reg [2:0] round_ham;

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<4 ; i=i+1) begin
			x_h[i] <= 0;
		end
	end
	else if(state==S_BUF4) begin
		for(i=0 ; i<4 ; i=i+1) begin
			x_h[i] <= 0;
		end
	end
	else if((op == OP_HAM) && (state==S_DIS_HAM) && (counter_256<=16) && (counter_256>0))begin
		case(counter_256[1:0]) 
			2'b01: begin
        		x_h[0] <= q[sram_addr_prev[1:0]];
			end
			2'b10: begin
        		x_h[1] <= q[sram_addr_prev[1:0]];
			end
			2'b11: begin
        		x_h[2] <= q[sram_addr_prev[1:0]];
			end
			2'b00: begin
        		x_h[3] <= q[sram_addr_prev[1:0]];
			end
		endcase
	end
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<4 ; i=i+1) begin
			z_h[i] <= 0;
		end
	end	
	else if(state==S_BUF4) begin
		for(i=0 ; i<4 ; i=i+1) begin
			z_h[i] <= 0;
		end
	end	
	else if( (op == OP_HAM) && (state==S_DIS_HAM) && ((counter_256==5) || (counter_256==9) || (counter_256==13) ||(counter_256==17)) ) begin
		z_h[0] <= x_h[0]+x_h[2]+x_h[1]+x_h[3];
		z_h[1] <= x_h[0]+x_h[2]-x_h[1]-x_h[3];
		z_h[2] <= x_h[0]-x_h[2]+x_h[1]-x_h[3];
		z_h[3] <= x_h[0]-x_h[2]-x_h[1]+x_h[3];
	end	
end	
// Rounding
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<16 ; i=i+1) begin
			ham_out[i] <= 0;
		end
		round_ham <= 0;
	end	
	else if(state==S_BUF4) begin
		for(i=0 ; i<16 ; i=i+1) begin
			ham_out[i] <= 0;
		end
		round_ham <= 0;
	end	
	else if( (op == OP_HAM) && (state==S_DIS_HAM) && ((counter_256==6) || (counter_256==10) || (counter_256==14) ||(counter_256==18)) ) begin
		for(i=0 ; i<4 ; i=i+1) begin
			if (z_h[i][0] == 1) begin 
				ham_out[(round_ham<<2)+i] <= {z_h[i][15], z_h[i][13:1]}+1;
			end 
			else begin
				ham_out[(round_ham<<2)+i] <= {z_h[i][15], z_h[i][13:1]};
			end
		end
		round_ham <= round_ham+1;
	end	
end	

// ============= out_valid / out_data =================== //

reg [1:0]	CONV_out_num;
reg [3:0]   ham_out_num;
reg	CONV_out_valid_3nxt, CONV_out_valid_2nxt, CONV_out_valid_nxt, CONV_out_valid;
reg	DIS_out_valid;
reg ham_out_valid [15:0];
wire DIS_out_valid_nxt = ((op==OP_DIS) && (state==S_DIS4||state==S_DIS2||state==S_DIS1));

wire [13:0] DIS_out_data	= {6'b0, q[sram_addr_prev[1:0]]}; 
wire [13:0]	CONV_out_data	= {1'b0, z[CONV_out_num]};
wire signed[13:0] ham_out_data    = {ham_out[ham_out_num]};
wire [13:0] med_out_data    = {6'b0, out_mod_r[ham_out_num]};
	
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		in_ready		<= 0;
		DIS_out_valid	<= 0;	
		CONV_out_num	<= 0;
		ham_out_num     <= 0;
		sram_addr_prev	<= 0;
	end		
	else begin
		in_ready		<= 1;
		DIS_out_valid	<= DIS_out_valid_nxt;	
		CONV_out_num	<= CONV_out_num + CONV_out_valid;
		ham_out_num     <= ham_out_num + ham_out_valid[0];
		sram_addr_prev	<= sram_addr[0];
	end
end	

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i=0 ; i<16 ; i=i+1)
			ham_out_valid[i] <= 0;	
	end
	else if((op==OP_HAM) && (state==S_DIS_HAM) && (counter_256==18)) begin
		for(i=0 ; i<16 ; i=i+1)
			ham_out_valid[i] <= 1;
	end
	else if((op==OP_MED) && (state==S_DIS_MED) && (counter_256==27)) begin
		for(i=0 ; i<16 ; i=i+1)
			ham_out_valid[i] <= 1;
	end
	else begin
		for(i=0 ; i<16 ; i=i+1)
			ham_out_valid[i] <= (i==15)? 0:ham_out_valid[i+1];
	end
end	

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		CONV_out_valid_3nxt	<= 0;
		CONV_out_valid_2nxt	<= 0;
		CONV_out_valid_nxt	<= 0;
		CONV_out_valid		<= 0;		
	end
	else if((op==OP_CONV) && (state==S_DIS4||state==S_DIS2||state==S_DIS1) && (counter_256==4*dis_size+2)) begin
		CONV_out_valid_3nxt	<= 1;
		CONV_out_valid_2nxt	<= 1;
		CONV_out_valid_nxt	<= 1;
		CONV_out_valid		<= 1;
	end
	else begin
		CONV_out_valid_3nxt	<= 0;
		CONV_out_valid_2nxt	<= CONV_out_valid_3nxt;	
		CONV_out_valid_nxt	<= CONV_out_valid_2nxt;
		CONV_out_valid		<= CONV_out_valid_nxt;
	end
end	

// ============= output assignment =================== //
assign o_in_ready  = in_ready;
assign o_op_ready  = op_ready;
assign o_out_valid = (op == OP_DIS)? DIS_out_valid : 
	(op == OP_CONV)? CONV_out_valid : ham_out_valid[0];
assign o_out_data  = (op == OP_DIS)? DIS_out_data : 
	(op == OP_CONV)? CONV_out_data : 
	(op == OP_HAM)?  ham_out_data : med_out_data;
endmodule
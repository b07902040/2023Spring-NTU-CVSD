`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [3:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

//===================== read in =====================//
parameter FN_MAX = 1;
parameter FN_MIN = 2;
parameter FN_MAX_2 = 3;
parameter FN_MIN_2 = 4;
parameter FN_AVG = 5;
parameter FN_EXT = 6;
parameter FN_EXC = 7;
parameter FN_PMAX = 8;
parameter FN_PMIN = 9;

reg [3:0] fn;
reg [7:0] iot_data;
reg in_en_r;

reg [8:0] count;
reg [3:0] indx;
reg [7:0] cycle [15:0];
integer i;

always@(posedge clk or posedge rst) begin // asynchronous
	if(rst) begin
		fn <= 0;
		iot_data <= 0;
		in_en_r <= 0;
	end
	else begin
		fn <= fn_sel;
		iot_data <= iot_in;
		in_en_r	<= in_en;	
	end	
end

//===================== FSM =====================//
parameter S_IDLE = 0;
parameter S_BUF = 1;
parameter S_GET_DATA = 2;
parameter S_EXE = 3;
parameter S_OUT = 4;
parameter S_BUF2 = 5;
parameter S_BUF3 = 6;

reg [3:0] state, state_next;
reg flag1, flag2;
wire[127:0] data_cat = {cycle[00], cycle[01], cycle[02], cycle[03],
			cycle[04], cycle[05], cycle[06], cycle[07],
			cycle[08], cycle[09], cycle[10], cycle[11],
			cycle[12], cycle[13], cycle[14], cycle[15]};

always @(posedge clk or posedge rst) begin
	if (rst) flag2 <= 0;
	else if (in_en_r)
		flag2 <= 1;
end

always@(*) begin
	state_next = state;
	case(state)
		S_IDLE:	state_next = S_BUF;
		S_BUF:	begin
			if(in_en_r)	begin 
				state_next = S_GET_DATA;
			end
			else if(flag2) state_next = S_GET_DATA;
		end
		S_GET_DATA: begin 
			if(count == 128) begin
				state_next = S_EXE;
			end
		end
		S_EXE: state_next = S_BUF2;
		S_BUF2: state_next = S_BUF3;
		S_BUF3: state_next = S_OUT;
		S_OUT: state_next = S_BUF;
	endcase
end

always@(posedge clk or posedge rst) begin
	if(rst)	state <= S_IDLE;
	else	state <= state_next;	
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
        count <= 1;
    end
	else if (count == 129) begin
		count <= 1;
	end
    else if(state==S_GET_DATA) begin
		count <= count+1;
    end
end

always@(posedge clk or posedge rst) begin
    if(rst)	begin		
	    for(i=0; i<16; i=i+1)	
			cycle[i] <= 0;
	end
	else if(in_en_r)	begin
		cycle[0] <= iot_data;	
		for(i=1; i<16; i=i+1)	
			cycle[i] <= cycle[i-1];
	end
end

reg [127:0] max1, max2;
always@(posedge clk or posedge rst) begin
 	if(rst)	begin		

	end
	else if(count == 1) begin
		max1 <= (fn == FN_MAX || fn == FN_MAX_2 || fn == FN_PMAX)? 0:128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	end
	else if(count == 2) begin
		max2 <= (fn == FN_MAX || fn == FN_MAX_2 || fn == FN_PMAX)? 0:128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	end
	else if(count[3:0] == 0) begin
		if (fn == FN_MAX || fn == FN_MAX_2 || fn == FN_PMAX) begin
			if (data_cat>max2) max2 <= data_cat;
		end
		else if (fn == FN_MIN || fn == FN_MIN_2 || fn == FN_PMIN) begin
			if (data_cat<max2) max2 <= data_cat;
		end
	end
	else if(count[3:0] == 1) begin
		if (fn == FN_MAX || fn == FN_MAX_2 || fn == FN_PMAX) begin
			if (max2>max1) begin
				max2 <= max1;
				max1 <= max2;
			end
		end
		else if (fn == FN_MIN || fn == FN_MIN_2 || fn == FN_PMIN) begin
			if (max2<max1) begin
				max2 <= max1;
				max1 <= max2;
			end
		end
	end
end

reg [130:0] iot_out_r;

parameter upper1 = 128'h AFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
parameter lower1 = 128'h 6FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
parameter upper2 = 128'h BFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
parameter lower2 = 128'h 7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

reg valid_r;
reg busy_r;
assign valid = valid_r;
assign iot_out = iot_out_r;
assign busy = busy_r;
reg flag3;

always@(posedge clk or posedge rst) begin
	if(rst) begin
		valid_r <= 0;
		iot_out_r <= 0;
		flag3 <= 0;
	end
	else if (state == S_EXE && fn == FN_AVG) begin
		iot_out_r <= iot_out_r>>3;
		valid_r <= 1;
	end
	else if((fn == FN_AVG) && count == 1) begin
		iot_out_r <= 0;
		valid_r <= 0;
	end
	else if((fn == FN_AVG) && count[3:0] == 0) begin
		iot_out_r <= iot_out_r+data_cat;
		valid_r <= 0;
	end
	else if ((state == S_EXE || state == S_GET_DATA) && fn == FN_EXT && count[3:0] == 0) begin
		if ((data_cat>lower1) && (data_cat<upper1)) begin
			iot_out_r <= data_cat;
			valid_r <= 1;
		end
	end
	else if ((state == S_EXE || state == S_GET_DATA) && fn == FN_EXC && count[3:0] == 0) begin
		if ((data_cat<lower2) || (data_cat>upper2)) begin
			iot_out_r <= data_cat;
			valid_r <= 1;
		end
	end
	else if (state == S_BUF2 && fn == FN_MAX) begin
		iot_out_r <= max1;
		valid_r <= 1;
	end
	else if (state == S_BUF2 && fn == FN_MIN) begin
		iot_out_r <= max1;
		valid_r <= 1;
	end
	else if (state == S_BUF2 && fn == FN_MAX_2) begin
		iot_out_r <= max1;
		valid_r <= 1;
	end
	else if (state == S_BUF3 && fn == FN_MAX_2) begin
		iot_out_r <= max2;
		valid_r <= 1;
	end
	else if (state == S_BUF2 && fn == FN_MIN_2) begin
		iot_out_r <= max1;
		valid_r <= 1;
	end
	else if (state == S_BUF3 && fn == FN_MIN_2) begin
		iot_out_r <= max2;
		valid_r <= 1;
	end
	else if(fn == FN_PMAX) begin
		if (state == S_GET_DATA && !flag3) begin
			iot_out_r <= 128'h0;
			flag3 <= 1;
		end
		else if (state == S_BUF2) begin
			if(max1>iot_out_r) begin
				iot_out_r <= max1;
				valid_r <= 1;
			end
		end 
		else valid_r <= 0;
	end
	else if(fn == FN_PMIN) begin
		if (state == S_GET_DATA && !flag3) begin
			iot_out_r <= 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
			flag3 <= 1;
		end
		else if (state == S_BUF2) begin
			if(max1<iot_out_r) begin
				iot_out_r <= max1;
				valid_r <= 1;
			end
		end 
		else valid_r <= 0;
	end	
	else begin
		valid_r <= 0;
	end
end

always @(posedge clk or posedge rst) begin
	if(rst) begin
		busy_r <= 1;
	end 
	else begin
		if ((state == S_GET_DATA && count == 125) || state == S_BUF2 || state == S_EXE ||state == S_OUT || state == S_BUF3)
			busy_r <= 1;
		else 
			busy_r <= 0;
	end
end

endmodule
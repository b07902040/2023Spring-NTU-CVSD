module Median(
    input        i_clk,
    input        i_clear, // one cycle
	input  [7:0] i_data,
    input        i_active,
	output [7:0] o_median
);

reg  [7:0] sort_r [0:8];
wire [7:0] sort_w [0:8];

wire [7:0] input_data;
wire [8:0] tag;

assign input_data = i_data;

genvar idx;
generate
    for(idx = 0; idx < 9; idx = idx + 1) begin: tagg
        assign tag[idx] = input_data > sort_r[idx];
    end
    for(idx = 0; idx < 8; idx = idx + 1) begin: sortt
        assign sort_w[idx] = (tag[idx+:2] == 2'b10) ? input_data : 
                            (tag[idx+:2] == 2'b11) ? sort_r[idx] : sort_r[idx+1];
    end
    assign sort_w[8] = tag[8] ? sort_r[8] : input_data;
endgenerate

always@(posedge i_clk) begin
    if(i_clear) begin
        sort_r[0] <= 8'd255;
        sort_r[1] <= 8'd255;
        sort_r[2] <= 8'd255;
        sort_r[3] <= 8'd255;
        sort_r[4] <= 8'd255;
        sort_r[5] <= 8'd255;
        sort_r[6] <= 8'd255;
        sort_r[7] <= 8'd255;
        sort_r[8] <= 8'd255;
    end
    else if (i_active) begin
        sort_r[0] <= sort_w[0];
        sort_r[1] <= sort_w[1];
        sort_r[2] <= sort_w[2];
        sort_r[3] <= sort_w[3];
        sort_r[4] <= sort_w[4];
        sort_r[5] <= sort_w[5];
        sort_r[6] <= sort_w[6];
        sort_r[7] <= sort_w[7];
        sort_r[8] <= sort_w[8];
    end
end

assign o_median = sort_r[4];

endmodule
`timescale 1ns/10ps
`define SDFFILE     "./IOTDF_syn.sdf"     //Modify your sdf file name
`define CYCLE       4.5                   //Modify your CYCLE 
`define DEL         1.0
`define PAT_NUM     96
`define End_CYCLE  1000000 


module test;
reg           clk;
reg           rst;
reg           in_en;
reg  [7:0]    iot_in;
reg  [3:0]    fn_sel;
wire          busy;
wire          valid;
wire [127:0]  iot_out;
integer cycle_count;

`ifdef p1
   localparam PAT_NUM = 96;
   localparam F1_NUM = 12;
   localparam F2_NUM = 12;
   localparam F3_NUM = 24;
   localparam F4_NUM = 24;
   localparam F5_NUM = 12;
   localparam F6_NUM = 25;
   localparam F7_NUM = 73;
   localparam F8_NUM = 3;
   localparam F9_NUM = 4;
`elsif p2 // modify the following number according to your pattern
   localparam PAT_NUM = 96;
   localparam F1_NUM = 12;
   localparam F2_NUM = 12;
   localparam F3_NUM = 24;
   localparam F4_NUM = 24;
   localparam F5_NUM = 12;
   localparam F6_NUM = 20;
   localparam F7_NUM = 73;
   localparam F8_NUM = 3;
   localparam F9_NUM = 1;
`else
   localparam PAT_NUM = 96;
   localparam F1_NUM = 12;
   localparam F2_NUM = 12;
   localparam F3_NUM = 24;
   localparam F4_NUM = 24;
   localparam F5_NUM = 12;
   localparam F6_NUM = 20;
   localparam F7_NUM = 73;
   localparam F8_NUM = 3;
   localparam F9_NUM = 1;
`endif


reg  [127:0]  pat_mem[0:PAT_NUM-1];
reg  [127:0]  f1_mem [0:F1_NUM-1];
reg  [127:0]  f2_mem [0:F2_NUM-1];
reg  [127:0]  f3_mem [0:F3_NUM-1];
reg  [127:0]  f4_mem [0:F4_NUM-1];
reg  [127:0]  f5_mem [0:F5_NUM-1];
reg  [127:0]  f6_mem [0:F6_NUM-1];
reg  [127:0]  f7_mem [0:F7_NUM-1];
reg  [127:0]  f8_mem [0:F8_NUM-1];
reg  [127:0]  f9_mem [0:F9_NUM-1];
reg  [127:0]  in_tmp;
reg  [127:0]  out_tmp;
integer       i, j, x, in_l, out_h, out_l, pass, err, err_a;
reg           over, over1, over2;
reg [8*40-1:0] pattern_file_path;
reg [8*34-1:0] func_ans_path;



IOTDF u_IOTDF( .clk        (clk        ),
               .rst        (rst        ),
               .in_en      (in_en      ), 
               .iot_in     (iot_in     ),
               .fn_sel     (fn_sel     ),
               .busy       (busy       ), 
               .valid      (valid      ), 
               .iot_out    (iot_out    )
             );

/*
`ifdef F4    
               .low        (128'h6FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF),
               .high       (128'hAFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF),
`elsif F5    
               .low        (128'h7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF),
               .high       (128'hBFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF),
`endif
*/

initial begin
   cycle_count = 0;
   @(negedge clk);
   while (1) begin
      cycle_count = cycle_count + 1;
      @(negedge clk);
   end
end


`ifdef p1
   initial begin 
      pattern_file_path = "../00_TESTBED/pattern1_data/pattern1.dat";
      // $display("Hello");
      // $display("%s", pattern_file_path);
      $readmemh(pattern_file_path, pat_mem);
   end
`elsif p2
   initial begin 
      pattern_file_path = "../00_TESTBED/pattern2_data/pattern2.dat";
      $readmemh(pattern_file_path, pat_mem);
   end
`else
   initial begin 
      pattern_file_path = "../00_TESTBED/pattern1_data/pattern1.dat";
      $display("%s", pattern_file_path);
      $readmemh(pattern_file_path, pat_mem);
   end
`endif


`ifdef SDF
   initial       $sdf_annotate(`SDFFILE, u_IOTDF );
`endif

// initial	 $readmemh("%s/pattern1.dat", pattern_file_path, pat_mem);

`ifdef F2
   initial begin
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f2.dat"};
      $readmemh(func_ans_path, f2_mem); 
      fn_sel=4'd2;  
   end
`elsif F3
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f3.dat"};
      $readmemh(func_ans_path, f3_mem); 
      fn_sel=4'd3;  
   end
`elsif F4
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f4.dat"};
      
      $readmemh(func_ans_path, f4_mem); 
      fn_sel=4'd4;  
   end
`elsif F5
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f5.dat"};
      $readmemh(func_ans_path, f5_mem); 
      fn_sel=4'd5;  
   end
`elsif F6
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f6.dat"};
      $readmemh(func_ans_path, f6_mem); 
      fn_sel=4'd6;  
   end
`elsif F7
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f7.dat"};
      $readmemh(func_ans_path, f7_mem); 
      fn_sel=4'd7;  
   end
`elsif F8
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f8.dat"};
      $readmemh(func_ans_path, f8_mem); 
      fn_sel=4'd8;  
   end
`elsif F9
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f9.dat"};
      $readmemh(func_ans_path, f9_mem); 
      fn_sel=4'd9;  
   end
`else //F1
   initial begin 
      func_ans_path = {pattern_file_path[40*8-1:12*8], "f1.dat"};
      // $display("%s", func_ans_path);
      // $display("%s", pattern_file_path[40*8-1:12*8]);
      $readmemh(func_ans_path, f1_mem); 
      fn_sel=4'd1;  
   end
`endif


initial begin
   clk           = 1'b0;   
   rst           = 1'b0;
   in_en         = 1'b0;   
   i             = 0;
   j             = 0;
   x             = 0;
   in_l          = 0;
   out_h         = 0;
   out_l         = 0;
   pass          = 0;
   err           = 0;
   err_a         = 0;
   over          = 0;
   over1         = 0;
   over2         = 0;
end

always begin #(`CYCLE/2)  clk = ~clk; end


initial begin
   @(posedge clk)  #`DEL  rst = 1'b1;
   #`CYCLE                rst = 1'b0;

    $display("-----------------------------------------------------\n");  
    $display("Start to Send IOT Data & Compare ...");       
    $display("\n");       
   @(posedge clk)  ;
    while (i < PAT_NUM) begin
      if(!busy)begin     
         in_tmp   = pat_mem[i];
         in_l=j*8;

         #`DEL;
         iot_in   =   in_tmp[in_l +: 8];
         in_en    =   1'b1;  

         if(j<15)     j=j+1;
         else begin
                      j=0;
                      i=i+1;              
         end
      end
      else begin
         #`DEL;
         iot_in   = 8'h0;
         in_en    = 1'b0;  
      end
      @(posedge clk);  
    end
    if(busy)begin
	#`DEL;
        iot_in   = 8'h0;          
    	in_en    = 1'b0;
    end 
    over1 = 1; 
end


always @(posedge clk)begin
   if(valid)begin        
      `ifdef F2
         out_tmp=f2_mem[x];
      `elsif F3
         out_tmp=f3_mem[x];
      `elsif F4
         out_tmp=f4_mem[x];
      `elsif F5
         out_tmp=f5_mem[x];
      `elsif F6
         out_tmp=f6_mem[x];
      `elsif F7
         out_tmp=f7_mem[x];
      `elsif F8
         out_tmp=f8_mem[x];
      `elsif F9
         out_tmp=f9_mem[x];
      `else //F1
         out_tmp=f1_mem[x];
      `endif


      if(iot_out !== out_tmp)begin
         $display("P%02d:  iot_out=%032h  != expect %032h", x, iot_out, out_tmp);
         err = err + 1 ;  
      end
      else begin
         $display("P%02d:  ** Correct!! ** , iot_out=%032h", x, iot_out);
         pass = pass + 1;
      end


         x = x+1;      

      
     `ifdef F2
      if(x >  F2_NUM-1)   over2=1;
     `elsif F3
      if(x >  F3_NUM-1)   over2=1;
     `elsif F4
      if(x >  F4_NUM-1)   over2=1; 
     `elsif F5
      if(x >  F5_NUM-1)   over2=1; 
     `elsif F5
      if(x >  F5_NUM-1)   over2=1; 
     `elsif F6
      if(x >  F6_NUM-1)   over2=1; 
     `elsif F7
      if(x >  F7_NUM-1)   over2=1; 
     `elsif F8
      if(x >  F8_NUM-1)   over2=1; 
     `elsif F9
      if(x >  F9_NUM-1)   over2=1; 
     `else  //F1
      if(x >  F1_NUM-1)   over2=1; 
     `endif

   end                                                                        
end

always @(*)begin
   over = over1 && over2;
end

initial begin
      @(posedge over)      
      if((over) && (pass !== 'd0) ) begin
         $display("\n-----------------------------------------------------\n");
         if (err == 0)  begin
            $display("Congratulations! All data have been generated successfully!\n");
            $display("Total cost time: %10.2f ns", cycle_count*(`CYCLE));
            $display("-------------------------PASS------------------------\n");
         end
         else begin
            $display("Final Simulation Result as below: \n");         
            $display("-----------------------------------------------------\n");
            $display("Pass:   %3d \n", pass);
            $display("Error:  %3d \n", err);
            $display("-----------------------------------------------------\n");
         end
      end
      #(`CYCLE/2); $finish;
end

initial begin
	#(`End_CYCLE*(`CYCLE));
	$display("-----------------------------------------------------\n");
	$display("Error!!! There is something wrong with your code ...!\n");
 	$display("------The test result is .....FAIL ------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end
   

   
endmodule




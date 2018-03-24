module top();

reg clk = 0;
always #5 clk = ~clk;

Lc3_if if( clk );

Model tb( if );

LC3 dut(	.clock(if.clk), 
         .reset(if.reset), 
         .pc(if.pc), 
         .instrmem_rd(if.instrmem_rd), 
         .Instr_dout(if.Instr_dout), 
         .Data_addr(if.Data_addr), 
         .complete_instr(if.complete_instr), 
         .complete_data(if.complete_data),  
         .Data_din(if.Data_din), 
         .Data_dout(if.Data_dout), 
         .Data_rd(if.Data_rd)	);

end;

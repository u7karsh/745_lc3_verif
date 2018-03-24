module top();

reg clk = 0;
always #5 clk = ~clk;

Lc3_if lc3if( clk );

Model tb( lc3if );

LC3 dut(	.clock(lc3if.clk), 
         .reset(lc3if.reset), 
         .pc(lc3if.pc), 
         .instrmem_rd(lc3if.instrmem_rd), 
         .Instr_dout(lc3if.Instr_dout), 
         .Data_addr(lc3if.Data_addr), 
         .complete_instr(lc3if.complete_instr), 
         .complete_data(lc3if.complete_data),  
         .Data_din(lc3if.Data_din), 
         .Data_dout(lc3if.Data_dout), 
         .Data_rd(lc3if.Data_rd)	);
endmodule

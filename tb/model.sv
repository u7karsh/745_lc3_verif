module Model( Lc3_if lif );

wire clk;
assign clk            = lif.clk;

integer  instCount    = 5;
integer baseAddr      = 16'h3000;
Instruction instMem[5];

initial begin
   //---------- RESET PHASE --------
   lif.reset          = 1;
   lif.complete_instr = 0;
   lif.complete_data  = 0;
   repeat(2) @(posedge clk);
   lif.reset          = 0;
   
   // Process each instruction
   while( lif.pc != (pc - baseAddr) ) begin
      // Read from instruction memory
      if( lif.instrmem_rd ) begin
         lif.complete_instr       = 1;
         lif.Instr_dout           = encodeInst( instMem[ lif.pc ] );
      end

      // Data memory read/write handling
      if( lif.Data_rd ) begin
         lif.complete_data        = 1;
         lif.Data_dout            = dataMem[ lif.Data_addr ];
      end else begin
         dataMem[ lif.Data_addr ] = lif.Data_din;
      end

      // One clock delay
      @(posedge clk);
   end
   $finish;
end

endmodule

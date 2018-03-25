
module Driver( Lc3_if lif );

wire clk;
assign clk            = lif.clk;

integer baseAddr      = 16'h3000;
integer instMemIndex;
Instruction instMem[];

reg [15:0] dataMem[0:65536];

// Driver
initial begin
   //---------- RESET PHASE --------
   lif.reset          = 1;
   lif.complete_instr = 0;
   lif.complete_data  = 0;
   repeat(2) @(posedge clk);
   lif.reset          = 0;

   // Process each instMemion
   while(1) begin
      instMemIndex                 = lif.pc - baseAddr;
      if( instMem.size() == instMemIndex )
         break;

      // Read from instMemion memory
      if( lif.instrmem_rd ) begin
         lif.complete_instr       = 1;
         lif.Instr_dout           = instMem[instMemIndex].encodeInst();
         `ifdef DEBUG
            instMem[instMemIndex].print();
         `endif
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

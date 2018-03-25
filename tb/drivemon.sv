
module Drivemon( Lc3_dr_if lif, Lc3_mon_if monif );

wire clk;
assign clk            = lif.clk;

Instruction instMem[];
integer instMemIndex;
reg [15:0] dataMem[0:65536];

integer num_tests     = 0;
integer failed_tests  = 0;


task checkerFn(reg cond, string A);
   num_tests         += 1;
   if(!cond) begin
      failed_tests   += 1;
      $warning("%t [CHECKER] %s", A);
   end
endtask

//--------------------------------- MONITOR BEGIN --------------------
reg [15:0] pc  = `BASE_ADDR; 
reg [15:0] npc;
initial begin
   while(1) begin
      if( !lif.reset ) begin
         pc    = (monif.CTRLR.enable_updatePC) ? ((monif.CTRLR.br_taken) ? monif.EXECUTE.pcout : npc) : pc;
         npc   = pc + 16'b1;
         checkerFn( pc  == monif.FETCH.pc, $psprintf("PC not matched (%0x != %0x)", pc, monif.FETCH.pc) );
         checkerFn( npc == monif.FETCH.npc, $psprintf("NPC not matched (%0x != %0x)", npc, monif.FETCH.npc) );
         $display("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", $time, monif.FETCH.pc, monif.FETCH.npc, monif.FETCH.instrmem_rd);
      end
      @(posedge clk);
   end
end

//---------------------------------- MONITOR END ---------------------

//---------------------------------- DRIVER BEGIN --------------------
initial begin
   //---------- RESET PHASE --------
   lif.reset          = 1;
   lif.complete_instr = 0;
   lif.complete_data  = 0;
   repeat(2) @(posedge clk);
   lif.reset          = 0;

   // Process each instMemion
   while(1) begin
      instMemIndex                 = lif.pc - `BASE_ADDR;
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
   $display("----------- END OF TEST -------------");
   $display("----------- BEGIN REPORT ------------");
   $display("Stats: %0d / %0d Evaluations Failed", failed_tests, num_tests);
   $display("------------ END REPORT -------------\n");
   $finish;
end
//----------------------------------- DRIVER END ---------------------

endmodule

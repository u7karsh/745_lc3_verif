`define DEBUG

`include "transaction.sv"
`include "driver.sv"
`include "monitor.sv"
`include "lc3_if.sv"

module top();

reg clk = 0;
always #5 clk = ~clk;

Lc3_if lc3if( clk );
Lc3_mon_if monif( clk );

assign monif.reset             = lc3if.reset;

// Fetch connections
assign monif.FETCH.pc          = dut.Fetch.pc;
assign monif.FETCH.npc         = dut.Fetch.npc_out;
assign monif.FETCH.instrmem_rd = dut.Fetch.instrmem_rd;

//------------------------------------ GENERATOR --------------------------
Instruction instMemEntry         = new();
function void asmTranslate( integer numTrans );
   dr.instMem                    = new [numTrans];
   mon.instMem                   = new [numTrans];
   for( int i = 0; i < numTrans; i++ ) begin
      if( instMemEntry.randomize() with { opcode inside {ADD, AND, NOT, LD, LDR, LDI, LEA, ST, STI}; } ) begin
         dr.instMem[i]           = instMemEntry.copy();
         mon.instMem[i]          = instMemEntry.copy();
      end else begin
         $error("Failed to randomize instMemEntry");
      end
   end
endfunction

initial begin
   asmTranslate(100);
end

//-------------------------------- MONITOR / DRIVER -----------------------
Monitor  mon( monif );
Driver   dr ( lc3if );
//--------------------------------------- DUT -----------------------------
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

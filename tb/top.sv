`include "transaction.sv"

module top();

reg clk = 0;
always #5 clk = ~clk;

Lc3_if lc3if( clk );
Lc3_mon_if monif( clk );
Driver dr( lc3if, monif );

assign monif.reset             = lc3if.reset;

// Fetch connections
assign monif.FETCH.pc          = dut.Fetch.pc;
assign monif.FETCH.npc         = dut.Fetch.npc_out;
assign monif.FETCH.instrmem_rd = dut.Fetch.instrmem_rd;

// Monitor mn()

//------------------------------------ GENERATOR --------------------------
function void asmTranslate( ref Instruction instMem );
   instMem                = new [5];
   for( int i = 0; i < 5; i++ ) begin
      instMem[i]          = new();
      instMem[i].opcode   = Instruction::ADD;
      instMem[i].dst      = i;
      instMem[i].src1     = 0;
      instMem[i].src2     = i + 1;
      instMem[i].immValid = $urandom_range(0,2);
      instMem[i].imm      = $urandom_range(0,32);
   end
endfunction

initial begin
   // Populate inst mem
   asmTranslate( dr.instMem );
end

//function void asmTranslate();
//   dr.instMem             = new [5];
//   for( int i = 0; i < 5; i++ ) begin
//      dr.instMem[i]          = new();
//      $cast(dr.instMem[i].opcode, Instruction::ADD);
//      dr.instMem[i].dst      = i;
//      dr.instMem[i].src1     = 0;
//      dr.instMem[i].src2     = i + 1;
//      dr.instMem[i].immValid = $urandom_range(0,2);
//      dr.instMem[i].imm      = $urandom_range(0,32);
//   end
//endfunction
//
//initial begin
//   // Populate inst mem
//   asmTranslate();
//end

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

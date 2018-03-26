`define DEBUG
`define BASE_ADDR    16'h3000;
`define DYN_INST_CNT 1000000

`include "transaction.sv"
`include "drivemon.sv"
`include "lc3_if.sv"

module top();

reg clk = 0;
always #5 clk = ~clk;

Lc3_dr_if lc3if( clk );
Lc3_mon_if monif( clk );


// Fetch connections
assign monif.reset                  = lc3if.reset;
assign monif.FETCH.pc               = dut.Fetch.pc;
assign monif.FETCH.npc              = dut.Fetch.npc_out;
assign monif.FETCH.instrmem_rd      = dut.Fetch.instrmem_rd;

//decode connections
assign monif.DECODE.IR              = dut.Dec.IR;
assign monif.DECODE.E_Control       = dut.Dec.E_Control;
assign monif.DECODE.W_Control       = dut.Dec.W_Control;
assign monif.DECODE.Mem_Control     = dut.Dec.Mem_Control;
assign monif.DECODE.npc_out         = dut.Dec.npc_out;

//execute connections
assign monif.EXECUTE.aluout          = dut.Ex.aluout;
assign monif.EXECUTE.W_Control_out   = dut.Ex.W_Control_out;
assign monif.EXECUTE.Mem_Control_out = dut.Ex.Mem_Control_out;
assign monif.EXECUTE.M_Data          = dut.Ex.M_Data;
assign monif.EXECUTE.dr              = dut.Ex.dr;
assign monif.EXECUTE.sr1             = dut.Ex.sr1;
assign monif.EXECUTE.sr2             = dut.Ex.sr2;
assign monif.EXECUTE.NZP             = dut.Ex.NZP;
assign monif.EXECUTE.IR_Exec         = dut.Ex.IR_Exec;
assign monif.EXECUTE.pcout           = dut.Ex.pcout;

//writeback connections
assign monif.WB.psr                  = dut.WB.psr;
assign monif.WB.VSR1                 = dut.WB.d1;
assign monif.WB.VSR2                 = dut.WB.d2;

//MemAccess connections
assign monif.MEM.Data_addr           = dut.MemAccess.Data_addr;
assign monif.MEM.Data_rd             = dut.MemAccess.Data_rd;
assign monif.MEM.Data_din            = dut.MemAccess.Data_din;
assign monif.MEM.memout              = dut.MemAccess.memout;

//controller connections
assign monif.CTRLR.enable_updatePC  = dut.Ctrl.enable_updatePC; 
assign monif.CTRLR.enable_fetch     = dut.Ctrl.enable_fetch; 
assign monif.CTRLR.enable_decode    = dut.Ctrl.enable_decode; 
assign monif.CTRLR.enable_execute   = dut.Ctrl.enable_execute; 
assign monif.CTRLR.enable_writeback = dut.Ctrl.enable_writeback; 
assign monif.CTRLR.br_taken         = dut.Ctrl.br_taken; 
assign monif.CTRLR.bypass_alu_1     = dut.Ctrl.bypass_alu_1; 
assign monif.CTRLR.bypass_alu_2     = dut.Ctrl.bypass_alu_2; 
assign monif.CTRLR.bypass_mem_1     = dut.Ctrl.bypass_mem_1; 
assign monif.CTRLR.bypass_mem_2     = dut.Ctrl.bypass_mem_2; 
assign monif.CTRLR.mem_state        = dut.Ctrl.mem_state; 
assign monif.CTRLR.Instr_dout       = dut.Ctrl.Instr_dout;

//------------------------------------ GENERATOR --------------------------
Instruction instMemEntry         = new();
function void asmTranslate( integer numTrans );
   dmon.instMem                  = new [numTrans];
   for( int i = 0; i < numTrans; i++ ) begin
      if( instMemEntry.randomize() with { opcode inside {ADD, BR, AND, NOT, LD, LDR, LDI, LEA, ST, STI, STR}; } ) begin
         dmon.instMem[i]         = instMemEntry.copy();
      end else begin
         $error("Failed to randomize instMemEntry");
      end
   end
endfunction
initial begin
   asmTranslate(10);
end

//-------------------------------- MONITOR / DRIVER -----------------------
Drivemon dmon( lc3if, monif );
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

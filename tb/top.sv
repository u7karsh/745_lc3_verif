`define DEBUG
`define STALL_THRESH   1000
`define BASE_ADDR      16'h3000
`define DYN_INST_CNT   100000
`define LC3_PIPE_DEPTH 6
//`define DEBUG_DRIVER
//`define DEBUG_EXEC
//`define DEBUG_FETCH
//`define DEBUG_WB
//`define DEBUG_CTRL
`define T_FETCH_MAX    0
`define T_DATA_MAX     0
//`define TOP_MONITOR
//`define RUN_FIXME

`include "types.sv"
`include "interface.sv"
`include "transaction.sv"
`include "agent.sv"
`include "monitor.sv"
`include "driver.sv"
`include "coverage.sv"
`include "env.sv"
`include "test.sv"
`include "tests.sv"

module top();

// Based on args, select a testcase
`TEST test;

reg clk = 0;

// Clock generation
always #5 clk = ~clk;

Lc3_dr_if lc3if( clk );
Lc3_mon_if monif( clk, lc3if.reset, 
                     // Fetch
                     dut.Fetch.npc_out, dut.Fetch.pc, dut.Fetch.instrmem_rd,
                     // Decode
                     dut.Dec.IR, dut.Dec.npc_out, dut.Dec.E_Control, dut.Dec.W_Control, dut.Dec.Mem_Control,
                     // EX
                     dut.Ex.aluout, dut.Ex.pcout, dut.Ex.IR_Exec, dut.Ex.M_Data, 
                     dut.Ex.W_Control_out, dut.Ex.Mem_Control_out, dut.Ex.dr, dut.Ex.sr1, dut.Ex.sr2, dut.Ex.NZP,
                     // WB
                     dut.WB.psr, dut.WB.d1, dut.WB.d2,
                     // MEM
                     dut.MemAccess.Data_addr, dut.MemAccess.Data_din, dut.MemAccess.memout, dut.MemAccess.Data_dout, 
                     dut.MemAccess.Data_rd,
                     // CTRL
                     dut.Ctrl.enable_updatePC, dut.Ctrl.enable_fetch, dut.Ctrl.enable_decode, 
                     dut.Ctrl.enable_execute, dut.Ctrl.enable_writeback, dut.Ctrl.br_taken,
                     dut.Ctrl.bypass_alu_1, dut.Ctrl.bypass_alu_2, dut.Ctrl.bypass_mem_1, dut.Ctrl.bypass_mem_2,
                     dut.Ctrl.mem_state, dut.Ctrl.Instr_dout
                  );

// Test
initial begin
   `ifdef TOP_MONITOR
      $monitor("%t [TOP] reset: %0b pc: %0x instrmem_rd: %0b instr_dout: %0x data_addr: %0x complete_instr: %0b complete_data: %0b data_dout: %0x data_rd: %0b data_din: %0x", $time, lc3if.reset, lc3if.pc, lc3if.instrmem_rd, lc3if.Instr_dout, lc3if.Data_addr, lc3if.complete_instr, lc3if.complete_data, lc3if.Data_dout, lc3if.Data_rd, lc3if.Data_din );
   `endif
   test = new( lc3if, monif, 65536 );
   test.run();
end

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

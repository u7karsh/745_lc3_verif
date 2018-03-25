interface Lc3_dr_if( input bit clk );
   logic        reset;
   logic        complete_instr, complete_data;
   logic [15:0] pc, Data_addr;
   logic        instrmem_rd, Data_rd;
   logic [15:0] Instr_dout, Data_dout;
   logic [15:0] Data_din;
endinterface

interface Lc3_mon_if(input bit clk);
   //fetch
   logic        reset;
   logic [15:0] npc;
   logic [15:0] pc;
   logic        instrmem_rd;

   //decode
   logic [15:0] IR, npc_out;
   logic [5:0]  E_Control;
   logic [1:0]  W_Control;
   logic        Mem_Control;

   //execute
   logic [15:0] aluout, pcout, IR_Exec, M_Data;
   logic [1:0]  W_Control_out;
   logic        Mem_Control_out;
   logic [2:0]  dr, sr1, sr2, NZP;

   //writeback
   logic [2:0]  psr;
   logic [15:0] VSR1, VSR2;

   //MemAccess
   logic [15:0] Data_addr, Data_din, memout;
   logic        Data_rd;

   //controller
   logic        enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback, br_taken, bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, mem_state;

   modport FETCH(output npc, pc, instrmem_rd);
   modport DECODE(output IR, E_Control, npc_out, Mem_Control, W_Control);
   modport EXECUTE(output aluout, W_Control_out, Mem_Control_out, M_Data, dr, sr1, sr2, NZP, IR_Exec, pcout);
   modport WB(output psr, VSR1, VSR2);
   modport MEM(output Data_addr, Data_rd, Data_din, memout);
   modport CTRLR(output enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback, br_taken, bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, mem_state);
endinterface

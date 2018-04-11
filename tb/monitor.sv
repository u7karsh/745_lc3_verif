//TODO: BUGS
// 1. JMP instruction not verified. Error: bad handling or reference. (PC issue)
// 2. Connectivity verif
class Monitor extends Agent;
   virtual Lc3_mon_if monIf;
   Instruction currentTrans;

   reg [15:0] fetch_pc;
   reg [15:0] fetch_npc;

   reg [5:0]  decode_Ectrl;
   reg        decode_Mctrl;
   reg [1:0]  decode_Wctrl;
   reg [15:0] decode_ir, decode_npcout;

   //------------------------FETCH-------------
   function void fetch(); //{
      if( !monIf.reset ) begin //{
         fetch_npc     = fetch_pc + 16'b1;
         currentTrans  = getInstIndex(fetch_pc - `BASE_ADDR);
         check("FETCH", WARN, fetch_pc  === monIf.FETCH.pc, $psprintf("PC not matched (%0x != %0x)", fetch_pc, monIf.FETCH.pc) );
         check("FETCH", WARN, fetch_npc === monIf.FETCH.npc, $psprintf("NPC not matched (%0x != %0x)", fetch_npc, monIf.FETCH.npc) );
         check("FETCH", WARN, monIf.CTRLR.enable_fetch === monIf.FETCH.instrmem_rd,
            $psprintf("instrmem_rd not matched (%0x != %0x)", monIf.CTRLR.enable_fetch, monIf.FETCH.instrmem_rd) );

         $display("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", 
            $time, monIf.FETCH.pc, monIf.FETCH.npc, monIf.FETCH.instrmem_rd);

         // Modelling 1 FF in PC
         fetch_pc      = (monIf.CTRLR.enable_updatePC) ? ((monIf.CTRLR.br_taken) ? monIf.EXECUTE.pcout : fetch_npc) : fetch_pc;
      end//}
      else begin //{
         //reset phase
         fetch_pc      = `BASE_ADDR; 
      end //}
   endfunction //}

   //------------------------DECODE---------------
   function void decode(); //{
      if( !monIf.reset ) begin //{
         check("DECODE", WARN, decode_ir === monIf.DECODE.IR, 
            $psprintf("Unmatched IR (%0x != %0x, Opcode: %s != %s)", decode_ir, monIf.DECODE.IR, 
            Instruction::op2str(decode_ir[15:12]), 
            Instruction::op2str(monIf.DECODE.IR[15:12])) );

         case(decode_ir[15:12])
            ADD: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b0, 2'bxx, 1'bx, !monIf.DECODE.IR[5]}; end
            AND: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b1, 2'bxx, 1'bx, !monIf.DECODE.IR[5]}; end
            NOT: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'd2, 2'bxx, 1'bx, 1'bx}; end
            BR : begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            JMP: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'd3, 1'b0, 1'bx}; end
            LD : begin decode_Mctrl = 0;    decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            LDR: begin decode_Mctrl = 0;    decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx}; end
            LDI: begin decode_Mctrl = 1;    decode_Wctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            LEA: begin decode_Mctrl = 1'bx; decode_Wctrl = 2; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            ST : begin decode_Mctrl = 0;    decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
            STR: begin decode_Mctrl = 0;    decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx}; end
            STI: begin decode_Mctrl = 1;    decode_Wctrl = 0; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx}; end
         endcase

         check("DECODE", WARN, decode_Ectrl === monIf.DECODE.E_Control, $psprintf("[%s] E_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Ectrl, monIf.DECODE.E_Control));
         check("DECODE", WARN, decode_Wctrl === monIf.DECODE.W_Control, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Wctrl, monIf.DECODE.W_Control));
         check("DECODE", WARN, decode_Mctrl === monIf.DECODE.Mem_Control, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Mctrl, monIf.DECODE.Mem_Control));
         check("DECODE", WARN, decode_npcout === monIf.DECODE.npc_out, $psprintf("npc_out unmatched! (%0x != %0x)", decode_npcout, monIf.DECODE.npc_out) );

         decode_ir     = monIf.CTRLR.enable_decode ? monIf.CTRLR.Instr_dout : decode_ir;
         decode_npcout = monIf.CTRLR.enable_decode ? monIf.FETCH.npc : decode_npcout;
         $display("%t [MON.decode] %0b E_Control: %0x, %0x, %0x, %0x", $time, monIf.DECODE.IR[15:12], monIf.DECODE.E_Control[5:4], 
            monIf.DECODE.E_Control[3:2], monIf.DECODE.E_Control[1], monIf.DECODE.E_Control[0]);
      end //}
   endfunction //}

   function new(virtual Lc3_mon_if monIf);
      super.new();
      this.monIf        = monIf;
      this.currentTrans = new;
   endfunction

   task run();
      while(1) begin
         @(posedge monIf.clk);
         fetch();
         decode();
      end
   endtask

endclass

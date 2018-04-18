//TODO: BUGS
// 1. JMP instruction not verified. Error: bad handling or reference. (PC issue)
// 2. Connectivity verif
class Monitor extends Agent;
   virtual Lc3_mon_if         monIf;
   virtual Lc3_mon_if.FETCH   fetchIf;
   virtual Lc3_mon_if.DECODE  decodeIf;
   virtual Lc3_mon_if.EXECUTE execIf;
   virtual Lc3_mon_if.WB      wbIf;
   virtual Lc3_mon_if.CTRLR   ctrlrIf;

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
         check("FETCH", WARN, fetch_pc  === fetchIf.pc, $psprintf("PC not matched (%0x != %0x)", fetch_pc, fetchIf.pc) );
         check("FETCH", WARN, fetch_npc === fetchIf.npc, $psprintf("NPC not matched (%0x != %0x)", fetch_npc, fetchIf.npc) );
         check("FETCH", WARN, ctrlrIf.enable_fetch === fetchIf.instrmem_rd,
            $psprintf("instrmem_rd not matched (%0x != %0x)", ctrlrIf.enable_fetch, fetchIf.instrmem_rd) );

         $display("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", 
            $time, fetchIf.pc, fetchIf.npc, fetchIf.instrmem_rd);

         // Modelling 1 FF in PC
         fetch_pc      = (ctrlrIf.enable_updatePC) ? ((ctrlrIf.br_taken) ? execIf.pcout : fetch_npc) : fetch_pc;
      end//}
      else begin //{
         //reset phase
         fetch_pc      = `BASE_ADDR; 
      end //}
   endfunction //}

   //------------------------DECODE---------------
   function void decode(); //{
      if( !monIf.reset ) begin //{
         check("DECODE", WARN, decode_ir === decodeIf.IR, 
            $psprintf("Unmatched IR (%0x != %0x, Opcode: %s != %s)", decode_ir, decodeIf.IR, 
            Instruction::op2str(decode_ir[15:12]), 
            Instruction::op2str(decodeIf.IR[15:12])) );

         case(decode_ir[15:12])
            ADD: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b0, 2'bxx, 1'bx, !decodeIf.IR[5]}; end
            AND: begin decode_Mctrl = 1'bx; decode_Wctrl = 0; decode_Ectrl = {2'b1, 2'bxx, 1'bx, !decodeIf.IR[5]}; end
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

         check("DECODE", WARN, decode_Ectrl === decodeIf.E_Control, $psprintf("[%s] E_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Ectrl, decodeIf.E_Control));
         check("DECODE", WARN, decode_Wctrl === decodeIf.W_Control, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Wctrl, decodeIf.W_Control));
         check("DECODE", WARN, decode_Mctrl === decodeIf.Mem_Control, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Mctrl, decodeIf.Mem_Control));
         check("DECODE", WARN, decode_npcout === decodeIf.npc_out, $psprintf("npc_out unmatched! (%0x != %0x)", decode_npcout, decodeIf.npc_out) );

         decode_ir     = ctrlrIf.enable_decode ? ctrlrIf.Instr_dout : decode_ir;
         decode_npcout = ctrlrIf.enable_decode ? fetchIf.npc : decode_npcout;
         $display("%t [MON.decode] %0b E_Control: %0x, %0x, %0x, %0x", $time, decodeIf.IR[15:12], decodeIf.E_Control[5:4], 
            decodeIf.E_Control[3:2], decodeIf.E_Control[1], decodeIf.E_Control[0]);
      end //}
   endfunction //}

   function new( virtual Lc3_mon_if monIf ); //{
      super.new();
      this.monIf        = monIf;
      this.fetchIf      = monIf.FETCH;
      this.decodeIf     = monIf.DECODE;
      this.execIf       = monIf.EXECUTE;
      this.wbIf         = monIf.WB;
      this.ctrlrIf      = monIf.CTRLR;
      this.currentTrans = new;
   endfunction //}

   task run();
      while(1) begin
         @(posedge monIf.clk);
         fetch();
         decode();
      end
   endtask

endclass

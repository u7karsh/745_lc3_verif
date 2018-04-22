// Assuming DUT's controller as golden for pipe stages
class Monitor extends Agent;
   virtual Lc3_dr_if          driverIf;
   virtual Lc3_mon_if         monIf;
   virtual Lc3_mon_if.FETCH   fetchIf;
   virtual Lc3_mon_if.DECODE  decodeIf;
   virtual Lc3_mon_if.EXECUTE execIf;
   virtual Lc3_mon_if.WB      wbIf;
   virtual Lc3_mon_if.MEM     memIf;
   virtual Lc3_mon_if.CTRLR   ctrlrIf;

   Instruction currentTrans;

   // Gloabls will contain pipeline FFs

   /*
    * Fetch globals
    */
   reg [15:0] fetch_pc;
   reg [15:0] fetch_npc;

   /*
    * Decode globals
    */
   reg [15:0] decode_ir;
   reg [5:0]  decode_Ectrl;
   reg        decode_Mctrl;
   reg [1:0]  decode_Wctrl;
   reg        decode_init;
   reg [15:0] decode_npcout;


   /*
    * Execute globals
    */
   reg [5:0]  exec_Ectrl;
   reg [15:0] exec_IR;
   reg [15:0] exec_npc;
   reg [1:0]  exec_bypass1;
   reg [1:0]  exec_bypass2;
   reg [15:0] exec_aluout;
   reg [15:0] exec_vsr1, exec_vsr2;
   reg [1:0]  exec_Wctrl;
   reg        exec_Mctrl;
   reg [15:0] exec_Mdata;
   reg        exec_init;

   /*
    * Mem globals
    */
   reg [15:0] mem_mData;
   reg [15:0] mem_mAddr;
   reg [15:0] mem_Dout;
   reg        mem_Mctrl;
   reg [1:0]  mem_memState;

   /*
    * Wb globals
    */
   reg [15:0] wb_aluout;
   reg [15:0] wb_pcout;
   reg [15:0] wb_memout;
   reg [2:0]  wb_sr1, wb_sr2, wb_dr_in;
   reg [1:0]  wb_W_Control;
   reg        wb_init;

   //Register File   
   reg [15:0] regFile[0:7];

   //for coverage
   reg [15:0] aluin1, aluin2;
   reg [2:0]  PSR;

   /*
    * Controller globals
    */
   reg [1:0]  ctrl_memState;
   reg [3:0]  ctrl_Imem_stash;
   reg [1:0]  ctrl_memState_N;
   reg [1:0]  ctrl_enState_N;
   reg [1:0]  ctrl_enState;
   reg [1:0]  ctrl_stallEnState;
   reg [1:0]  ctrl_stallEnState_N;
   reg [1:0]  ctrl_brEnState;
   reg [1:0]  ctrl_brEnState_N;
   reg        ctrl_complete_data;
   reg        ctrl_complete_instr;
   reg        ctrl_decode_enable;

   //------------------------FETCH-------------
   function void fetch(); //{
      if( !monIf.reset ) begin //{
         fetch_npc        = fetch_pc + 16'b1;
         // Access to safe get inst index
         currentTrans     = getInstIndex(fetch_pc - `BASE_ADDR, 1);
         check("FETCH", WARN, fetch_pc  === fetchIf.pc, $psprintf("PC not matched (%0x != %0x)", fetch_pc, fetchIf.pc) );
         check("FETCH", WARN, fetch_npc === fetchIf.npc, $psprintf("NPC not matched (%0x != %0x)", fetch_npc, fetchIf.npc) );
         check("FETCH", WARN, ctrlrIf.enable_fetch === fetchIf.instrmem_rd,
            $psprintf("instrmem_rd not matched (%0x != %0x)", ctrlrIf.enable_fetch, fetchIf.instrmem_rd) );

         fetch_pc      = (ctrlrIf.enable_updatePC) ? ((ctrlrIf.br_taken) ? execIf.pcout : fetch_npc) : fetch_pc;
         `ifdef DEBUG_FETCH
            $display("%t [MON.fetch] pc: %0x, npc: %0x, instrmem_rd: %b", 
               $time, fetchIf.pc, fetchIf.npc, fetchIf.instrmem_rd);
		      $display("debugging ctrlrIf.br_taken::  %d",ctrlrIf.br_taken );
		      $display("debugging execIf.pcout::  %d",execIf.pcout );
		      
		      $display("debugging enable_updatePC ::  %d",ctrlrIf.enable_updatePC);
		      $display("debugging PC2 ::  %d",fetch_pc);
		      $display("debugging NPC ::  %d",fetch_pc - `BASE_ADDR );
         `endif
      end//}

      if (monIf.reset)begin //{
         //reset phase
         fetch_pc      = `BASE_ADDR; 
         fetch_npc     = 0;
      end //}
   endfunction //}

   //------------------------DECODE---------------
   function void decode(); //{
      if( !monIf.reset ) begin //{
         bit sliceEctrl = 0;
         case(decode_ir[15:12])
            ADD: begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 0; decode_Ectrl = {2'b0, 2'b0, 1'b0, !decode_ir[5]}; end
            AND: begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 0; decode_Ectrl = {2'b1, 2'b0, 1'b0, !decode_ir[5]}; end
            NOT: begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 0; decode_Ectrl = {2'd2, 2'b0, 1'b0, 1'b1};          end
            BR : begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
            JMP: begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'd3, 1'b0, 1'bx};         end
            LD : begin decode_Mctrl = 0; decode_Wctrl = 1; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
            LDR: begin decode_Mctrl = 0; decode_Wctrl = 1; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx};         end
            LDI: begin decode_Mctrl = 1; decode_Wctrl = 1; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
            LEA: begin decode_Mctrl = 0; decode_Wctrl = 2; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
            ST : begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
            STR: begin decode_Mctrl = 0; decode_Wctrl = 0; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'd2, 1'b0, 1'bx};         end
            STI: begin decode_Mctrl = 1; decode_Wctrl = 0; sliceEctrl = 1; decode_Ectrl = {2'bxx, 2'b1, 1'b1, 1'bx};         end
         endcase

         check("DECODE", WARN, decode_ir === decodeIf.IR, 
            $psprintf("Unmatched IR (%0x != %0x, Opcode: %s != %s)", decode_ir, decodeIf.IR, 
            Instruction::op2str(decode_ir[15:12]), Instruction::op2str(decodeIf.IR[15:12])) );

         if( decode_init ) begin
            decode_Ectrl = 0;
         end

         if( sliceEctrl ) begin
            check("DECODE", WARN, decode_Ectrl[3:1] === decodeIf.E_Control[3:1], $psprintf("[%s] E_control unmatched! (%0b != %0x)", 
                     Instruction::op2str(decode_ir[15:12]), decode_Ectrl[3:1], decodeIf.E_Control[3:1]));
         end else begin
            check("DECODE", WARN, decode_Ectrl === decodeIf.E_Control, $psprintf("[%s] E_control unmatched! (%0b != %0x)", 
                     Instruction::op2str(decode_ir[15:12]), decode_Ectrl, decodeIf.E_Control));
         end

         check("DECODE", WARN, decode_Wctrl === decodeIf.W_Control, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Wctrl, decodeIf.W_Control));
         check("DECODE", WARN, decode_Mctrl === decodeIf.Mem_Control, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
            Instruction::op2str(decode_ir[15:12]), decode_Mctrl, decodeIf.Mem_Control));
         check("DECODE", WARN, decode_npcout === decodeIf.npc_out, $psprintf("npc_out unmatched! (%0x != %0x)", decode_npcout, decodeIf.npc_out) );

         // Pipeline regs
         if( ctrlrIf.enable_decode ) begin
            decode_ir      =  ctrlrIf.Instr_dout;
            decode_npcout  =  fetchIf.npc;
            decode_init    = 0;
         end
      end //}

      // Reset state
      if( monIf.reset ) begin
         decode_ir         = 0;
         decode_npcout     = 0;
         decode_init       = 1;
      end

   endfunction //}

   //------------------------EXECUTE---------------
   function void execute(); //{
      logic [15:0] pcout;
      logic [15:0] val_1;
      logic [15:0] val_2;
      logic [2:0]  exec_nzp;
      logic [2:0]  exec_dr;
      logic [15:0] aluout;

      if( !monIf.reset ) begin //{
         //reconfiguring offsets in execute
         //for PC OUT
         case(exec_bypass1)
            2'b00: val_1 = exec_vsr1;
            2'b01: val_1 = memIf.memout;
            2'b10: val_1 = exec_aluout;
         endcase

         case(exec_bypass2)
            2'b00: val_2 = exec_Ectrl[0] ? exec_vsr2 : {{11{exec_IR[4]}}, exec_IR[4:0]};		//immediate operation
            2'b01: val_2 = memIf.memout;
            2'b10: val_2 = exec_aluout;
         endcase
         
         aluin1          = val_1;
         aluin2          = val_2;

         case(exec_Ectrl[3:2])
            2'b00: begin pcout = {{5{exec_IR[10]}}, exec_IR[10:0]} + (exec_Ectrl[1] ? exec_npc     : val_1); end //offset 11
            2'b01: begin pcout = {{7{exec_IR[8]}} , exec_IR[8:0]}  + (exec_Ectrl[1] ? exec_npc - 1 : val_1); end //offset 9
            2'b10: begin pcout = {{10{exec_IR[5]}}, exec_IR[5:0]}  + (exec_Ectrl[1] ? exec_npc     : val_1); end //offset 6
            2'b11: begin pcout = 16'b0; end
         endcase

         //ALU Control unit
         case(exec_Ectrl[5:4])
            2'b00: begin aluout = val_1 + val_2; end 
            2'b01: begin aluout = val_1 & val_2; end 
            2'b10: begin aluout = ~val_1; end
            default: begin check("EXEC", FATAL, 1, "Control not supported"); end
         endcase

         // For ALU, short alout with pcout (not documented)
         case(exec_IR[15:12])
            ADD, AND, NOT:      begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        pcout  = aluout; end
            LDR, LDI, LEA:      begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        aluout = pcout;  end
            ST, STR, STI:       begin exec_dr = 3'b0;          exec_nzp = 3'b000;        aluout = pcout;  end
            BR :                begin exec_dr = 3'b0;          exec_nzp = exec_IR[11:9]; aluout = pcout;  end
            JMP:                begin exec_dr = 3'b0;          exec_nzp = 3'b111;                         end 
         endcase

         exec_Mdata                  =  exec_bypass2[1] ? val_2 : exec_vsr2;

         if( exec_init ) begin
            exec_Mdata  = 0;
            exec_Wctrl  = 0;
            exec_Mctrl  = 0;
            aluout      = 0;
            pcout       = 0;
         end

         `ifdef DEBUG_EXEC
            $display("%t EXEC: IR: 0x%0x bypass1: %0b bypass2: %0b %0b val1: %0x val2: %0x vsr1: %0x vsr2: %0x %0x aluout: %0x pcout: %0x Mdata: %0x", $time, exec_IR, exec_bypass1, exec_bypass2, exec_Ectrl[5:4], val_1, val_2, exec_vsr1, exec_vsr2, exec_IR[4:0], exec_aluout, pcout, execIf.M_Data);
         `endif

         check("EXEC", WARN, exec_Mdata === execIf.M_Data, $psprintf("[%s] mem data unmatched! (%0x != %0x) %0x %0x %0x %0x", 
            Instruction::op2str(exec_IR[15:12]), exec_Mdata, execIf.M_Data, val_2, exec_vsr2, val_1, exec_vsr1));

         check("EXEC", WARN, exec_Wctrl === execIf.W_Control_out, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_Wctrl, execIf.W_Control_out));

         check("EXEC", WARN, exec_Mctrl === execIf.Mem_Control_out, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_Mctrl, execIf.Mem_Control_out));

         check("EXEC", WARN, aluout === execIf.aluout, $psprintf("[%s] alu out unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), aluout, execIf.aluout));

         check("EXEC", WARN, pcout === execIf.pcout, $psprintf("[%s] pc out unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), pcout, execIf.pcout));

         check("EXEC", WARN, exec_dr === execIf.dr, $psprintf("[%s] destination register unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_dr, execIf.dr));

         check("EXEC", WARN, exec_nzp === execIf.NZP, $psprintf("[%s] NZP unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_nzp, execIf.NZP));

         check("EXEC", WARN, exec_IR === execIf.IR_Exec, $psprintf("[%s] IR Execute unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_IR, execIf.IR_Exec));

         // Pipeline regs
         if( ctrlrIf.enable_execute ) begin
            exec_Ectrl      = decodeIf.E_Control;
            exec_Wctrl      = decodeIf.W_Control;
            exec_Mctrl      = decodeIf.Mem_Control;
            exec_IR         = decodeIf.IR;
            exec_npc        = decodeIf.npc_out;
            exec_init       = 0;
            exec_vsr1       = wbIf.VSR1;
            exec_vsr2       = wbIf.VSR2;
            exec_bypass1    = {ctrlrIf.bypass_alu_1, ctrlrIf.bypass_mem_1};
            exec_bypass2    = {ctrlrIf.bypass_alu_2, ctrlrIf.bypass_mem_2};
            exec_aluout     = aluout;
         end
      end //}

      if( monIf.reset ) begin
         exec_Ectrl  = 0;
         exec_IR     = 0;
         exec_npc    = 0;
         exec_init   = 1;
      end
   endfunction //}

   function void memAccess();
      logic        mem_Dmem_rd;  
      logic [15:0] mem_Dmem_din; 
      logic [15:0] mem_Dmem_addr;

      mem_memState = ctrlrIf.mem_state;
      mem_Mctrl    = execIf.Mem_Control_out;
      mem_mAddr    = execIf.pcout;
      mem_Dout     = memIf.Data_dout;
      mem_mData    = execIf.M_Data;

      if(!monIf.reset) begin //{
         case(mem_memState) 
            2'b00: begin //{
               mem_Dmem_rd     = 1;
               mem_Dmem_din    = 0;
               mem_Dmem_addr   = (mem_Mctrl) ? mem_Dout : mem_mAddr;
            end //}
            2'b01: begin //{
               mem_Dmem_rd     = (mem_Mctrl) ? 1 : 0;
               mem_Dmem_din    = 0;
               mem_Dmem_addr   = mem_mAddr;
            end//}
            2'b10: begin //{
               mem_Dmem_rd     = 0;
               mem_Dmem_din    = mem_mData;
               mem_Dmem_addr   = (mem_Mctrl) ? mem_Dout : mem_mAddr;
            end//}
            2'b11: begin //{ 
               mem_Dmem_rd     = 1'bz;
               mem_Dmem_din    = 16'hz;
               mem_Dmem_addr   = 16'hz;
            end //}
         endcase

         //FIXME: Instruction opcode as exec_IR (change it)
         check("MEM", WARN, mem_Dmem_rd === memIf.Data_rd, $psprintf("[%s] mem read unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), mem_Dmem_rd, memIf.Data_rd));

         check("MEM", WARN, mem_Dmem_din === memIf.Data_din, $psprintf("[%s] mem din unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), mem_Dmem_din, memIf.Data_din));

         check("MEM", WARN, mem_Dmem_addr === memIf.Data_addr, $psprintf("[%s] mem addr unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), mem_Dmem_addr, memIf.Data_addr));
      end //}
      else begin //{
         mem_Mctrl    = 0;  
         mem_mAddr    = 0; 
         mem_Dout     = 0; 
         mem_mData    = 0; 
      end//}
   endfunction

   function void writeback();
      logic [2:0]  wb_psr;
      logic [15:0] wb_VSR1, wb_VSR2;

      wb_W_Control = execIf.W_Control_out;

      if(!monIf.reset) begin//{
         case(wb_W_Control)
            2'b00: begin //{
               regFile[wb_dr_in] = wb_aluout; 
               casex({wb_aluout[15],|wb_aluout})
                  2'b1x:   begin wb_psr  = 3'b100; end
                  2'b01:   begin wb_psr  = 3'b001; end
                  2'b00:   begin wb_psr  = 3'b010; end
                  default: begin check("WB", FATAL, 1, "impossible aluout value"); end
               endcase
            end //}

            2'b01: begin //{ 
               regFile[wb_dr_in] = wb_memout;
               casex({wb_memout[15],|wb_memout})
                  2'b1x:   begin wb_psr  = 3'b100; end
                  2'b01:   begin wb_psr  = 3'b001; end
                  2'b00:   begin wb_psr  = 3'b010; end
                  default: begin check("WB", FATAL, 1, "impossible memout value"); end
               endcase
            end//}

            2'b10: begin //{
               regFile[wb_dr_in] = wb_pcout; 
               casex({wb_pcout[15],|wb_pcout})
                  2'b1x:   begin wb_psr  = 3'b100; end
                  2'b01:   begin wb_psr  = 3'b001; end
                  2'b00:   begin wb_psr  = 3'b010; end
                  default: begin check("WB", FATAL, 1, "impossible pcout value"); end
               endcase
            end//}

            2'b11: begin check("WB", FATAL, 1, "W control 11 not required"); end
         endcase
         `ifdef DEBUG_WB
            $display("WB: PSR %0b ALUOUT %0b PCOUT %0b MEMOUT %0b W_CTRL %0b EXALU %0b EXPCOUT %0b EXMEM %0b", wb_psr, wb_aluout, wb_pcout, wb_memout, execIf.aluout, execIf.pcout, memIf.memout, wb_W_Control);
         `endif
    	
         if( wb_init ) begin //{
            wb_psr        = 3'b000;
            for( int i = 0; i < 8; i++ )
               regFile[i] = 16'bx;
         end //}

         PSR             = wb_psr;
         check("WB", WARN, wb_psr === wbIf.psr, $psprintf("[%s] psr unmatched! (%0b != %0b)", 
            Instruction::op2str(exec_IR[15:12]), wb_psr, wbIf.psr));

         // Pipeline regs
         if( ctrlrIf.enable_writeback ) begin
            wb_aluout    = execIf.aluout; 
            wb_pcout     = execIf.pcout;
            wb_memout    = memIf.memout;
            wb_sr1       = execIf.sr1;
            wb_sr2       = execIf.sr2;
            wb_dr_in     = execIf.dr;
            wb_W_Control = execIf.W_Control_out;
            wb_init      = 0;
         end
      end //}

      if(monIf.reset) begin //{
         wb_aluout     = 0; 
         wb_pcout      = 0; 
         wb_memout     = 0; 
         wb_sr1        = 0; 
         wb_sr2        = 0; 
         wb_dr_in      = 0; 
         wb_W_Control  = 0; 
         wb_init       = 1;
      end //}
   endfunction

   //-------------------------------- CONTROLLER ---------------------------//
   function void controller(); //{
      logic [2:0]  ctrl_dst;
      logic [2:0]  ctrl_sr1;
      logic [2:0]  ctrl_sr2;
      logic        ctrl_AluBit;
      logic        ctrl_storeBit;
      logic        ctrl_loadBit;
      logic        ctrl_brBit;
      logic [15:0] ctrl_decIR;
      logic [15:0] ctrl_execIR;
      logic        ctrl_DSBit;

      logic [2:0]  ctrl_psr;
      logic [2:0]  ctrl_NZP;
      logic [15:0] ctrl_ImemOut;

      logic        ctrl_enUpPC, ctrl_enFetch, ctrl_enDecode, ctrl_enExec, ctrl_enWB;
      logic        ctrl_brTaken;
      logic        ctrl_bpAlu1, ctrl_bpAlu2, ctrl_bpMem1, ctrl_bpMem2;
      logic [3:0]  ctrl_exec_opcode, ctrl_dec_opcode;    
      logic        ctrl_Imem_br_jmp;

      string       header;

      if( !monIf.reset ) begin//{
         ctrl_bpAlu1      = 0;
         ctrl_bpAlu2      = 0;
         ctrl_bpMem1      = 0;
         ctrl_bpMem2      = 0;
         ctrl_DSBit       = 0;

         ctrl_decIR       = decodeIf.IR;
         ctrl_execIR      = execIf.IR_Exec;
         ctrl_psr         = wbIf.psr; 
         ctrl_NZP         = execIf.NZP;
         ctrl_ImemOut     = driverIf.Instr_dout;
         ctrl_exec_opcode = execIf.IR_Exec[15:12];
         ctrl_dec_opcode  = decodeIf.IR[15:12];

         //alu and load/store bits
         ctrl_AluBit      = ((ctrl_exec_opcode == AND) || (ctrl_exec_opcode == ADD) || (ctrl_exec_opcode == NOT));
         ctrl_storeBit    = ((ctrl_exec_opcode == ST ) || (ctrl_exec_opcode == STI) || (ctrl_exec_opcode == STR));
         ctrl_loadBit     = ((ctrl_exec_opcode == LD ) || (ctrl_exec_opcode == LDI) || (ctrl_exec_opcode == LDR));
         ctrl_brBit       = ((ctrl_exec_opcode == BR ) || (ctrl_exec_opcode == JMP));
         ctrl_DSBit       = ((ctrl_dec_opcode  == ST ) || (ctrl_dec_opcode  == STI)  || (ctrl_dec_opcode == STR));

         ctrl_dst         = !(ctrl_storeBit && ctrl_brBit) ? ctrl_execIR[11:9] : 0;
         ctrl_sr1         = ctrl_decIR[8:6];
         ctrl_sr2         = ctrl_DSBit ? ctrl_decIR[11:9] : (!ctrl_decIR[5] ? ctrl_decIR[2:0] : 0);

         ctrl_Imem_br_jmp = (ctrl_ImemOut[15:12] == BR) || (ctrl_ImemOut[15:12] == JMP);

         header           = $psprintf("[E: %s: D: %s]", Instruction::op2str(ctrl_exec_opcode), Instruction::op2str(ctrl_dec_opcode));

         //------------------------------- BYPASS LOGIC BEGIN -------------------
         //bypass ALU operation
         //NOTE: initially ctrl_dec_opcode will have all 0's aka BR
         //Following case won't be affected as branch is not used
         case(ctrl_dec_opcode)
            ADD, AND, NOT: begin //{ 
               if(ctrl_AluBit || (ctrl_exec_opcode == LEA)) begin //{ 
                  ctrl_bpAlu1  = (ctrl_dst == ctrl_sr1);
                  ctrl_bpAlu2  = !ctrl_decIR[5] ? (ctrl_dst == ctrl_sr2) : 0; 
               end //}
               else if(ctrl_loadBit) begin //{
                  ctrl_bpMem1  = (ctrl_dst == ctrl_sr1);
                  ctrl_bpMem2  = !ctrl_decIR[5] ? (ctrl_dst == ctrl_sr2) : 0;
               end //}
            end //}
            LDR, JMP: begin //{
               if(ctrl_AluBit) begin //{
                  ctrl_bpAlu1  = (ctrl_dst == ctrl_sr1);
               end //}
            end //}
            STR: begin //{
               if(ctrl_AluBit) begin //{
                  ctrl_bpAlu1  = (ctrl_dst == ctrl_sr1);
                  ctrl_bpAlu2  = (ctrl_dst == ctrl_sr2);
               end //}
            end //}
            ST, STI: begin //{
               if(ctrl_AluBit) begin //{
                  ctrl_bpAlu2  = (ctrl_dst == ctrl_sr2);
               end //}
            end //}
         endcase

         `ifdef DEBUG_CTRL
            $display("\t %s NOT_IMM %0b, ALU_2 %0b, IR_DST %0b, DEC_SR1 %0b, DEC_SR2 %0b",
                      header, !ctrl_decIR[5], ctrl_bpAlu2, ctrl_dst, ctrl_sr1, ctrl_sr2);
            $display("\t %0d %0d %0x", driverIf.complete_data, ctrl_complete_data, ctrlrIf.mem_state);
         `endif
         //---------------------- BYPASS LOGIC END -------------------

         //----------------------- MEM STATE BEGIN -------------------
         ctrl_memState      = ctrl_memState_N;
         case (ctrl_memState)
            2'b00: begin ctrl_memState_N = driverIf.complete_data ? 2'b11 : 2'b00; end
            2'b01: begin ctrl_memState_N = driverIf.complete_data ? (ctrl_loadBit ? 2'b00 : (ctrl_storeBit ? 2'b10 : 2'b01)) : 2'b01; end
            2'b10: begin ctrl_memState_N = driverIf.complete_data ? 2'b11 : 2'b10; end
            2'b11: begin //{
                      case(ctrl_decIR[15:12]) //{
                         LD, LDR : ctrl_memState_N = 2'b00;
                         LDI, STI: ctrl_memState_N = 2'b01;
                         ST, STR : ctrl_memState_N = 2'b10;
                      endcase //}
                   end //}
         endcase
         //-------------------------- MEM STATE END ------------------------

         //---------------------- ENABLE SIGNALS BEGIN ---------------------
         ctrl_brTaken         = ctrl_Imem_br_jmp ? (|(ctrl_NZP & ctrl_psr) ? 1 : 0) : 0;
         ctrl_enUpPC          = ctrl_complete_instr;

         ctrl_enState         = ctrl_enState_N;
         case(ctrl_enState)
            2'b00: begin //{
               ctrl_enFetch   = 1;
               ctrl_enDecode  = 0;
               ctrl_enExec    = 0;
               ctrl_enWB      = 0;
               ctrl_enState_N = 2'b01;
            end //}
            2'b01: begin 
               ctrl_enFetch   = 1;
               ctrl_enDecode  = 1;
               ctrl_enExec    = 0;
               ctrl_enWB      = 0;
               ctrl_enState_N = 2'b10;
            end //}
            2'b10: begin //{
               ctrl_enFetch   = 1;
               ctrl_enDecode  = 1;
               ctrl_enExec    = 1;
               ctrl_enWB      = 0;
               ctrl_enState_N = 2'b11;
            end //}
            2'b11: begin //{
               ctrl_enFetch   = 1;
               ctrl_enDecode  = 1;
               ctrl_enExec    = 1;
               ctrl_enWB      = 1;
               ctrl_enState_N = 2'b11;
            end //}
         endcase

         `ifdef DEBUG_CTRL
            $display("BaseEnable  : F: %0b D: %0b E: %0b W: %0b", ctrl_enFetch, ctrl_enDecode, ctrl_enExec, ctrl_enWB);
         `endif

         ctrl_stallEnState = ctrl_stallEnState_N;
         case(ctrl_stallEnState)
            2'b00: begin //{
               if( ctrl_decode_enable ) begin //{
                  case(ctrl_dec_opcode)
                     LD, LDR, LDI,
                     STI, ST, STR  : begin ctrl_stallEnState_N = 2'b01; ctrl_Imem_stash = ctrl_dec_opcode; end
                  endcase
               end //}
            end //}

            2'b01: begin //{
               ctrl_enFetch         = 0;
               ctrl_enUpPC          = 0;
               ctrl_enDecode        = 0;
               ctrl_enExec          = 0;
               ctrl_enWB            = 0; 
               case(ctrl_Imem_stash)
                  LD, LDR          : ctrl_stallEnState_N = 2'b00;
                  LDI, STI         : ctrl_stallEnState_N = 2'b11;
                  ST, STR          : ctrl_stallEnState_N = 2'b10;
               endcase
            end //}

            2'b10: begin //{ 
               ctrl_enWB            = 0; 
               ctrl_stallEnState_N  = 2'b00;
            end //}

            2'b11: begin //{
               ctrl_enFetch         = 0;
               ctrl_enUpPC          = 0;
               ctrl_enDecode        = 0;
               ctrl_enExec          = 0;
               ctrl_enWB            = 0; 
               ctrl_stallEnState_N  = (ctrl_Imem_stash == LDI) ? 2'b00 : (ctrl_Imem_stash == STI) ? 2'b10 : 2'b00;
            end //}
         endcase

         `ifdef DEBUG_CTRL
            $display("IntermEnable: F: %0b D: %0b E: %0b W: %0b", ctrl_enFetch, ctrl_enDecode, ctrl_enExec, ctrl_enWB);
         `endif

         ctrl_brEnState = ctrl_brEnState_N;
         case(ctrl_brEnState)
            2'b00: begin //{
               case( ctrl_ImemOut[15:12] )
                  BR, JMP: begin
                     ctrl_brEnState_N = 2'b01;
                  end
               endcase
            end //}
            2'b01: begin ctrl_enFetch  = 0; ctrl_enUpPC = 0;                     ctrl_brEnState_N = 2'b10; end
            2'b10: begin ctrl_enFetch  = 0; ctrl_enUpPC = 0; ctrl_enDecode  = 0; ctrl_brEnState_N = 2'b11; end
            2'b11: begin ctrl_enFetch  = 0; ctrl_enUpPC =    ctrl_brTaken;       ctrl_enDecode    = 0;  
                         ctrl_enExec   = 0; ctrl_enWB   = 0; ctrl_enState_N = 0; ctrl_brEnState_N = 2'b00; end
         endcase

         $display("complete_ins: %0b en_decode: %0b", ctrl_complete_instr, ctrl_enDecode);
         // In general case, enable decode stays low until complete_instr goes high and instruction
         // is ready to use
         ctrl_enDecode                 = ctrl_complete_instr ? ctrl_enDecode : 0;

         `ifdef DEBUG_CTRL
            $display("FinalEnable : F: %0b D: %0b E: %0b W: %0b", ctrl_enFetch, ctrl_enDecode, ctrl_enExec, ctrl_enWB);
            $display("\tdrIf_complete_instr: %0b, enstate: %0b, stallState: %0b brState: %0b, Imem: %s, inst: %s, stash: %s", 
            driverIf.complete_instr, ctrl_enState, ctrl_stallEnState,
            ctrl_brEnState, Instruction::op2str(ctrl_ImemOut[15:12]), Instruction::op2str(ctrl_dec_opcode),
            Instruction::op2str(ctrl_Imem_stash));
            $display("%t ct_state %0b, branch_taken %0b", $time, ctrl_stallEnState, ctrl_brTaken); 
            $display("\tbrTaken: %0x br_jmp: %0x NZP: %0b psr: %0b", ctrl_brTaken, ctrl_Imem_br_jmp, ctrl_NZP, ctrl_psr );
         `endif

         check("CTRLR", WARN, ctrl_bpAlu1 === ctrlrIf.bypass_alu_1, $psprintf("%s BYPASS ALU 1 unmatched! (%0x != %0x)", 
            header, ctrl_bpAlu1, ctrlrIf.bypass_alu_1));

         check("CTRLR", WARN, ctrl_bpAlu2 === ctrlrIf.bypass_alu_2, $psprintf("%s BYPASS ALU 2 unmatched! (%0x != %0x)", 
            header, ctrl_bpAlu2, ctrlrIf.bypass_alu_2));

         check("CTRLR", WARN, ctrl_bpMem1 === ctrlrIf.bypass_mem_1, $psprintf("%s BYPASS MEM 1 unmatched! (%0x != %0x)", 
            header, ctrl_bpMem1, ctrlrIf.bypass_mem_1));

         check("CTRLR", WARN, ctrl_bpMem2 === ctrlrIf.bypass_mem_2, $psprintf("%s BYPASS MEM 2 unmatched! (%0x != %0x)", 
            header, ctrl_bpMem2, ctrlrIf.bypass_mem_2));

         check("CTRLR", WARN, ctrl_memState === ctrlrIf.mem_state, $psprintf("%s mem state unmatched! (%0x != %0x, %0x)", 
            header, ctrl_memState, ctrlrIf.mem_state, ctrl_memState_N));

         check("CTRLR", WARN, ctrl_enFetch === ctrlrIf.enable_fetch, $psprintf("%s enable fetch unmatched! (%0x != %0x)", 
            header, ctrl_enFetch, ctrlrIf.enable_fetch));

         check("CTRLR", WARN, ctrl_enDecode === ctrlrIf.enable_decode, $psprintf("%s enable decode unmatched! (%0x != %0x)", 
            header, ctrl_enDecode, ctrlrIf.enable_decode));

         check("CTRLR", WARN, ctrl_enExec === ctrlrIf.enable_execute, $psprintf("%s enable execute unmatched! (%0x != %0x)", 
            header, ctrl_enExec, ctrlrIf.enable_execute));

         check("CTRLR", WARN, ctrl_enWB === ctrlrIf.enable_writeback, $psprintf("%s enable write back unmatched! (%0x != %0x)", 
            header, ctrl_enWB, ctrlrIf.enable_writeback));

         check("CTRLR", WARN, ctrl_brTaken === ctrlrIf.br_taken, $psprintf("%s branch taken unmatched! (%0x != %0x)", 
            header, ctrl_brTaken, ctrlrIf.br_taken));

         check("CTRLR", WARN, ctrl_enUpPC === ctrlrIf.enable_updatePC, $psprintf("%s enable update PC unmatched! (%0x != %0x)", 
            header, ctrl_enUpPC, ctrlrIf.enable_updatePC));
           
         //---------------------- ENABLE SIGNALS END ----------------------
         ctrl_decode_enable = ctrl_enDecode;
      end //}

      // Pipeline regs
      ctrl_complete_data   = driverIf.complete_data;
      ctrl_complete_instr  = driverIf.complete_instr;

      if ( monIf.reset ) begin //{
         // Reset FSM regs
         //mem state
         ctrl_memState       = 2'b11;
         ctrl_memState_N     = ctrl_memState;
         ctrl_enState        = 0;
         ctrl_enState_N      = 0;
         ctrl_stallEnState   = 0;
         ctrl_stallEnState_N = 0;
         ctrl_brEnState      = 0;
         ctrl_brEnState_N    = 0;
         ctrl_decode_enable  = 0;
      end //}
   endfunction //}


   function new( virtual Lc3_mon_if monIf, virtual Lc3_dr_if driverIf ); //{
      super.new();
      this.monIf        = monIf;
      this.driverIf     = driverIf;
      this.fetchIf      = monIf.FETCH;
      this.decodeIf     = monIf.DECODE;
      this.execIf       = monIf.EXECUTE;
      this.wbIf         = monIf.WB;
      this.memIf        = monIf.MEM;
      this.ctrlrIf      = monIf.CTRLR;
      this.currentTrans = new;
   endfunction //}
   
   task run_async();
      logic [2:0]  sr1, sr2;
      logic [2:0]  exec_sr2;
      logic [16:0] memout;
      logic [16:0] vsr1, vsr2;
      forever begin
         // Sample and hold DUT signals
         sr1    = execIf.sr1;
         sr2    = execIf.sr2;
         memout = memIf.memout;
         vsr1   = wbIf.VSR1;
         vsr2   = wbIf.VSR2;
         // Sensitize on all DUT async signals
         @(execIf.sr1 or execIf.sr2 or memIf.memout or wbIf.VSR1 or wbIf.VSR2);

         if( !monIf.reset ) begin
            //--------------------- EXEC ---------------------
            check("A_EXEC", WARN, exec_IR[8:6] === sr1, $psprintf("sr1 unmatched! (%0x != %0x)", exec_IR[8:6], sr1));

            case(exec_IR[15:12])
               ADD: begin exec_sr2 = exec_IR[02:0]; end
               AND: begin exec_sr2 = exec_IR[02:0]; end
               NOT: begin exec_sr2 = exec_IR[02:0]; end
               LD : begin exec_sr2 =             0; end
               LDR: begin exec_sr2 =             0; end
               LDI: begin exec_sr2 =             0; end
               LEA: begin exec_sr2 =             0; end
               ST : begin exec_sr2 = exec_IR[11:9]; end
               STR: begin exec_sr2 = exec_IR[11:9]; end
               STI: begin exec_sr2 = exec_IR[11:9]; end
               BR : begin exec_sr2 =             0; end
               JMP: begin exec_sr2 =             0; end 
            endcase

            check("A_EXEC", WARN, exec_sr2 === sr2, $psprintf("sr2 unmatched! (%0x != %0x)", exec_sr2, sr2));

            //--------------------- MEM ---------------------
            check("A_MEM", WARN, mem_Dout === memout, $psprintf("memout unmatched! (%0x != %0x)", mem_Dout, memout));

            //---------------------- WB ---------------------
            // regFile is updated by wb sync function at the same clock. Add timestep delay to remove that hazard
            //TODO:
            #1;
            check("A_WB", WARN, regFile[sr1] === vsr1, $psprintf("vsr1(%0d) unmatched! (%0x != %0x)", sr1, regFile[sr1], vsr1));
            check("A_WB", WARN, regFile[sr2] === vsr2, $psprintf("vsr2(%0d) unmatched! (%0x != %0x)", sr2, regFile[sr2], vsr2));
         end

      end
   endtask

   task run_sync();
      forever begin
         fetch();
         decode();
         execute();
         memAccess();
         writeback();
         controller();
         @(posedge monIf.clk);
      end
   endtask

   task run();
      fork
         run_sync();
         run_async();
      join
   endtask

endclass

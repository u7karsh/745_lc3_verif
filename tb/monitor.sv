// Assuming DUT's controller as golden for pipe stages
class Monitor extends Agent;
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

   /*
    * Wb globals
    */
   reg [15:0] execute_ir, exec_E_Control, decode_npcout;

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
         fetch_npc     = 0;
      end //}
   endfunction //}

   //------------------------DECODE---------------
   function void decode(); //{
      if( !monIf.reset && ctrlrIf.enable_decode ) begin //{
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

         decode_ir         =  ctrlrIf.Instr_dout;
         decode_npcout     =  fetchIf.npc;
         decode_init       = 0;
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
      logic [15:0] exec_pcout;
      logic [15:0] val_1;
      logic [15:0] val_2;
      logic [2:0]  exec_nzp;
      logic [2:0]  exec_dr;

      if( !monIf.reset && ctrlrIf.enable_execute ) begin //{
         //reconfiguring offsets in execute
         //for PC OUT
         case(exec_bypass1)
            2'b00: val_1 = exec_vsr1;
            2'b01: val_1 = memIf.memout;
            2'b10: val_1 = exec_aluout;
         endcase

         case(exec_bypass2)
            2'b00: val_2 = exec_Ectrl[0] ? exec_vsr2 : {{11{exec_IR[4]}}, exec_IR[4:0]};
            2'b01: val_2 = memIf.memout;
            2'b10: val_2 = exec_aluout;
         endcase

         case(exec_Ectrl[3:2])
            2'b00: begin exec_pcout = {{5{exec_IR[10]}}, exec_IR[10:0]} + (exec_Ectrl[1] ? exec_npc : val_1); end
            2'b01: begin exec_pcout = {{7{exec_IR[8]}} , exec_IR[8:0]}  + (exec_Ectrl[1] ? exec_npc : val_1); end
            2'b10: begin exec_pcout = {{10{exec_IR[5]}}, exec_IR[5:0]}  + (exec_Ectrl[1] ? exec_npc : val_1); end
            2'b11: begin exec_pcout = 16'b0; end
         endcase

         //ALU Control unit
         case(exec_Ectrl[5:4])
            2'b00: begin exec_aluout = val_1 + val_2; end 
            2'b01: begin exec_aluout = val_1 & val_2; end 
            2'b10: begin exec_aluout = ~val_1; end
            default: begin check("EXEC", FATAL, 1, "Control not supported"); end
         endcase

         exec_Mdata                  =  exec_bypass2[1] ? val_2 : exec_vsr2;

         // For ALU, short alout with pcout (not documented)
         case(exec_IR[15:12])
            ADD: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_pcout  = exec_aluout; end
            AND: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_pcout  = exec_aluout; end
            NOT: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_pcout  = exec_aluout; end
            LD : begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            LDR: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            LDI: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            LEA: begin exec_dr = exec_IR[11:9]; exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            ST : begin exec_dr = 3'b0;          exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            STR: begin exec_dr = 3'b0;          exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            STI: begin exec_dr = 3'b0;          exec_nzp = 3'b000;        exec_aluout = exec_pcout;  end
            BR : begin exec_dr = 3'b0;          exec_nzp = exec_IR[11:9]; exec_aluout = exec_pcout;  end
            JMP: begin exec_dr = 3'b0;          exec_nzp = 3'b111;                                   end 
         endcase

         if( exec_init ) begin
            exec_Mdata  = 0;
            exec_Wctrl  = 0;
            exec_Mctrl  = 0;
            exec_aluout = 0;
            exec_pcout  = 0;
         end

         `ifdef DEBUG_EXEC
            $display("%t IR: 0x%0x bypass1: %0b bypass2: %0b %0b val1: %0x val2: %0x vsr1: %0x vsr2: %0x %0x aluout: %0x pcout: %0x Mdata: %0x", $time, exec_IR, exec_bypass1, exec_bypass2, exec_Ectrl[5:4], val_1, val_2, exec_vsr1, exec_vsr2, exec_IR[4:0], exec_aluout, execIf.pcout, execIf.M_Data);
         `endif

         check("EXEC", WARN, exec_Mdata === execIf.M_Data, $psprintf("[%s] mem data unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_Mdata, execIf.M_Data));

         check("EXEC", WARN, exec_Wctrl === execIf.W_Control_out, $psprintf("[%s] W_control unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_Wctrl, execIf.W_Control_out));

         check("EXEC", WARN, exec_Mctrl === execIf.Mem_Control_out, $psprintf("[%s] Mem_control unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_Mctrl, execIf.Mem_Control_out));

         check("EXEC", WARN, exec_aluout === execIf.aluout, $psprintf("[%s] alu out unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_aluout, execIf.aluout));

         check("EXEC", WARN, exec_pcout === execIf.pcout, $psprintf("[%s] pc out unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_pcout, execIf.pcout));

         check("EXEC", WARN, exec_dr === execIf.dr, $psprintf("[%s] destination register unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_dr, execIf.dr));

         check("EXEC", WARN, exec_nzp === execIf.NZP, $psprintf("[%s] NZP unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_nzp, execIf.NZP));

         check("EXEC", WARN, exec_IR === execIf.IR_Exec, $psprintf("[%s] IR Execute unmatched! (%0x != %0x)", 
            Instruction::op2str(exec_IR[15:12]), exec_IR, execIf.IR_Exec));

         exec_Ectrl   = decodeIf.E_Control;
         exec_Wctrl   = decodeIf.W_Control;
         exec_Mctrl   = decodeIf.Mem_Control;
         exec_IR      = decodeIf.IR;
         exec_npc     = decodeIf.npc_out;
         exec_init    = 0;
      end //}

      exec_bypass1    = {ctrlrIf.bypass_alu_1, ctrlrIf.bypass_mem_1};
      exec_bypass2    = {ctrlrIf.bypass_alu_2, ctrlrIf.bypass_mem_2};
      exec_vsr1       = wbIf.VSR1;
      exec_vsr2       = wbIf.VSR2;

      if( monIf.reset ) begin
         exec_Ectrl  = 0;
         exec_IR     = 0;
         exec_npc    = 0;
         exec_init   = 1;
      end
   endfunction //}

   //function void memAccess();
   //   reg        mem_Dmem_rd;  
   //   reg [15:0] mem_Dmem_din; 
   //   reg [15:0] mem_Dmem_addr;
   //   case(ctrlrIf.mem_state) 
   //      2'b00: begin //{
   //         mem_Dmem_rd     = 1;
   //         mem_Dmem_din    = 0;
   //         mem_Dmem_addr   = (execIf.Mem_Control_out) ? memIf.Data_dout : execIf.pcout;
   //      end //}
   //      2'b01: begin //{
   //         mem_Dmem_rd     = (execIf.Mem_Control_out) ? 1 : 0;
   //         mem_Dmem_din    = 0;
   //         mem_Dmem_addr   = execIf.pcout;
   //      end//}
   //      2'b10: begin //{
   //         mem_Dmem_rd     = 0;
   //         mem_Dmem_din    = execIf.M_Data;
   //         mem_Dmem_addr   = (execIf.Mem_Control_out) ? memIf.Data_dout : execIf.pcout;
   //      end//}
   //      2'b11: begin //{ 
   //         mem_Dmem_rd     = 1'bz;
   //         mem_Dmem_din    = 16'hz;
   //         mem_Dmem_addr   = 16'hz;
   //      end //}
   //   endcase
   //endfunction
   
   //function void controller();
   //begin //{
   //  always@(posedge clk)
   //  begin//{
   //  
   //  if(!monIf.reset)
   //  begin//{
   //  //*************bypass part********************//
   //    bypass_alu_1=0; bypass_alu_2=0; bypass_mem_1=0; bypass_mem_2=0;
   //    begin//{
   //      if((IR[15:12]==ADD)||(IR[15:12]==AND) || (IR[15:12]==NOT))
   //      begin //{
   //        if((IR_Exec[15:12]==ADD)||(IR_Exec[15:12]==AND)||(IR_Exec[15:12]==NOT)||(IR_Exec[15:12]==LEA))
   //          begin //{
   //            if(IR[5]==1)
   //              begin //{
   //                if(IR_Exec[11:9]==IR[8:6])
   //                  bypass_alu_1=1;  
   //              end //}
   //            else
   //              begin //{
   //                if(IR_Exec[11:9]==IR[8:6])
   //                  bypass_alu_1=1;
   //                if(IR_Exec[11:9]==IR[2:0])
   //                  bypass_alu_2=1;
   //              end//}
   //          end //}
   //        else if((IR_Exec[15:12]==LD)||(IR_Exec[15:12]==LDR)||(IR_Exec[15:12]==LDI))
   //            begin //{
   //              if(IR[5]==1)
   //                begin //{
   //                  if(IR_Exec[11:9]==IR[8:6])
   //                    bypass_alu_1=1;  
   //                end //}
   //              else
   //                begin //{
   //                  if(IR_Exec[11:9]==IR[8:6])
   //                    bypass_alu_1=1;
   //                  if(IR_Exec[11:9]==IR[2:0])
   //                    bypass_alu_2=1;
   //                end//}
   //              end //}
   //          
   //      end //}
   //      else if(IR[15:12]==LDR)
   //          begin
   //            if((IR_Exec[11:9]==ADD) || (IR_Exec[11:9]==AND)||(IR_Exec[11:9]==NOT))
   //              begin
   //                if(IR_Exec[11:9]==IR[8:6])
   //                  bypass_alu_1=1;
   //              end
   //          end
   //      else if(IR[15:12]==STR)
   //          begin
   //            if((IR_Exec[11:9]==ADD) || (IR_Exec[11:9]==AND)||(IR_Exec[11:9]==NOT))
   //              begin
   //                if(IR_Exec[11:9]==IR[8:6])
   //                  bypass_alu_1=1;
   //                if(IR_Exec[11:9]==IR[11:9])
   //                  bypass_alu_2=1;
   //              end
   //          end
   //      else if((IR[15:12]==STI)||(IR[15:12]==ST)
   //          begin
   //            if((IR_Exec[11:9]==ADD) || (IR_Exec[11:9]==AND)||(IR_Exec[11:9]==NOT))
   //              begin
   //                if(IR_Exec[11:9]==IR[11:9])
   //                  bypass_alu_2=1;
   //              end
   //          end
   //      else if(IR[15:12]==JMP)
   //          begin
   //            if((IR_Exec[11:9]==ADD) || (IR_Exec[11:9]==AND)||(IR_Exec[11:9]==NOT))
   //              begin
   //                if(IR_Exec[11:9] == IR[8:6])
   //                  bypass_alu_1 = 1;
   //              end
   //          end
   //      
   //    end//}
   //  end //}
   //end //}
   //end function
   ////************memory check stage***********************//
   //function mem_gen();
   //begin//{
   //  forever
   //    begin //{
   //  if(mem_state==2'b00)
   //    begin
   //      if(complete_data==1)
   //        next_state=2'b11;
   //      else
   //        next_state=2'b00;    
   //    end
   //  if(mem_state==2'b01)
   //    begin
   //      if((complete_data==1)&&(IR_Exec[15:12]==LDI))
   //        next_state=2'b00;
   //      else if((complete_data==1)&&(IR_Exec[15:12]==STI))
   //        next_state=2'b10;
   //    end
   //  if(mem_state=2'b10)
   //    begin
   //      if(complete_data==1)
   //        next_state=2'b11;
   //      else
   //        next_state=2'b10;
   //    end
   //  if(mem_state==2'11)
   //    begin
   //      if((complete_data==1)&&((IR[15:12]==LD)||(IR[15:12]==LDR)))
   //        next_state=2'b00;
   //      else if((complete_data==1)&&((IR[15:12]==STI)||(IR[15:12]==LDI)))
   //        next_state=2'b01;
   //      else if((complete_data==1)&&((IR[15:12]==ST)||(IR[15:12]==STR)))
   //        next_state=2'b10;
   //      else
   //        next_state=2'b11;
   //    end
   //    else
   //    next_state=2'b11;
   //  end //}
   //end //}
   //end function
   ////**************enable signals*************//
   //function enable_gen();
   //begin//{
   //  always@(posedge clk)
   //  begin //{
   //    if(!monIf.reset)
   //      begin//{
   //        if((Instr_dout[15:12]==JMP)||(Instr_dout[15:12]==BR))
   //          begin//{
   //            enable_fetch= 0;
   //            enable_updatePC= 0;
   //            
   //            @(posedge clk);
   //            //begin
   //              enable_decode=0;
   //            //end
   //            @(posedge clk);
   //            //begin
   //              enable_execute=0;
   //              enable_write_back=0;
   //              
   //              branch = |(NZP & PSR);
   //              if(branch===3'b000)
   //              begin
   //                br_taken=0;
   //                
   //                @(posedge clk)
   //                enable_fetch=1;
   //                enable_updatePC=1;
   //              end
   //            
   //          end//}
   //        else if((IR[15:12]==LD)||(IR[15:12]==LDR))
   //          begin
   //            @(posedge clk);
   //            //begin
   //              enable_fetch = 0;
   //              enable_updatePC = 0;
   //              enable_decode = 0;
   //              enable_execute = 0;
   //              enable_writeback = 0;
   //            //end
   //            @(posedge clk);
   //            //begin
   //              enable_fetch = 1;
   //              enable_updatePC = 1;
   //              enable_decode = 1;
   //              enable_execute = 1;
   //              enable_writeback = 1;
   //            //end
   //          end
   //        else if((IR[15:12]==ST)||(IR[15:12]==STR))
   //          begin
   //            @(posedge clk);
   //            //begin
   //              enable_fetch = 0;
   //              enable_updatePC = 0;
   //              enable_decode = 0;
   //              enable_execute = 0;
   //              enable_writeback = 0;
   //            //end
   //            @(posedge clk);
   //            //begin
   //              enable_fetch = 1;
   //              enable_updatePC = 1;
   //              enable_decode = 1;
   //              enable_execute = 1;
   //              
   //            //end
   //            @(posedge clk);
   //            enable_writeback = 1;
   //          end
   //        else if(IR[15:12] == LDI)  
   //            begin
   //              @(posedge clk);
   //              //begin
   //                enable_fetch = 0;
   //                enable_updatePC = 0;
   //                enable_decode = 0;
   //                enable_execute = 0;
   //                enable_writeback = 0;
   //              //end
   //          
   //              @(posedge clk);
   //              enable_fetch = 1;
   //              enable_updatePC = 1;
   //              enable_decode = 1;
   //              enable_execute = 1;
   //              enable_writeback = 1;
   //              
   //            end
   //          else if(IR[15:12] == STI)  
   //            begin
   //              @(posedge clk);
   //              enable_fetch = 0;
   //              enable_updatePC = 0;
   //              enable_decode = 0;
   //              enable_execute = 0;
   //              enable_writeback = 0;
   //          
   //              @(posedge clk);
   //              enable_fetch = 1;
   //              enable_updatePC = 1;
   //              enable_decode = 1;
   //              enable_execute = 1;
   //          
   //              @(posedge clk);
   //              enable_writeback = 1;
   //            end
   //      end //}
   //      else
   //        begin  //{
   //          @(posedge clk);
   //          enable_fetch = 1;
   //          enable_updatePC = 0;
   //          enable_decode = 0;
   //          enable_execute = 0;
   //          enable_writeback = 0;
   //          br_taken = 0;
   //          
   //          wait(!monIf.reset);
   //          @(posedge clk);
   //          enable_updatePC = 1;
   //          
   //          @(posedge clk);
   //          enable_decode = 1;
   //
   //          @(posedge clk);
   //          enable_execute = 1;
   //
   //          @(posedge clk);
   //          enable_writeback = 1;
   //        end //}
   //    end//}
   //  
   //  end//}
   //end function
   

   function new( virtual Lc3_mon_if monIf ); //{
      super.new();
      this.monIf        = monIf;
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
      forever begin
         if( !monIf.reset ) begin
            //--------------------- EXEC ---------------------
            check("AEXEC", WARN, exec_IR[8:6] === sr1, $psprintf("[%s] sr1 unmatched! (%0x != %0x)", 
               Instruction::op2str(exec_IR[15:12]), exec_IR[8:6], sr1));

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

            check("AEXEC", WARN, exec_sr2 === sr2, $psprintf("[%s] sr2 unmatched! (%0x != %0x)", 
               Instruction::op2str(exec_IR[15:12]), exec_sr2, sr2));
         end

         // Sample and hold
         sr1   = execIf.sr1;
         sr2   = execIf.sr2;
         @(execIf.sr1 or execIf.sr2);
      end
   endtask

   task run_sync();
      forever begin
         fetch();
         decode();
         execute();
         @(posedge monIf.clk);
      end
   endtask

   task run();
      fork
         run_async();
         run_sync();
      join
   endtask

endclass

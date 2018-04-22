class Coverage;
   virtual Lc3_mon_if monIf;

   covergroup ALU_OPR_cg @(posedge monIf.clk);
   
		cov_alu_opcode: coverpoint top.test.env.monitor.currentTrans.opcode {
			 bins Add    = {ADD};
			 bins And    = {AND};
			 bins Not    = {NOT};
		}
		
		cov_imm_en: coverpoint top.test.env.monitor.currentTrans.immValid{
			bins zero = {0};
			bins one = {1};
		}
		
		cov_SR1: coverpoint top.test.env.monitor.currentTrans.src1 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT}){
			bins SRC1 = {[0:8]};
		}
		
		cov_SR2: coverpoint top.test.env.monitor.currentTrans.src2 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT}){
			bins SRC2 = {[0:8]};
		}
		
		cov_DR: coverpoint top.test.env.monitor.currentTrans.dst iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT}){
			bins DST = {[0:8]};
		}
		
		cov_imm5: coverpoint top.test.env.monitor.currentTrans.imm iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT}){
			bins IMM[] = {[5'b00000:5'b11111]};
		} 
		
		xc_opcode_imm_en: cross cov_alu_opcode,cov_imm_en;
		
		xc_opcode_dr_sr1_imm5: cross cov_alu_opcode, cov_SR1, cov_DR, cov_imm5 iff(top.test.env.monitor.currentTrans.immValid == 1);
		  
		xc_opcode_dr_sr1_sr2: cross cov_alu_opcode, cov_SR1, cov_DR, cov_SR2 iff(top.test.env.monitor.currentTrans.immValid == 0);
		
		cov_aluin1 : coverpoint top.test.env.monitor.aluin1 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		option.auto_bin_max = 8 ;
		}
		
		cov_aluin1_corner : coverpoint top.test.env.monitor.aluin1 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin1_corner_high = {16'hFFFF} ;
		bins aluin1_corner_low  = {16'h0000} ;
		}
		
		cov_aluin2 : coverpoint top.test.env.monitor.aluin2 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		option.auto_bin_max = 8 ;
		}
		
		cov_aluin2_corner : coverpoint top.test.env.monitor.aluin2 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin2_corner_high = {16'hFFFF} ;
		bins aluin2_corner_low  = {16'h0000} ;
		}
		
		xc_opcode_aluin1: cross cov_alu_opcode,cov_aluin1_corner ;
		
		xc_opcode_aluin2: cross cov_alu_opcode,cov_aluin2_corner ;

	
		/*xc_Cov_opr_zero_all1 : cross cov_alu_opcode,cov_aluin1_corner,cov_aluin2_corner{
		bins aluin1_zero_aluin2_high = binsof(cov_aluin1_corner.aluin1_corner_low) &&  binsof(cov_aluin2_corner.aluin2_corner_high);
		} 		
		
		xc_Cov_opr_all1_zero : cross cov_alu_opcode,cov_aluin1_corner,cov_aluin2_corner{
		bins aluin1_high_aluin2_zero= binsof(cov_aluin1_corner.aluin1_corner_high) &&  binsof(cov_aluin2_corner.aluin2_corner_low);
		} 
		
		xc_Cov_opr_all1_all1 : cross cov_alu_opcode,cov_aluin1_corner,cov_aluin2_corner{
		bins aluin1_high_aluin2_high = binsof(cov_aluin1_corner.aluin1_corner_high) &&  binsof(cov_aluin2_corner.aluin2_corner_high);
		} 
		
		xc_Cov_opr_zero_zero : cross cov_alu_opcode,cov_aluin1_corner,cov_aluin2_corner{
		bins aluin1_zero_aluin2_zero = binsof(cov_aluin1_corner.aluin1_corner_low) &&  binsof(cov_aluin2_corner.aluin2_corner_low);
		} */
		
		xc_Cov_opr_zero_all1 : cross cov_alu_opcode,cov_aluin1_corner,cov_aluin2_corner{
		bins aluin1_zero_aluin2_high = binsof(cov_aluin1_corner.aluin1_corner_low) &&  binsof(cov_aluin2_corner.aluin2_corner_high);
		bins aluin1_high_aluin2_zero= binsof(cov_aluin1_corner.aluin1_corner_high) &&  binsof(cov_aluin2_corner.aluin2_corner_low);
		bins aluin1_high_aluin2_high = binsof(cov_aluin1_corner.aluin1_corner_high) &&  binsof(cov_aluin2_corner.aluin2_corner_high);
		bins aluin1_zero_aluin2_zero = binsof(cov_aluin1_corner.aluin1_corner_low) &&  binsof(cov_aluin2_corner.aluin2_corner_low);
		} 
		
		cov_aluin1_alt : coverpoint top.test.env.monitor.aluin1 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin1_alt01 = {16'b0101010101010101} ;
		bins aluin1_alt10 = {16'b1010101010101010} ;
		bins others = default;
		}
		
		cov_aluin2_alt : coverpoint top.test.env.monitor.aluin2 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin2_alt01 = {16'b0101010101010101} ;
		bins aluin2_alt10 = {16'b1010101010101010} ;
		bins others = default;
		}
		
		/*xc_Cov_opr_alt01_alt01: cross cov_alu_opcode,cov_aluin1_alt,cov_aluin2_alt{
		bins a01b01 = binsof(cov_aluin1_alt.aluin1_alt01) && binsof(cov_aluin2_alt.aluin2_alt01);
		}
		xc_Cov_opr_alt01_alt10: cross cov_alu_opcode,cov_aluin1_alt,cov_aluin2_alt{
		bins a01b10 = binsof(cov_aluin1_alt.aluin1_alt01) && binsof(cov_aluin2_alt.aluin2_alt10);
		}
		xc_Cov_opr_alt10_alt01: cross cov_alu_opcode,cov_aluin1_alt,cov_aluin2_alt{
		bins a10b01 = binsof(cov_aluin1_alt.aluin1_alt10) && binsof(cov_aluin2_alt.aluin2_alt01);
		}
		xc_Cov_opr_alt10_alt10: cross cov_alu_opcode,cov_aluin1_alt,cov_aluin2_alt{
		bins a10b10 = binsof(cov_aluin1_alt.aluin1_alt10) && binsof(cov_aluin2_alt.aluin2_alt10);
		
		}*/
		
		xc_cov_opr_alt01_alt01: cross cov_alu_opcode,cov_aluin1_alt,cov_aluin2_alt{
		bins a01b01 = binsof(cov_aluin1_alt.aluin1_alt01) && binsof(cov_aluin2_alt.aluin2_alt01);
		bins a01b10 = binsof(cov_aluin1_alt.aluin1_alt01) && binsof(cov_aluin2_alt.aluin2_alt10);
		bins a10b01 = binsof(cov_aluin1_alt.aluin1_alt10) && binsof(cov_aluin2_alt.aluin2_alt01);
		bins a10b10 = binsof(cov_aluin1_alt.aluin1_alt10) && binsof(cov_aluin2_alt.aluin2_alt10);
		}
		
		cov_aluin1_pos : coverpoint top.test.env.monitor.aluin1 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin1_pos = {1'b0} ;
		bins aluin1_neg = {1'b1} ;
		}
		
		cov_aluin2_pos : coverpoint top.test.env.monitor.aluin2 iff (top.test.env.monitor.currentTrans.opcode inside {ADD, AND, NOT})
		{
		bins aluin2_pos = {1'b0} ;
		bins aluin2_neg = {1'b1} ;
		}
		
		Xc_cov_opr_pos_neg : cross cov_alu_opcode,cov_aluin1_pos,cov_aluin2_pos{
		bins opr_pos_pos = binsof(cov_aluin1_pos.aluin1_pos) && binsof(cov_aluin2_pos.aluin2_pos);
		bins opr_pos_neg = binsof(cov_aluin1_pos.aluin1_pos) && binsof(cov_aluin2_pos.aluin2_neg);
		bins opr_neg_pos = binsof(cov_aluin1_pos.aluin1_neg) && binsof(cov_aluin2_pos.aluin2_pos);
		bins opr_neg_neg = binsof(cov_aluin1_pos.aluin1_neg) && binsof(cov_aluin2_pos.aluin2_neg);
		}	
   endgroup

   
   
   covergroup MEM_OPR_cg @(posedge monIf.clk);
   
		opcode_load: coverpoint top.test.env.monitor.currentTrans.opcode {
			 bins ld     = {LD};
			 bins ldr    = {LDR};
			 bins ldi    = {LDI};
			 bins lea    = {LEA};
		}
		opcode_store: coverpoint top.test.env.monitor.currentTrans.opcode {
			 bins st     = {ST};
			 bins str    = {STR};
			 bins sti    = {STI};
		}
		
		cov_mem_opcode: coverpoint top.test.env.monitor.currentTrans.opcode {
			 bins ld     = {LD};
			 bins ldr    = {LDR};
			 bins ldi    = {LDI};
			 bins lea    = {LEA};
			 bins st     = {ST};
			 bins str    = {STR};
			 bins sti    = {STI};
		}
		
		cov_baseR: coverpoint top.test.env.monitor.currentTrans.baseR iff (top.test.env.monitor.currentTrans.opcode inside {LDR,STR}){
			bins baseR 	 = {[0:7]};
		}
		
		cov_SR: coverpoint top.test.env.monitor.currentTrans.src1 iff (top.test.env.monitor.currentTrans.opcode inside {ST, STI, STR}) {
			bins SR = {[0:8]};
		}
		
		cov_DR: coverpoint top.test.env.monitor.currentTrans.dst iff (top.test.env.monitor.currentTrans.opcode inside {LD, LDI, LEA, LDR}) {
			bins DR = {[0:8]};
		}
		
		cov_PCoffset9: coverpoint top.test.env.monitor.currentTrans.pcOffset9 iff(top.test.env.monitor.currentTrans.opcode inside {LD, LDI, LEA, LDR, ST, STI, STR}) {
			option.auto_bin_max=8;
			
		}
		
		cov_PCoffset9_c: coverpoint top.test.env.monitor.currentTrans.pcOffset9 iff(top.test.env.monitor.currentTrans.opcode inside {LD, LDI, LEA, LDR, ST, STI, STR}){
			 bins pcOffset9_corner_high =  {9'b111111111};  
			 bins pcOffset9_corner_low =  {9'b000000000};  
		}
		
		cov_PCoffset6: coverpoint top.test.env.monitor.currentTrans.pcOffset6 iff(top.test.env.monitor.currentTrans.opcode inside {LD, LDI, LEA, LDR, ST, STI, STR}){
			option.auto_bin_max=8;
		}
		
		cov_PCoffset6_c: coverpoint top.test.env.monitor.currentTrans.pcOffset6 iff(top.test.env.monitor.currentTrans.opcode inside {LD, LDI, LEA, LDR, ST, STI, STR}){
			 bins pcOffset6_corner_high =  {6'b111111};  
			 bins pcOffset6_corner_low =  {6'b000000}; 
		}
		
		xc_BaseR_DR_offset6 : cross cov_PCoffset6,cov_DR,cov_baseR,opcode_load;

		xc_BaseR_SR_offset6 : cross cov_PCoffset6,cov_SR,cov_baseR,opcode_store;
		
   endgroup

   
   
   
   covergroup CTRL_OPR_cg @(posedge monIf.clk);
   
		opcode_branch: coverpoint top.test.env.monitor.currentTrans.opcode {
			 bins br     = {BR};
			 bins jmp    = {JMP};
		}
		cov_baseR: coverpoint top.test.env.monitor.currentTrans.baseR iff(top.test.env.monitor.currentTrans.opcode == {JMP}){
			option.auto_bin_max = 8;
		}
		
		/*cov_NZP : cross top.test.env.monitor.currentTrans.N, top.test.env.monitor.currentTrans.Z, top.test.env.monitor.currentTrans.P,opcode_branch {
			ignore_bins others = binsof(opcode_branch) intersect {BR};
		}*/
		
		cov_N : coverpoint top.test.env.monitor.currentTrans.N iff(top.test.env.monitor.currentTrans.opcode == {JMP});
		
		cov_Z : coverpoint top.test.env.monitor.currentTrans.Z iff(top.test.env.monitor.currentTrans.opcode == {JMP});
		
		cov_P : coverpoint top.test.env.monitor.currentTrans.P iff(top.test.env.monitor.currentTrans.opcode == {JMP});
		
		cov_PSR:coverpoint top.test.env.monitor.PSR iff(top.test.env.monitor.currentTrans.opcode == {JMP});
		
		cov_PCoffset9: coverpoint top.test.env.monitor.currentTrans.pcOffset9 iff(top.test.env.monitor.currentTrans.opcode == {JMP, BR}){
			option.auto_bin_max = 8;
		}
		
		cov_PCoffset9_c: coverpoint top.test.env.monitor.currentTrans.pcOffset9 iff(top.test.env.monitor.currentTrans.opcode == {JMP, BR}){
			 bins pcOffset9_corner_high =  {9'b111111111};  
			 bins pcOffset9_corner_low =  {9'b000000000}; 
		}
		
		xc_NZP_PSR: cross cov_N,cov_Z,cov_P,cov_PSR;
   endgroup

   
   
   covergroup OPR_SEQ_cg @(posedge monIf.clk);
	Cov_opcode_order : coverpoint top.test.env.monitor.currentTrans.opcode
	{
		bins ALU_Memory_Control = (AND, ADD, NOT => LD, LDR, LDI, LEA, ST, STR, STI => BR, JMP);
		bins Memory_Control_ALU = (LD, LDR, LDI, LEA, ST, STR, STI => BR, JMP => AND, ADD, NOT);
		bins Memory_ALU_Control = (LD, LDR, LDI, LEA, ST, STR, STI => AND, ADD, NOT  => BR, JMP );
	}  
   
   endgroup

   function new( virtual Lc3_mon_if monIf );
      this.monIf       = monIf;
      this.ALU_OPR_cg  = new;
      this.MEM_OPR_cg  = new;
      this.CTRL_OPR_cg = new;
      this.OPR_SEQ_cg  = new;
   endfunction

endclass

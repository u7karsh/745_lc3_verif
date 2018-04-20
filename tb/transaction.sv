class Instruction; //{
   rand opcode_t  opcode;
   rand reg_t     dst;
   rand reg_t     src1;
   rand reg_t     src2;

   rand bit       immValid;
   rand reg [4:0] imm;

   rand reg [8:0] pcOffset9;  
   rand reg [5:0] pcOffset6;  
   rand reg [2:0] baseR;  
   rand bit       N, Z, P;

   function new();
      this.opcode    = UNDEF;
   endfunction

   function void create(opcode_t opcode, reg_t dst, reg_t src1, reg_t src2, bit immValid, 
      reg[4:0] imm, reg[8:0] pcOffset9, reg[5:0] pcOffset6, reg[2:0] baseR, bit N, bit Z, bit P);
      this.opcode    = opcode;
      this.dst       = dst;
      this.src1      = src1;
      this.src2      = src2;
      this.immValid  = immValid;
      this.imm       = imm;
      this.pcOffset9 = pcOffset9;
      this.pcOffset6 = pcOffset6;
      this.baseR     = baseR;
      this.N         = N;
      this.Z         = Z;
      this.P         = P;
   endfunction

   function Instruction copy();
      copy           = new();
      copy.opcode    = opcode;
      copy.dst       = dst;
      copy.src1      = src1;
      copy.src2      = src2;
      copy.immValid  = immValid;
      copy.imm       = imm;
      copy.pcOffset9 = pcOffset9;
      copy.pcOffset6 = pcOffset6;
      copy.baseR     = baseR;
      copy.N         = N;
      copy.Z         = Z;
      copy.P         = P;
      return copy;
   endfunction

   static function string op2str( reg [3:0] opcode );
      case( opcode )
         ADD:   return "ADD";
         AND:   return "AND";
         NOT:   return "NOT";
         LD :   return "LD ";
         LDR:   return "LDR";
         LDI:   return "LDI";
         LEA:   return "LEA";
         ST :   return "ST ";
         STR:   return "STR";
         STI:   return "STI";
         BR :   return "BR ";
         JMP:   return "JMP";
      endcase
      return "UNDEF";
   endfunction

   function bit isCtrl();
      bit cond       = 0;
      case( opcode )
         BR : cond   = 1; 
         JMP: cond   = 1; 
      endcase
      return cond;
   endfunction

   function bit isMem();
      bit cond       = 0;
      case( opcode )
         LD : cond   = 1; 
         LDR: cond   = 1; 
         LDI: cond   = 1; 
         LEA: cond   = 1; 
         ST : cond   = 1; 
         STR: cond   = 1; 
         STI: cond   = 1; 
      endcase
      return cond;
   endfunction

   function string opcode2str();
      return op2str( opcode );
   endfunction


   function void print();
      $display("%t [INSTR] 0x%0x %s, dst: %0d, src1: %0d, src2: %0d, immValid: %0d, imm: %0x, off9: %0x, off6: %0x, baseR: %0x", 
               $time, encodeInst(), opcode2str(),dst, src1, src2, immValid, imm, pcOffset9, pcOffset6, baseR);
   endfunction

   function reg[15:0] encodeInst();
      // Default values
      reg[15:0] encInst = 16'h0;
      $cast(encInst[15:12], this.opcode);
      encInst[11:9]     = this.dst;
   
      // Encoder
      case (this.opcode)
         ADD: begin //{
                 encInst[8:6]   = this.src1;
                 encInst[5]     = this.immValid;
                 encInst[4:0]   = this.immValid ? this.imm : {2'b0, this.src2};
              end //}

         AND: begin //{
                 encInst[8:6]   = this.src1;
                 encInst[5]     = this.immValid;
                 encInst[4:0]   = this.immValid ? this.imm : {2'b0, this.src2};
              end //}

         NOT: begin //{
                 encInst[8:6]   = this.src1;
                 encInst[5:0]   = 5'b1_1111;
              end //}

         LDI: begin //{
                 encInst[8:0]   = this.pcOffset9;
             end //}

         LEA: begin //{
                 encInst[8:0]   = this.pcOffset9;
             end //}

         LD: begin //{
                 encInst[8:0]   = this.pcOffset9;
             end //}

         LDR: begin //{
                 encInst[8:0]   = {this.baseR, this.pcOffset6};
              end //}

         STI:  begin //{
                 encInst[11:9]  = this.src1;
                 encInst[8:0]   = this.pcOffset9;
              end //}

         ST:  begin //{
                 encInst[11:9]  = this.src1;
                 encInst[8:0]   = this.pcOffset9;
              end //}

         STR: begin //{
                 encInst[11:9]  = this.src1;
                 encInst[8:0]   = {this.baseR, this.pcOffset6};
              end //}

         BR:  begin //{
                 encInst[11:9]  = {N, Z, P};
                 encInst[8:0]   = this.pcOffset9;
              end //}
              
         JMP: begin //{
                 encInst[8:6]   = this.baseR;
              end //}
         //TODO: Assert on default
      endcase
   
      return encInst;
   endfunction
endclass; //}

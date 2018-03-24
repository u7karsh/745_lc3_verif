class Instruction; //{

   typedef enum {
      ADD     = 32'b0001,
      AND     = 32'b0101,
      NOT     = 32'b1001,
      BR      = 32'b0000, 
      JMP     = 32'b1100,
      LD      = 32'b0010,
      LDR     = 32'b0110,
      LDI     = 32'b1010,
      LEA     = 32'b1110,
      ST      = 32'b0011,
      STR     = 32'b0111,
      STI     = 32'b1011
   } opcode_t;
   
   typedef reg [2:0] reg_t;

   opcode_t  opcode;
   reg_t     dst;
   reg_t     src1;
   reg_t     src2;

   bit       immValid;
   reg [4:0] imm;

   reg [8:0] pcOffset9;  
   reg [5:0] pcOffset6;  
   reg [2:0] baseR;  
   bit       N, Z, P;

   function new();
   endfunction

   function string opcode2str();
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
   endfunction

   function void print();
      $display("%s, dst: %0d, src1: %0d, src2: %0d, immValid: %0d, imm: %0x, off9: %0x, off6: %0x, baseR: %0x", 
               opcode2str(),dst, src1, src2, immValid, imm, pcOffset9, pcOffset6, baseR);
   endfunction

   function reg[15:0] encodeInst();
      // Default values
      reg[15:0] encInst = 16'h0;
      encInst[15:12]    = this.opcode;
      encInst[11:9]     = this.dst;
   
      // Encoder
      case (this.opcode)
         ADD: begin //{
                 encInst[8:6]   = this.src1;
                 encInst[5]     = this.immValid;
                 encInst[4:0]   = this.immValid ? this.imm : this.src2;
              end //}

         AND: begin //{
                 encInst[8:6]   = this.src1;
                 encInst[5]     = this.immValid;
                 encInst[4:0]   = this.immValid ? this.imm : this.src2;
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

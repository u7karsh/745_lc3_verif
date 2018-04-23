// This file contains all tests needed

// Test: MaxOneBrStoreLoadTest
class MaxOneBrStoreLoadTest extends Test;

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize );
      super.new( driverIf, monIf, dataMemSize, "MaxOneBrStoreLoadTest" );
   endfunction

   // Populates env's instruct mem
   virtual function void sequenceInstr();
      integer numTrans             = 8 + 1000;
      integer count                = 8;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];
      
      for( int i = 0; i < 8; i++ ) begin
         instMemEntry.create(AND, i, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end
      
      for( int i = 0; i < numTrans - 8; i++ ) begin
         if( instMemEntry.randomize() 
            with { 
               if( count <= 0 )
                  opcode    inside {ADD, AND, NOT, LD, LDR, LDI, LEA, ST, STI, STR, BR, JMP}; 
               else
                  opcode    inside {ADD, AND, NOT};
               {N,Z,P}      inside {[3'b001:3'b111]};
            } ) begin
              count--;
              if( instMemEntry.isMem() || instMemEntry.isCtrl() ) count = 8;
              pushInst(instMemEntry);
         end 
         else begin
              $fatal(1, "Failed to randomize instMemEntry");
              eos(0);
         end
      end
   endfunction
endclass

// Test: RandomBrStoreLoadTest
// Warms up a few load store addresses
class RandomBrStoreLoadTest extends Test;

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize );
      super.new( driverIf, monIf, dataMemSize, "RandomBrStoreLoadTest" );
   endfunction

   // Populates env's instruct mem
   virtual function void sequenceInstr();
      integer numTrans             = 8 + 1000000;
      integer ctrl = 0, mem = 0;
      integer instCnt              = 0;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];

      // Warmup R0-R8
      // Memory is already pre-warmed up
      // AND R0, R0, #0
      for( int i = 0; i < 8; i++ ) begin
         instMemEntry.create(AND, i, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end

      for( int i = 0; i < numTrans - 8; i++ ) begin
         // Basic instructions
         opcode_t opList[]        = {ADD, AND, NOT};

         if( ctrl > `LC3_PIPE_DEPTH ) begin
            integer s       = opList.size();
            opList          = new[s + 2](opList);
            opList[s]       = BR;
            opList[s+1]     = JMP;
         end

         if( mem > `LC3_PIPE_DEPTH ) begin
            integer s       = opList.size();
            opList          = new[s + 7](opList);
            opList[s]       = LD;
            opList[s+1]     = LDR;
            opList[s+2]     = LDI;
            opList[s+3]     = LEA;
            opList[s+4]     = ST;
            opList[s+5]     = STI;
            opList[s+6]     = STR;
         end

         if( instMemEntry.randomize() with { 
               opcode    inside {opList};
            } ) begin
            if( instMemEntry.isCtrl() ) ctrl = 0;
            if( instMemEntry.isMem()  ) mem  = 0;
            pushInst(instMemEntry);
            ctrl  += 1;
            mem   += 1;
         end else begin
            $fatal(1, "Failed to randomize instMemEntry");
            eos(0);
         end
      end
   endfunction

endclass

// This file contains all tests needed

// Test: BasicStoreLoadTest
// Warms up a few load store addresses
class BaseStoreLoadTest extends Test;

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize );
      super.new( driverIf, monIf, dataMemSize, "BasicStoreLoadTest" );
   endfunction

   // Populates env's instruct mem
   virtual function void sequenceInstr();
      //integer numTrans             = 8 + 100 + 100; // R0-7 + warmup + test
      integer numTrans             = 100*9 + 700;
      integer ctrl = 0, mem = 0;
      integer instCnt              = 0;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];

      // Warmup 0-100 addresses
      // Between all stores, initialize all regs to 0
      // AND R0, R0, #0
      for( int i = 0; i < 100; i++ ) begin
         instMemEntry.create(STR, 0, 0, 0, 0, 0, 0, i, 0, 0, 0, 0);
         pushInst(instMemEntry);
         for( int j = 0; j < 8; j++ ) begin
            instMemEntry.create(AND, j, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
            pushInst(instMemEntry);
         end
      end

      for( int i = 0; i < numTrans - 100*9; i++ ) begin
         int position             = i + 100*9;
         // Basic instructions
         opcode_t opList[]        = {ADD, AND, NOT};
         reg [8:0] startAddr      = 0;
         reg [8:0] endAddr        = numTrans - position - 1;

         if( ctrl > `LC3_PIPE_DEPTH ) begin
            integer s       = opList.size();
            opList          = new[s + 2](opList);
            opList[s]       = BR;
            opList[s+1]     = JMP;
         end

         if( ctrl > `LC3_PIPE_DEPTH ) begin
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
               pcOffset6 inside { [startAddr:endAddr] };
               baseR      ==    0;
            } ) begin
            if( instMemEntry.isCtrl() || instMemEntry.isMem()) ctrl = 0;
            //if( instMemEntry.isMem()  ) mem  = 0;
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

// This file contains all tests needed

// Test: BasicStoreLoadTest
// Warms up a few load store addresses
class BaseStoreLoadTest extends Test;

   function new( virtual Lc3_dr_if driverIf, virtual Lc3_mon_if monIf, integer dataMemSize );
      super.new( driverIf, monIf, dataMemSize, "BasicStoreLoadTest" );
   endfunction

   // Populates env's instruct mem
   virtual function void sequenceInstr();
      integer numTrans             = 8 + 100 + 100; // R0-7 + warmup + test
      integer instCnt              = 0;
      Instruction instMemEntry     = new;
      env.instMem                  = new [numTrans];

      // Initialize all regs to 0
      // AND R0, R0, #0
      for( int i = 0; i < 8; i++ ) begin
         instMemEntry.create(Instruction::AND, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end

      // Warmup 0-100 addresses
      for( int i = 0; i < 100; i++ ) begin
         instMemEntry.create(Instruction::STR, 0, 0, 0, 0, 0, 0, i, 0, 0, 0, 0);
         pushInst(instMemEntry);
      end

      // Randomize tests.. limit pc relative addressing
      for( int i = 0; i < 100; i++ ) begin
         if( instMemEntry.randomize() with 
            { 
               opcode    inside {ADD, /*BR,*/ AND, NOT, /*LD,*/ LDR, /*LDI, LEA, ST, STI,*/ STR}; 
               pcOffset6 inside { [0:99] };
               baseR      ==    0;
            } 
         ) begin
            pushInst(instMemEntry);
         end else begin
            $fatal(1, "Failed to randomize instMemEntry");
         end
      end
   endfunction

endclass

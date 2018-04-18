// Class for common functionality between monitor and driver
class Agent;
   integer num_assert  = 0;
   integer fail_assert = 0;

   virtual function void printInstMemIndex( integer index );
      check("AGENT", FATAL, index >= 0 && index < top.test.env.instMem.size(), 
         $psprintf("Out of bounds instruct memory access %0d", index));
      top.test.env.instMem[index].print();
   endfunction

   virtual function Instruction getInstIndex( integer index );
      check("AGENT", FATAL, index >= 0 && index < top.test.env.instMem.size(), 
         $psprintf("Out of bounds instruct memory access %0d", index));
      return top.test.env.instMem[index];
   endfunction

   virtual function integer getInstMemSize();
      return top.test.env.instMem.size();
   endfunction

   // Read data memory
   virtual function data_t readDataMem( integer address );
      check("AGENT", FATAL, address < top.test.env.dataMem.size(), $psprintf("Out of bounds memory access %0x", address));
      return top.test.env.dataMem[ address ];
   endfunction

   // write data memory
   virtual function void writeDataMem( integer address, data_t value );
      check("AGENT", FATAL, address < top.test.env.dataMem.size(), $psprintf("Out of bounds memory access %0x", address));
      top.test.env.dataMem[ address ] = value;
   endfunction

   // assert 
   virtual function void check(string stage, severityT severity, reg cond, string A);
      num_assert        += 1;
      if(!cond) begin
         fail_assert    += 1;
         if( severity == FATAL ) begin
            $fatal(1, "%t [CHECKER.%s] %s", $time, stage, A);
            void'(top.test.eos());
         end
         else
            $warning("%t [CHECKER.%s] %s", $time, stage, A);
      end
   endfunction

   function new();
   endfunction

endclass

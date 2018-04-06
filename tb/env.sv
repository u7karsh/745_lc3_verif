// Environment class
// Contains agents, data memory, instruction memory
class Env;
   // Memories
   Instruction instMem[];
   data_t      dataMem[];

   // Agents
   Driver      driver;
   Monitor     monitor;

   function new(virtual Lc3_dr_if  driverIf, virtual Lc3_mon_if monIf);
      driver   = new( driverIf );
      monitor  = new( monIf );
   endfunction

   task run();
      fork
         driver.run();
         monitor.run();
      join_any
   endtask
endclass
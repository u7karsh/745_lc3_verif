typedef enum {
   ADD     = 4'b0001,
   AND     = 4'b0101,
   NOT     = 4'b1001,
   //BR,
   //JMP,
   LD      = 4'b0010,
   LDR     = 4'b0110,
   LDI     = 4'b1010,
   LEA     = 4'b1110,
   ST      = 4'b0011,
   STR     = 4'b0111,
   STI     = 4'b1011
} opcode_t;

typedef reg [2:0] reg_t;

typedef struct{
   opcode_t  opcode;
   reg_t     dst;
   boolean   dstValid;
   reg_t     src1;
   boolean   src1Valid;
   reg_t     src2;
   boolean   src2Valid;
   boolean   immValid;
   reg [4:0] imm;
} Instruction;

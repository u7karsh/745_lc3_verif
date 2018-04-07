// Data memory
typedef reg[15:0] data_t;
typedef reg [2:0] reg_t;

typedef enum {
   WARN,
   FATAL
} severityT;

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
   STI     = 32'b1011,
   UNDEF   = 32'b1111
} opcode_t;

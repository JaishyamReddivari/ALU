`timescale 1us/1ns
module ALU_tb();
   parameter B_W = 8;
   reg [3:0] opcode;
   reg [B_W-1:0] a, b;
   reg c_in;
   wire [B_W-1:0] y;
   wire c_out, borrow, invalid_op;
   wire zero, parity;

   localparam OP_ADD = 1;
   localparam OP_ADD_CARRY = 2;
   localparam OP_SUB = 3;
   localparam OP_INC = 4;
   localparam OP_DEC = 5;
   localparam OP_AND = 6;
   localparam OP_NOT = 7;   
   localparam OP_ROL = 8;
   localparam OP_ROR = 9;
   integer success_count = 0, error_count = 0, test_count = 0, i = 0;

ALU
   #(.B_W(B_W))
ALU(
   .a(a), .b(b), .c_in(c_in), .opcode(opcode),
   .y(y), .c_out(c_out), .borrow(borrow), 
   .invalid_op(invalid_op), .parity(parity),
   .zero(zero)
);

   function [B_W+4:0] model_ALU(input [3:0] opcode, input [B_W-1:0] a, input [B_W-1:0] b, input c_in);
      reg [B_W-1:0] y;
      reg c_out;
      reg borrow, zero, parity, invalid_op;

      begin
         y = 0; c_out = 0; borrow = 0; invalid_op = 0;
         case(opcode)
            OP_ADD : begin {c_out, y} = a + b; end
            OP_ADD_CARRY : begin {c_out, y} = a + b + c_in; end
            OP_SUB : begin {borrow, y} = a - b; end
            OP_INC : begin {c_out, y} = a + 1'b1; end
            OP_DEC : begin {borrow, y} = a - 1'b1; end
            OP_AND : begin y = a & b; end
            OP_NOT : begin y = ~a ; end
            OP_ROL : begin y = {a[B_W-2:0], a[B_W-1]}; end
            OP_ROR : begin y = {a[0], a[B_W-1:1]}; end
            default : begin invalid_op = 1; y = 0; c_out = 0; borrow = 0; end
          endcase
          
          parity = ^y;
          zero = (y == 0);
          model_ALU = {invalid_op, parity, zero, borrow, c_out, y};
       end
   endfunction

   task compare_data(input [B_W+4:0] expected_ALU, input [B_W+4:0] observed_ALU);
      begin
         if(expected_ALU === observed_ALU) begin
            $display($time, " SUCCESS \t EXPECTED invalid_op=%0d, parity=%b, zero=%b, c_out=%b, y=%b", expected_ALU[B_W+4], expected_ALU[B_W+3], expected_ALU[B_W+2], expected_ALU[B_W+1], expected_ALU[B_W], expected_ALU[B_W-1:0]);          
            $display($time, "         \t OBSERVED invalid_op=%0d, parity=%b, zero=%b, c_out=%b, y=%b", observed_ALU[B_W+4], observed_ALU[B_W+3], observed_ALU[B_W+2], observed_ALU[B_W+1], observed_ALU[B_W], observed_ALU[B_W-1:0]);
            success_count = success_count + 1;

         end else begin
             $display($time, " ERROR \t EXPECTED invalid_op=%0d, parity=%b, zero=%b, c_out=%b, y=%b", expected_ALU[B_W+4], expected_ALU[B_W+3], expected_ALU[B_W+2], expected_ALU[B_W+1], expected_ALU[B_W], expected_ALU[B_W-1:0]);          
            $display($time, "         \t OBSERVED invalid_op=%0d, parity=%b, zero=%b, c_out=%b, y=%b", observed_ALU[B_W+4], observed_ALU[B_W+3], observed_ALU[B_W+2], observed_ALU[B_W+1], observed_ALU[B_W], observed_ALU[B_W-1:0]);
            error_count = error_count + 1;
         end
         test_count = test_count + 1;
      end
   endtask

   initial begin
      for (i=0; i<100; i=i+1) begin
         opcode = $random % 10'd11;
         a = $random;
         b = $random;
         c_in = $random;

         #1;
         $display($time, " TEST%0d opcode = %0d, a = %0d, b = %0d, c_in = %0b", i, opcode, a, b, c_in);
         compare_data(model_ALU(opcode, a, b, c_in), {invalid_op, parity, zero,borrow, c_out, y});

         #2;
      end
      
      $display($time, " TEST RESULTS success_count = %0d, error_count = %0d, test_count = %0d", success_count, error_count, test_count);
      #40 $stop;
   end
endmodule 
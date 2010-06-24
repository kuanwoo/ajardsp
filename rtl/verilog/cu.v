// This file is part of AjarDSP
//
// Copyright (c) 2010, Markus Lavin
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the <ORGANIZATION> nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module cu(clk,
	  rst,

	  inst,

          satctrl_i,
          mulsign_i,

	  op_0_idx_o,
	  op_0_data_i,

	  op_1_idx_o,
	  op_1_data_i,

	  op_2_idx_o,
	  op_2_data_i,

	  res_idx_o,
	  res_wen_o,
          res_mask_o,
	  res_data_o,

          pred_tst_idx_o,
          pred_tst_bit_i,

          pred_set_idx_o,
          pred_set_wen_o,
          pred_set_bit_o
	  );

`include "insns.v"

   input clk;
   input rst;
   input [31:0] inst;

   input [7:0]  satctrl_i;
   input [7:0]  mulsign_i;

   output [2:0]	  op_0_idx_o;
   reg    [2:0]   op_0_idx_o;
   input [31:0]   op_0_data_i;

   output [2:0]   op_1_idx_o;
   reg    [2:0]   op_1_idx_o;
   input [31:0]   op_1_data_i;

   output [2:0]   op_2_idx_o;
   reg    [2:0]   op_2_idx_o;
   input [31:0]   op_2_data_i;

   output [2:0]   res_idx_o;
   output 	  res_wen_o;
   output [1:0]	  res_mask_o;
   output [31:0]  res_data_o;

   output [1:0]   pred_tst_idx_o;
   input          pred_tst_bit_i;

   output [1:0]   pred_set_idx_o;
   reg    [1:0]   pred_set_idx_o;
   output         pred_set_wen_o;
   reg            pred_set_wen_o;
   output         pred_set_bit_o;
   reg            pred_set_bit_o;

   reg [31:0] inst_pipe_0_r;
   reg [31:0] inst_pipe_1_r;
   reg [31:0] inst_pipe_2_r;
   reg [31:0] inst_pipe_3_r;
   reg [31:0] inst_pipe_4_r;

   reg [31:0] op_0_r;
   reg [31:0] op_1_r;
   reg [31:0] op_2_r;

   reg [15:0] op_0_16_r;
   reg [15:0] op_1_16_r;

   reg        op_0_16_pos;
   reg        op_1_16_pos;

   reg [31:0] res;
   reg [31:0] res_r;

   reg [31:0]  addsub_op_0_w;
   reg [31:0]  addsub_op_1_w;
   reg         addsub_sub_en_w;
   reg         addsub_sat_en_w;
   wire [31:0] addsub_res_w;

   reg [15:0]  mul_op_0_w;
   reg [15:0]  mul_op_1_w;
   reg         mul_op_0_signed_w;
   reg         mul_op_1_signed_w;
   wire [31:0] mul_res_w;

   reg [15:0]  fp_mul_op_0_w;
   reg [15:0]  fp_mul_op_1_w;
   wire [15:0] fp_mul_res_w;
   reg         fp_mul_begin_w;

   reg [2:0]   res_early_idx_w;
   reg         res_early_wen_w;
   reg [1:0]   res_early_mask_w;
   reg [15:0]  res_early_data_w;

   reg [2:0]   res_late_idx_w;
   reg         res_late_wen_w;
   reg [1:0]   res_late_mask_w;
   reg [15:0]  res_late_data_w;


   int_addsub addsub(.op_a_i(addsub_op_0_w),
                     .op_b_i(addsub_op_1_w),
                     .res_o(addsub_res_w),
                     .sat_en_i(addsub_sat_en_w),
                     .sub_en_i(addsub_sub_en_w)
                     );

   int_mul mul(.op_a_i(mul_op_0_w),
               .op_b_i(mul_op_1_w),
               .op_a_signed_i(mul_op_0_signed_w),
               .op_b_signed_i(mul_op_1_signed_w),
               .res_o(mul_res_w)
               );

   fp_mul fp_mul_0(.clk(clk),
                   .rst(fp_mul_begin_w),
                   .op_a_i(fp_mul_op_0_w),
                   .op_b_i(fp_mul_op_1_w),
                   .res_o(fp_mul_res_w)
                   );


   assign res_idx_o  = res_late_wen_w ? res_late_idx_w  : res_early_idx_w;
   assign res_wen_o  = res_late_wen_w ? res_late_wen_w  : res_early_wen_w;
   assign res_mask_o = res_late_wen_w ? res_late_mask_w : res_early_mask_w;
   assign res_data_o = res_late_wen_w ? res_late_data_w : res_early_data_w;

   assign pred_tst_idx_o = inst_pipe_2_r[31:30];

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     inst_pipe_0_r <= 32'h0;
	     inst_pipe_1_r <= 32'h0;
	     inst_pipe_2_r <= 32'h0;
             inst_pipe_3_r <= 32'h0;
             inst_pipe_4_r <= 32'h0;
	  end
	else
	  begin
	     inst_pipe_0_r <= inst;
	     inst_pipe_1_r <= inst_pipe_0_r;
	     inst_pipe_2_r <= inst_pipe_1_r;
             inst_pipe_3_r <= inst_pipe_2_r;
             inst_pipe_4_r <= inst_pipe_3_r;
	  end
     end // always @ (posedge clk)

   always @(posedge clk)
     begin
	if (rst)
	  begin
	     res_r <= 0;
	     op_0_r <= 0;
	     op_1_r <= 0;
             op_2_r <= 0;
	  end
	else
	  begin
	     res_r <= res;

	     op_0_r <= op_0_data_i;
             op_1_r <= op_1_data_i;

             /* MAC16 specific CU local bypass logic */
             if (op_2_idx_o == res_idx_o)
               begin
                  op_2_r <= res_r;
               end
             else
               begin
                  op_2_r <= op_2_data_i;
               end

             if (op_0_16_pos)
               op_0_16_r <= op_0_data_i[31:16];
             else
               op_0_16_r <= op_0_data_i[15:0];

             if (op_1_16_pos)
	       op_1_16_r <= op_1_data_i[31:16];
             else
               op_1_16_r <= op_1_data_i[15:0];

	  end
     end // always @ (posedge clk)

   // Instruction decode pipeline stage #0
   always @(inst_pipe_0_r)
     begin

	op_0_idx_o = 0;
	op_1_idx_o = 0;
        op_2_idx_o = 0;

        op_0_16_pos = 0;
        op_1_16_pos = 0;

        fp_mul_begin_w = 0;

        if (inst_pipe_0_r[INSN_SIZE_BIT] & inst_pipe_0_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             case (inst_pipe_0_r[8:4])
               CU_ITYPE_CMP_16: begin
                  op_0_idx_o = inst_pipe_0_r[12:10];
                  op_0_16_pos = inst_pipe_0_r[9];
 	          op_1_idx_o = inst_pipe_0_r[16:14];
                  op_1_16_pos = inst_pipe_0_r[13];
               end

               CU_ITYPE_FP_MUL: begin
                  op_0_idx_o = inst_pipe_0_r[12:10];
                  op_0_16_pos = inst_pipe_0_r[9];
 	          op_1_idx_o = inst_pipe_0_r[16:14];
                  op_1_16_pos = inst_pipe_0_r[13];
                  fp_mul_begin_w = 1;
               end
             endcase // case (inst_pipe_0_r[7:4])

          end
        else  /* 16 bit instruction encoding */
          begin

	     case (inst_pipe_0_r[6:4])

	       CU_ITYPE_ADD_32: begin
	          op_0_idx_o = inst_pipe_0_r[9:7];
	          op_1_idx_o = inst_pipe_0_r[12:10];
	       end

	       CU_ITYPE_SUB_32: begin
	          op_0_idx_o = inst_pipe_0_r[9:7];
	          op_1_idx_o = inst_pipe_0_r[12:10];
	       end

	       CU_ITYPE_ADD_16: begin
	          op_0_idx_o  = inst_pipe_0_r[10:8];
                  op_0_16_pos = inst_pipe_0_r[7];
	          op_1_idx_o  = inst_pipe_0_r[14:12];
                  op_1_16_pos = inst_pipe_0_r[11];
	       end

	       CU_ITYPE_SUB_16: begin
	          op_0_idx_o  = inst_pipe_0_r[10:8];
                  op_0_16_pos = inst_pipe_0_r[7];
	          op_1_idx_o  = inst_pipe_0_r[14:12];
                  op_1_16_pos = inst_pipe_0_r[11];
	       end

	       CU_ITYPE_MPY_16: begin
	          op_0_idx_o  = {1'b0, inst_pipe_0_r[9:8]};
                  op_0_16_pos = inst_pipe_0_r[7];
	          op_1_idx_o  = {1'b0, inst_pipe_0_r[12:11]};
                  op_1_16_pos = inst_pipe_0_r[10];
	       end

	       CU_ITYPE_MAC_16: begin
	          op_0_idx_o  = {1'b0, inst_pipe_0_r[9:8]};
                  op_0_16_pos = inst_pipe_0_r[7];
	          op_1_idx_o  = {1'b0, inst_pipe_0_r[12:11]};
                  op_1_16_pos = inst_pipe_0_r[10];
                  op_2_idx_o  = inst_pipe_0_r[15:13];
	       end

	       default: begin

	       end

	     endcase // case ({inst_pipe_0_r[1], inst_pipe_0_r[7:4]})
          end // else: !if(inst_pipe_0_r[INSN_SIZE_BIT] & inst_pipe_0_r[INSN_ENC_BIT])

     end

   // Instruction execute pipeline stage #1
   always @(inst_pipe_1_r or op_0_r or op_1_r or op_2_r or op_0_16_r or op_1_16_r or
            addsub_res_w or mul_res_w)
     begin

	res = 0;

        addsub_op_0_w = 0;
        addsub_op_1_w = 0;
        addsub_sub_en_w = 0;
        addsub_sat_en_w = 0;

        mul_op_0_w = 0;
        mul_op_1_w = 0;
        mul_op_0_signed_w = 0;
        mul_op_1_signed_w = 0;
        fp_mul_op_0_w = 0;
        fp_mul_op_1_w = 0;


        if (inst_pipe_1_r[INSN_SIZE_BIT] & inst_pipe_1_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             case (inst_pipe_1_r[8:4])
               CU_ITYPE_CMP_16: begin
 	          res = {16'h0, op_0_16_r - op_1_16_r};
 	       end

               CU_ITYPE_FP_MUL: begin
                  fp_mul_op_0_w = op_0_16_r;
                  fp_mul_op_1_w = op_1_16_r;
               end
             endcase
          end
        else  /* 16 bit instruction encoding */
          begin
	     case (inst_pipe_1_r[6:4])

	       CU_ITYPE_ADD_32: begin
/*	          res = op_0_r + op_1_r; */
                  addsub_sat_en_w = satctrl_i[inst_pipe_1_r[15:13]];
                  addsub_op_0_w = op_0_r;
                  addsub_op_1_w = op_1_r;
                  res = addsub_res_w;
	       end

	       CU_ITYPE_SUB_32: begin
/*	          res = op_0_r - op_1_r; */
                  addsub_sat_en_w = satctrl_i[inst_pipe_1_r[15:13]];
                  addsub_op_0_w = op_0_r;
                  addsub_op_1_w = op_1_r;
                  addsub_sub_en_w = 1;
                  res = addsub_res_w;
	       end

	       CU_ITYPE_ADD_16: begin
                  if (inst_pipe_1_r[7])
                    begin
/*	               res[31:16] = op_0_16_r + op_1_16_r; */
                       addsub_op_0_w = {16'h0, op_0_16_r};
                       addsub_op_1_w = {16'h0, op_1_16_r};
                       res[31:16] = addsub_res_w[15:0];
                    end
                  else
                    begin
/*                     res[15:0] = op_0_16_r + op_1_16_r; */
                       addsub_op_0_w = {16'h0, op_0_16_r};
                       addsub_op_1_w = {16'h0, op_1_16_r};
                       res[15:0] = addsub_res_w[15:0];
                    end
	       end

	       CU_ITYPE_SUB_16: begin
                  if (inst_pipe_1_r[7])
                    begin
/*                     res[31:16] = op_0_16_r - op_1_16_r; */
                       addsub_op_0_w = {16'h0, op_0_16_r};
                       addsub_op_1_w = {16'h0, op_1_16_r};
                       addsub_sub_en_w = 1;
                       res[31:16] = addsub_res_w[15:0];
                    end
                  else
                    begin
/*                     res[15:0] = op_0_16_r - op_1_16_r; */
                       addsub_op_0_w = {16'h0, op_0_16_r};
                       addsub_op_1_w = {16'h0, op_1_16_r};
                       addsub_sub_en_w = 1;
                       res[15:0] = addsub_res_w[15:0];
                    end
	       end

	       CU_ITYPE_MPY_16: begin
/*	          res = op_0_16_r * op_1_16_r; */
                  mul_op_0_w = op_0_16_r;
                  mul_op_1_w = op_1_16_r;
                  mul_op_0_signed_w = mulsign_i[inst_pipe_1_r[9:7]];
                  mul_op_1_signed_w = mulsign_i[inst_pipe_1_r[12:10]];
                  res = mul_res_w;
	       end

               CU_ITYPE_MAC_16: begin
/*	          res = op_2_r + (op_0_16_r * op_1_16_r); */
                  mul_op_0_w = op_0_16_r;
                  mul_op_1_w = op_1_16_r;
                  mul_op_0_signed_w = mulsign_i[inst_pipe_1_r[9:7]];
                  mul_op_1_signed_w = mulsign_i[inst_pipe_1_r[12:10]];
                  addsub_sat_en_w = satctrl_i[inst_pipe_1_r[15:13]];
                  addsub_op_0_w = op_2_r;
                  addsub_op_1_w = mul_res_w;
                  res = addsub_res_w;
	       end


	     endcase // case ({inst_pipe_0_r[1], inst_pipe_0_r[7:4]})
          end

     end // always @ (inst_pipe_0_r)

   // Instruction writeback (early) pipeline stage #2
   always @(inst_pipe_2_r or res_r or pred_tst_bit_i)
     begin
	res_early_idx_w  = 0;
	res_early_wen_w  = (inst_pipe_2_r[1] == 0 || pred_tst_bit_i) && inst_pipe_2_r[15:0] != 0;
        res_early_mask_w = 2'b11;
	res_early_data_w = res_r;

        pred_set_idx_o = 0;
        pred_set_wen_o = 0;
        pred_set_bit_o = 0;

        if (inst_pipe_2_r[INSN_SIZE_BIT] & inst_pipe_2_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             case (inst_pipe_2_r[8:4])
 	       CU_ITYPE_CMP_16: begin
                  pred_set_idx_o = inst_pipe_2_r[25:24];
                  pred_set_wen_o = 1;
                  res_early_wen_w  = 0;

 	          case (inst_pipe_2_r[28:26])
 	            cmp_eq: begin
 		       pred_set_bit_o = (res_r == 0);
 	            end
 	            cmp_ne: begin
 		       pred_set_bit_o = (res_r != 0);
 	            end
 	            cmp_lt: begin
 		       pred_set_bit_o = res_r[15];
 	            end
 	            cmp_le: begin
 		       pred_set_bit_o = (res_r == 0) || res_r[15];
 	            end
 	            cmp_gt: begin
 		       pred_set_bit_o = ~res_r[15];
 	            end
 	            cmp_ge: begin
 		       pred_set_bit_o = (res_r == 0) || ~res_r[15];
 	            end
 	          endcase
               end
             endcase
          end
        else
          begin  /* 16 bit instruction encoding */

	     case (inst_pipe_2_r[6:4])

	       CU_ITYPE_ADD_32: begin
	          res_early_idx_w = inst_pipe_2_r[15:13];
	       end

	       CU_ITYPE_SUB_32: begin
	          res_early_idx_w = inst_pipe_2_r[15:13];
	       end

	       CU_ITYPE_ADD_16: begin
	          res_early_idx_w = inst_pipe_2_r[10:8];
                  if (inst_pipe_2_r[7])
                    res_early_mask_w = 2'b10;
                  else
                    res_early_mask_w = 2'b01;
	       end

	       CU_ITYPE_SUB_16: begin
	          res_early_idx_w = inst_pipe_2_r[10:8];
                  if (inst_pipe_2_r[7])
                    res_early_mask_w = 2'b10;
                  else
                    res_early_mask_w = 2'b01;
	       end

	       CU_ITYPE_MPY_16: begin
	          res_early_idx_w = inst_pipe_2_r[15:13];
	       end

               CU_ITYPE_MAC_16: begin
	          res_early_idx_w = inst_pipe_2_r[15:13];
	       end

	     endcase

          end
     end


   // Instruction writeback (late) pipeline stage #4
   always @(inst_pipe_4_r or fp_mul_res_w)
     begin
	res_late_idx_w  = 0;
	res_late_wen_w  = 0;  /* cannot be predicatable yet... */
        res_late_mask_w = 2'b11;
	res_late_data_w = 0;

        if (inst_pipe_4_r[INSN_SIZE_BIT] & inst_pipe_4_r[INSN_ENC_BIT])
          begin  /* 32 bit instruction encoding */
             case (inst_pipe_4_r[8:4])
 	       CU_ITYPE_FP_MUL: begin
                  res_late_wen_w  = 1;
                  res_late_data_w = fp_mul_res_w;
                  res_late_idx_w = inst_pipe_4_r[20:18];
                  if (inst_pipe_4_r[17])
                    res_late_mask_w = 2'b10;
                  else
                    res_late_mask_w = 2'b01;
               end
             endcase
          end
     end


endmodule // cu

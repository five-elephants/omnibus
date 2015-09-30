// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


import Bus::*;

/** Bus arbitration between in_0 and in_1 competing for output out.
*
* in_0 always wins over in_1, when both request simultaneously. The module
* stays locked until the response from the slave was returned. It expects
* a slave response with DVA also for writes.
* The RESET_BY_0 parameter indicates, that only in_0 can affect the reset on
* out. If this option is not set out is reset when either of them is in reset. */
module Bus_if_arb
  #(parameter bit RESET_BY_0 = 1'b0,
    parameter bit RESET_BY_1 = 1'b0,
    parameter int NUM_IN_FLIGHT = 4)
  ( Bus_if.slave in_0,
    Bus_if.slave in_1,
    Bus_if.master out );

  
  //---------------------------------------------------------------------------
  // Local types and signals
  //---------------------------------------------------------------------------
 
  typedef enum logic[2:0] {
    S_UNDEF  = 3'bxxx,
    S_IDLE   = 3'b001,
    S_LOCK_0 = 3'b010,
    S_LOCK_1 = 3'b100
  } Req_state;

  logic resetb;
  logic empty;
  logic full;
  logic push;
  logic pop;
  logic resp_sel_in;
  logic resp_sel_out;
  wire almost_empty;
  wire half_full;
  wire almost_full;
  wire error;


  Req_state req_state;

  //---------------------------------------------------------------------------
  // Request side
  //---------------------------------------------------------------------------

  generate
  if( RESET_BY_0 && !RESET_BY_1 ) begin : gen_reset_by_0

    assign resetb = in_0.MReset_n;

  end else if( !RESET_BY_0 && RESET_BY_1 ) begin : gen_reset_by_1

    assign resetb = in_1.MReset_n;

  end else begin : gen_reset_combined

    assign resetb = in_0.MReset_n & in_1.MReset_n;

  end
  endgenerate
  
  assign out.MReset_n = resetb;


  always_comb begin
    // default assignments
    out.MCmd = Bus::IDLE;
    out.MAddr = '0;
    out.MData = '0;
    out.MByteEn = '0;

    resp_sel_in = 1'b0;
    if( !full ) begin
      if( req_state == S_LOCK_0 ) begin
          resp_sel_in = 1'b0;
          out.MCmd = in_0.MCmd;
          out.MAddr = in_0.MAddr;
          out.MData = in_0.MData;
          out.MByteEn = in_0.MByteEn;
      end else if( req_state == S_LOCK_1 ) begin
          resp_sel_in = 1'b1;
          out.MCmd = in_1.MCmd;
          out.MAddr = in_1.MAddr;
          out.MData = in_1.MData;
          out.MByteEn = in_1.MByteEn;
      end else begin
        if( in_0.MCmd != Bus::IDLE ) begin
          resp_sel_in = 1'b0;

          out.MCmd = in_0.MCmd;
          out.MAddr = in_0.MAddr;
          out.MData = in_0.MData;
          out.MByteEn = in_0.MByteEn;
        end else if( in_1.MCmd != Bus::IDLE ) begin
          resp_sel_in = 1'b1;

          out.MCmd = in_1.MCmd;
          out.MAddr = in_1.MAddr;
          out.MData = in_1.MData;
          out.MByteEn = in_1.MByteEn;
        end
      end
    end
  end

  assign push = !full && ((in_0.MCmd != Bus::IDLE) || (in_1.MCmd != Bus::IDLE)) && out.SCmdAccept;

  always_comb begin
    // default assignment
    in_0.SCmdAccept = 1'b0;
    in_1.SCmdAccept = 1'b0;

    if( push) begin
      if( req_state == S_LOCK_0 ) begin
        in_0.SCmdAccept = 1'b1;
      end else if( req_state == S_LOCK_1 ) begin
        in_1.SCmdAccept = 1'b1;
      end else if( in_0.MCmd != Bus::IDLE ) begin
        in_0.SCmdAccept = 1'b1;
      end else begin
        in_1.SCmdAccept = 1'b1;
      end
    end
  end

  always_ff @(posedge in_0.Clk or negedge resetb)
    if( !resetb )
      req_state <= S_IDLE;
    else
      unique case(req_state)
        S_IDLE: begin
          if( (in_0.MCmd != Bus::IDLE) && !push )
            req_state <= S_LOCK_0;
          else if( (in_1.MCmd != Bus::IDLE) && !push )
            req_state <= S_LOCK_1;
        end

        S_LOCK_0: begin
          if( push )
            req_state <= S_IDLE;
        end

        S_LOCK_1: begin
          if( push )
            req_state <= S_IDLE;
        end

        default: begin
          req_state <= S_UNDEF;
        end
      endcase

  DW_fifo_s1_sf #(
    .width(1),
    .depth(NUM_IN_FLIGHT),
    .ae_level(1),
    .af_level(NUM_IN_FLIGHT-1),
    .err_mode(0),
    .rst_mode(2)   // async reset without FIFO memory
  ) resp_queue (
    .clk(in_0.Clk),
    .rst_n(resetb),
    .push_req_n(~push),
    .pop_req_n(~pop),
    .diag_n(1'b1),
    .data_in(resp_sel_in),
    .empty(empty),
    .almost_empty(almost_empty),
    .half_full(half_full),
    .almost_full(almost_full),
    .full(full),
    .error(error),
    .data_out(resp_sel_out)
  );

  //---------------------------------------------------------------------------
  // Response side
  //---------------------------------------------------------------------------

  always_comb begin
    // default assignments
    in_0.SResp = Bus::NULL;
    in_1.SResp = Bus::NULL;
    in_0.SData = '0;
    in_1.SData = '0;

    if( !empty ) begin
      if( resp_sel_out == 1'b0 ) begin
        in_0.SResp = out.SResp;
        in_0.SData = out.SData;
      end else if( resp_sel_out == 1'b1 ) begin
        in_1.SResp = out.SResp;
        in_1.SData = out.SData;
      end
    end
  end

  always_comb begin
    out.MRespAccept = 1'b0;

    if( !empty ) begin
      if( resp_sel_out == 1'b0 ) begin
        if( in_0.MRespAccept )
          out.MRespAccept = 1'b1;
      end else if( resp_sel_out == 1'b1 ) begin
        if( in_1.MRespAccept )
          out.MRespAccept = 1'b1;
      end
    end
  end

  always_comb begin
    // default assignment
    pop = 1'b0;

    if( !empty ) begin
      if( (resp_sel_out == 1'b0) && in_0.MRespAccept && (out.SResp != Bus::NULL) )
        pop = 1'b1;
      else if( (resp_sel_out == 1'b1) && in_1.MRespAccept && (out.SResp != Bus::NULL) )
        pop = 1'b1;
    end
  end


`ifndef SYNTHESIS

  initial begin
    check_reset_params: assert(!(RESET_BY_0 && RESET_BY_1));
    warn_convergent_reset: assert( RESET_BY_0 ^ RESET_BY_1 ) else
      $warning("Your arbiter configuration generates the downstream reset as logical combination of upstream resets.");
  end

`endif  /* SYNTHESIS */

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:

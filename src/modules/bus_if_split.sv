import Bus::*;

//module Bus_if_split
  //#(parameter int SELECT_BIT = 31)
  //( Bus_if.slave top,
    //Bus_if.master out_0,
    //Bus_if.master out_1 );

  //logic next_lock, lock;
  //logic next_sel_d, sel_d;

  //assign 
    //out_0.MReset_n = top.MReset_n,
    //out_1.MReset_n = top.MReset_n;

  //// Forward request from master to slave
  //always_comb begin
    //// default assignments
    //out_0.MAddr = top.MAddr;
    //out_0.MCmd = Bus::IDLE;
    //out_0.MData = top.MData;
    //out_0.MDataValid = top.MDataValid;
    //out_0.MRespAccept = top.MRespAccept;
    //out_0.MByteEn = top.MByteEn;
    //out_1.MAddr = top.MAddr;
    //out_1.MCmd = Bus::IDLE;
    //out_1.MData = top.MData;
    //out_1.MDataValid = top.MDataValid;
    //out_1.MRespAccept = top.MRespAccept;
    //out_1.MByteEn = top.MByteEn;

    //if( top.MAddr[SELECT_BIT] == 1'b1 ) begin
      //out_1.MCmd = top.MCmd;
    //end else begin
      //out_0.MCmd = top.MCmd;
    //end
  //end

  //// short circuit slave accept signals
  //always_comb begin
    //// default assignments
    //top.SCmdAccept = 1'b0;
    //top.SDataAccept = 1'b0;

    //if( (top.MCmd != Bus::IDLE) && (!lock || (lock && !next_lock)) ) begin
      //if( top.MAddr[SELECT_BIT] == 1'b1 ) begin
        //top.SCmdAccept = out_1.SCmdAccept;
        //top.SDataAccept = out_1.SDataAccept;
        //top.SResp = out_1.SResp;
        //top.SData = out_1.SData;
      //end else begin
        //top.SCmdAccept = out_0.SCmdAccept;
        //top.SDataAccept = out_0.SDataAccept;
        //top.SResp = out_0.SResp;
        //top.SData = out_0.SData;
      //end 
    //end else begin
      //if( sel_d == 1'b1 ) begin
        //top.SCmdAccept = out_1.SCmdAccept;
        //top.SDataAccept = out_1.SDataAccept;
        //top.SResp = out_1.SResp;
        //top.SData = out_1.SData;
      //end else begin
        //top.SCmdAccept = out_0.SCmdAccept;
        //top.SDataAccept = out_0.SDataAccept;
        //top.SResp = out_0.SResp;
        //top.SData = out_0.SData;
      //end
    //end
  //end

  //// Register leaf with outstanding response
  //always_comb begin
    //// default assignments
    //next_sel_d = sel_d;
    //next_lock = lock;
    
    //if( !lock ) begin
      //if( top.MCmd != Bus::IDLE ) begin
        //next_sel_d = top.MAddr[SELECT_BIT];
        
        //if( top.MRespAccept && 
          //( (next_sel_d && (out_1.SResp == Bus::DVA))
            //|| (!next_sel_d && (out_0.SResp == Bus::DVA)) ) )
        //begin
          //next_lock = 1'b0;
        //end else begin
          //next_lock = 1'b1;
        //end
      //end
    //end else begin
      //if( top.MRespAccept && 
        //( (sel_d && (out_1.SResp == Bus::DVA))
          //|| (!sel_d && (out_0.SResp == Bus::DVA)) ) )
      //begin
        //next_lock = 1'b0;
      //end
    //end
  //end

  //always_ff @(posedge top.Clk or negedge top.MReset_n)
    //if( !top.MReset_n ) begin
      //sel_d <= 1'b0;
      //lock <= 1'b0;
    //end else begin
      //sel_d <= next_sel_d;
      //lock <= next_lock;
    //end

//endmodule


module Bus_if_split
  #(parameter int SELECT_BIT = 31,
    parameter int NUM_IN_FLIGHT = 4)
  ( Bus_if.slave top,
    Bus_if.master out_0,
    Bus_if.master out_1 );

  logic push;
  logic pop;
  logic full;
  logic empty;
  logic resp_sel_in;
  logic resp_sel_out;

  assign 
    out_0.MReset_n = top.MReset_n,
    out_1.MReset_n = top.MReset_n;

  // Forward request from master to slave
  always_comb begin
    // default assignments
    out_0.MAddr = top.MAddr;
    out_0.MCmd = Bus::IDLE;
    out_0.MData = top.MData;
    out_0.MDataValid = top.MDataValid;
    out_0.MByteEn = top.MByteEn;
    out_1.MAddr = top.MAddr;
    out_1.MCmd = Bus::IDLE;
    out_1.MData = top.MData;
    out_1.MDataValid = top.MDataValid;
    out_1.MByteEn = top.MByteEn;

    if( !full ) begin
      if( top.MAddr[SELECT_BIT] == 1'b1 ) begin
        out_1.MCmd = top.MCmd;
      end else begin
        out_0.MCmd = top.MCmd;
      end
    end
  end


  // forward request accept from slave to master
  always_comb begin
    // default assignment
    top.SCmdAccept = 1'b0;
    top.SDataAccept = 1'b0;

    if( !full && (top.MCmd != Bus::IDLE) ) begin
      if( top.MAddr[SELECT_BIT] == 1'b1 ) begin
        top.SCmdAccept = out_1.SCmdAccept;
        top.SDataAccept = out_1.SDataAccept;
      end else begin
        top.SCmdAccept = out_0.SCmdAccept;
        top.SDataAccept = out_0.SDataAccept;
      end
    end
  end

  assign resp_sel_in = top.MAddr[SELECT_BIT];
  //assign push = !full && (top.MCmd != Bus::IDLE) && (out_0.SCmdAccept || out_1.SCmdAccept);
  assign push = !full && (top.MCmd != Bus::IDLE) && (top.MAddr[SELECT_BIT] ? out_1.SCmdAccept : out_0.SCmdAccept);

  DW_fifo_s1_sf #(
    .width(1),
    .depth(NUM_IN_FLIGHT),
    .ae_level(1),
    .af_level(1),
    .err_mode(0),
    .rst_mode(2)   // async reset without FIFO memory
  ) resp_queue (
    .clk(top.Clk),
    .rst_n(top.MReset_n),
    .push_req_n(~push),
    .pop_req_n(~pop),
    .diag_n(1'b1),
    .data_in(resp_sel_in),
    .empty(empty),
    .almost_empty(),
    .half_full(),
    .almost_full(),
    .full(full),
    .error(),
    .data_out(resp_sel_out)
  );


  //---------------------------------------------------------------------------
  // Response side
  //---------------------------------------------------------------------------

  /* XXX One needs additional information to preserve the order of responses
  * in the case of two slaves with different response latencies. This can be
  * done with a response queue to select the next response source. The special
  * case of slaves responding in the same cycle has to be treated separately
  * or MRespAccept is held low until the queue is not empty the next cyle. */
  // forward responses from slave to master
  always_comb begin
    // default assignments
    top.SResp = Bus::NULL;
    top.SData = '0;

    if( !empty ) begin
      if( resp_sel_out == 1'b0 ) begin
        top.SResp = out_0.SResp;
        top.SData = out_0.SData;
      end else if( resp_sel_out == 1'b1 ) begin
        top.SResp = out_1.SResp;
        top.SData = out_1.SData;
      end
    end
  end

  // forward response accept from master to slave
  always_comb begin
    out_0.MRespAccept = 1'b0;
    out_1.MRespAccept = 1'b0;

    if( !empty ) begin
      if( resp_sel_out == 1'b0 ) begin
        if( top.MRespAccept )
          out_0.MRespAccept = 1'b1;
      end else if( resp_sel_out == 1'b1 ) begin
        if( top.MRespAccept )
          out_1.MRespAccept = 1'b1;
      end
    end
  end

  // pop from queue
  always_comb begin
    pop = 1'b0;

    if( !empty ) begin
      if( (resp_sel_out == 1'b0) && top.MRespAccept && (out_0.SResp != Bus::NULL) )
        pop = 1'b1;
      else if( (resp_sel_out == 1'b1) && top.MRespAccept && (out_1.SResp != Bus::NULL) )
        pop = 1'b1;
    end
  end

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:

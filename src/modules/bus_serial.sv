module Bus_serial
  #(parameter int SERIAL_WIDTH = 4,
    parameter int PIPELINE_LENGTH = 0,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter bit byteen = 1'b1)
  ( Bus_if.slave in,
    Bus_if.master out);


  //---------------------------------------------------------------------------
  // Local types and signals
  //---------------------------------------------------------------------------
  
  typedef logic[SERIAL_WIDTH-1:0] Ser_data;
  typedef logic[ADDR_WIDTH-1:0] Addr;
  typedef logic[DATA_WIDTH-1:0] Data;
  typedef logic[DATA_WIDTH/8-1:0] Byte_en;

  typedef struct packed {
    Bus::Ocp_cmd MCmd;
    Addr MAddr;
    Data MData;
    Byte_en MByteEn;
  } Master_word;

  typedef struct packed {
    Bus::Ocp_resp SResp;
    Data SData;
  } Slave_word;


  Master_word master_word_in, master_word_out;
  Master_word next_master_word_in;
  Ser_data master_ser_line;
  Slave_word slave_word_in, slave_word_out;
  Slave_word next_slave_word_in;
  Ser_data slave_ser_line;

  logic master_ser_start;
  logic master_ser_valid;
  logic slave_ser_start;
  logic slave_ser_valid;
  logic master_des_ready;
  logic master_rx_ready;
  logic slave_des_ready;
  logic slave_rx_ready;

  logic master_des_out;
  logic slave_des_out;
  logic cmd_accepted;
  logic resp_accepted;


  assign out.MReset_n = in.MReset_n;

  //---------------------------------------------------------------------------
  // Serialization master -> slave
  //---------------------------------------------------------------------------
 
  always_comb begin
    // default assignment
    next_master_word_in = master_word_in;
    in.SCmdAccept = master_rx_ready;
    master_ser_start = 1'b0;

    if( (in.MCmd != Bus::IDLE) && master_rx_ready ) begin
      next_master_word_in.MCmd = in.MCmd;
      next_master_word_in.MAddr = in.MAddr;
      next_master_word_in.MData = in.MData;
      next_master_word_in.MByteEn = in.MByteEn;
      master_ser_start = 1'b1;
    end
  end

  always_ff @(posedge in.Clk or negedge in.MReset_n)
    if( ~in.MReset_n )
      master_word_in <= '0;
    else
      master_word_in <= next_master_word_in;

  Serialize #(
    .SERIAL_WIDTH(SERIAL_WIDTH),
    .PARALLEL_WIDTH($bits(Master_word))
  ) master_ser (
    .clk(in.Clk), 
    .reset(~in.MReset_n),
    .start(master_ser_start),
    .done(),
    .ready(master_rx_ready),
    .valid_out(master_ser_valid),
    .pin(master_word_in),
    .sout(master_ser_line)
  );

  Deserialize #(
    .SERIAL_WIDTH(SERIAL_WIDTH),
    .PARALLEL_WIDTH($bits(Master_word))
  ) master_des (
    .clk(in.Clk), 
    .reset(~in.MReset_n),
    .valid_in(master_ser_valid),
    .sin(master_ser_line),
    .pout(master_word_out),
    .valid_out(master_des_out),
    .ready(master_des_ready)
  );

  always_comb begin
    out.MCmd = Bus::IDLE;
    out.MAddr = '0;
    out.MData = '0;
    out.MByteEn = '0;
    //master_rx_ready = out.SCmdAccept & master_des_ready;
    master_rx_ready = master_des_ready & cmd_accepted;

    if( master_des_out && !cmd_accepted ) begin
      out.MCmd = master_word_out.MCmd;
      out.MAddr = master_word_out.MAddr;
      out.MData = master_word_out.MData;
      out.MByteEn = master_word_out.MByteEn;
    end
  end

  always_ff @(posedge in.Clk or negedge in.MReset_n)
    if( !in.MReset_n )
      cmd_accepted <= 1'b1;
    else begin
      //if( cmd_accepted && (in.MCmd != Bus::IDLE) )
      if( cmd_accepted && !master_des_out )
        cmd_accepted <= 1'b0;
      else if( !cmd_accepted && (master_des_out && out.SCmdAccept) )
        cmd_accepted <= 1'b1;
    end

  //---------------------------------------------------------------------------
  // Serialization slave -> master
  //---------------------------------------------------------------------------

  always_comb begin
    // default assignment
    next_slave_word_in = slave_word_in;
    slave_ser_start = 1'b0;
    out.MRespAccept = slave_rx_ready;

    if( (out.SResp != Bus::NULL) && slave_rx_ready ) begin
      next_slave_word_in.SResp = out.SResp;
      next_slave_word_in.SData = out.SData;
      slave_ser_start = 1'b1;
    end
  end

  always_ff @(posedge in.Clk or negedge in.MReset_n)
    if( !in.MReset_n ) begin
      slave_word_in <= '0;
    end else begin
      slave_word_in <= next_slave_word_in;
    end
  

  Serialize #(
    .SERIAL_WIDTH(SERIAL_WIDTH),
    .PARALLEL_WIDTH($bits(Slave_word))
  ) slave_ser (
    .clk(in.Clk), 
    .reset(~in.MReset_n),
    .start(slave_ser_start),
    .done(),
    .ready(slave_rx_ready),
    .valid_out(slave_ser_valid),
    .pin(slave_word_in),
    .sout(slave_ser_line)
  );

  Deserialize #(
    .SERIAL_WIDTH(SERIAL_WIDTH),
    .PARALLEL_WIDTH($bits(Slave_word))
  ) slave_des (
    .clk(in.Clk), 
    .reset(~in.MReset_n),
    .valid_in(slave_ser_valid),
    .sin(slave_ser_line),
    .pout(slave_word_out),
    .valid_out(slave_des_out),
    .ready(slave_des_ready)
  );

  always_comb begin
    in.SResp = Bus::NULL;
    in.SData = '0;
    slave_rx_ready = slave_des_ready & resp_accepted;

    if( slave_des_out && !resp_accepted ) begin
      in.SResp = slave_word_out.SResp;
      in.SData = slave_word_out.SData;
    end
  end

  always_ff @(posedge in.Clk or negedge in.MReset_n)
    if( !in.MReset_n )
      resp_accepted <= 1'b1;
    else begin
      if( resp_accepted && !slave_des_out )
        resp_accepted <= 1'b0;
      else if( !resp_accepted && (slave_des_out && in.MRespAccept) )
        resp_accepted <= 1'b1;
    end

endmodule


module Serialize
  #(parameter int SERIAL_WIDTH = 4,
    parameter int PARALLEL_WIDTH = 32)
  ( input logic clk, reset,
    input logic start,
    output logic done,
    input logic ready,
    output logic valid_out,
    input logic[PARALLEL_WIDTH-1:0] pin,
    output logic[SERIAL_WIDTH-1:0] sout );

  //---------------------------------------------------------------------------
  // Local types and signals
  //---------------------------------------------------------------------------
 
  //localparam int COUNTER_WIDTH = Bus::clog2($ceil(real'(PARALLEL_WIDTH)/real'(SERIAL_WIDTH)) +1); // ncsim does not like
  localparam int COUNTER_WIDTH = Bus::clog2(PARALLEL_WIDTH/SERIAL_WIDTH +2);
  typedef logic[COUNTER_WIDTH-1:0] Counter;

  //localparam Counter COUNTER_END = $ceil(PARALLEL_WIDTH/SERIAL_WIDTH);  // ncsim does not like
  localparam Counter COUNTER_END = (PARALLEL_WIDTH/SERIAL_WIDTH) + ((PARALLEL_WIDTH % SERIAL_WIDTH != 0) ? 1 : 0) - 1;

  localparam int PADDING_WIDTH = SERIAL_WIDTH - (PARALLEL_WIDTH % SERIAL_WIDTH);
  localparam int PADDED_WIDTH = PARALLEL_WIDTH + PADDING_WIDTH;

  typedef enum logic[2:0] {
    S_IDLE     = 3'b001,
    S_WAIT     = 3'b010,
    S_TRANSMIT = 3'b100,
    S_UNDEF    = 3'bxxx
  } State;
 
  State state;
  Counter ctr;
  logic next_valid_out;
  logic[SERIAL_WIDTH-1:0] next_sout;
  logic[PADDED_WIDTH-1:0] pin_padded;

  //---------------------------------------------------------------------------
  // Controlling state machine
  //---------------------------------------------------------------------------
  
  always_ff @(posedge clk or posedge reset)
    if( reset )
      state <= S_IDLE;
    else
      unique case(state)
        S_IDLE: begin
          if( start && !ready )
            state <= S_WAIT;
          else if( start && ready )
            state <= S_TRANSMIT;
        end

        S_WAIT: begin
          if( ready )
            state <= S_TRANSMIT;
        end

        S_TRANSMIT: begin
          if( ctr == COUNTER_END )
            state <= S_IDLE;
        end

        default:
          state <= S_UNDEF;
      endcase

  //---------------------------------------------------------------------------
  // Counter
  //---------------------------------------------------------------------------
 
  always_ff @(posedge clk or posedge reset)
    if( reset ) 
      ctr <= 0;
    else begin
      if( state == S_TRANSMIT )
        ctr <= ctr + 1;

      if( ctr == COUNTER_END )
        ctr <= 0;
    end

  //---------------------------------------------------------------------------
  // Serializer output
  //---------------------------------------------------------------------------

  assign pin_padded = {pin, {PADDING_WIDTH{1'b0}}};

  always_comb begin
    // default assignments
    //if( ($left(pin) - (ctr+1)*SERIAL_WIDTH) < $right(pin) )
      //next_sout = {pin[$left(pin) - ctr*SERIAL_WIDTH : $right(pin)], '0};
    //else
    next_sout = pin_padded[$left(pin_padded) - ctr*SERIAL_WIDTH -: SERIAL_WIDTH];

    //for(int i=SERIAL_WIDTH; i>=0; i--) begin
      //int j;
      //j = $left(pin) - ctr*SERIAL_WIDTH + i;

      //if( j > $right(pin) )
        //next_sout[i] = pin[j];
      //else
        //next_sout[i] = 1'b0;
    //end

    next_valid_out = 1'b0;
    done = 1'b0;
    
    if( state == S_TRANSMIT )
      next_valid_out = 1'b1;

    if( ((state == S_TRANSMIT) && (ctr == COUNTER_END)) || (state == S_IDLE) )
      done = 1'b1;
  end


  always_ff @(posedge clk or posedge reset)
    if( reset ) begin
      valid_out <= 1'b0;
      sout <= 1'b0;
    end else begin
      valid_out <= next_valid_out;
      sout <= next_sout;
    end

endmodule

module Deserialize
  #(parameter int SERIAL_WIDTH = 4,
    parameter int PARALLEL_WIDTH = 32)
  ( input logic clk, reset,
    input logic valid_in,
    input logic[SERIAL_WIDTH-1:0] sin,
    output logic[PARALLEL_WIDTH-1:0] pout,
    output logic valid_out,
    output logic ready);

  //localparam int COUNTER_WIDTH = Bus::clog2($ceil(real'(PARALLEL_WIDTH)/real'(SERIAL_WIDTH)) +1); // ncsim does not like
  localparam int COUNTER_WIDTH = Bus::clog2(PARALLEL_WIDTH/SERIAL_WIDTH +2);
  typedef logic[COUNTER_WIDTH-1:0] Counter;

  //localparam Counter COUNTER_END = $ceil(PARALLEL_WIDTH/SERIAL_WIDTH);  // ncsim does not like
  localparam Counter COUNTER_END = (PARALLEL_WIDTH/SERIAL_WIDTH) + ((PARALLEL_WIDTH % SERIAL_WIDTH != 0) ? 1 : 0) - 1;
  
  localparam int PADDING_WIDTH = SERIAL_WIDTH - (PARALLEL_WIDTH % SERIAL_WIDTH);
  localparam int PADDED_WIDTH = PARALLEL_WIDTH + PADDING_WIDTH;

  typedef enum logic[1:0] {
    S_IDLE    = 2'b01,
    S_RECEIVE = 2'b10,
    S_UNDEF   = 2'bxx
  } State;

  State state;
  Counter ctr;
  logic[PADDED_WIDTH-1:0] pout_padded;

  //---------------------------------------------------------------------------
  // Controlling statemachine
  //---------------------------------------------------------------------------
  
  always_ff @(posedge clk or posedge reset)
    if( reset )
      state <= S_IDLE;
    else
      unique case(state)
        S_IDLE: begin
          if( valid_in )
            state <= S_RECEIVE;
        end

        S_RECEIVE: begin
          if( ctr == COUNTER_END )
            state <= S_IDLE;
        end

        default:
          state <= S_UNDEF;
      endcase

  //---------------------------------------------------------------------------
  // Counter
  //---------------------------------------------------------------------------

  always_ff @(posedge clk or posedge reset)
    if( reset )
      ctr <= 0;
    else begin
      if( (state == S_RECEIVE) || ((state == S_IDLE) && valid_in))
        ctr <= ctr + 1;

      if( ctr == COUNTER_END )
        ctr <= 0;
    end
      
  //---------------------------------------------------------------------------
  // Datapath
  //---------------------------------------------------------------------------

  assign pout = pout_padded[$left(pout_padded) -: $bits(pout)];

  always_ff @(posedge clk or posedge reset)
    if( reset )
      pout_padded <= '0;
    else begin
      if( (state == S_RECEIVE) || ((state == S_IDLE) && valid_in) )
        pout_padded[$left(pout_padded) - ctr*SERIAL_WIDTH -: SERIAL_WIDTH] <= sin;
    end

  always_comb begin
    // default assignment
    valid_out = 1'b0;
    ready = 1'b1;

    if( state == S_IDLE ) begin
      valid_out = 1'b1;
    end

    if( (state == S_RECEIVE) || ((state == S_IDLE) && valid_in) )
      ready = 1'b0;
  end

endmodule

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:

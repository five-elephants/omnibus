`ifndef BUS_TRANSACTOR_SV__
`define BUS_TRANSACTOR_SV__

//---------------------------------------------------------------------------
// Bus handling class
//---------------------------------------------------------------------------

class Bus_transactor #(type Addr = int, type Data = int);
  virtual Bus_if #(.byteen(1'b1)) intf = null;

  localparam int num_data_bytes = $bits(Data)/8;

  typedef logic[num_data_bytes-1:0] Data_byte_en;

  function new(virtual Bus_if #(.byteen(1'b1)) intf);
    this.intf = intf;
    clear_request();
    intf.MRespAccept = 1'b0;
  endfunction

  function automatic void clear_request();
    intf.MReset_n = 1'b1;
    intf.MCmd = Bus::IDLE;
    intf.MAddr = 0;
    intf.MData = 0;
    intf.MByteEn = '1;
  endfunction

  task reset();
    intf.MReset_n <= 1'b0;
  endtask

  task automatic write(input Addr addr, Data data, Data_byte_en byte_en);
    intf.MCmd <= Bus::WR;
    intf.MAddr <= addr;
    intf.MData <= data;
    intf.MByteEn <= byte_en;
    intf.MRespAccept <= 1'b1;

    @(posedge intf.Clk);
    while( intf.SCmdAccept == 1'b0 ) @(posedge intf.Clk);

    clear_request();

    while( intf.SResp != Bus::DVA) @(posedge intf.Clk);    

    intf.MRespAccept <= 1'b0;
  endtask


  task automatic read(input Addr addr, Data_byte_en byte_en, output Data data);
    intf.MCmd <= Bus::RD;
    intf.MAddr <= addr;
    intf.MByteEn <= byte_en;
    intf.MRespAccept <= 1'b1;

    @(posedge intf.Clk);
    while( intf.SCmdAccept == 1'b0 ) @(posedge intf.Clk);

    clear_request();

    while( intf.SResp != Bus::DVA) @(posedge intf.Clk);    

    intf.MRespAccept <= 1'b0;
    data = intf.SData;
  endtask
endclass

`endif

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab:

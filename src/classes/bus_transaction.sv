`ifndef BUS_TRANSACTION_SV_
`define BUS_TRANSACTION_SV_

class Bus_transaction #(type Addr = int, type Data = int);
  localparam int num_data_bytes = $bits(Data)/8;

  typedef logic[num_data_bytes-1:0] Data_byte_en;

  Bus::Ocp_cmd cmd;
  Addr addr;
  Data data;
  Data_byte_en byte_en;

  function new(Bus::Ocp_cmd cmd, Addr addr, Data data, Data_byte_en byte_en = '1);
    this.cmd = cmd;
    this.addr = addr;
    this.data = data;
    this.byte_en = byte_en;
  endfunction

endclass


`endif  /* BUS_TRANSACTION_SV_ */

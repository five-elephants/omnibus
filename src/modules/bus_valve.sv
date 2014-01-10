/** OMNIBUS valve
 * If close is asserted, in and out are disconnected from each other.
   * This means, that requests on in and responses on out are still
   * accepted, but not forwarded to the other side. */ 
module Bus_valve
  ( Bus_if.slave in,
    Bus_if.master out,
    input logic close );

  always_comb begin 
    if( close ) begin
      out.MReset_n = 1'b1;
      out.MAddr = 'x;
      out.MCmd = Bus::IDLE;
      out.MData = 'x;
      out.MRespAccept = 1'b1;
      out.MByteEn = 'x;

      in.SCmdAccept = 1'b1;
      in.SData = 'x;
      in.SResp = Bus::NULL;
    end else begin
      out.MReset_n = in.MReset_n;
      out.MAddr = in.MAddr;
      out.MCmd = in.MCmd;
      out.MData = in.MData;
      out.MRespAccept = in.MRespAccept;
      out.MByteEn = in.MByteEn;

      in.SCmdAccept = out.SCmdAccept;
      in.SData = out.SData;
      in.SResp = out.SResp;
    end
  end

endmodule

/* vim: set et fenc= ff=unix sts=2 sw=2 ts=2 : */

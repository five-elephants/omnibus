module Bus_connect
  ( Bus_if.master in,
    Bus_if.slave out );

  assign
    out.MReset_n = in.MReset_n,
    out.MAddr = in.MAddr,
    out.MCmd = in.MCmd,
    out.MData = in.MData,
    out.MRespAccept = in.MRespAccept,
    out.MByteEn = in.MByteEn;

  assign
    in.SCmdAccept = out.SCmdAccept,
    in.SData = out.SData,
    in.SResp = out.SResp;

endmodule

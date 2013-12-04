
package Bus;
	typedef enum logic[2:0] {
		IDLE = 3'b000,
		WR   = 3'b001,
		RD   = 3'b010,
		RDEX = 3'b011,
		RDL  = 3'b100,
		WRNP = 3'b101,
		WRC  = 3'b110,
		BCST = 3'b111
	} Ocp_cmd;

	typedef enum logic[1:0] {
		NULL = 2'b00,
		DVA  = 2'b01,
		FAIL = 2'b10,
		ERR  = 2'b11
	} Ocp_resp;
endpackage

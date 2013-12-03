/**! Interface to Random Access Memory (RAM)
 *
 * The interface represents the connection between one storage element and one
 * client module, accessing the storage with read and write operations. Both 
 * sides must be driven by the same clock. Read operations must be completed 
 * within one clock cycle.
 * */
interface Ram_if
	#(	parameter integer ADDR_WIDTH = 32,//12,   // number of address bits
		                  DATA_WIDTH = 32 ); // number of data bits per address
	
	localparam integer BYTE_COUNT = DATA_WIDTH/8;

	logic                   en;      // enables RAM operation altogether
	logic[ADDR_WIDTH-1 : 0] addr;
	logic[DATA_WIDTH-1 : 0] data_r;  // data line for read operations
	logic[DATA_WIDTH-1 : 0] data_w;  // data line for write operations
	logic                   we;      // write enable
	logic[BYTE_COUNT-1 : 0] be;      // byte enable for write
	logic                   delay;   // data for requested address not yet available


	function automatic integer addr_width();
		return ADDR_WIDTH;
	endfunction

	function automatic integer data_width();
		return DATA_WIDTH;
	endfunction

	/**! Modport for the storage side of the connection */
	modport memory
		(	
			`ifdef SYNTOOL_SYNPLIFY
			ref ADDR_WIDTH, DATA_WIDTH,
			`endif  /* SYNTOOL_SYNPLIFY */

			import addr_width, data_width,
		 	input  en, addr, data_w, we, be,
			output data_r,
			output delay);

	/**! Modport for the client side of the connection */
	modport client
		(
			`ifdef SYNTOOL_SYNPLIFY
			ref ADDR_WIDTH, DATA_WIDTH,
			`endif  /* SYNTOOL_SYNPLIFY */

			import addr_width, data_width,
		 	input  data_r,
			input delay,
			output en, addr, data_w, we, be );


	/**! Modport for a monitor */
	modport monitor
		(	import addr_width, data_width,
			input en, addr, data_r, data_w, we, be, delay );	

endinterface


// vim: noexpandtab ts=4 sw=4 softtabstop=0 nosmarttab:

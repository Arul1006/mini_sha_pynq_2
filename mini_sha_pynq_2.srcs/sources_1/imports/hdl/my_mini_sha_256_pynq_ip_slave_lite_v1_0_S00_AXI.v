
`timescale 1 ns / 1 ps

	module my_mini_sha_256_pynq_ip_slave_lite_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output wire led_status,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0; // Map to data_in (write only)
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1; // Map to control/status: [0]=start, [1]=first_block, [2]=done, [3]=data_rdy, [4]=led_status
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2; // Map to digest_addr: [2:0]
	// slv_reg3 is replaced by dynamic read of digest_out
	
	// Control registers that auto-clear or need to be stored
	reg start_reg;
	reg first_block_reg;
	reg led_status_reg;
	
	// Pulse generator for data_vld on writing to slv_reg0
	reg data_vld_reg;
	
	integer	 byte_index;

	// I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;

	// AXI Write Address Channel
	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    axi_awready <= 1'b0;
	    axi_awaddr <= 0;
	  end else begin    
	    if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
	      axi_awready <= 1'b1;
	      axi_awaddr  <= S_AXI_AWADDR;
	    end else begin
	      axi_awready <= 1'b0;
	    end
	  end 
	end       

	// AXI Write Data Channel
	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    axi_wready <= 1'b0;
	  end else begin    
	    if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID) begin
	      axi_wready <= 1'b1;
	    end else begin
	      axi_wready <= 1'b0;
	    end
	  end 
	end       

	// AXI Write Response Channel
	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    axi_bvalid <= 1'b0;
	    axi_bresp  <= 2'b0;
	  end else begin    
	    if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
	      axi_bvalid <= 1'b1;
	      axi_bresp  <= 2'b0; // 'OKAY' response
	    end else if (S_AXI_BREADY && axi_bvalid) begin
	      axi_bvalid <= 1'b0;
	    end  
	  end
	end   

	// Write Register Logic
	wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    slv_reg0 <= 0;
	    start_reg <= 0;
	    first_block_reg <= 0;
	    led_status_reg <= 0;
	    slv_reg2 <= 0;
	    data_vld_reg <= 0;
	  end else begin
	    // Default behavior for pulses
	    start_reg <= 0;
	    data_vld_reg <= 0;
	    
	    if (slv_reg_wren) begin
	      case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
	        2'h0: begin
	          for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
	            if (S_AXI_WSTRB[byte_index] == 1) begin
	              slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            end
	          end
	          // Pulse data_vld on write to slv_reg0
	          data_vld_reg <= 1'b1;
	        end  
	        2'h1: begin
	          if (S_AXI_WSTRB[0] == 1) begin
	            start_reg       <= S_AXI_WDATA[0];
	            first_block_reg <= S_AXI_WDATA[1];
	            led_status_reg  <= S_AXI_WDATA[4];
	          end
	        end  
	        2'h2: begin
	          for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1) begin
	            if (S_AXI_WSTRB[byte_index] == 1) begin
	              slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            end
	          end  
	        end  
	        default: ;
	      endcase
	    end
	  end
	end    

	// AXI Read Address Channel
	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    axi_arready <= 1'b0;
	    axi_araddr  <= 32'b0;
	  end else begin    
	    if (~axi_arready && S_AXI_ARVALID) begin
	      axi_arready <= 1'b1;
	      axi_araddr  <= S_AXI_ARADDR;
	    end else begin
	      axi_arready <= 1'b0;
	    end
	  end 
	end       

	// AXI Read Data Channel
	always @(posedge S_AXI_ACLK) begin
	  if (S_AXI_ARESETN == 1'b0) begin
	    axi_rvalid <= 1'b0;
	    axi_rresp  <= 2'b0;
	  end else begin    
	    if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
	      axi_rvalid <= 1'b1;
	      axi_rresp  <= 2'b0; // 'OKAY' response
	    end else if (axi_rvalid && S_AXI_RREADY) begin
	      axi_rvalid <= 1'b0;
	    end                
	  end
	end

	// Memory mapped register select and read logic generation
	reg done_latch;
	always @(posedge S_AXI_ACLK) begin
	    if (S_AXI_ARESETN == 1'b0) begin
	        done_latch <= 1'b0;
	    end else begin
	        if (done) begin
	            done_latch <= 1'b1;
	        end else if (start_reg) begin
	            done_latch <= 1'b0;
	        end
	    end
	end

	wire [31:0] read_reg1 = {27'd0, led_status_reg, data_rdy, done_latch, first_block_reg, start_reg};
	wire [31:0] read_reg3 = {16'd0, digest_out};

	assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 : 
	                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? read_reg1 : 
	                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 : 
	                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? read_reg3 : 0; 

	// Add user logic here
	
	// Instantiate the core
	wire [15:0] digest_out;
	wire done;
	wire data_rdy;
	
	mini_sha256_core u_core (
	    .clk(S_AXI_ACLK),
	    .rst_n(S_AXI_ARESETN),
	    .start(start_reg),
	    .first_block(first_block_reg),
	    .done(done),
	    .data_rdy(data_rdy),
	    .data_vld(data_vld_reg),
	    .data_in(slv_reg0[15:0]),
	    .digest_addr(slv_reg2[2:0]),
	    .digest_out(digest_out)
	);
	
	assign led_status = led_status_reg;
	// User logic ends

	endmodule

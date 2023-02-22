//
// This is the template for Part 1 of Lab 8.
//
// Paul Chow
// November 2021
//

// iColour is the colour for the box
//
// oX, oY, oColour and oPlot should be wired to the appropriate ports on the VGA controller
//

// Some constants are set as parameters to accommodate the different implementations
// X_SCREEN_PIXELS, Y_SCREEN_PIXELS are the dimensions of the screen
//       Default is 160 x 120, which is size for fake_fpga and baseline for the DE1_SoC vga controller
// CLOCKS_PER_SECOND should be the frequency of the clock being used.

module part1(iColour,iResetn,iClock,oX,oY,oColour,oPlot,oNewFrame);
   input wire [2:0] iColour;
   input wire 	    iResetn;
   input wire	    iClock;
   output wire [7:0] oX;         // VGA pixel coordinates
   output wire [6:0] oY;

   output wire [2:0] oColour;     // VGA pixel colour (0-7)
   output wire 	     oPlot;       // Pixel drawn enable
   output wire       oNewFrame;

	wire drawDone, erase, frameDelay, move, plot, resetN,tester1,eraseDone;
	wire [3:0] state;
   parameter
     X_BOXSIZE = 8'd4,   // Box X dimension
     Y_BOXSIZE = 7'd4,   // Box Y dimension
     X_SCREEN_PIXELS = 9,  // X screen width for starting resolution and fake_fpga
     Y_SCREEN_PIXELS = 7,  // Y screen height for starting resolution and fake_fpga
     CLOCKS_PER_SECOND = 1200, // 5 KHZ for fake_fpga
     X_MAX = X_SCREEN_PIXELS - 1 - X_BOXSIZE, // 0-based and account for box width
     Y_MAX = Y_SCREEN_PIXELS - 1 - Y_BOXSIZE,

     FRAMES_PER_UPDATE = 15,
     PULSES_PER_SIXTIETH_SECOND = CLOCKS_PER_SECOND / 60;

   //
   // Your code goes here
   wire [7:0] frameCounter;
   controlPath p0(iClock, iResetn, oPlot, drawDone, erase, frameDelay, move, resetN,eraseDone,state);
   dataPath p1(iColour,iClock, iResetn, oPlot, erase, drawDone, oNewFrame, oX, oY,oColour, frameDelay, move, resetN,eraseDone,state,frameCounter);
   //
	//assign oPlot = plot;

endmodule // part1


module controlPath(clk, reset, plot, drawDone, erase,frameDelay, move, resetN,eraseDone,state);
	input clk, reset,drawDone,frameDelay,eraseDone;
	output reg plot, erase, move, resetN;
	output reg[3:0] state;
	
	reg [2:0] next;
	
	localparam
		RESET = 4'd0,
		DRAW = 4'd1,
		DELAY = 4'd2,
		ERASE = 4'd3,
		MOVE = 4'd4;
		
		
	always @(*)
	begin
		//tester1 = 1'b0;
		case (state)
		//if the state is in reset, then everything goes back to initial value
		RESET:
			next = DRAW;
		DRAW:
			begin
			if(!reset)
				next = RESET;
			
			next = drawDone? DELAY:DRAW;
			end
		
		DELAY: 
			begin
			if(!reset)
				next = RESET;
			next = frameDelay ? ERASE : DELAY;
			end
		ERASE: 
			begin
			if(!reset)
				next = RESET;
			next = eraseDone ? MOVE : ERASE;
			end
		MOVE: 
			begin
			if(!reset)
				next = RESET;
			next = RESET;
			end
		
		
		default: state = RESET;
		endcase
	end
	
	always @(*)
	begin
		//default values
		plot = 1'b0;
		erase = 1'b0;
		move = 1'b0;
		//resetN = 1'b0;
		case(state)
		DRAW:
			plot =1'b1;
		
		ERASE: 
			erase = 1'b1;
		MOVE:
			//resetN = 1'b1;
			move = 1'b1;
		
			
		endcase
	end
	
	always @(posedge clk)
		begin
		if(!reset)
			state <= RESET;
		else
			state <= next;	
		end
endmodule
	
		
module dataPath (iColor,clk, reset, plot, erase, drawDone, oNewFrame, outX, outY,color, frameDelay, move,resetN,eraseDone,state,frameCounter);
	input clk, reset, plot, erase, move,resetN;
	input [2:0] iColor;
	input [3:0] state;
	output reg drawDone, oNewFrame, frameDelay, eraseDone;
	output reg [7:0] outX;
	output reg [6:0] outY;
	output reg [2:0] color;
	output reg [7:0] frameCounter;
	
	//x y counter used to see if the square is at the edge of the screen
	//reg [3:0] xCounter;
	//reg [2:0] yCounter;
	//frame counter used to calculate to 299 to make 1 frame
	//reg [4:0] frameCounter;
	//delay counter used to determine the 20 cycle delay
	reg [4:0] delayCounter;
	
	reg [4:0] drawCounter;
	
	reg [3:0] tempX;
	reg [2:0] tempY;
	
	reg DirH, DirY;
	//calculate based on the pass in signal from controlPath
	always @(posedge clk)
		begin
		color = (state == 1)? iColor : 3'b0;
		if(!reset)
			begin
				drawDone = 1'b0;
				oNewFrame = 1'b0;
				outX = 4'b0;
				outY = 3'b0;
				tempX = 4'b0;
				tempY = 3'b0;
				frameCounter = 5'b0;
				
				drawCounter = 5'b0;
				
				color = 3'b0;
				frameDelay = 1'b0;
				DirH = 1'b1;
				DirY = 1'b0;
				eraseDone = 1'b0;
			end
		if(state == 4'd1 || state == 4'd3)
			begin
				outX <= tempX;
				outY <= tempY;

				if(state == 4'd1)
				begin
					//color = iColor;
					drawCounter<=5'b0;
					if(drawCounter == 5'd16)
						begin
						drawCounter <= 5'b0;
						drawDone = 1'b1;
						end
					else
						begin
						outX <= tempX + {drawCounter[1], drawCounter[0]};
						outY <= tempY + {drawCounter[3], drawCounter[2]};
						drawCounter <= drawCounter + 1'b1;
						drawDone = 1'b0;
						end
				
				end
				else if(state == 4'd3)
				begin
					drawCounter<=5'b0;
					if(drawCounter == 5'd16)
					begin
						drawCounter <= 5'b0;
						eraseDone = 1'b1;
						//color = iColor;
					end
					else
					begin
						outX <= tempX + {drawCounter[1], drawCounter[0]};
						outY <= tempY + {drawCounter[3], drawCounter[2]};
						drawCounter <= drawCounter + 1'b1;
						eraseDone = 1'b0;
						//drawDone = 1'b0;
					end
				end
			end	
		if(state == 4'd4)
			begin
				if(outX == 4'b0)
					DirY = 1'b0;
				else if(outX == 4'd4)
					DirY = 1'b1;
				else if(outY == 3'b0)
					DirH = 1'b1;
				else if(outY == 3'd2)
					DirH = 1'b0;
					
				//move the block down
				//moving down right
				if(DirH & !DirY)
				begin
					//outX <= outX - 1'b1;
					tempX <= tempX + 1'b1;
					//outY <= outY + 1'b1;
					tempY <= tempY + 1'b1;
				end
				// moving up right
				else if(!DirH & !DirY)
				begin
					//outX <= outX - 1'b1;
					tempX <= tempX + 1'b1;
					tempY <= tempY - 1'b1;
					//outY <= outY - 1'b1;
				end
				//moving down left
				else if(DirH & DirY)
				begin
					//outX <= outX + 1'b1;
					tempX <= tempX - 1'b1;
					tempY <= tempY + 1'b1;
					//outY <= outY + 1'b1;
				end
				//moving up left
				else if(!DirH & DirY)
				begin
					//outX <= outX + 1'b1;
					tempX <= tempX - 1'b1;
					tempY <= tempY - 1'b1;
					//outY <= outY - 1'b1;
				end
				
			end
		if(delayCounter == 5'd19)
		begin
			delayCounter <= 5'b0;
			oNewFrame = 1'b1;
		end
		else if(!reset)
			delayCounter<=5'b0;
		else 
		begin
			delayCounter <= delayCounter + 1'b1;
			oNewFrame = 1'b0;
		end		
		if(oNewFrame)
		begin
			if(frameCounter == 5'd14)
				begin
				frameCounter <= 5'b0;
				frameDelay = 1'b1;
				end
			else
				begin
				frameCounter <= frameCounter + 1'b1;
				frameDelay = 1'b0;
				end
		end

		
	end
	
endmodule
		
			
			
		
		
		





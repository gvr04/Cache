`define loc 15:2
`define b1 7:0
`define b2 15:8    
`define b3 23:16
`define b4 31:24
module Memory(input [15:0]memaddr,wire clk,[0:0]req,[0:0]rw,[31:0]datafcac,output reg [31:0]datatcac,reg [0:0]rdy);

//Declaration of 
 reg [7:0] ram [(2**16)-1:0];
reg[15:0] memaddrr;

//State Declaration of the RAM FSM
localparam idle=6'b000001,memac0=6'b000010,memac1=6'b000100,memac2=6'b001000,memac3=6'b010000,ready=6'b100000;
reg[5:0]sreg;

//Ram Content Initialization
integer i;
initial
  begin
  for(i=0;i<2**16;i=i+1) begin
     ram[i]=8'hab;
  ram[16'h0000]=8'hef;
  ram[16'h0001]=8'hef;
  ram[16'h0002]=8'hef;
  ram[16'h0003]=8'hef;
  end 
  end
  
//RAM FSM
always@(posedge clk)
begin
case(sreg)
  //Idle State: Remains idle as long as there is no request from cache
    idle:begin
      rdy=1'b0;
      if(req)
          begin
        memaddrr={memaddr[15:2],2'b00};
        if(rw) 
          ram[memaddrr]<=datafcac[7:0];
        else 
          datatcac[7:0]<=ram[memaddrr];    
        memaddrr=memaddrr+1;
        sreg<=memac0;
          end
      else
        sreg<=idle;
     end
     
     memac0:begin
        if(rw)
          ram[memaddrr]<=datafcac[15:8];
        else 
          datatcac[15:8]<=ram[memaddrr];    
        memaddrr=memaddrr+1;
        sreg<=memac1;
           end
    
     memac1:begin   
        if(rw)
          ram[memaddrr]<=datafcac[23:16];
        else 
          datatcac[23:16]<=ram[memaddrr];    
        memaddrr=memaddrr+1;
        sreg<=memac2;
            end
     
     memac2:begin   
        if(rw)
          ram[memaddrr]<=datafcac[31:24];
        else 
          datatcac[31:24]<=ram[memaddrr];    
        memaddrr=memaddrr+1;
        sreg<=memac3; end
   
     memac3:begin   
        rdy=1'b1;
        rdy<=1'b0;
        sreg<=idle;
            end

     default:begin
      rdy=1'b0;
      if(req)
          begin
        memaddrr={memaddr[15:2],2'b00};
        if(rw) 
          ram[memaddrr]<=datafcac[7:0];
        else 
          datatcac[7:0]<=ram[memaddrr];    
        memaddrr=memaddrr+1;
        sreg<=memac0;  
          end
      else
        sreg<=idle;
     end        
endcase
end

endmodule
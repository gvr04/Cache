
`define tag 15:10
`define set 9:2
`define D 7         //Definitions for making indexing easier
`define V 6
`define ByOff 1:0

module DM(input clk,req,rw,[15:0]memaddr,[7:0]datafcpu,output reg[7:0] datatcpu,reg [31:0]datatmem,reg [0:0]rdy,[3:0]state);

//Data and Tag Directory of the Cache
reg[31:0] datad[(2**8)-1:0];
reg[7:0] tagd[(2**8)-1:0];

//Definitions and Declarations of states and registers of the FSMs
reg [3:0]sreg;
localparam idle=4'b0001,tagcomp=4'b0010,memac=4'b0100,wback=4'b1000;
assign state=sreg;

//Declaration of Memory Signals and Instantiation of the Memory Module
wire[31:0] datafmem;
reg reqm,rwm;
wire rdym;
reg[15:0] rmemaddr;
Memory md1(rmemaddr,clk,reqm,rwm,datatmem,datafmem,rdym);

//Cache Controller FSM
always@(posedge clk) begin
case(sreg)
     //Idle State: Stays idle when request(req)=0;when req is set,sets next state to tag comparison
     idle:begin
            rdy=1'b0;
            if(req) begin
              sreg<=tagcomp;
              reqm=0;
              end
            else
              sreg<=idle;end
     
     // Tag Comparison: Checks whether the data from the requested memory address is present in the cache, enables write back on replacement of Dirty Block
     tagcomp:begin reqm=0; 
             if(tagd[memaddr[`set]][`V]) 
                if(tagd[memaddr[`set]][5:0]==memaddr[`tag]) begin
                   if (rw) begin
                      datad[memaddr[`set]][memaddr[`ByOff]*8+:8]<=datafcpu;
                      tagd[memaddr[`set]][`D]<=1'b1; 
                      end
                   else
                      datatcpu<= datad[memaddr[`set]][memaddr[`ByOff]*8+:8];
                   rdy<=1'b1;
                   sreg<=idle;end
                else
                   if(tagd[memaddr[`set]][`D]) begin
                    sreg<=wback;rwm=1;datatmem=datad[memaddr[`set]];
                    rmemaddr={tagd[memaddr[`set]][5:0],memaddr[9:2],2'b00};
                    reqm=1;
                    end
                   else begin
                    sreg<=memac;reqm=1; rmemaddr=memaddr;rwm=0;end
               else begin
                   sreg<=memac;reqm=1; rmemaddr=memaddr;rwm=0; end end
  
   //Write Back: Controller remains in this state until RAM signals Ready to ensure data has been properly written back       
       wback: begin
                if(rdym) begin
                  sreg<=memac;rmemaddr=memaddr;reqm=1;end
                else
                  sreg<=wback;  
              end
   //Memory Access:The particular set location(determined by the set field of the memory address) is loaded with data from Memory    
       memac:begin
             rmemaddr=memaddr;
             reqm=1;
             rwm=0;
             tagd[memaddr[`set]]={2'b01,memaddr[`tag]}; 
             datad[memaddr[`set]]=datafmem;  
             if(rdym) begin
              sreg<=tagcomp;
              reqm=0;
              end
             else
              sreg<=memac;
             end                             

//Behaves like idle state when initally the state register is uninitialized          
      default:if(req) begin
               sreg<=tagcomp;
               reqm=0;
               rdy=1'b0;
              end
              else
               sreg<=idle;           
endcase
end          
endmodule



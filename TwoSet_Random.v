`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2024 12:30:22
// Design Name: 
// Module Name: TwoSet_Random
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define tag 15:9
`define set 8:2
`define D 8           //Definitions for making indexing easier
`define V 7
`define ByOff 1:0


module TwoSet_Random(
    input clk,req,rw,[15:0]memaddr,[7:0]datafcpu,output reg[7:0] datatcpu,reg [31:0]datatmem,reg [0:0]rdy,[3:0]state,[0:0]idr
    );
//Data and Tag Directory of Way 1
reg [31:0] datad1 [(2**7 )-1:0];  
reg[8:0] tagd1[(2**7 )-1:0];

//Data and Tag Directory of Way 2
reg [31:0] datad2 [(2**7 )-1:0];
reg[8:0] tagd2[(2**7 )-1:0];

//Required HW for implementing Random Replacement
reg[2:0]lfsr;
reg id;

//Definitions and Declarations of states and registers of the FSMs
localparam idle=4'b0001,tagcomp=4'b0010,memac=4'b0100,wback=4'b1000;
reg[3:0] sreg;
assign state=sreg;

assign idr=id;

//Declaration of Memory Signals and Instantiation of the Memory Module
wire[31:0] datafmem;
reg reqm,rwm;
wire rdym;
reg[15:0] rmemaddr;
Memory md1(rmemaddr,clk,reqm,rwm,datatmem,datafmem,rdym);

//initializing cache contents to 0
integer i;
initial begin
   for(i=0;i<2**7;i=i+1) begin
   datad1[i]=32'h0000;
   tagd1[i]='b0;
   datad2[i]='b0;
   tagd2[i]='b0;
   end 
   id=0;
   lfsr=3'b110;
   end

//Cache Controller FSM
always@(posedge clk) begin
case(sreg)
     //Idle State: Stays idle when request(req)=0;when req is set,sets next state to tag comparison,implements lfsr and also ensures invalid blocks are evicted
     //before random replacement
     idle: begin rdy=1'b0; 
         if(req) begin
              sreg<=tagcomp;
              reqm=0;
              rdy=1'b0;
              lfsr[0]<=lfsr[1]^lfsr[2];
              lfsr[1]<=lfsr[0];
              lfsr[2]<=lfsr[1];
             if (tagd1[memaddr[`set]][`V]&&tagd2[memaddr[`set]][`V])
               id=lfsr[0];
             else 
               if(~tagd2[memaddr[`set]][`V])
                 id=0;
               else if(~tagd1[memaddr[`set]][`V])
                 id=1;
              end
         else
              sreg<=idle; end
    // Tag Comparison: Checks whether the data from the requested memory address is present in the cache , decides the way to be replaced and also enable write
    //back of the cache block according to the replacement logic
     tagcomp:begin reqm=0; 
              if(tagd1[memaddr[`set]][`V]&(tagd1[memaddr[`set]][6:0]==memaddr[`tag])) begin
//                if(tagd1[memaddr[`set]][6:0]==memaddr[`tag]) begin
                   if (rw) begin
                      datad1[memaddr[`set]][memaddr[`ByOff]*8+:8]<=datafcpu;
                      tagd1[memaddr[`set]][`D]<=1'b1; 
                      end
                   else
                      datatcpu<= datad1[memaddr[`set]][memaddr[`ByOff]*8+:8];
                   rdy<=1'b1;
                   
                   sreg<=idle;end
               
              else if(tagd2[memaddr[`set]][`V]&(tagd2[memaddr[`set]][6:0]==memaddr[`tag])) begin

                   if (rw) begin
                      datad2[memaddr[`set]][memaddr[`ByOff]*8+:8]<=datafcpu;
                      tagd2[memaddr[`set]][`D]<=1'b1; 
                      end
                   else
                      datatcpu<= datad2[memaddr[`set]][memaddr[`ByOff]*8+:8];
                   rdy<=1'b1;
                   
                   sreg<=idle;end
               
              else 
                  if((tagd1[memaddr[`set]][`D]&id)||(tagd2[memaddr[`set]][`D]&~id)) begin
                    sreg<=wback;rwm=1;
                    if(id) begin
                      rmemaddr={tagd1[memaddr[`set]][6:0],memaddr[`set],2'b00};
                      datatmem=datad1[memaddr[`set]]; end
                    else begin
                      rmemaddr={tagd2[memaddr[`set]][6:0],memaddr[`set],2'b00};
                      datatmem=datad2[memaddr[`set]]; end
                    reqm=1;
                    end
                   else begin 
                    sreg<=memac;reqm=1'b1; rmemaddr=memaddr;rwm=0; end           
         end     
 //Write Back: Controller remains in this state until RAM signals Ready to ensure data has been properly written back      
       wback: begin
                if(rdym) begin
                  sreg<=memac;rmemaddr=memaddr;reqm=1;end
                else
                  sreg<=wback;  
              end
//Memory Access:The appropriate way at the particular set location(decided by replacement policy) is loaded with data from the memory address requested by the CPU       
//and the controller remains in this state till the data has been properly loaded into the cache            
       memac:begin
             rmemaddr=memaddr;
             reqm=1;
             rwm=0;
             
             if(id) begin
              tagd1[memaddr[`set]]={2'b01,memaddr[`tag]}; 
              datad1[memaddr[`set]]=datafmem; end
             else begin
              tagd2[memaddr[`set]]={2'b01,memaddr[`tag]}; 
              datad2[memaddr[`set]]=datafmem; end
             
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
   


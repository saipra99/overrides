import uvm_pkg::*;
`include "uvm_macros.svh"

class Packet extends uvm_sequence_item;
  
 rand  bit[7:0] addr;
 rand  bit[7:0] data;
  
  function new(string name="Packet");
    super.new(name);
  endfunction
  
  `uvm_object_utils_begin(Packet)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_int(data,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function string convert2string();
    string s;
    s=$sformatf("addr :0x%0h data: 0x%0h",addr,data);
    return s;
  endfunction
  
endclass

//********************Packet2***************************

class Packet2 extends Packet;
  
  `uvm_object_utils(Packet2)
  
  function new(string name="Packet2");
    super.new(name);
  endfunction
  
  Packet pkt;
  rand bit valid;
  
  function string convert2string();
    string s;
    s=$sformatf("addr:%0d data:%0d valid: %0d",addr,data,valid);
    return s;
  endfunction
  
endclass

///*******************SEQUENCE*******************

class sequence_ extends uvm_sequence #(Packet);
  
  `uvm_object_utils(sequence_)
  
  function new(string name="sequence_");
    super.new(name);
  endfunction
  
  rand int num;
  
  constraint no_of{soft num inside {[3:10]};}
  
  task body();
    
    for(int i=0;i<num;i=i+1)
      begin
    
    Packet pkt=Packet::type_id::create("pkt");
    
    start_item(pkt);
    
    pkt.randomize();
    
    finish_item(pkt);
        
      end
    `uvm_info(get_type_name(),$sformatf("Done generating %0d items",num),UVM_LOW)
    
  endtask
endclass

//*********************DRIVER*************************

class driver extends uvm_driver#(Packet);
  
  `uvm_component_utils(driver)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  Packet pkt;
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever
      begin
      
        seq_item_port.get_next_item(pkt);
        #10 `uvm_info(get_type_name(),$sformatf(" %s",pkt.convert2string()),UVM_LOW)
        seq_item_port.item_done();
      end
  endtask
  
endclass

//**********************DRIVER2************************

class driver2 extends driver;
  
  `uvm_component_utils(driver2)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  
  
  task run_phase (uvm_phase phase);
    Packet tx;
    forever 
      begin
        seq_item_port.get_next_item(tx);
        `uvm_info(get_type_name(),"**EXTENDED DRIVER**",UVM_LOW)
        #10 `uvm_info(get_type_name(),tx.convert2string(),UVM_LOW)
        seq_item_port.item_done();
      end
  endtask
endclass

   
//*************************AGENT******************************
  
class agent extends uvm_agent;
  
  `uvm_component_utils(agent)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  uvm_sequencer#(Packet) seqr;
  driver drv;
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    drv=driver::type_id::create("drv",this);
    seqr=uvm_sequencer#(Packet)::type_id::create("seqr",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
endclass

//**************************ENVIRONMENT*******************************

class environment extends uvm_env;
  
  `uvm_component_utils(environment)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  agent a0;
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    a0=agent::type_id::create("a0",this);
  endfunction
  
endclass

//******************TEST*********************************
class test1 extends uvm_test;
  
  `uvm_component_utils(test1)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  environment e0;
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e0=environment::type_id::create("e0",this);
    
   set_type_override_by_type(Packet::get_type(),Packet2::get_type());
  set_inst_override_by_type("e0.a0.drv",driver::get_type(),driver2::get_type());
  endfunction
  
  
  task run_phase(uvm_phase phase);
     sequence_ s0;
    s0=sequence_::type_id::create("s0",this);
    
    phase.raise_objection(this);
    
    void'(  s0.randomize() with {num inside {[12:15]}; });
    s0.start(e0.a0.seqr);
    
    phase.drop_objection(this);
  endtask
  
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    this.print();
    //factory.print();
  endfunction
  
endclass

//**************TOP*****************

module tb;
  
  initial
    begin
      run_test("test1");
    end
endmodule

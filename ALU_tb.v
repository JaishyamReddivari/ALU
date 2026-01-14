interface alu_if #(parameter B_W = 8);
    logic [B_W-1:0] a, b;
    logic c_in;
    logic [3:0] opcode;
    logic [B_W-1:0] y;
    logic c_out, borrow, invalid_op;
    logic zero, parity;
endinterface

class alu_txn;
    rand bit [7:0] a, b;
    rand bit c_in;
    rand bit [3:0] opcode;

    bit [7:0] y_obs;
    bit c_out_obs, borrow_obs, invalid_op_obs;
    bit zero_obs, parity_obs;
endclass

class alu_driver;
    virtual alu_if vif;
    mailbox #(alu_txn) gen2drv;

    function new(virtual alu_if vif, mailbox #(alu_txn) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task run();
        alu_txn tx;
        forever begin
            gen2drv.get(tx);
            vif.a      = tx.a;
            vif.b      = tx.b;
            vif.c_in   = tx.c_in;
            vif.opcode = tx.opcode;
            #5;
        end
    endtask
endclass

class alu_monitor;
    virtual alu_if vif;
    mailbox #(alu_txn) mon2scb;

    function new(virtual alu_if vif, mailbox #(alu_txn) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        alu_txn tx;
        forever begin
            #5;
            tx = new();
            tx.a = vif.a;
            tx.b = vif.b;
            tx.c_in = vif.c_in;
            tx.opcode = vif.opcode;

            tx.y_obs = vif.y;
            tx.c_out_obs = vif.c_out;
            tx.borrow_obs = vif.borrow;
            tx.invalid_op_obs = vif.invalid_op;
            tx.zero_obs = vif.zero;
            tx.parity_obs = vif.parity;

            mon2scb.put(tx);
        end
    endtask
endclass

class alu_scoreboard;
    mailbox #(alu_txn) mon2scb;

    function new(mailbox #(alu_txn) mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();
        alu_txn tx;
        bit [8:0] exp;

        forever begin
            mon2scb.get(tx);

            case (tx.opcode)
                1:  exp = tx.a + tx.b;
                2:  exp = tx.a + tx.b + tx.c_in;
                3:  exp = tx.a - tx.b;
                4:  exp = tx.a + 1;
                5:  exp = tx.a - 1;
                6:  exp = tx.a & tx.b;
                7:  exp = ~tx.a;
                8:  exp = {tx.a[6:0], tx.a[7]};
                9:  exp = {tx.a[0], tx.a[7:1]};
                default: exp = 0;
            endcase

            if (tx.y_obs !== exp[7:0]) begin
                $error("ALU ERROR | opcode=%0d a=%0h b=%0h exp=%0h got=%0h",
                       tx.opcode, tx.a, tx.b, exp[7:0], tx.y_obs);
            end
        end
    endtask
endclass

class alu_env;
    alu_driver drv;
    alu_monitor mon;
    alu_scoreboard scb;

    mailbox #(alu_txn) gen2drv;
    mailbox #(alu_txn) mon2scb;

    function new(virtual alu_if vif);
        gen2drv = new();
        mon2scb = new();
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
    endfunction

    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask
endclass

class alu_test;
    alu_env env;

    function new(virtual alu_if vif);
        env = new(vif);
    endfunction

    task run();
        alu_txn tx;
        env.run();

        repeat (100) begin
            tx = new();
            tx.randomize() with { opcode inside {[1:9]}; };
            env.gen2drv.put(tx);
            #10;
        end

        #50 $finish;
    endtask
endclass

module tb;
    alu_if intf();

    ALU dut (
        .a(intf.a),
        .b(intf.b),
        .c_in(intf.c_in),
        .opcode(intf.opcode),
        .y(intf.y),
        .c_out(intf.c_out),
        .borrow(intf.borrow),
        .invalid_op(intf.invalid_op),
        .zero(intf.zero),
        .parity(intf.parity)
    );

    initial begin
        alu_test test = new(intf);
        test.run();
    end
endmodule

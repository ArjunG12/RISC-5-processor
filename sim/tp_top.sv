`timescale 1ns / 1ps

module tb_top;

    logic clk, rst;
    logic [31:0] debug_pc;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: wait N cycles
    task wait_cycles(input int n);
        repeat(n) @(posedge clk);
    endtask

    initial begin
        // Reset for 3 cycles
        rst = 1;
        wait_cycles(3);
        rst = 0;

        // Run for enough cycles to execute the program
        wait_cycles(25);

        // ── Spot-check register values ──────────────────────────────
        $display("=== Register Check ===");
        $display("x1  = %0d (expect 10)",  dut.reg_file.registers[1]);
        $display("x2  = %0d (expect 20)",  dut.reg_file.registers[2]);
        $display("x3  = %0d (expect 30)",  dut.reg_file.registers[3]);
        $display("x5  = %0d (expect 25)",  dut.reg_file.registers[5]);
        $display("x6  = %0d (expect 30)",  dut.reg_file.registers[6]);
        $display("x7  = %0d (expect 40)",  dut.reg_file.registers[7]);
        $display("x10 = %0d (expect 1)",   dut.reg_file.registers[10]);

        // ── Check data memory ────────────────────────────────────────
        $display("=== Memory Check ===");
        $display("mem[0] = %0d (expect 30)", dut.dm.mem[0]);

        // ── Pass/fail summary ────────────────────────────────────────
        if (dut.reg_file.registers[3]  == 32'd30 &&
            dut.reg_file.registers[10] == 32'd1  &&
            dut.dm.mem[0]              == 32'd30)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

    // Waveform dump (for GTKWave / Vivado)
    initial begin
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, tb_top);
    end

endmodule

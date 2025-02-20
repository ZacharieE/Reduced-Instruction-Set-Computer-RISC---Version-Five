
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity riscv_fetchMemory_tb is
end entity;

architecture tb of riscv_fetchMemory_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant DEPTH : integer := 9;

    -- Clock and reset
    signal i_clk         : std_logic := '0';
    signal i_rstn        : std_logic := '1';
    signal i_stall       : std_logic := '0';
    signal i_flush       : std_logic := '0';
    signal i_transfert   : std_logic := '0';
    signal i_target      : std_logic_vector(XLEN-1 downto 0) := (others => '0');

    -- Memory interface signals
    signal imem_en       : std_logic;
    signal imem_addr     : std_logic_vector(8 downto 0);
    signal imem_read     : std_logic_vector(XLEN-1 downto 0);
    signal o_pc_current  : std_logic_vector(XLEN-1 downto 0);
    signal o_instr       : std_logic_vector(XLEN-1 downto 0);

    -- Debug signals
    signal debug_addr    : unsigned(8 downto 0);
    signal debug_pc_addr : std_logic_vector(8 downto 0);

    -- Expected values
    type instruction_array is array (0 to 7) of std_logic_vector(31 downto 0);
    constant expected_instructions : instruction_array := (
        x"000074B3", x"FFFFF2B7", x"7FF06313", x"FFF00393",
        x"00204E13", x"00137E93", x"00431513", x"0042D593"
    );

begin
    -- Clock generation
    i_clk <= not i_clk after CLK_PERIOD/2;

    -- Debug address counter for monitoring
    process(i_clk, i_rstn)
    begin
        if i_rstn = '0' then
            debug_addr <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_stall = '0' then
                debug_addr <= debug_addr + 1;
            end if;
        end if;
    end process;

    -- Convert PC to memory address for monitoring
    debug_pc_addr <= o_pc_current(10 downto 2);

    -- Fetch module
    u_fetch: entity work.fetch
        port map (
            i_clk        => i_clk,
            i_rst      => i_rstn,
            i_stall     => i_stall,
            i_flush     => i_flush,
            i_transfert => i_transfert,
            i_target    => i_target,
            i_mem	 => imem_read,
            o_imem_addr => imem_addr,
            o_imem_en   => imem_en,
            o_pc => o_pc_current,
            o_instruction     => o_instr
        );

    -- Memory module
    u_mem: entity work.dpm
        generic map (
            WIDTH => 32,
            DEPTH => DEPTH,
            RESET => 16#00000000#,
            INIT  => "riscv_basic.mem"
        )
        port map (
            i_a_clk   => i_clk,
            i_a_rstn  => i_rstn,
            i_a_en    => '1',  -- Always enable memory
            i_a_we    => '0',
            i_a_addr  => imem_addr,
            i_a_write => (others => '0'),
            o_a_read  => imem_read,
            i_b_clk   => i_clk,
            i_b_rstn  => i_rstn,
            i_b_en    => '0',
            i_b_we    => '0',
            i_b_addr  => (others => '0'),
            i_b_write => (others => '0'),
            o_b_read  => open
        );

imem:
    -- Test process
    process
        procedure wait_cycles(n: positive) is
        begin
            for i in 1 to n loop
                wait until rising_edge(i_clk);
            end loop;
        end procedure;

        -- Debug printing procedure
        procedure print_debug_info is
        begin
            report "Debug Info:" &
                   " PC=" & to_hstring(o_pc_current) &
                   " Addr=" & to_hstring(imem_addr) &
                   " Data=" & to_hstring(imem_read) &
                   " Instr=" & to_hstring(o_instr);
        end procedure;
    begin
        -- Initial state
        i_stall <= '0';
        i_flush <= '0';
        i_transfert <= '0';
        i_target <= (others => '0');

        -- Reset sequence
        report "Reset asynchrone en test";
        i_rstn <= '0';
        wait_cycles(5);
        i_rstn <= '1';
        wait_cycles(5);

        -- Test instruction fetch sequence
        report "Sequence d'instructions en test";
        for i in 0 to 7 loop
            wait_cycles(5);
            print_debug_info;  -- Print debug info before assertion
            assert o_instr = expected_instructions(i) 
                report "Instruction fetch erreur --- Attendu: " & 
                       to_hstring(expected_instructions(i)) & 
                       ", Obtenu: " & to_hstring(o_instr) & 
                       ", PC=" & to_hstring(o_pc_current) &
                       ", Addr=" & to_hstring(imem_addr)
                severity error;
        end loop;

        report "Fin des tests du module FetchMemory";
        wait;
    end process;

end architecture tb;
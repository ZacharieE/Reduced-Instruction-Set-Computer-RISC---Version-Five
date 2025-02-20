library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.riscv_pkg.all;

entity riscv_id_tb is
end entity;

architecture testbench of riscv_id_tb is
    -- Signals for inputs and outputs of the riscv_id module
    signal i_clk       : std_logic := '0';
    signal i_rstn      : std_logic := '1';
    signal i_instr     : std_logic_vector(31 downto 0) := (others => '0');
    signal i_wb        : std_logic := '0';
    signal i_rd_addr   : std_logic_vector(4 downto 0) := (others => '0');
    signal i_rd_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal i_flush     : std_logic := '0';

    signal o_rs1_data  : std_logic_vector(31 downto 0);
    signal o_rs2_data  : std_logic_vector(31 downto 0);
    signal o_branch    : std_logic;
    signal o_jump      : std_logic;
    signal o_rw        : std_logic;
    signal o_wb_out    : std_logic;
    signal o_arith     : std_logic;
    signal o_sign      : std_logic;
    signal o_src_imm   : std_logic;
    signal o_alu_op    : std_logic_vector(2 downto 0);
    signal o_imm       : std_logic_vector(31 downto 0);
    signal i_pc     : std_logic_vector(XLEN-1 downto 0);
    signal o_pc     : std_logic_vector(XLEN-1 downto 0);
    -- Clock period definition
    constant clk_period : time := 10 ns;

 component riscv_id is
    port (
      i_clk       : in  std_logic;
      i_rstn      : in  std_logic;
      i_instr     : in  std_logic_vector(31 downto 0);
      i_wb        : in  std_logic;
      i_rd_addr   : in  std_logic_vector(4 downto 0);
      i_rd_data   : in  std_logic_vector(31 downto 0);
      i_flush     : in  std_logic;
      i_pc        : in std_logic_vector(XLEN-1 downto 0);

      o_rs1_data  : out std_logic_vector(31 downto 0);
      o_rs2_data  : out std_logic_vector(31 downto 0);
      o_branch    : out std_logic;
      o_jump      : out std_logic;
      o_rw        : out std_logic;
      o_wb_out    : out std_logic;
      o_arith     : out std_logic;
      o_sign      : out std_logic;
      o_src_imm   : out std_logic;
      o_alu_op    : out std_logic_vector(2 downto 0);
      o_pc        : out std_logic_vector(XLEN-1 downto 0);

      o_imm       : out std_logic_vector(31 downto 0)
    );
  end component;

begin
    -- Clock generation process
    clk_gen : process
    begin
        i_clk <= '0';
        wait for clk_period / 2;
        i_clk <= '1';
        wait for clk_period / 2;
    end process;

    -- DUT instantiation
    uut: riscv_id
        port map (
            i_clk       => i_clk,
            i_rstn      => i_rstn,
            i_instr     => i_instr,
            i_wb        => i_wb,
            i_rd_addr   => i_rd_addr,
            i_rd_data   => i_rd_data,
            i_flush     => i_flush,
            i_pc        => i_pc,
            o_rs1_data  => o_rs1_data,
            o_rs2_data  => o_rs2_data,
            o_branch    => o_branch,
            o_jump      => o_jump,
            o_rw        => o_rw,
            o_wb_out    => o_wb_out,
            o_arith     => o_arith,
            o_sign      => o_sign,
            o_src_imm   => o_src_imm,
            o_alu_op    => o_alu_op,
            o_pc        => o_pc,
            o_imm       => o_imm
        );

    -- Stimulus process
    stim_proc : process
    begin
        -- Test case 1: BEQ instruction
        i_rstn <= '0';  -- Assert reset
        wait for clk_period;
        i_rstn <= '1';  -- Deassert reset
        wait for clk_period;
        i_instr <= "00000000000100001000000001100011";  -- BEQ a0, a1, offset
        wait for clk_period;

        assert (o_branch = '1') report "BEQ instruction failed to set o_branch!" severity error;
        assert (o_imm = x"00000004") report "Immediate value incorrect for BEQ!" severity error;

        -- Add more test cases for different instructions as required
        wait for clk_period;

        -- End simulation
        wait;
    end process;

end architecture testbench;

--begin

--
--    -- Clock generation
--    clk_process : process
--    begin
--        while true loop
--            i_clk <= '0';
--            wait for clk_period / 2;
--            i_clk <= '1';
--            wait for clk_period / 2;
--        end loop;
--    end process;
--
--    -- Test process
--    stim_proc: process
--    begin
--        -- Reset the module
--        i_rstn <= '1';
--        wait for clk_period;
--        --i_rstn <= '1';
--	i_pc <= x"1A1A1A1A";
--        -- Test Case 1: Simple instruction
--        i_instr <= x"00000013"; -- ADDI x0, x0, 0
--        i_rd_addr <= "00001";
--        i_rd_data <= x"00000001";
--        i_wb <= '1';
--        wait for clk_period;
--
--        -- Assert outputs for the first test case
--        assert o_branch = '0' report "Test Case 1 Failed: o_branch is incorrect" severity error;
--        assert o_jump = '0' report "Test Case 1 Failed: o_jump is incorrect" severity error;
--        assert o_alu_op = "000" report "Test Case 1 Failed: o_alu_op is incorrect" severity error;
--	assert o_pc = i_pc report "Test Case 1 Failed : o_pc incorrect" severity error;
--
--        -- Test Case 2: Branch instruction
--        i_instr <= x"00012063"; -- BEQ x2, x0, 4
--        i_wb <= '0';
--        wait for clk_period;
--
--        -- Assert outputs for the second test case
--        assert o_branch = '1' report "Test Case 2 Failed: o_branch is incorrect" severity error;
--        assert o_jump = '0' report "Test Case 2 Failed: o_jump is incorrect" severity error;
--
--        -- Test Case 3: Flush
--        i_flush <= '1';
--        wait for clk_period;
--
--        -- Assert that outputs are cleared on flush
--        assert o_rs1_data =  "00000000000000000000000000000000" report "Test Case 3 Failed: o_rs1_data not flushed" severity error;
--        assert o_rs2_data =  "00000000000000000000000000000000"  report "Test Case 3 Failed: o_rs2_data not flushed" severity error;
--
--        -- End simulation
--        wait for clk_period;
--        assert false report "Simulation Finished Successfully" severity note;
--        --wait;
--
--
--    -- Test Case 1: Simple instruction
--    i_instr <= x"0010A013"; -- ADDI x0, x0, 0
--    i_rd_addr <= "00001";
--    i_rd_data <= x"00000001";
--    i_wb <= '1';
--	i_pc <= x"00000000";
--    wait for clk_period;
--
--    -- Assert outputs for the first test case
--    assert o_branch = '0' report "Test Case 1 Failed: o_branch is incorrect" severity error;
--    assert o_jump = '0' report "Test Case 1 Failed: o_jump is incorrect" severity error;
--    assert o_rw = '1' report "Test Case 1 Failed: o_rw is incorrect" severity error;
--    assert o_wb_out = '1' report "Test 
--
--begin
--    -- Instantiate the riscv_id module
--    uut: entity work.riscv_id
--        port map (
--            i_clk       => i_clk,
--            i_rstn      => i_rstn,
--            i_instr     => i_instr,
--            i_wb        => i_wb,
--            i_rd_addr   => i_rd_addr,
--            i_rd_data   => i_rd_data,
--            i_flush     => i_flush,
--	    i_pc        => i_pc,
--            o_rs1_data  => o_rs1_data,
--            o_rs2_data  => o_rs2_data,
--            o_branch    => o_branch,
--            o_jump      => o_jump,
--            o_rw        => o_rw,
--            o_wb_out    => o_wb_out,
--            o_arith     => o_arith,
--            o_sign      => o_sign,
--            o_src_imm   => o_src_imm,
--            o_alu_op    => o_alu_op,
--            o_imm       => o_imm,
--	    o_pc        => o_pc
--        );
--
--    -- Clock generation
--    clk_process : process
--    begin
--        while true loop
--            i_clk <= '0';
--            wait for clk_period / 2;
--            i_clk <= '1';
--            wait for clk_period / 2;
--        end loop;
--    end process;
--
--    -- Test process
--    stim_proc: process
--    begin
--        -- Reset the module
--        i_rstn <= '1';
--        wait for clk_period;
--        --i_rstn <= '1';
--	i_pc <= x"1A1A1A1A";
--        -- Test Case 1: Simple instruction
--        i_instr <= x"00000013"; -- ADDI x0, x0, 0
--        i_rd_addr <= "00001";
--        i_rd_data <= x"00000001";
--        i_wb <= '1';
--        wait for clk_period;
--
--        -- Assert outputs for the first test case
--        assert o_branch = '0' report "Test Case 1 Failed: o_branch is incorrect" severity error;
--        assert o_jump = '0' report "Test Case 1 Failed: o_jump is incorrect" severity error;
--        assert o_alu_op = "000" report "Test Case 1 Failed: o_alu_op is incorrect" severity error;
--	assert o_pc = i_pc report "Test Case 1 Failed : o_pc incorrect" severity error;
--
--        -- Test Case 2: Branch instruction
--        i_instr <= x"00012063"; -- BEQ x2, x0, 4
--        i_wb <= '0';
--        wait for clk_period;
--
--        -- Assert outputs for the second test case
--        assert o_branch = '1' report "Test Case 2 Failed: o_branch is incorrect" severity error;
--        assert o_jump = '0' report "Test Case 2 Failed: o_jump is incorrect" severity error;
--
--        -- Test Case 3: Flush
--        i_flush <= '1';
--        wait for clk_period;
--
--        -- Assert that outputs are cleared on flush
--        assert o_rs1_data =  "00000000000000000000000000000000" report "Test Case 3 Failed: o_rs1_data not flushed" severity error;
--        assert o_rs2_data =  "00000000000000000000000000000000"  report "Test Case 3 Failed: o_rs2_data not flushed" severity error;
--
--        -- End simulation
--        wait for clk_period;
--        assert false report "Simulation Finished Successfully" severity note;
--        --wait;
--
--
--    -- Test Case 1: Simple instruction
--    i_instr <= x"0010A013"; -- ADDI x0, x0, 0
--    i_rd_addr <= "00001";
--    i_rd_data <= x"00000001";
--    i_wb <= '1';
--	i_pc <= x"00000000";
--    wait for clk_period;
--Case 1 Failed: o_wb_out is incorrect" severity error;
--    assert o_arith = '1' report "Test Case 1 Failed: o_arith is incorrect" severity error;
--    assert o_sign = '0' report "Test Case 1 Failed: o_sign is incorrect" severity error;
--    assert o_src_imm = '1' report "Test Case 1 Failed: o_src_imm is incorrect" severity error;
--    assert o_alu_op = "000" report "Test Case 1 Failed: o_alu_op is incorrect" severity error;
--    assert o_imm = x"00000000" report "Test Case 1 Failed: o_imm is incorrect" severity error;
--
--    -- Test Case 2: Branch instruction
--    --i_instr <= x"00012063"; -- BEQ x2, x0, 4
--	i_instr <= x"0010A063";    
--i_wb <= '0';
--    wait for clk_period;
--
--    -- Assert outputs for the second test case
--    assert o_branch = '1' report "Test Case 2 Failed: o_branch is incorrect" severity error;
--    assert o_jump = '0' report "Test Case 2 Failed: o_jump is incorrect" severity error;
--    assert o_rw = '0' report "Test Case 2 Failed: o_rw is incorrect" severity error;
--    assert o_wb_out = '0' report "Test Case 2 Failed: o_wb_out is incorrect" severity error;
--    assert o_arith = '0' report "Test Case 2 Failed: o_arith is incorrect" severity error;
--    assert o_sign = '0' report "Test Case 2 Failed: o_sign is incorrect" severity error;
--    assert o_src_imm = '0' report "Test Case 2 Failed: o_src_imm is incorrect" severity error;
--    assert o_alu_op = "000" report "Test Case 2 Failed: o_alu_op is incorrect" severity error;
--    assert o_imm = x"00000000" report "Test Case 2 Failed: o_imm is incorrect" severity error;
--
--    -- Test Case 3: Flush
--    i_flush <= '1';
--    wait for clk_period;
--
--    -- Assert that outputs are cleared on flush
--    --assert o_rs1_data = x"00000000" report "Test Case 3 Failed: o_rs1_data not flushed" severity error;
--    --assert o_rs2_data = x"00000000" report "Test Case 3 Failed: o_rs2_data not flushed" severity error;
--    assert o_branch = '0' report "Test Case 3 Failed: o_branch not flushed" severity error;
--    assert o_jump = '0' report "Test Case 3 Failed: o_jump not flushed" severity error;
--    assert o_rw = '0' report "Test Case 3 Failed: o_rw not flushed" severity error;
--    assert o_wb_out = '0' report "Test Case 3 Failed: o_wb_out not flushed" severity error;
--    assert o_arith = '0' report "Test Case 3 Failed: o_arith not flushed" severity error;
--    assert o_sign = '0' report "Test Case 3 Failed: o_sign not flushed" severity error;
--    assert o_src_imm = '0' report "Test Case 3 Failed: o_src_imm not flushed" severity error;
--    assert o_alu_op = "000" report "Test Case 3 Failed: o_alu_op not flushed" severity error;
--    assert o_imm = x"00000000" report "Test Case 3 Failed: o_imm not flushed" severity error;
--
--
--
--	i_flush <= '0';
--
--
--i_instr <= x"F0F06013"; -- ORI x1, x0, 0xF0F (0x0000F0F0)  
--   wait for clk_period; 
---- Assert outputs for ORI instruction
--assert o_branch = '0' report "Test Case 4 Failed: o_branch is incorrect" severity error;
--assert o_jump = '0' report "Test Case 4 Failed: o_jump is incorrect" severity error;
--assert o_rw = '1' report "Test Case 4 Failed: o_rw is incorrect" severity error;
--assert o_wb_out = '1' report "Test Case 4 Failed: o_wb_out is incorrect" severity error;
--assert o_arith = '1' report "Test Case 4 Failed: o_arith is incorrect" severity error;
--assert o_sign = '0' report "Test Case 4 Failed: o_sign is incorrect" severity error;
--assert o_src_imm = '1' report "Test Case 4 Failed: o_src_imm is incorrect" severity error;
--assert o_alu_op = "010" report "Test Case 4 Failed: o_alu_op is incorrect" severity error;
--assert o_imm = x"00000F0F" report "Test Case 4 Failed: o_imm is incorrect" severity error;
--
--
---- Test Case 5: ANDI instruction (I-Type)
--i_instr <= x"F1F07113"; -- ANDI x0, x0, 0xF1F
--i_wb <= '1';
--wait for clk_period;
--
---- Assert outputs for ANDI instruction
--assert o_branch = '0' report "Test Case 5 Failed: o_branch is incorrect" severity error;
--assert o_jump = '0' report "Test Case 5 Failed: o_jump is incorrect" severity error;
--assert o_rw = '1' report "Test Case 5 Failed: o_rw is incorrect" severity error;
--assert o_wb_out = '1' report "Test Case 5 Failed: o_wb_out is incorrect" severity error;
--assert o_arith = '1' report "Test Case 5 Failed: o_arith is incorrect" severity error;
--assert o_sign = '0' report "Test Case 5 Failed: o_sign is incorrect" severity error;
--assert o_src_imm = '1' report "Test Case 5 Failed: o_src_imm is incorrect" severity error;
--assert o_alu_op = "011" report "Test Case 5 Failed: o_alu_op is incorrect" severity error;
--assert o_imm = x"00000F1F" report "Test Case 5 Failed: o_imm is incorrect" severity error;
--
---- Test Case 6: JALR instruction (I-Type)
--i_instr <= x"000000E7"; -- JALR x1, x0, 0x0
--i_wb <= '1';
--wait for clk_period;
--
---- Assert outputs for JALR instruction
--assert o_branch = '0' report "Test Case 6 Failed: o_branch is incorrect" severity error;
--assert o_jump = '1' report "Test Case 6 Failed: o_jump is incorrect" severity error;
--assert o_rw = '0' report "Test Case 6 Failed: o_rw is incorrect" severity error;
--assert o_wb_out = '1' report "Test Case 6 Failed: o_wb_out is incorrect" severity error;
--assert o_arith = '0' report "Test Case 6 Failed: o_arith is incorrect" severity error;
--assert o_sign = '0' report "Test Case 6 Failed: o_sign is incorrect" severity error;
--assert o_src_imm = '1' report "Test Case 6 Failed: o_src_imm is incorrect" severity error;
--assert o_alu_op = "000" report "Test Case 6 Failed: o_alu_op is incorrect" severity error;
--assert o_imm = x"00000000" report "Test Case 6 Failed: o_imm is incorrect" severity error;
--
---- Test Case 7: JAL instruction (J-Type)
--i_instr <= x"000000EF"; -- JAL x1, 0x0
--i_wb <= '1';
--wait for clk_period;
--
---- Assert outputs for JAL instruction
--assert o_branch = '0' report "Test Case 7 Failed: o_branch is incorrect" severity error;
--assert o_jump = '1' report "Test Case 7 Failed: o_jump is incorrect" severity error;
--assert o_rw = '0' report "Test Case 7 Failed: o_rw is incorrect" severity error;
--assert o_wb_out = '1' report "Test Case 7 Failed: o_wb_out is incorrect" severity error;
--assert o_arith = '0' report "Test Case 7 Failed: o_arith is incorrect" severity error;
--assert o_sign = '0' report "Test Case 7 Failed: o_sign is incorrect" severity error;
--assert o_src_imm = '0' report "Test Case 7 Failed: o_src_imm is incorrect" severity error;
--assert o_alu_op = "000" report "Test Case 7 Failed: o_alu_op is incorrect" severity error;
--assert o_imm = x"00000000" report "Test Case 7 Failed: o_imm is incorrect" severity error;
--
---- Test Case 8: LUI instruction (U-Type)
--i_instr <= x"12345037"; -- LUI x1, 0x12345
--i_wb <= '1';
--wait for clk_period;
--
---- Assert outputs for LUI instruction
--assert o_branch = '0' report "Test Case 8 Failed: o_branch is incorrect" severity error;
--assert o_jump = '0' report "Test Case 8 Failed: o_jump is incorrect" severity error;
--assert o_rw = '0' report "Test Case 8 Failed: o_rw is incorrect" severity error;
--assert o_wb_out = '1' report "Test Case 8 Failed: o_wb_out is incorrect" severity error;
--assert o_arith = '0' report "Test Case 8 Failed: o_arith is incorrect" severity error;
--assert o_sign = '0' report "Test Case 8 Failed: o_sign is incorrect" severity error;
--assert o_src_imm = '0' report "Test Case 8 Failed: o_src_imm is incorrect" severity error;
--assert o_alu_op = "000" report "Test Case 8 Failed: o_alu_op is incorrect" severity error;
--assert o_imm = x"00012345" report "Test Case 8 Failed: o_imm is incorrect" severity error;
--
--
--
--
--
--
--    -- End simulation
--    wait for clk_period;
--    assert false report "Simulation Finished Successfully" severity note;
--    wait;
--
--
--
--
--
--
--    end process;
--end architecture;
--

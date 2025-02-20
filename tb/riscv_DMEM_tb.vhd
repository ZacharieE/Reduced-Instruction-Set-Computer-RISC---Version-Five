library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity d_mem_tb is
end entity d_mem_tb;

architecture tb of d_mem_tb is
    -- Clock and Test Signals
    signal tb_clk         : std_logic := '0';
    signal tb_store_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_rw          : std_logic := '0';
    signal tb_we          : std_logic := '0';
    signal tb_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_load_data   : std_logic_vector(31 downto 0);

    constant PERIOD : time := 20 ns;

    -- Instantiate the D-MEM module
    component d_mem is
        port (
            i_clk        : in  std_logic;
            i_store_data : in  std_logic_vector(31 downto 0);
            i_rw         : in  std_logic;
            i_we         : in  std_logic;
            i_alu_result : in  std_logic_vector(31 downto 0);
            o_load_data  : out std_logic_vector(31 downto 0)
        );
    end component;

begin
    -- Instantiate DUT
    dut: d_mem
        port map (
            i_clk        => tb_clk,
            i_store_data => tb_store_data,
            i_rw         => tb_rw,
            i_we         => tb_we,
            i_alu_result => tb_alu_result,
            o_load_data  => tb_load_data
        );

    -- Clock Process
    tb_clk <= not tb_clk after PERIOD / 2;

    -- Test Process
    test_process: process
    begin
        -- Test Case 1: Write to address 0x01
        tb_we <= '1';          -- Enable write
        tb_rw <= '1';          -- Write mode
        tb_alu_result <= x"00000001"; -- Address = 0x01
        tb_store_data <= x"12345678"; -- Data = 0x12345678
        wait for PERIOD;

        assert tb_load_data = "00000000000000000000000000000000"
        report "Test Case 1 failed: Load data should remain unchanged during write"
        severity error;

        -- Test Case 2: Read from address 0x01
        tb_we <= '0';          -- Disable write
        tb_rw <= '0';          -- Read mode
        tb_alu_result <= x"00000001"; -- Address = 0x01
        wait for PERIOD;

        assert tb_load_data = x"12345678"
        report "Test Case 2 failed: Load data mismatch when reading from address 0x01"
        severity error;

        -- Test Case 3: Write to address 0x02
        tb_we <= '1';          -- Enable write
        tb_rw <= '1';          -- Write mode
        tb_alu_result <= x"00000002"; -- Address = 0x02
        tb_store_data <= x"AABBCCDD"; -- Data = 0xAABBCCDD
        wait for PERIOD;

        assert tb_load_data = x"12345678"
        report "Test Case 3 failed: Load data should not change during write"
        severity error;

        -- Test Case 4: Read from address 0x02
        tb_we <= '0';          -- Disable write
        tb_rw <= '0';          -- Read mode
        tb_alu_result <= x"00000002"; -- Address = 0x02
        wait for PERIOD;

        assert tb_load_data = x"AABBCCDD"
        report "Test Case 4 failed: Load data mismatch when reading from address 0x02"
        severity error;

        -- Test Case 5: Read from an uninitialized address (0x03)
        tb_we <= '0';          -- Disable write
        tb_rw <= '0';          -- Read mode
        tb_alu_result <= x"00000003"; -- Address = 0x03
        wait for PERIOD;

        assert tb_load_data = x"00000000"
        report "Test Case 5 failed: Load data should be 0 when reading from an uninitialized address"
        severity error;

        -- End of Simulation
        report "All test cases passed!" severity note;
        wait;
    end process;

end architecture tb;


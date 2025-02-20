library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode_tb is
end entity decode_tb;

architecture beh of decode_tb is

  -- Component declaration for the decode unit
  component riscv_decode is
    Port (
      i_opcode  : in std_logic_vector(6 downto 0);
      i_funct3  : in std_logic_vector(2 downto 0);
      i_funct7  : in std_logic_vector(6 downto 0);
      i_instr   : in std_logic_vector(31 downto 0);
      
      o_branch  : out std_logic;
      o_jump    : out std_logic;
      o_rw      : out std_logic;
      o_wb      : out std_logic;
      o_arith   : out std_logic;
      o_sign    : out std_logic;
      o_src_imm : out std_logic;
      o_alu_op  : out std_logic_vector(2 downto 0);
      o_imm     : out std_logic_vector(31 downto 0)
    );
  end component;

  -- Signals to connect to the decode module
  signal i_opcode  : std_logic_vector(6 downto 0) := (others => '0');
  signal i_funct3  : std_logic_vector(2 downto 0) := (others => '0');
  signal i_funct7  : std_logic_vector(6 downto 0) := (others => '0');
  signal i_instr   : std_logic_vector(31 downto 0) := (others => '0');

  signal o_branch  : std_logic;
  signal o_jump    : std_logic;
  signal o_rw      : std_logic;
  signal o_wb      : std_logic;
  signal o_arith   : std_logic;
  signal o_sign    : std_logic;
  signal o_src_imm : std_logic;
  signal o_alu_op  : std_logic_vector(2 downto 0);
  signal o_imm     : std_logic_vector(31 downto 0);

begin
  -- Instantiate the decode module
  uut: riscv_decode
    port map (
      i_opcode  => i_opcode,
      i_funct3  => i_funct3,
      i_funct7  => i_funct7,
      i_instr   => i_instr,
      o_branch  => o_branch,
      o_jump    => o_jump,
      o_rw      => o_rw,
      o_wb      => o_wb,
      o_arith   => o_arith,
      o_sign    => o_sign,
      o_src_imm => o_src_imm,
      o_alu_op  => o_alu_op,
      o_imm     => o_imm
    );

  -- Stimulus process
  process
  begin
    -- Test Case 1: LUI
    i_opcode <= "0110111";
    i_instr <= "00000000000000000001000000000000";  -- Immediate value for LUI
    wait for 10 ns;
    report "LUI Test - o_wb: " & std_logic'image(o_wb) &
           ", o_imm: " & integer'image(to_integer(signed(o_imm)));

    -- Test Case 2: JAL
    i_opcode <= "1101111";
    i_instr <= "00000000000000000000000000001001";  -- Immediate value for JAL
    wait for 10 ns;
    report "JAL Test - o_jump: " & std_logic'image(o_jump) &
           ", o_imm: " & integer'image(to_integer(signed(o_imm)));

    -- Test Case 3: BEQ
    i_opcode <= "1100011";
    i_funct3 <= "000";
    i_instr <= "00000000000000000000000001100001";  -- Immediate value for BEQ
    wait for 10 ns;
    report "BEQ Test - o_branch: " & std_logic'image(o_branch) &
           ", o_imm: " & integer'image(to_integer(signed(o_imm)));

    -- Test Case 4: LW
    i_opcode <= "0000011";
    i_funct3 <= "010";
    i_instr <= "00000000000000000000000010000011";  -- Immediate value for LW
    wait for 10 ns;
    report "LW Test - o_rw: " & std_logic'image(o_rw) &
           ", o_imm: " & integer'image(to_integer(signed(o_imm)));

    -- Test Case 5: SW
    i_opcode <= "0100011";
    i_funct3 <= "010";
    i_instr <= "00000000000000000000100010100011";  -- Immediate value for SW
    wait for 10 ns;
    report "SW Test - o_rw: " & std_logic'image(o_rw) &
           ", o_imm: " & integer'image(to_integer(signed(o_imm)));

    -- Test Case 6: R-type ALU (ADD)
    i_opcode <= "0110011";                            -- R-type opcode
    i_funct3 <= "000";                                -- ADD funct3
    i_funct7 <= "0000000";                            -- ADD funct7
    i_instr <= "00000000001000001000000000110011";    -- Example ADD instruction (ADD x3, x1, x2)
    wait for 10 ns;
	report "R-Type ADD Test - o_arith: " & std_logic'image(o_arith) &
       ", o_alu_op: " & integer'image(to_integer(unsigned(o_alu_op)));

    wait;
  end process;

end architecture beh;


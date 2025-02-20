

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_decode is
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
    o_shamt   : out std_logic_vector(4 downto 0);	

    o_imm     : out std_logic_vector(31 downto 0)
  );
end entity riscv_decode;

architecture beh of riscv_decode is


signal o_branch_buffer : std_logic;
signal o_jump_buffer : std_logic;
signal o_rw_buffer : std_logic:='0'; 
signal o_wb_buffer : std_logic:='0'; 
signal o_arith_buffer : std_logic:='0'; 
signal o_sign_buffer : std_logic:='0'; 
signal o_src_imm_buffer : std_logic:='0'; 
signal o_alu_op_buffer  : std_logic_vector(2 downto 0):=(others => '0');
signal o_imm_buffer : std_logic_vector(31 downto 0):=(others => '0'); 
signal shamt				: std_logic_vector(5-1 downto 0);


begin
  o_branch  <= o_branch_buffer ;
  o_jump    <= o_jump_buffer;
  o_rw      <= o_rw_buffer;
  o_wb      <= o_wb_buffer;
  o_arith   <= o_arith_buffer;
  o_sign    <= o_sign_buffer ;
  o_src_imm <= o_src_imm_buffer;
  o_alu_op  <= o_alu_op_buffer ;
  o_imm     <= o_imm_buffer ;

  process(i_opcode, i_funct3, i_funct7, i_instr)
  begin

--o_branch  <= o_branch_buffer ;
	
	o_branch_buffer <= '0';
        o_jump_buffer <= '0';
        o_rw_buffer <= '0';
        o_wb_buffer <= '0';
        o_arith_buffer <= '0';
        o_sign_buffer <= '0';
        o_imm_buffer <= (others => '0');
        o_src_imm_buffer <= '0';
        o_alu_op_buffer <= "000";  -- Default ALU operation (e.g., NOP)



    case i_opcode is
      when "0110111" => --LUI
        o_wb_buffer <= '1';
        o_imm_buffer <= std_logic_vector(signed( "000000000000" & i_instr(31 downto 12)) );
      when "1101111" => --JAL
        o_jump_buffer <= '1';
        o_wb_buffer <= '1'; 
        o_imm_buffer <= std_logic_vector(signed(  "000000000000" & i_instr(31) & i_instr(19 downto 12) & i_instr(20) & i_instr(30 downto 21) ));
      when "1100111" => --JALR
        o_jump_buffer <= '1';
        o_wb_buffer <='1';
        o_src_imm_buffer <= '1'; 
        o_imm_buffer <= std_logic_vector(signed(   "00000000000000000000" & i_instr(31 downto 20) ));

      when "1100011" =>  -- BEQ (Branch Equal)
      o_arith_buffer <= '1';
       o_wb_buffer <= '0';
       o_branch_buffer <= '1';
    	-- o_imm_buffer <= std_logic_vector(signed( "00000000000000000000" & i_instr(31) & i_instr(7) & i_instr(30 downto 25) & i_instr(11 downto 8)));

       o_imm_buffer(31 downto 12) <= (others => i_instr(31));
       o_imm_buffer(11 downto 0) <= i_instr(7)&i_instr(30 downto 25)&i_instr(11 downto 8)&'0';
     
      when "0000011" =>  -- LW
        o_rw_buffer <= '1';
        o_wb_buffer <= '1';
        o_src_imm_buffer <= '1';
        o_imm_buffer <= std_logic_vector(signed( "00000000000000000000" & i_instr(31 downto 20)  ));

      when "0100011" =>  -- SW               
        o_rw_buffer <= '1';
        o_imm_buffer <= std_logic_vector(signed( "00000000000000000000" & i_instr(31) & i_instr(30 downto 25) & i_instr(11 downto 7) ));

      when "0010011" =>  -- I-type ALU (e.g., ADDI, ANDI)
        o_arith_buffer <= '1';
        o_wb_buffer <= '1';
        o_src_imm_buffer <= '1';
	o_rw_buffer <= '1';
        o_imm_buffer <= std_logic_vector(signed( "00000000000000000000" & i_instr(31 downto 20)));

        -- ALU operation based on funct3
        case i_funct3 is
          when "000" => o_alu_op_buffer <= "000"; -- ADDI
          when "110" => o_alu_op_buffer <= "010"; -- ORI
          when "111" => o_alu_op_buffer <= "011"; -- ANDI
          when others => o_alu_op_buffer <= (others => '0');
        end case;

      when "0110011" =>  -- R-type ALU (e.g., ADD, SUB, AND)
        o_arith_buffer <= '1';
        o_wb_buffer <= '1';

        -- ALU operation based on funct3 and funct7
        case i_funct3 is
          when "000" =>
            if i_funct7 = "0000000" then
              o_alu_op_buffer <= "000"; -- ADD
            elsif i_funct7 = "0100000" then
              o_alu_op_buffer <= "001"; -- SUB
            end if;
          when "111" => o_alu_op_buffer <= "011"; -- AND
          when "110" => o_alu_op_buffer <= "010"; -- OR
          when others => o_alu_op_buffer <= (others => '0');
        end case;

      when others =>
        -- Default for unsupported instructions
        o_alu_op_buffer <= (others => '0');
    end case;
  end process;



end architecture beh;
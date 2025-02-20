
library ieee; 
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library std;
use     std.textio.all;                                                      
use     std.env.all;

library work;
use     work.all;

entity riscv_core_tb is 
end riscv_core_tb;

architecture tb of riscv_core_tb is
  
signal	clk		: std_logic := '0';
signal	rstn		: std_logic := '0';

signal imem_en : std_logic;
signal imem_addr : std_logic_vector(31 downto 0);
signal imem_read : std_logic_vector(31 downto 0);

signal dmem_en : std_logic;
signal dmem_we : std_logic;
signal dmem_addr : std_logic_vector(31 downto 0);
signal dmem_read : std_logic_vector(31 downto 0);
signal dmem_write : std_logic_vector(31 downto 0);

signal imem_addr_div4 : std_logic_vector(31 downto 0);
signal dmem_addr_div4 : std_logic_vector(31 downto 0); 

--test bench signals
   
signal tb_fetch_pc, tb_decode_instruction	: std_logic_vector(31 downto 0); 
signal tb_execute_rs1_data, tb_execute_rs2_data, tb_execute_pc	 : std_logic_vector(31 downto 0);
signal tb_decode_branch, tb_decode_jump,tb_write_back_rw, tb_memory_we,tb_decode_arith, tb_decode_sign: std_logic;
signal tb_decode_alu_op : std_logic_vector(2 downto 0);
signal tb_decode_rs1_addr, tb_decode_rs2_addr : std_logic_vector(4 downto 0);
signal tb_execute_pc_target,tb_execute_alu_result , tb_memory_alu_result: std_logic_vector(31 downto 0); 
signal tb_execute_pc_transfert, tb_execute_src_imm : std_logic;
signal tb_write_back_wb : std_logic;
signal tb_write_back_rd_addr : std_logic_vector(4 downto 0);
signal tb_write_back_rd_data : std_logic_vector(31 downto 0);
signal tb_memory_store_data : std_logic_vector(31 downto 0);
signal tb_decode_imm : std_logic_vector(31 downto 0);
signal tb_execute_imm : std_logic_vector(31 downto 0);
signal tb_write_back_load_data : std_logic_vector(31 downto 0);
signal tb_write_back_alu_result : std_logic_vector(31 downto 0);

constant PERIOD   : time := 100 ns;
constant TWO	: std_logic_vector(1 downto 0) := "10";

begin

MEM0 : entity work.dpm 
  generic map (
    WIDTH => 32,
    DEPTH => 9,
    RESET => 16#00000000#,
    INIT  => "riscv_basic.mem")
  port map (
    -- Port A
    i_a_clk   => clk,          -- Clock
    i_a_rstn  => rstn,         -- Reset Address
    i_a_en    => imem_en,            -- Port enable
    i_a_we    => '0',            -- Write enable
    i_a_addr  => imem_addr_div4(8 downto 0),     	 -- Address port			
    i_a_write => X"00000000",      	 -- Data write port
    o_a_read  => imem_read,-- Data read port
    -- Port B
    i_b_clk   => clk,          -- Clock
    i_b_rstn  => rstn,           -- Reset Address
    i_b_en    => dmem_en,            -- Port enable
    i_b_we    => dmem_we,                -- Write enable
    i_b_addr  => dmem_addr_div4(8 downto 0),      -- Address port  --Mettre adresse initiale a 1000 kb
    i_b_write => dmem_write,     -- Data write port
    o_b_read  => dmem_read    	 -- Data read port
);


imem_addr_div4 <= imem_addr srl 2;     --the memory is only word adressable and not byte so divide the instruction adress by 4
dmem_addr_div4 <= dmem_addr srl 2;  


DUT : entity work.riscv_core 
port map(
	i_rstn => rstn,
	i_clk  => clk,
	o_imem_en => imem_en,
	o_imem_addr => imem_addr,
	i_imem_read => imem_read,
	o_dmem_en   => dmem_en,
	o_dmem_we   => dmem_we,
	o_dmem_addr => dmem_addr,
	i_dmem_read => dmem_read,
	o_dmem_write=> dmem_write,

	i_scan_en => '0',
	i_test_mode => '0',
	i_tdi => '0',
	o_tdo => open,
	
	--Test Bench
	tb_decode_instruction => tb_decode_instruction,
  	tb_fetch_pc => tb_fetch_pc, 
 
	tb_execute_rs1_data=>tb_execute_rs1_data, 
	tb_execute_rs2_data=>tb_execute_rs2_data ,
	tb_execute_pc=> tb_execute_pc,
	tb_decode_branch => tb_decode_branch,
	tb_decode_jump => tb_decode_jump,
	tb_write_back_rw => tb_write_back_rw,
	tb_memory_we => tb_memory_we,
	tb_decode_arith => tb_decode_arith,
	tb_decode_sign => tb_decode_sign,
	tb_decode_alu_op => tb_decode_alu_op,
    tb_decode_imm => tb_decode_imm,
	
	tb_execute_pc_target =>  tb_execute_pc_target,
	tb_execute_alu_result => tb_execute_alu_result,
	tb_memory_alu_result => tb_memory_alu_result,
	tb_execute_imm => tb_execute_imm,
	
	tb_write_back_wb => tb_write_back_wb,
	tb_write_back_rd_addr => tb_write_back_rd_addr,
	tb_write_back_rd_data => tb_write_back_rd_data,		 
	tb_write_back_load_data => tb_write_back_load_data,
	tb_write_back_alu_result => tb_write_back_alu_result,
	
	tb_decode_rs1_addr => tb_decode_rs1_addr,
	tb_decode_rs2_addr => tb_decode_rs2_addr,
	
	tb_memory_store_data => tb_memory_store_data,
	tb_execute_pc_transfert => tb_execute_pc_transfert,
	tb_execute_src_imm => tb_execute_src_imm
);
	
clk <= not clk after PERIOD/2 ;
rstn <= '1' after 2*PERIOD;
  
end architecture tb;




--																									 -------------------------------------------------------------------------------
--
-- Import necessary libraries for logic operations and data handling
library ieee;
use ieee.std_logic_1164.all; -- Provides definitions for basic logic types
use ieee.numeric_std.all;    -- Provides numeric operations on vectors
use work.riscv_pkg.all;      -- Custom package for RISC-V core definitions

-- Entity declaration for the RISC-V core
entity riscv_core is
  port ( 
    -- Global control signals
    i_rstn         : in  std_logic;  -- Active-low reset signal
    i_clk          : in  std_logic;  -- Clock signal

    -- Instruction memory interface
    i_imem_read    : in  std_logic_vector(XLEN-1 downto 0); -- Instruction data input
    i_dmem_read    : in  std_logic_vector(XLEN-1 downto 0); -- Data memory read input
    o_imem_en      : out std_logic;                        -- Instruction memory enable signal
    o_imem_addr    : out std_logic_vector(XLEN-1 downto 0); -- Instruction memory address
    o_dmem_en      : out std_logic;                        -- Data memory enable signal
    o_dmem_we      : out std_logic;                        -- Data memory write enable signal
    o_dmem_addr    : out std_logic_vector(XLEN-1 downto 0); -- Data memory address
    o_dmem_write   : out std_logic_vector(XLEN-1 downto 0); -- Data to write to memory

    -- Design for Testability (DFT) interface
    i_scan_en      : in  std_logic;  -- Scan enable signal for DFT
    i_test_mode    : in  std_logic;  -- Test mode signal
    i_tdi          : in  std_logic;  -- Test data input
    o_tdo          : out std_logic;  -- Test data output

    -- Testbench signals for debugging
    tb_decode_instruction : out std_logic_vector(XLEN-1 downto 0); -- Decoded instruction output
    tb_fetch_pc           : out std_logic_vector(XLEN-1 downto 0); -- Program counter from fetch stage

    -- Execute stage outputs for testbench
    tb_execute_rs1_data, tb_execute_rs2_data, tb_execute_pc: out std_logic_vector(XLEN-1 downto 0);
    tb_decode_branch, tb_decode_jump, tb_write_back_rw, tb_memory_we, tb_decode_arith, tb_decode_sign: out std_logic;
    tb_decode_alu_op    : out std_logic_vector(ALUOP_WIDTH-1 downto 0); -- ALU operation code
    tb_decode_imm       : out std_logic_vector(XLEN-1 downto 0);       -- Immediate value

    -- Other testbench outputs
    tb_execute_pc_target, tb_execute_alu_result, tb_memory_alu_result, tb_execute_imm: out std_logic_vector(XLEN-1 downto 0);
    tb_execute_pc_transfert, tb_execute_src_imm : out std_logic;
    tb_write_back_wb        : out std_logic;                           -- Write-back enable signal
    tb_write_back_rd_addr   : out std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    tb_write_back_rd_data   : out std_logic_vector(XLEN-1 downto 0);   -- Data to write back to register
    tb_write_back_load_data : out std_logic_vector(XLEN-1 downto 0);   -- Data loaded from memory
    tb_write_back_alu_result: out std_logic_vector(XLEN-1 downto 0);   -- ALU result to write back
    tb_decode_rs1_addr, tb_decode_rs2_addr: out std_logic_vector(REG_WIDTH-1 downto 0); -- Source register addresses
    tb_memory_store_data    : out std_logic_vector(XLEN-1 downto 0)    -- Data to store in memory
  ); 
end entity riscv_core;

-- Architecture declaration for the RISC-V core
architecture beh of riscv_core is 

-- Fetch stage component
component fetch is
  port (
    -- Input signals
    i_target       : in  std_logic_vector(XLEN-1 downto 0); -- Target address for jumps/branches
    i_imem_read    : in  std_logic_vector(XLEN-1 downto 0); -- Instruction data input
    i_transfert    : in  std_logic;                        -- Transfer control signal
    i_stall        : in  std_logic;                        -- Stall signal
    i_flush        : in  std_logic;                        -- Flush signal
    i_rstn         : in  std_logic;                        -- Reset signal
    i_clk          : in  std_logic;                        -- Clock signal

    -- Output signals
    o_imem_en      : out std_logic;                        -- Instruction memory enable
    o_imem_addr    : out std_logic_vector(XLEN-1 downto 0); -- Instruction memory address
    o_pc           : out std_logic_vector(XLEN-1 downto 0); -- Program counter
    o_instruction  : out std_logic_vector(XLEN-1 downto 0)  -- Fetched instruction
  );
end component fetch;

-- Decode stage component
component decode is
  port (
    -- Input signals
    i_instr        : in  std_logic_vector(XLEN-1 downto 0); -- Instruction input
    i_rd_data      : in  std_logic_vector(XLEN-1 downto 0); -- Destination register data
    i_rd_addr      : in  std_logic_vector(REG_WIDTH -1 downto 0); -- Destination register address
    i_wb           : in  std_logic;                        -- Write-back signal
    i_pc           : in  std_logic_vector(XLEN-1 downto 0); -- Program counter
    i_flush        : in  std_logic;                        -- Flush signal
    i_rstn         : in  std_logic;                        -- Reset signal
    i_clk          : in  std_logic;                        -- Clock signal

    -- Output signals
    o_rs1_data     : out std_logic_vector(XLEN-1 downto 0); -- Source register 1 data
    o_rs2_data     : out std_logic_vector(XLEN-1 downto 0); -- Source register 2 data
    o_branch       : out std_logic;                        -- Branch control signal
    o_jump         : out std_logic;                        -- Jump control signal
    o_rw           : out std_logic;                        -- Read/Write signal for memory
    o_we           : out std_logic;                        -- Write enable for memory
    o_wb           : out std_logic;                        -- Write-back enable
    o_imm          : out std_logic_vector(XLEN-1 downto 0); -- Immediate value
    o_src_imm      : out std_logic;                        -- Source immediate flag
    o_rd_addr      : out std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    o_pc           : out std_logic_vector(XLEN-1 downto 0); -- Program counter
    o_arith        : out std_logic;                        -- Arithmetic operation flag
    o_sign         : out std_logic;                        -- Sign extension flag
    o_shamt        : out std_logic_vector(4 downto 0);     -- Shift amount for ALU
    o_alu_op       : out std_logic_vector(ALUOP_WIDTH-1 downto 0); -- ALU operation code

    -- Testbench outputs
    tb_rs1_addr    : out std_logic_vector(REG_WIDTH-1 downto 0); -- Source register 1 address
    tb_rs2_addr    : out std_logic_vector(REG_WIDTH-1 downto 0); -- Source register 2 address
    tb_alu_op      : out std_logic_vector(ALUOP_WIDTH-1 downto 0); -- ALU operation code
    tb_arith       : out std_logic;                        -- Arithmetic flag
    tb_sign        : out std_logic;                        -- Sign extension flag
    tb_decode_branch: out std_logic;                       -- Branch flag for testbench
    tb_decode_jump : out std_logic;                        -- Jump flag for testbench
    tb_imm         : out std_logic_vector(XLEN-1 downto 0) -- Immediate value for testbench
  ); 
end component decode;
-- Execute stage component
component execute is
  port (
    -- Input signals
    i_jump          : in  std_logic;                        -- Jump control signal
    i_branch        : in  std_logic;                        -- Branch control signal
    i_src_imm       : in  std_logic;                        -- Use immediate value as source
    i_rw            : in  std_logic;                        -- Memory read/write signal
    i_we            : in  std_logic;                        -- Memory write enable
    i_wb            : in  std_logic;                        -- Write-back enable
    i_rs1_data      : in  std_logic_vector(XLEN-1 downto 0); -- Source register 1 data
    i_rs2_data      : in  std_logic_vector(XLEN-1 downto 0); -- Source register 2 data
    i_imm           : in  std_logic_vector(XLEN-1 downto 0); -- Immediate value
    i_pc            : in  std_logic_vector(XLEN-1 downto 0); -- Program counter
    i_rd_addr       : in  std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    i_stall         : in  std_logic;                        -- Stall signal
    i_rstn          : in  std_logic;                        -- Reset signal
    i_clk           : in  std_logic;                        -- Clock signal
    i_shamt         : in  std_logic_vector(SHAMT_WIDTH-1 downto 0); -- ALU shift amount
    i_alu_op        : in  std_logic_vector(ALUOP_WIDTH-1 downto 0); -- ALU operation code
    i_arith         : in  std_logic;                        -- Arithmetic operation flag
    i_sign          : in  std_logic;                        -- Sign extension flag

    -- Output signals
    o_pc_transfert  : out std_logic;                        -- Program counter transfer signal
    o_alu_result    : out std_logic_vector(XLEN-1 downto 0); -- ALU result
    o_store_data    : out std_logic_vector(XLEN-1 downto 0); -- Data to store in memory
    o_pc_target     : out std_logic_vector(XLEN-1 downto 0); -- Branch/jump target program counter
    o_rw            : out std_logic;                        -- Memory read/write signal
    o_we            : out std_logic;                        -- Memory write enable
    o_wb            : out std_logic;                        -- Write-back enable
    o_rd_addr       : out std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address

    -- Testbench outputs
    tb_execute_alu_result : out std_logic_vector(XLEN-1 downto 0); -- ALU result for testbench
    tb_pc_transfert       : out std_logic;                        -- Program counter transfer signal
    tb_pc_target          : out std_logic_vector(XLEN-1 downto 0); -- Branch/jump target PC
    tb_imm                : out std_logic_vector(XLEN-1 downto 0) -- Immediate value for testbench
  );
end component execute;

-- Memory access stage component
component memory_access is
  port (
    -- Input signals
    i_store_data    : in  std_logic_vector(XLEN-1 downto 0); -- Data to store in memory
    i_alu_result    : in  std_logic_vector(XLEN-1 downto 0); -- ALU result
    i_rd_addr       : in  std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    i_rw            : in  std_logic;                        -- Memory read/write signal
    i_wb            : in  std_logic;                        -- Write-back enable
    i_we            : in  std_logic;                        -- Memory write enable
    i_rstn          : in  std_logic;                        -- Reset signal
    i_clk           : in  std_logic;                        -- Clock signal

    -- Output signals
    o_store_data    : out std_logic_vector(XLEN-1 downto 0); -- Stored data in memory
    o_alu_result    : out std_logic_vector(XLEN-1 downto 0); -- ALU result
    o_wb            : out std_logic;                        -- Write-back enable
    o_we            : out std_logic;                        -- Memory write enable
    o_rw            : out std_logic;                        -- Memory read/write signal
    o_rd_addr       : out std_logic_vector(REG_WIDTH-1 downto 0) -- Destination register address
  );
end component memory_access;

-- Write-back stage component
component write_back is
  port (
    -- Input signals
    i_load_data     : in  std_logic_vector(XLEN-1 downto 0); -- Data loaded from memory
    i_alu_result    : in  std_logic_vector(XLEN-1 downto 0); -- ALU result
    i_rd_addr       : in  std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    i_rw            : in  std_logic;                        -- Memory read/write signal
    i_wb            : in  std_logic;                        -- Write-back enable
    i_rstn          : in  std_logic;                        -- Reset signal
    i_clk           : in  std_logic;                        -- Clock signal

    -- Output signals
    o_wb            : out std_logic;                        -- Write-back enable
    o_rd_addr       : out std_logic_vector(REG_WIDTH-1 downto 0); -- Destination register address
    o_rd_data       : out std_logic_vector(XLEN-1 downto 0)  -- Data to write back to register
  );
end component write_back;

-- Fetch stage signals
signal fetched_instr        : std_logic_vector(XLEN-1 downto 0); -- Instruction fetched
signal program_counter      : std_logic_vector(XLEN-1 downto 0) := x"00000004"; -- Program counter

-- Decode stage signals
signal decode_rs1_data, decode_rs2_data, decode_pc, decode_imm : std_logic_vector(XLEN-1 downto 0);
signal decode_branch_flag, decode_jump_flag, decode_rw, decode_we, decode_wb, decode_src_imm,
       decode_arith_flag, decode_sign_flag                     : std_logic;
signal decode_dest_reg_addr : std_logic_vector(REG_WIDTH-1 downto 0);
signal decode_shamt         : std_logic_vector(4 downto 0);
signal decode_alu_op        : std_logic_vector(ALUOP_WIDTH-1 downto 0);

-- Execute stage signals
signal execute_alu_result, execute_store_data, execute_pc_target : std_logic_vector(XLEN-1 downto 0);
signal execute_dest_reg_addr : std_logic_vector(REG_WIDTH-1 downto 0);
signal execute_pc_transfert, execute_rw, execute_we, execute_wb : std_logic;

-- Memory access stage signals
signal memory_store_data, memory_alu_result : std_logic_vector(XLEN-1 downto 0);
signal memory_wb, memory_we, memory_rw      : std_logic;
signal memory_dest_reg_addr                 : std_logic_vector(REG_WIDTH-1 downto 0);

-- Write-back stage signals
signal write_back_data    : std_logic_vector(XLEN-1 downto 0);
signal write_back_dest_reg_addr : std_logic_vector(REG_WIDTH-1 downto 0);
signal write_back_wb_flag : std_logic;

-- Architecture body
begin
  -- Testbench signals mapping
  tb_fetch_pc <= program_counter;
  tb_execute_pc <= decode_pc;
  tb_execute_src_imm <= decode_src_imm;
  tb_write_back_rw <= memory_rw;
  tb_memory_we <= execute_we;
  tb_execute_rs1_data <= decode_rs1_data;
  tb_execute_rs2_data <= decode_rs2_data;
  tb_decode_instruction <= fetched_instr;
  tb_memory_alu_result <= execute_alu_result;
  tb_memory_store_data <= execute_store_data;
  tb_write_back_rd_addr <= write_back_dest_reg_addr;
  tb_write_back_wb <= write_back_wb_flag;
  tb_write_back_rd_data <= write_back_data;
  tb_write_back_alu_result <= memory_alu_result;
  tb_write_back_load_data <= i_dmem_read;

  -- Data memory outputs
  o_dmem_en <= '1';
  o_dmem_we <= memory_we;
  o_dmem_addr <= memory_alu_result;
  o_dmem_write <= memory_store_data;
  -- Instantiate fetch stage
  fetch_inst : component fetch
    port map (
      i_target       => execute_pc_target,            -- Target address for jump/branch
      i_imem_read    => i_imem_read,                  -- Instruction data from memory
      i_transfert    => execute_pc_transfert,         -- Program counter transfer signal
      i_stall        => '0',                          -- Stall signal (not used)
      i_flush        => execute_pc_transfert,         -- Flush signal (active during branch/jump)
      i_rstn         => i_rstn,                       -- Reset signal
      i_clk          => i_clk,                        -- Clock signal
      o_imem_en      => o_imem_en,                    -- Enable signal for instruction memory
      o_imem_addr    => o_imem_addr,                  -- Address for instruction memory
      o_pc           => program_counter,             -- Current program counter
      o_instruction  => fetched_instr                -- Fetched instruction
    );

  -- Instantiate decode stage
  decode_inst : component decode
    port map (
      i_instr        => fetched_instr,                -- Instruction input from fetch stage
      i_rd_data      => write_back_data,              -- Data to write back to register file
      i_rd_addr      => write_back_dest_reg_addr,     -- Address of destination register
      i_wb           => write_back_wb_flag,          -- Write-back enable
      i_pc           => program_counter,             -- Current program counter
      i_flush        => execute_pc_transfert,         -- Flush signal (active during branch/jump)
      i_rstn         => i_rstn,                       -- Reset signal
      i_clk          => i_clk,                        -- Clock signal
      o_rs1_data     => decode_rs1_data,              -- Source register 1 data
      o_rs2_data     => decode_rs2_data,              -- Source register 2 data
      o_branch       => decode_branch_flag,           -- Branch control flag
      o_jump         => decode_jump_flag,             -- Jump control flag
      o_rw           => decode_rw,                   -- Read/Write flag for memory
      o_we           => decode_we,                   -- Write enable for memory
      o_wb           => decode_wb,                   -- Write-back enable
      o_imm          => decode_imm,                  -- Immediate value
      o_src_imm      => decode_src_imm,              -- Source immediate flag
      o_rd_addr      => decode_dest_reg_addr,         -- Destination register address
      o_pc           => decode_pc,                   -- Decoded program counter
      o_arith        => decode_arith_flag,           -- Arithmetic operation flag
      o_sign         => decode_sign_flag,            -- Sign extension flag
      o_shamt        => decode_shamt,                -- Shift amount for ALU
      o_alu_op       => decode_alu_op,               -- ALU operation code
      tb_rs1_addr    => tb_decode_rs1_addr,          -- Source register 1 address for testbench
      tb_rs2_addr    => tb_decode_rs2_addr,          -- Source register 2 address for testbench
      tb_alu_op      => tb_decode_alu_op,            -- ALU operation code for testbench
      tb_arith       => tb_decode_arith,             -- Arithmetic operation flag for testbench
      tb_sign        => tb_decode_sign,              -- Sign extension flag for testbench
      tb_decode_branch => tb_decode_branch,          -- Branch flag for testbench
      tb_decode_jump => tb_decode_jump,              -- Jump flag for testbench
      tb_imm         => tb_decode_imm                -- Immediate value for testbench
    );

  -- Instantiate execute stage
  execute_inst : component execute
    port map (
      i_jump         => decode_jump_flag,             -- Jump control signal
      i_branch       => decode_branch_flag,           -- Branch control signal
      i_src_imm      => decode_src_imm,              -- Immediate value as source
      i_rw           => decode_rw,                   -- Read/Write flag for memory
      i_we           => decode_we,                   -- Write enable for memory
      i_wb           => decode_wb,                   -- Write-back enable
      i_rs1_data     => decode_rs1_data,              -- Source register 1 data
      i_rs2_data     => decode_rs2_data,              -- Source register 2 data
      i_imm          => decode_imm,                  -- Immediate value
      i_pc           => decode_pc,                   -- Decoded program counter
      i_rd_addr      => decode_dest_reg_addr,         -- Destination register address
      i_stall        => '0',                          -- Stall signal (not used)
      i_rstn         => i_rstn,                       -- Reset signal
      i_clk          => i_clk,                        -- Clock signal
      i_shamt        => decode_shamt,                -- Shift amount for ALU
      i_alu_op       => decode_alu_op,               -- ALU operation code
      i_arith        => decode_arith_flag,           -- Arithmetic operation flag
      i_sign         => decode_sign_flag,            -- Sign extension flag
      o_pc_transfert => execute_pc_transfert,         -- Program counter transfer signal
      o_alu_result   => execute_alu_result,           -- ALU result
      o_store_data   => execute_store_data,           -- Data to store in memory
      o_pc_target    => execute_pc_target,            -- Target PC for branch/jump
      o_rw           => execute_rw,                  -- Memory read/write flag
      o_we           => execute_we,                  -- Memory write enable
      o_wb           => execute_wb,                  -- Write-back enable
      o_rd_addr      => execute_dest_reg_addr,        -- Destination register address
      tb_execute_alu_result => tb_execute_alu_result, -- ALU result for testbench
      tb_pc_transfert       => tb_execute_pc_transfert, -- PC transfer signal for testbench
      tb_pc_target          => tb_execute_pc_target,  -- Target PC for testbench
      tb_imm                => tb_execute_imm         -- Immediate value for testbench
    );

  -- Instantiate memory access stage
  memory_access_inst : component memory_access
    port map (
      i_store_data   => execute_store_data,           -- Data to store in memory
      i_alu_result   => execute_alu_result,           -- ALU result
      i_rd_addr      => execute_dest_reg_addr,        -- Destination register address
      i_rw           => execute_rw,                  -- Memory read/write flag
      i_wb           => execute_wb,                  -- Write-back enable
      i_we           => execute_we,                  -- Memory write enable
      i_rstn         => i_rstn,                       -- Reset signal
      i_clk          => i_clk,                        -- Clock signal
      o_store_data   => memory_store_data,            -- Stored data in memory
      o_alu_result   => memory_alu_result,            -- ALU result
      o_wb           => memory_wb,                   -- Write-back enable
      o_we           => memory_we,                   -- Memory write enable
      o_rw           => memory_rw,                   -- Memory read/write flag
      o_rd_addr      => memory_dest_reg_addr          -- Destination register address
    );

  -- Instantiate write-back stage
  write_back_inst : component write_back
    port map (
      i_load_data    => i_dmem_read,                  -- Data loaded from memory
      i_alu_result   => memory_alu_result,            -- ALU result
      i_rd_addr      => memory_dest_reg_addr,         -- Destination register address
      i_rw           => memory_rw,                   -- Memory read/write flag
      i_wb           => memory_wb,                   -- Write-back enable
      i_rstn         => i_rstn,                       -- Reset signal
      i_clk          => i_clk,                        -- Clock signal
      o_wb           => write_back_wb_flag,          -- Write-back enable
      o_rd_addr      => write_back_dest_reg_addr,     -- Destination register address
      o_rd_data      => write_back_data               -- Data to write back to register
    );

end architecture beh;





--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use work.riscv_pkg.all;
--
--entity riscv_core is
--  port ( 
--  i_rstn		: in  std_logic;
--  i_clk 		: in  std_logic;
-- 
--  i_imem_read	: in  std_logic_vector(XLEN-1 downto 0);
--  i_dmem_read 	: in  std_logic_vector(XLEN-1 downto 0);
--	
--  o_imem_en 	: out std_logic; 
--  o_imem_addr 	: out std_logic_vector(XLEN-1 downto 0);
--  o_dmem_en 	: out std_logic;
--  o_dmem_we		: out std_logic;
--  o_dmem_addr 	: out std_logic_vector(XLEN-1 downto 0);
--  o_dmem_write  : out std_logic_vector(XLEN-1 downto 0);  
--  -- DFT
--  i_scan_en 	: in  std_logic;  
--  i_test_mode 	: in  std_logic;	  
--  i_tdi 		: in  std_logic;
--  o_tdo			: out std_logic;
--  
--  --Test Bench
--  tb_decode_instruction :out std_logic_vector(XLEN-1 downto 0); 
--  tb_fetch_pc 	: out std_logic_vector(XLEN-1 downto 0); 
--    
--  tb_execute_rs1_data, tb_execute_rs2_data, tb_execute_pc: out std_logic_vector(XLEN-1 downto 0);
--  tb_decode_branch,tb_decode_jump, tb_write_back_rw, tb_memory_we, tb_decode_arith, tb_decode_sign: out std_logic;
--  tb_decode_alu_op : out std_logic_vector(ALUOP_WIDTH-1 downto 0);
--  tb_decode_imm : out std_logic_vector(XLEN-1 downto 0);
--  
--  tb_execute_pc_target , tb_execute_alu_result, tb_memory_alu_result, tb_execute_imm: out std_logic_vector(XLEN-1 downto 0);
--  tb_execute_pc_transfert, tb_execute_src_imm 	: out std_logic	;
--  
--  tb_write_back_wb : out std_logic;
--  tb_write_back_rd_addr : out std_logic_vector(REG_WIDTH-1 downto 0);
--  tb_write_back_rd_data : out std_logic_vector(XLEN-1 downto 0); 
--  tb_write_back_load_data : out std_logic_vector(XLEN-1 downto 0);
--  tb_write_back_alu_result : out std_logic_vector(XLEN-1 downto 0);
--  tb_decode_rs1_addr , tb_decode_rs2_addr	: out std_logic_vector(REG_WIDTH-1 downto 0);
--  tb_memory_store_data : out std_logic_vector(XLEN-1 downto 0)
--  ); 
--  
--end entity riscv_core;
--
--architecture beh of riscv_core is 
--
--component fetch is
--  port (
--  i_target	    : in  std_logic_vector(XLEN-1 downto 0);
--  i_imem_read   : in  std_logic_vector(XLEN-1 downto 0);
--  i_transfert   : in  std_logic;
--  i_stall		: in  std_logic;
--  i_flush		: in  std_logic;
--  i_rstn		: in  std_logic;
--  i_clk    	    : in  std_logic;  
--  
--  o_imem_en 	: out std_logic;
--  o_imem_addr   : out std_logic_vector(XLEN-1 downto 0);	
--  o_pc		    : out std_logic_vector(XLEN-1 downto 0);	
--  o_instruction : out std_logic_vector(XLEN-1 downto 0)
--  );
--end component fetch;
--
--component decode is
--  port (
--  i_instr		: in  std_logic_vector(XLEN-1 downto 0);
--  i_rd_data 	: in  std_logic_vector(XLEN-1 downto 0);
--  i_rd_addr 	: in  std_logic_vector(REG_WIDTH -1 downto 0);  
--  --i_rw 			: in  std_logic;
--  --i_we			: in  std_logic;
--  i_wb 			: in  std_logic;
--  i_pc			: in  std_logic_vector(XLEN-1 downto 0);
--  i_flush		: in  std_logic;
--  i_rstn		: in  std_logic;
--  i_clk 		: in  std_logic;
--  
--  o_rs1_data 	: out std_logic_vector(XLEN-1 downto 0);
--  o_rs2_data 	: out std_logic_vector(XLEN-1 downto 0); 
--  o_branch		: out std_logic;
--  o_jump		: out std_logic;
--  o_rw 			: out std_logic;  -- read word from d-mem
--  o_we			: out std_logic;	-- write enable in d-mem
--  o_wb			: out std_logic;  -- write back in rf
--  o_imm			: out std_logic_vector(XLEN-1 downto 0);  
--  o_src_imm		: out std_logic;
--  o_rd_addr 	: out std_logic_vector(REG_WIDTH-1 downto 0);
--  o_pc			: out std_logic_vector(XLEN-1 downto 0);
--  -- for ALU in EX
--  o_arith		: out std_logic;
--  o_sign		: out std_logic;
--  o_shamt		: out std_logic_vector(4 downto 0);	
--  o_alu_op		: out std_logic_vector(ALUOP_WIDTH-1 downto 0);
--  tb_rs1_addr   : out std_logic_vector(REG_WIDTH-1 downto 0);
--  tb_rs2_addr   : out std_logic_vector(REG_WIDTH-1 downto 0);
--  tb_alu_op		: out std_logic_vector(ALUOP_WIDTH-1 downto 0);
--  tb_arith		: out std_logic;
--  tb_sign		: out std_logic;
--  tb_decode_branch: out std_logic;
--  tb_decode_jump	: out std_logic;
--  tb_imm			: out std_logic_vector(XLEN-1 downto 0)
--  ); 
--  
--end component decode;	 
--
--
--component execute is
--  port ( 						
--  i_jump 			: in  std_logic;
--  i_branch 			: in  std_logic; 
--  i_src_imm			: in  std_logic;
--  i_rw 				: in  std_logic; -- read word from d-mem
--  i_we				: in  std_logic; -- write enable in d-mem	
--  i_wb 				: in  std_logic; -- write back in rf
--  i_rs1_data 		: in  std_logic_vector(XLEN-1 downto 0);
--  i_rs2_data 		: in  std_logic_vector(XLEN-1 downto 0);
--  i_imm				: in  std_logic_vector(XLEN-1 downto 0);
--  i_pc				: in  std_logic_vector(XLEN-1  downto 0);
--  i_rd_addr 		: in  std_logic_vector(REG_WIDTH-1 downto 0);
--  i_stall			: in  std_logic;
--  i_rstn			: in  std_logic;
--  i_clk 			: in  std_logic;
--  -- ALU inputs	from ID
--  i_shamt			: in  std_logic_vector(SHAMT_WIDTH-1 downto 0);
--  i_alu_op			: in  std_logic_vector(ALUOP_WIDTH-1 downto 0);
--  i_arith			: in  std_logic;
--  i_sign			: in  std_logic;
--	
--  o_pc_transfert	: out std_logic;
--  o_alu_result 		: out std_logic_vector(XLEN-1 downto 0);
--  o_store_data 		: out std_logic_vector(XLEN-1 downto 0); 
--  o_pc_target 		: out std_logic_vector(XLEN-1 downto 0);
--  o_rw 				: out std_logic;  -- read word from d-mem
--  o_we				: out std_logic;	-- write enable in d-mem
--  o_wb				: out std_logic;  -- write back in rf
--  o_rd_addr 		: out std_logic_vector(REG_WIDTH-1 downto 0);
--  tb_execute_alu_result: out std_logic_vector(XLEN-1 downto 0);
--  tb_pc_transfert 	: out std_logic;
--  tb_pc_target 		: out std_logic_vector(XLEN-1 downto 0);
--  tb_imm			: out std_logic_vector(XLEN-1 downto 0)
--  ); 
--  
--end component execute;
--
--component memory_access is
--
--  port (
--  i_store_data  		: in  std_logic_vector(XLEN-1 downto 0);
--  i_alu_result  		: in  std_logic_vector(XLEN-1 downto 0);	 
--  i_rd_addr  			: in  std_logic_vector(REG_WIDTH -1 downto 0);  
--  i_rw 		 			: in  std_logic;		
--  i_wb 		 			: in  std_logic;
--  i_we					: in  std_logic;
--  i_rstn 	 			: in  std_logic;
--  i_clk 	 			: in  std_logic; 
--  
--  o_store_data 			: out std_logic_vector(XLEN-1 downto 0);		
--  o_alu_result 			: out std_logic_vector(XLEN-1 downto 0);
--  o_wb 		 			: out std_logic;
--  o_we					: out std_logic;
--  o_rw 					: out std_logic;		
--  o_rd_addr  			: out std_logic_vector(REG_WIDTH -1 downto 0)  
--  );
--end component memory_access;
--
--
--component write_back is
--
--  port (
--  i_load_data	: in  std_logic_vector(XLEN-1 downto 0);
--  i_alu_result 	: in  std_logic_vector(XLEN-1 downto 0);
--  i_rd_addr 	: in  std_logic_vector(REG_WIDTH-1 downto 0);  
--  i_rw 			: in  std_logic;	  
--  i_wb 			: in  std_logic;
--  i_rstn		: in  std_logic;
--  i_clk 		: in  std_logic;
--	
--  o_wb 			: out std_logic;
--  o_rd_addr 	: out std_logic_vector(REG_WIDTH-1 downto 0); 
--  o_rd_data 	: out std_logic_vector(XLEN-1 downto 0)
--  ); 
--  
--end component write_back; 
--
--  
--  -- fetch
--  signal fetch_instruction 	: std_logic_vector(XLEN-1 downto 0); 
--  signal fetch_pc 	: std_logic_vector(XLEN-1 downto 0):= x"00000004"; 
--  -- decode
--  signal decode_rs1_data, decode_rs2_data, decode_pc, decode_imm	 : std_logic_vector(XLEN-1 downto 0);
--  signal decode_branch, decode_jump, decode_rw, decode_we, decode_wb, decode_src_imm, decode_arith,decode_sign: std_logic;   
--  signal decode_rd_addr : std_logic_vector(REG_WIDTH-1 downto 0); 
--  signal decode_shamt : std_logic_vector(4 downto 0);
--  signal decode_alu_op : std_logic_vector(ALUOP_WIDTH-1 downto 0);
--  -- execute
--  signal execute_alu_result, execute_store_data, execute_pc_target : std_logic_vector(XLEN-1 downto 0);
--  signal execute_rd_addr : std_logic_vector(REG_WIDTH-1 downto 0);
--  signal execute_pc_transfert, execute_rw, execute_we, execute_wb : std_logic;
--  -- memory
--  signal memory_store_data, memory_alu_result : std_logic_vector(XLEN-1 downto 0); 
--  signal memory_wb, memory_we, memory_rw : std_logic;
--  signal memory_rd_addr : std_logic_vector(REG_WIDTH -1 downto 0);
--  -- write back
--  signal write_back_rd_data : std_logic_vector(XLEN-1 downto 0);
--  signal write_back_rd_addr : std_logic_vector(REG_WIDTH-1 downto 0);
--  signal write_back_wb : std_logic;
--  
--begin
--	--test bench
--	tb_fetch_pc	<= fetch_pc;
--	
--	tb_execute_pc <= decode_pc;	
--	tb_execute_src_imm <= decode_src_imm;
--	
--
--	tb_write_back_rw<= memory_rw;
--	tb_memory_we<= execute_we;
--
--	tb_execute_rs1_data <= decode_rs1_data;
--	tb_execute_rs2_data <= decode_rs2_data;
--	tb_decode_instruction <= fetch_instruction;
--	tb_memory_alu_result <= execute_alu_result;
--	tb_memory_store_data <= execute_store_data;
--	tb_write_back_rd_addr <=  write_back_rd_addr;
--	tb_write_back_wb <= write_back_wb;
--	tb_write_back_rd_data <= write_back_rd_data;
--	tb_write_back_alu_result <= memory_alu_result ;
--	tb_write_back_load_data <= i_dmem_read;
--	
--	
--  o_dmem_en <= '1';
--  o_dmem_we	  <= memory_we;
--  o_dmem_addr <= memory_alu_result;
--  o_dmem_write <= memory_store_data;
--
--  -- Instantiate fetch stage
--  fetch_inst : component fetch
--    port map (
--      i_target => execute_pc_target,
--      i_imem_read => i_imem_read,
--      i_transfert => execute_pc_transfert, 
--      i_stall => '0',
--      i_flush => execute_pc_transfert, 
--      i_rstn => i_rstn, 
--      i_clk => i_clk, 
--      o_imem_en => o_imem_en,
--	  o_imem_addr => o_imem_addr,
--      o_pc => fetch_pc,
--      o_instruction => fetch_instruction
--    );
--
--  -- Instantiate decode stage
--  decode_inst : component decode
--    port map (
--      i_instr => fetch_instruction,
--      i_rd_data => write_back_rd_data,
--      i_rd_addr => write_back_rd_addr,
--      i_wb => write_back_wb, 
--      i_pc => fetch_pc,
--      i_flush => execute_pc_transfert, 	 -- pc_transfert == flush 
--      i_rstn => i_rstn, 
--      i_clk => i_clk,
--      o_rs1_data => decode_rs1_data,
--      o_rs2_data => decode_rs2_data,
--      o_branch => decode_branch,
--      o_jump => decode_jump, 
--      o_rw => decode_rw,
--      o_we => decode_we,
--      o_wb => decode_wb,
--      o_imm => decode_imm,
--      o_src_imm => decode_src_imm,
--      o_rd_addr => decode_rd_addr,
--      o_pc => decode_pc,
--      o_arith => decode_arith, 
--      o_sign => decode_sign,
--      o_shamt => decode_shamt, 
--      o_alu_op => decode_alu_op,
--	  tb_rs1_addr => tb_decode_rs1_addr,
--  	  tb_rs2_addr => tb_decode_rs2_addr,
--	  tb_alu_op => tb_decode_alu_op,
--  	  tb_arith => tb_decode_arith,
--  	  tb_sign => tb_decode_sign,
--	  tb_decode_branch => tb_decode_branch,
--  	  tb_decode_jump => tb_decode_jump,
--	  tb_imm => tb_decode_imm
--  
--    );
--
--  -- Instantiate execute stage
--  execute_inst : component execute
--    port map (
--      i_jump => decode_jump,
--      i_branch => decode_branch,
--      i_src_imm => decode_src_imm,
--      i_rw => decode_rw,
--      i_we => decode_we,
--      i_wb => decode_wb,
--      i_rs1_data => decode_rs1_data,
--      i_rs2_data => decode_rs2_data,
--      i_imm => decode_imm,
--      i_pc => decode_pc,
--      i_rd_addr => decode_rd_addr,
--      i_stall => '0', -- no stall
--      i_rstn => i_rstn, 
--      i_clk => i_clk, 
--      i_shamt => decode_shamt, 
--      i_alu_op => decode_alu_op,
--      i_arith => decode_arith,
--      i_sign => decode_sign,
--      o_pc_transfert => execute_pc_transfert,
--      o_alu_result => execute_alu_result,
--      o_store_data => execute_store_data,
--      o_pc_target => execute_pc_target,
--      o_rw => execute_rw,
--      o_we => execute_we,
--      o_wb => execute_wb,
--      o_rd_addr => execute_rd_addr,
--	  tb_execute_alu_result => tb_execute_alu_result,
--	  tb_pc_transfert 	=>  tb_execute_pc_transfert,
--	  tb_pc_target => tb_execute_pc_target,
--	  tb_imm => tb_execute_imm
--    );
--
--  -- Instantiate memory access stage
--  memory_access_inst : component memory_access
--    port map (
--      i_store_data => execute_store_data,
--      i_alu_result => execute_alu_result,
--      i_rd_addr => execute_rd_addr,
--      i_rw => execute_rw,
--      i_wb => execute_wb,
--      i_we => execute_we,
--      i_rstn => i_rstn, 
--      i_clk => i_clk, 
--      o_store_data => memory_store_data,
--      o_alu_result => memory_alu_result,
--      o_wb => memory_wb,
--      o_we => memory_we,
--      o_rw => memory_rw,
--      o_rd_addr => memory_rd_addr
--    );
--
--  -- Instantiate write back stage
--  write_back_inst : component write_back
--    port map (
--      i_load_data => i_dmem_read,
--      i_alu_result => memory_alu_result,
--      i_rd_addr => memory_rd_addr,
--      i_rw => memory_rw,
--      i_wb => memory_wb,
--      i_rstn => i_rstn, 
--      i_clk => i_clk, 
--      o_wb => write_back_wb,
--      o_rd_addr => write_back_rd_addr,
--      o_rd_data => write_back_rd_data
--    );
--
--
--  
--end architecture beh;
-------------------------------------------------------------------------------
-- Project  ELE8304 : Circuits intégrés à très grande échelle
-- Polytechnique Montréal
-------------------------------------------------------------------------------
-- File     riscv_adder.vhd
-- Author   Théo Dupuis  <theo.dupuis@polymtl.ca>
-- Date     2022-08-27
-------------------------------------------------------------------------------
-- Description 	adder with ripple-carry
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_adder is
  generic (
    N : positive := 32
  );
  port (
    i_a    : in  std_logic_vector(N-1 downto 0);
    i_b    : in  std_logic_vector(N-1 downto 0);
    i_sign : in  std_logic;
    i_sub  : in  std_logic;
    o_sum  : out std_logic_vector(N downto 0)
  );
end entity riscv_adder;

architecture beh of riscv_adder is
--------------------------------------
--------- COMPLETE FROM HERE ---------
   component riscv_halfadder is
	port (  
		in_a    : in  std_logic;
    		in_b    : in  std_logic;
		out_sum : out std_logic;
    		o_carry : out std_logic
		); 
   end component riscv_halfadder;

signal o_sum_buffer : std_logic_vector(N-1 downto 0); --:= (others => '0');
signal o_sum_buffer2 : std_logic_vector(N-1 downto 0):= (others => '0');
signal o_sum_buffer3 : std_logic_vector(N-1 downto 0); --:= (others => '0');
signal o_sum_buffer4 : std_logic_vector(N-1 downto 0):= (others => '0');
signal o_sum_buffer5 : std_logic_vector(N-1 downto 0):= (others => '0');
signal o_sum_buffer6 : std_logic_vector(N-1 downto 0):= (others => '0');
signal o_sum_buffer7 : std_logic_vector(N-1 downto 0):= (others => '0');
signal o_sum_buffer8 : std_logic_vector(N-1 downto 0):= (others => '0');

signal carry : std_logic_vector(N-1 downto 0); 
signal carry2 : std_logic_vector(N-1 downto 0); 
signal carry3: std_logic_vector(N-1 downto 0); 
signal carry4: std_logic_vector(N-1 downto 0); 
signal carry5: std_logic_vector(N-1 downto 0); 
signal carry6: std_logic_vector(N-1 downto 0); 
signal carry7: std_logic_vector(N-1 downto 0); 
signal carry8: std_logic_vector(N-1 downto 0); 

signal SecondComplement : std_logic_vector(N-1 downto 0);
signal SecondComplement2 : std_logic_vector(N-1 downto 0);
signal SecondComplementb : std_logic_vector(N-1 downto 0);
signal sign: std_logic;
signal sub: std_logic;
signal subsign: std_logic_vector(1 downto 0);

signal o_rafraichi_AddunSign : std_logic_vector(N downto 0):= (others => '0');
signal o_rafraichi_subUnSign : std_logic_vector(N downto 0):= (others => '0');
signal o_rafraichi_subSign : std_logic_vector(N downto 0):= (others => '0');
signal o_rafraichi_AddSign : std_logic_vector(N downto 0):= (others => '0');

signal CarryBuff1: std_logic;
signal CarryBuff2: std_logic;
signal CarryBuff3: std_logic;

signal APourSign: std_logic_vector(N-1 downto 0):= (others => '0');
signal BPourSign: std_logic_vector(N-1 downto 0):= (others => '0');
signal CPourSign: std_logic_vector(N-1 downto 0):= (others => '0');
signal BuffA: std_logic_vector(N-1 downto 0):= (others => '0');
signal BuffB: std_logic_vector(N-1 downto 0):= (others => '0');


signal BuffSortieSignAdd: std_logic_vector(N downto 0):= (others => '0');

signal overflow : std_logic;
begin 
SecondComplement <= std_logic_vector(unsigned(not i_a)+1);
SecondComplement2 <= std_logic_vector(unsigned(not i_a)+1);
SecondComplementb <= std_logic_vector(unsigned(not i_b)+1);
sign <= i_sign;
sub <= i_sub;
subsign <= sub & sign;
BuffA<=i_a;
BuffB<=i_b;


	overflow <= '1' when ((i_a(31) = '0' and i_b(31) = '0' and o_sum_buffer(31) = '1') or  -- Positive overflow
        (i_a(31) = '1' and i_b(31) = '1' and o_sum_buffer(31) = '0'))   -- Negative overflow
         else '0';

with i_a(31) select
	APourSign <= SecondComplement when '1',
	   i_a when '0',
	(others=>'1') when others;

with i_b(31) select
	BPourSign <= SecondComplementb when '1',
	   i_b when '0',
	(others=>'1') when others;


with i_b(31) select
	CPourSign <= SecondComplementb when '1',
	   i_b when '0',
	(others=>'1') when others;


--gen_unsigned: if i_sign = '0' generate
	--gen_adder : if i_sub = '0' generate


	gen_Add:for i in 0 to N-1 generate
		gen_0:if (i=0) generate 
			u_add:riscv_halfadder port map(i_a(i), i_b(i), o_sum_buffer2(i), carry(i));
			u_add2:riscv_halfadder port map (carry(i),o_sum_buffer(i+1),o_sum_buffer2(i+1),carry2(i));
		end generate gen_0;	


		gen_i:if (i > 0 and i < N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),i_b(i),o_sum_buffer(i),carry(i));
			gen_i2:if (i < N-1 ) generate
			u_add2:riscv_halfadder port map (carry(i) OR carry2(i-1),o_sum_buffer(i+1),o_sum_buffer2(i+1),carry2(i));
			end generate gen_i2;
		end generate gen_i;	

		gen_N:if (i = N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),i_b(i),o_sum_buffer(i),carry(i));
		end generate gen_N;
	end generate gen_Add;

--end generate gen_adder;
--
--gen_substitution: if i_sub = '1' generate
--

	gen_sub:for i in 0 to N-1 generate
		gen_0:if (i=0) generate 
			u_add:riscv_halfadder port map(
			i_a(0),  SecondComplementb(0), o_sum_buffer4(0), carry3(0));
			u_add2:riscv_halfadder port map (carry3(i),o_sum_buffer3(i+1),o_sum_buffer4(i+1),carry4(i));
		end generate gen_0;	


		gen_i:if (i > 0 and i < N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),SecondComplementb(i),o_sum_buffer3(i),carry3(i));
			gen_i2:if (i < N-1 ) generate
			u_add2:riscv_halfadder port map (carry3(i) OR carry4(i-1),o_sum_buffer3(i+1),o_sum_buffer4(i+1),carry4(i));
			end generate gen_i2;
		end generate gen_i;	

		gen_N:if (i = N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),SecondComplementb(i),o_sum_buffer3(i),carry3(i));
		end generate gen_N;
	end generate gen_sub;


--end generate gen_substitution;
--end generate gen_unsigned;
--
--gen_signed: if i_sign = '1' generate
--	gen_adder : if i_sub = '0' generate
--
	gen_Add1:for i in 0 to N-1 generate
		gen_0:if (i=0) generate 
			u_add:riscv_halfadder port map(
			i_a(0), i_b(0), o_sum_buffer6(0), carry5(0));
			u_add2:riscv_halfadder port map (carry5(i),o_sum_buffer5(i+1),o_sum_buffer6(i+1),carry6(i));
		end generate gen_0;	


		gen_i:if (i > 0 and i < N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),i_b(i),o_sum_buffer5(i),carry5(i));
			gen_i2:if (i < N-1 ) generate
			u_add2:riscv_halfadder port map (carry5(i) OR carry6(i-1),o_sum_buffer5(i+1),o_sum_buffer6(i+1),carry6(i));
			end generate gen_i2;
		end generate gen_i;	

		gen_N:if (i = N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),i_b(i),o_sum_buffer5(i),carry5(i));
		end generate gen_N;
	end generate gen_Add1;
--
--end generate gen_adder;
--
--gen_substitution: if i_sub = '1' generate
--
	gen_sub2:for i in 0 to N-1 generate
		gen_0:if (i=0) generate 
			u_add:riscv_halfadder port map(
			i_a(0), SecondComplementb(0), o_sum_buffer8(0), carry7(0));
			u_add2:riscv_halfadder port map (carry7(i),o_sum_buffer7(i+1),o_sum_buffer8(i+1),carry8(i));
		end generate gen_0;	


		gen_i:if (i > 0 and i < N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),SecondComplementb(i),o_sum_buffer7(i),carry7(i));
			gen_i2:if (i < N-1 ) generate
			u_add2:riscv_halfadder port map (carry7(i) OR carry8(i-1),o_sum_buffer7(i+1),o_sum_buffer8(i+1),carry8(i));
			end generate gen_i2;
		end generate gen_i;	

		gen_N:if (i = N-1) generate
			u_add:riscv_halfadder port map(
			i_a(i),SecondComplementb(i),o_sum_buffer7(i),carry7(i));
		end generate gen_N;
	end generate gen_sub2;

--CarryBuff1 <= (carry5(30) XOR carry5(29));
--CarryBuff2 <=  (carry7(30) XOR carry7(29));

CarryBuff1 <= carry5(31) when (carry5(31) XOR carry5(30)) else o_sum_buffer6(31);
CarryBuff2 <= carry7(31) when (carry7(31) XOR carry7(30)) else o_sum_buffer8(31);

--CarryBuff3 <= carry3(31) when (carry3(31) XOR carry4(30)) else '0';

--o_rafraichi_AddunSign <=  carry(30) & o_sum_buffer2;
--o_rafraichi_subUnSign <=  carry3(30) & not(o_sum_buffer4);

o_rafraichi_AddunSign <=  carry(31) & o_sum_buffer2;
o_rafraichi_subUnSign <=  carry3(31) & (o_sum_buffer4);
o_rafraichi_AddSign <=     CarryBuff1  & o_sum_buffer6;
--o_rafraichi_AddSign <=     so_sum_buffer6(31)  & o_sum_buffer6;
o_rafraichi_subSign <=   CarryBuff2 &  o_sum_buffer8;

with subsign select
	o_sum <= o_rafraichi_AddunSign when  "00",
		 o_rafraichi_subUnSign when "10",
		 o_rafraichi_AddSign when  "01",
		 o_rafraichi_subSign when "11",
		(others=>'1') when others;
		
end architecture beh;


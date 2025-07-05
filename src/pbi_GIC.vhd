-------------------------------------------------------------------------------
-- Title      : pbi_GIC
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_GIC.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2025-07-05
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-04  0.1      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
use     ieee.std_logic_textio.all;
use     std.textio.all;

library work;
use     work.logic_pkg.all;
use     work.pbi_pkg.all;
use     work.GIC_csr_pkg.all;

entity pbi_GIC is
  port   (
    clk_i            : in    std_logic;
    arst_b_i         : in    std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in    pbi_ini_t;
    pbi_tgt_o        : out   pbi_tgt_t;
    
    -- Interrupt Interface
    itm_o            : out std_logic;
    its_i            : in  std_logic_vector
    );

end entity pbi_GIC;

architecture rtl of pbi_GIC is

  signal   sw2hw                  : GIC_sw2hw_t;
  signal   hw2sw                  : GIC_hw2sw_t;

  signal   its                    : std_logic_vector(8-1 downto 0);
  
begin  -- architecture rtl

  ins_csr : entity work.GIC_registers(rtl)
  port map(
    clk_i     => clk_i           ,
    arst_b_i  => arst_b_i        ,
    pbi_ini_i => pbi_ini_i       ,
    pbi_tgt_o => pbi_tgt_o       ,
    sw2hw_o   => sw2hw           ,
    hw2sw_i   => hw2sw   
    );

  its             <= std_logic_vector(resize(unsigned(its_i), 8));
  hw2sw.isr.we    <= '1';
  hw2sw.isr.value <= (sw2hw.imr.enable and its) or sw2hw.isr.value;

  itm_o           <= reduce_or(sw2hw.isr.value);

end architecture rtl;

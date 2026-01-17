-------------------------------------------------------------------------------
-- Title      : sbi_GIC
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : sbi_GIC.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2026-01-17
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

library asylum;
use     asylum.logic_pkg.all;
use     asylum.sbi_pkg.all;
use     asylum.GIC_pkg.all;
use     asylum.GIC_csr_pkg.all;
use     asylum.techmap_pkg.all;

entity sbi_GIC is
  generic (
    ITS_SYNC_ENABLE  : in  std_logic_vector
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in  sbi_ini_t;
    sbi_tgt_o        : out sbi_tgt_t;
    
    -- Interrupt Interface
    its_i            : in  std_logic_vector; -- Interruptions Input
    itm_o            : out std_logic         -- Interruption  Output (Merged) 
    );

end entity sbi_GIC;

architecture rtl of sbi_GIC is

  signal   its_sync               : std_logic_vector(its_i'range);
  signal   sw2hw                  : GIC_sw2hw_t;
  signal   hw2sw                  : GIC_hw2sw_t;

begin  -- architecture rtl

  gen_its_sync: for i in ITS_SYNC_ENABLE'range
  generate

    gen_syncdff :
    if (ITS_SYNC_ENABLE(i) = '1')
    generate
      ins_it_sync : sync2dffrn
        port map
        (clk_i    => clk_i
        ,arst_b_i => arst_b_i
        ,d_i      => its_i(i)
        ,q_o      => its_sync(i)
         );
    end generate;

    gen_syncdff_b :
    if (ITS_SYNC_ENABLE(i) = '0')
    generate
      its_sync(i) <= its_i(i);
    end generate;

  end generate;
  
  
  ins_csr : GIC_registers
  port map(
    clk_i     => clk_i           ,
    arst_b_i  => arst_b_i        ,
    sbi_ini_i => sbi_ini_i       ,
    sbi_tgt_o => sbi_tgt_o       ,
    sw2hw_o   => sw2hw           ,
    hw2sw_i   => hw2sw   
    );

  ins_GIC_core : GIC_core
  port map(
    itm_o     => itm_o           ,
    its_i     => its_sync        ,
    isr_i     => sw2hw.isr.value ,
    isr_o     => hw2sw.isr.value ,
    imr_i     => sw2hw.imr.enable
    );

  hw2sw.isr.we <= '1';
  
end architecture rtl;

-------------------------------------------------------------------------------
-- Title      : GIC_core
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GIC_core.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2025-07-31
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
use     asylum.pbi_pkg.all;
use     asylum.GIC_pkg.all;
use     asylum.GIC_csr_pkg.all;

entity GIC_core is
  port   (
    -- Interrupt Interface
    itm_o            : out std_logic;        -- Interruption  Output (Merged) 
    its_i            : in  std_logic_vector; -- Interruptions Input

    -- IT Bank
    isr_i            : in  std_logic_vector; -- Interruption Statut register (Current)
    isr_o            : out std_logic_vector; -- Interruption Statut register (Next)
    imr_i            : in  std_logic_vector  -- Interruption Mask   register (Current)
    );

end entity GIC_core;

architecture rtl of GIC_core is

  signal   its : std_logic_vector(isr_i'range);
  signal   isr : std_logic_vector(isr_i'range);
  
begin  -- architecture rtl

  its   <= std_logic_vector(resize(unsigned(its_i), its'length));
  isr   <= (imr_i and its) or isr_i;
  isr_o <= isr;
  itm_o <= reduce_or(isr_i);

end architecture rtl;

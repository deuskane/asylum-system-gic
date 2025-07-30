-------------------------------------------------------------------------------
-- Title      : GIC_pkg
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GIC_pkg.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-30
-- Last update: 2025-07-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-07-30  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

package GIC_pkg is

  type it_ini_t is record
    valid  : std_logic;
    name   : string;
  end record it_ini_t;

  type it_tgt_t is record
    valid  : std_logic;
    name   : string;
  end record it_tgt_t;
  
  type it_inis_t is array (natural range <>) of it_ini_t;
  type it_tgts_t is array (natural range <>) of it_tgt_t;
  
end package GIC_pkg;

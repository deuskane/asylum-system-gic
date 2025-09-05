-------------------------------------------------------------------------------
-- Title      : GIC_pkg
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GIC_pkg.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-31
-- Last update: 2025-09-01
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-07-31  1.0      mrosiere Created
-------------------------------------------------------------------------------
library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.pbi_pkg.all;

package GIC_pkg is

  type it_ini_t is record
    valid  : std_logic;
    name   : string;
  end record it_ini_t;

  type it_tgt_t is record
    ready  : std_logic;
  end record it_tgt_t;
  
  type it_inis_t is array (natural range <>) of it_ini_t;
  type it_tgts_t is array (natural range <>) of it_tgt_t;
  
-- [COMPONENT_INSERT][BEGIN]
component it_ctrl is
  port (
    clk_i   : in  std_logic;
    arstn_i : in  std_logic;
    it_i    : in  std_logic;
    it_val_o: out std_logic;
    it_ack_i: in  std_logic
    );
end component it_ctrl;

component GIC_core is
  port   (
    -- Interrupt Interface
    itm_o            : out std_logic;        -- Interruption  Output (Merged) 
    its_i            : in  std_logic_vector; -- Interruptions Input

    -- IT Bank
    isr_i            : in  std_logic_vector; -- Interruption Statut register (Current)
    isr_o            : out std_logic_vector; -- Interruption Statut register (Next)
    imr_i            : in  std_logic_vector  -- Interruption Mask   register (Current)
    );

end component GIC_core;

component pbi_GIC is
  port   (
    clk_i            : in    std_logic;
    arst_b_i         : in    std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in    pbi_ini_t;
    pbi_tgt_o        : out   pbi_tgt_t;
    
    -- Interrupt Interface
    its_i            : in  std_logic_vector; -- Interruptions Input
    itm_o            : out std_logic         -- Interruption  Output (Merged) 
    );

end component pbi_GIC;

-- [COMPONENT_INSERT][END]

end GIC_pkg;

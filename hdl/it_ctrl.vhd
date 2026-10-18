-------------------------------------------------------------------------------
-- Title      : it_ctrl
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : it_ctrl.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2025-07-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2024        1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity it_ctrl is
  port (
    clk_i   : in  std_logic;
    arstn_i : in  std_logic;
    it_i    : in  std_logic;
    it_val_o: out std_logic;
    it_ack_i: in  std_logic
    );
end it_ctrl;

architecture rtl of it_ctrl is

  signal it       : std_logic;
  signal it_r     : std_logic;
  signal it_val_r : std_logic;

begin

  it <= it_i and not it_r;

  p_it_val_r: process (clk_i, arstn_i) is
  begin  -- process p_it_val_r
    if arstn_i = '0' then                 -- asynchronous reset (active low)
      it_r     <= '0';
      it_val_r <= '0';
      
    elsif clk_i'event and clk_i = '1' then  -- rising clock edge
      it_r <= it_i;

      -- A new edge has priority over the acknowledge of the same cycle :
      -- the edge is kept instead of being lost
      it_val_r <= it or (it_val_r and not it_ack_i);
    end if;
  end process p_it_val_r;

  it_val_o <= it_val_r;
  
end architecture rtl;
    
  

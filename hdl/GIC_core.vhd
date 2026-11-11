-------------------------------------------------------------------------------
-- Title      : GIC_core
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : GIC_core.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-07-04
-- Last update: 2026-11-11
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
-- 2026-11-11  0.2      mrosiere Replay of the events cleared by a
--                               simultaneous W1C (clk_i, arst_b_i, isr_we_i)
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
    -- Clock and reset of the W1C replay (optional : without arst_b_i the
    -- replay register is held in reset, without isr_we_i it is not used)
    clk_i            : in  std_logic := '0';
    arst_b_i         : in  std_logic := '0'; -- asynchronous reset, active low

    -- Interrupt Interface
    itm_o            : out std_logic;        -- Interruption  Output (Merged) 
    its_i            : in  std_logic_vector; -- Interruptions Input

    -- IT Bank
    isr_i            : in  std_logic_vector; -- Interruption Statut register (Current)
    isr_o            : out std_logic_vector; -- Interruption Statut register (Next)
    isr_we_i         : in  std_logic := '0'; -- Interruption Statut register written by software in the previous cycle (regtool sw2hw.isr.we)
    imr_i            : in  std_logic_vector  -- Interruption Mask   register (Current)
    );

end entity GIC_core;

architecture rtl of GIC_core is

  -- The lines are mapped by position, whatever the bounds and the direction
  -- of its_i : the rightmost element of its_i is line 0 = ISR bit 0
  alias    its_n : std_logic_vector(its_i'length-1 downto 0) is its_i;

  signal   its        : std_logic_vector(isr_i'range);
  signal   its_replay : std_logic_vector(isr_i'range);
  signal   its_hold_r : std_logic_vector(isr_i'range);
  signal   isr        : std_logic_vector(isr_i'range);
  
begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Parameters checks
  -----------------------------------------------------------------------------
  assert its_i'length <= isr_i'length
    report "GIC_core : its_i has "&integer'image(its_i'length)&" lines, the ISR has only "&integer'image(isr_i'length)&" bits"
    severity failure;

  its   <= std_logic_vector(resize(unsigned(its_n), its'length));

  -----------------------------------------------------------------------------
  -- W1C / event collision
  -- The rw1c ISR gives the priority to the software clear (csr_reg :
  -- q_next = d_hw and not wd) : an event in the cycle of an ISR write is
  -- cleared with it, and a 1-cycle pulse is lost. The events are held one
  -- cycle and replayed in the cycle that follows an ISR write (isr_we_i,
  -- the write strobe delayed by one cycle). its_hold_r keeps the replayed
  -- value : an event cleared again by a back-to-back ISR write is replayed
  -- again.
  -----------------------------------------------------------------------------
  its_replay <= its or its_hold_r when isr_we_i = '1' else
                its;

  p_its_hold: process (clk_i, arst_b_i) is
  begin
    if arst_b_i = '0' then
      its_hold_r <= (others => '0');
    elsif rising_edge(clk_i) then
      its_hold_r <= its_replay;
    end if;
  end process p_its_hold;

  -- The ISR latches the raw events (masked lines included : polling possible,
  -- no event lost while masked), the IMR only masks the merged output
  isr   <= its_replay or isr_i;
  isr_o <= isr;
  itm_o <= reduce_or(isr_i and imr_i);

end architecture rtl;

-------------------------------------------------------------------------------
-- Title      : tb_GIC_random_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_random_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario random of tb_GIC, from reset : C_NB_RANDOM random IMR
--              / line patterns (1-cycle pulses) with random clears, checked
--              against ISR = OR(its) and itm_o = OR(ISR and IMR). The seeds
--              depend on the number of lines and on its_sync
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-19  1.0      mrosiere Created (split of tb_GIC)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.GIC_csr_pkg.all;

library work;
use     work.tb_GIC_bfm_pkg.all;

package tb_GIC_random_pkg is

  constant C_NB_RANDOM : natural := 32;

  -- C_NB_RANDOM random IMR / line patterns (1-cycle pulses) with random
  -- clears, checked against ISR = OR(its) and itm_o = OR(ISR and IMR). The
  -- seeds depend on the number of lines and on its_sync
  procedure run
    (constant its_sync : in    std_logic_vector -- ITS_SYNC_ENABLE, line i = its_sync(i)
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_random_pkg;

package body tb_GIC_random_pkg is

  procedure run
    (constant its_sync : in    std_logic_vector -- ITS_SYNC_ENABLE, line i = its_sync(i)
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
    variable v_seed1   : positive := 3;
    variable v_seed2   : positive := 77 + its'length*256 + to_integer(unsigned(its_sync));
    variable v_r       : real;
    variable v_imr     : std_logic_vector(8-1 downto 0);
    variable v_its     : std_logic_vector(its'length-1 downto 0);
    variable v_isr     : std_logic_vector(8-1 downto 0) := x"00";
    variable v_clr     : std_logic_vector(8-1 downto 0);
  begin
    log(ID_SEQUENCER, integer'image(C_NB_RANDOM) & " random IMR / line patterns : ISR = OR(its), itm_o = OR(ISR and IMR)", C_TB_SCOPE);
    for n in 1 to C_NB_RANDOM loop
      uniform(v_seed1, v_seed2, v_r);
      v_imr := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)), 8));
      uniform(v_seed1, v_seed2, v_r);
      v_its := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)) mod 2**its'length, its'length));
      wr(GIC_IMR, v_imr, "Random IMR", clk, sbi_if);
      set_its(v_its , clk, its);
      set_its(C_NONE, clk, its);
      settle (clk);
      v_isr := v_isr or to_isr(v_its);
      chk(GIC_ISR, v_isr, "ISR accumulates every line", clk, sbi_if);
      wait until falling_edge(clk);
      chk_itm(itm, or (v_isr and v_imr), "itm_o = OR(ISR and IMR)");
      -- clear a random subset
      uniform(v_seed1, v_seed2, v_r);
      v_clr := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)), 8));
      wr (GIC_ISR, v_clr, "Clear a random subset", clk, sbi_if);
      v_isr := v_isr and not v_clr;
      chk(GIC_ISR, v_isr, "ISR after the clear"  , clk, sbi_if);
    end loop;
  end procedure;

end package body tb_GIC_random_pkg;

-------------------------------------------------------------------------------
-- Title      : tb_GIC_masked_latched_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_masked_latched_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario masked_latched of tb_GIC, from reset : every line
--              masked : the active lines are latched in the ISR, itm_o stays 0
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-19  1.0      mrosiere Created (split of tb_GIC)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.GIC_csr_pkg.all;

library work;
use     work.tb_GIC_bfm_pkg.all;

package tb_GIC_masked_latched_pkg is

  -- Every line masked : the active lines are latched in the ISR, itm_o stays 0
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_masked_latched_pkg;

package body tb_GIC_masked_latched_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_ALL     : std_logic_vector(its'length-1 downto 0) := (others => '1');
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
  begin
    log(ID_SEQUENCER, "Masked lines are latched in the ISR but do not raise itm_o", C_TB_SCOPE);
    wr (GIC_IMR, x"00", "Mask every line", clk, sbi_if);
    set_its(C_ALL, clk, its);
    settle (clk);
    chk(GIC_ISR, to_isr(C_ALL), "ISR = every line with every line active and masked", clk, sbi_if);
    chk_itm(itm, '0', "itm_o = 0 with every line masked");
    set_its(C_NONE, clk, its);
    settle (clk);
    wr (GIC_ISR, x"FF", "Clear every ISR bit", clk, sbi_if);
    chk(GIC_ISR, x"00", "ISR cleared"        , clk, sbi_if);
  end procedure;

end package body tb_GIC_masked_latched_pkg;

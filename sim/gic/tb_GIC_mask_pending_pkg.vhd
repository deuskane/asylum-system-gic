-------------------------------------------------------------------------------
-- Title      : tb_GIC_mask_pending_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_mask_pending_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario mask_pending of tb_GIC, from reset : masking pending
--              lines drops itm_o without clearing them, unmasking raises it
--              again ; masked active lines and masked 1-cycle pulses are
--              latched, unmasking them raises itm_o (event not lost)
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

package tb_GIC_mask_pending_pkg is

  -- Masking pending lines drops itm_o without clearing them, unmasking raises
  -- it again ; masked active lines and masked 1-cycle pulses are latched,
  -- unmasking them raises itm_o (event not lost)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_mask_pending_pkg;

package body tb_GIC_mask_pending_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_ALL     : std_logic_vector(its'length-1 downto 0) := (others => '1');
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
  begin
    log(ID_SEQUENCER, "Masking a pending line drops itm_o without clearing it, a masked event is kept", C_TB_SCOPE);
    -- Every line active and unmasked : itm_o = 1
    wr(GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    set_its(C_ALL, clk, its);
    settle (clk);
    chk_itm(itm, '1', "itm_o = 1 : every line pending and unmasked");
    wr (GIC_IMR, x"00", "Mask every line, sources still active", clk, sbi_if);
    chk(GIC_ISR, to_isr(C_ALL), "ISR bits stay set after masking", clk, sbi_if);
    wait until falling_edge(clk);
    chk_itm(itm, '0', "itm_o = 0 : every pending line is masked");
    wr (GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    wait until falling_edge(clk);
    chk_itm(itm, '1', "itm_o = 1 again after unmasking");
    wr (GIC_IMR, x"00", "Mask every line", clk, sbi_if);
    wr (GIC_ISR, x"FF", "Clear every bit", clk, sbi_if);
    settle (clk);
    chk(GIC_ISR, to_isr(C_ALL), "Masked active lines are latched again (polling)", clk, sbi_if);
    chk_itm(itm, '0', "itm_o = 0 (lines masked)");
    set_its(C_NONE, clk, its);
    settle (clk);
    wr (GIC_ISR, x"FF", "Clear every bit", clk, sbi_if);
    chk(GIC_ISR, x"00", "ISR cleared"    , clk, sbi_if);
    set_its(C_ALL , clk, its);
    set_its(C_NONE, clk, its);
    settle (clk);
    chk(GIC_ISR, to_isr(C_ALL), "1-cycle pulses on masked lines are latched", clk, sbi_if);
    chk_itm(itm, '0', "itm_o = 0 (lines masked)");
    wr (GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    wait until falling_edge(clk);
    chk_itm(itm, '1', "Unmasking the pending lines raises itm_o (event not lost)");
    wr (GIC_ISR, x"FF", "Clear every bit", clk, sbi_if);
    chk(GIC_ISR, x"00", "ISR cleared"    , clk, sbi_if);
  end procedure;

end package body tb_GIC_mask_pending_pkg;

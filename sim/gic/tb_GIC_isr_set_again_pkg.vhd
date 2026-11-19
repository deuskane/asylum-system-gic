-------------------------------------------------------------------------------
-- Title      : tb_GIC_isr_set_again_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_isr_set_again_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario isr_set_again of tb_GIC, from reset : for each line,
--              every line unmasked : an ISR bit cleared while its source is
--              active reads 0 during one cycle and is set again
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

package tb_GIC_isr_set_again_pkg is

  -- For each line, every line unmasked : an ISR bit cleared while its source
  -- is active reads 0 during one cycle and is set again
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_isr_set_again_pkg;

package body tb_GIC_isr_set_again_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
    variable v_its     : std_logic_vector(its'length-1 downto 0);
  begin
    log(ID_SEQUENCER, "ISR bit set again when the source stays active", C_TB_SCOPE);
    -- Every line unmasked : itm_o follows the ISR
    wr(GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    for i in 0 to its'length-1 loop
      v_its    := C_NONE;
      v_its(i) := '1';
      set_its(v_its, clk, its);
      settle (clk);
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " while the source is active", clk, sbi_if);
      -- The clear wins during one cycle, the active source sets the bit again on the next cycle
      chk(GIC_ISR, x"00"      , "ISR bit cleared during one cycle", clk, sbi_if);
      chk(GIC_ISR, one_hot(i) , "ISR bit set again (source still active)", clk, sbi_if);
      wait until falling_edge(clk);
      chk_itm(itm, '1', "itm_o = 1 (source still active)");
      set_its(C_NONE, clk, its);
      settle (clk);
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " after the source falls", clk, sbi_if);
      chk(GIC_ISR, x"00", "ISR stays cleared", clk, sbi_if);
    end loop;
  end procedure;

end package body tb_GIC_isr_set_again_pkg;

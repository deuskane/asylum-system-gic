-------------------------------------------------------------------------------
-- Title      : tb_GIC_unmasked_itm_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_unmasked_itm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario unmasked_itm of tb_GIC, from reset : for each line,
--              unmasked alone with every line active : every line is latched,
--              only the unmasked one raises itm_o, the bits stay set after the
--              lines fall, clearing the unmasked bit drops itm_o while the
--              masked bits stay pending
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

package tb_GIC_unmasked_itm_pkg is

  -- For each line, unmasked alone with every line active : every line is
  -- latched, only the unmasked one raises itm_o, the bits stay set after the
  -- lines fall, clearing the unmasked bit drops itm_o while the masked bits
  -- stay pending
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_unmasked_itm_pkg;

package body tb_GIC_unmasked_itm_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_ALL     : std_logic_vector(its'length-1 downto 0) := (others => '1');
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
  begin
    log(ID_SEQUENCER, "Only the unmasked line raises itm_o (every line active and latched)", C_TB_SCOPE);
    for i in 0 to its'length-1 loop
      wr (GIC_IMR, one_hot(i), "Unmask line " & integer'image(i), clk, sbi_if);
      set_its(C_ALL, clk, its);
      settle (clk);
      chk(GIC_ISR, to_isr(C_ALL), "ISR = every line (raw status)", clk, sbi_if);
      chk_itm(itm, '1', "itm_o = 1 (line " & integer'image(i) & " unmasked)");
      set_its(C_NONE, clk, its);
      settle (clk);
      chk(GIC_ISR, to_isr(C_ALL), "ISR bits stay set after the lines fall (latched)", clk, sbi_if);
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " (write 1)", clk, sbi_if);
      chk(GIC_ISR, to_isr(C_ALL) and not one_hot(i), "Only line " & integer'image(i) & " cleared", clk, sbi_if);
      wait until falling_edge(clk);
      chk_itm(itm, '0', "itm_o = 0 after the clear : the pending lines are masked");
      wr (GIC_ISR, x"FF", "Clear every line", clk, sbi_if);
      chk(GIC_ISR, x"00", "ISR cleared"     , clk, sbi_if);
    end loop;
  end procedure;

end package body tb_GIC_unmasked_itm_pkg;

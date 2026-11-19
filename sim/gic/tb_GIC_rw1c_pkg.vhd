-------------------------------------------------------------------------------
-- Title      : tb_GIC_rw1c_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_rw1c_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rw1c of tb_GIC, from reset : ISR rw1c, every line
--              latched and unmasked : write 0 has no effect, write 1 clears
--              (0x55 even bits, 0xAA odd bits), itm_o = OR(ISR)
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

package tb_GIC_rw1c_pkg is

  -- ISR rw1c, every line latched and unmasked : write 0 has no effect, write 1
  -- clears (0x55 even bits, 0xAA odd bits), itm_o = OR(ISR)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_rw1c_pkg;

package body tb_GIC_rw1c_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    constant C_ALL     : std_logic_vector(its'length-1 downto 0) := (others => '1');
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
    variable v_isr     : std_logic_vector(8-1 downto 0);
  begin
    log(ID_SEQUENCER, "rw1c : write 1 clears, write 0 has no effect", C_TB_SCOPE);
    wr(GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    set_its(C_ALL , clk, its);
    set_its(C_NONE, clk, its);
    settle (clk);
    v_isr := to_isr(C_ALL);
    chk(GIC_ISR, v_isr, "Every line latched, ISR bits above NB_LINES stay 0", clk, sbi_if);
    wr (GIC_ISR, x"00", "Write 0x00 : no effect", clk, sbi_if);
    chk(GIC_ISR, v_isr, "ISR unchanged", clk, sbi_if);
    wr (GIC_ISR, x"55", "Write 0x55 : clear even bits", clk, sbi_if);
    v_isr := v_isr and x"AA";
    chk(GIC_ISR, v_isr, "Only the even bits are cleared", clk, sbi_if);
    wait until falling_edge(clk);
    chk_itm(itm, or v_isr, "itm_o = OR(ISR)");
    wr (GIC_ISR, x"AA", "Write 0xAA : clear odd bits", clk, sbi_if);
    chk(GIC_ISR, x"00", "ISR cleared", clk, sbi_if);
    wait until falling_edge(clk);
    chk_itm(itm, '0', "itm_o = 0");
  end procedure;

end package body tb_GIC_rw1c_pkg;

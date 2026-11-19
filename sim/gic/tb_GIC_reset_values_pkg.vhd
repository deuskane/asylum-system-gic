-------------------------------------------------------------------------------
-- Title      : tb_GIC_reset_values_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_reset_values_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset_values of tb_GIC, from reset : ISR = IMR = 0
--              (every line masked) and itm_o = 0 after the reset
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

package tb_GIC_reset_values_pkg is

  -- ISR = IMR = 0 (every line masked) and itm_o = 0 after the reset
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_reset_values_pkg;

package body tb_GIC_reset_values_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   itm      : in    std_logic
    ) is
  begin
    log(ID_SEQUENCER, "Reset values", C_TB_SCOPE);
    chk    (GIC_ISR, x"00", "ISR reset value"                   , clk, sbi_if);
    chk    (GIC_IMR, x"00", "IMR reset value (all lines masked)", clk, sbi_if);
    chk_itm(itm, '0', "itm_o after reset");
  end procedure;

end package body tb_GIC_reset_values_pkg;

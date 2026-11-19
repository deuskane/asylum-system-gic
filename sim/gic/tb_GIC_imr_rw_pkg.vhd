-------------------------------------------------------------------------------
-- Title      : tb_GIC_imr_rw_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_imr_rw_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario imr_rw of tb_GIC, from reset : IMR read / write with
--              the lines inactive, the ISR stays 0
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

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.GIC_csr_pkg.all;

library work;
use     work.tb_GIC_bfm_pkg.all;

package tb_GIC_imr_rw_pkg is

  -- IMR read / write with the lines inactive, the ISR stays 0
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

end package tb_GIC_imr_rw_pkg;

package body tb_GIC_imr_rw_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
    variable v_imr     : std_logic_vector(8-1 downto 0);
  begin
    log(ID_SEQUENCER, "IMR read/write (lines inactive)", C_TB_SCOPE);
    for v in 0 to 3 loop
      v_imr := std_logic_vector(to_unsigned((v * 85 + 17) mod 256, 8));
      wr (GIC_IMR, v_imr, "Write IMR"    , clk, sbi_if);
      chk(GIC_IMR, v_imr, "Read back IMR", clk, sbi_if);
    end loop;
    wr (GIC_IMR, x"FF", "Write IMR 0xFF"              , clk, sbi_if);
    chk(GIC_IMR, x"FF", "Read back IMR 0xFF"          , clk, sbi_if);
    chk(GIC_ISR, x"00", "ISR still 0 (no active line)", clk, sbi_if);
  end procedure;

end package body tb_GIC_imr_rw_pkg;

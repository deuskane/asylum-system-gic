-------------------------------------------------------------------------------
-- Title      : tb_GIC_latency_pulse_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_latency_pulse_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario latency_pulse of tb_GIC, from reset : for each line,
--              every line unmasked : latency its_i -> itm_o (1 cycle, 3 cycles
--              with the synchronizer) and capture of a 1-cycle pulse
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

package tb_GIC_latency_pulse_pkg is

  -- For each line, every line unmasked : latency its_i -> itm_o (1 cycle, 3
  -- cycles with the synchronizer) and capture of a 1-cycle pulse
  procedure run
    (constant its_sync : in    std_logic_vector -- ITS_SYNC_ENABLE, line i = its_sync(i)
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_latency_pulse_pkg;

package body tb_GIC_latency_pulse_pkg is

  -- Latency its_i -> itm_o of a line : 1 cycle for the ISR register, 2 more
  -- with the synchronizer
  function lat
    (constant sync     : in    std_logic
    ) return natural is
  begin
    if sync = '1'
    then
      return 3;
    else
      return 1;
    end if;
  end function;

  procedure run
    (constant its_sync : in    std_logic_vector -- ITS_SYNC_ENABLE, line i = its_sync(i)
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
    alias    sync      : std_logic_vector(its_sync'length-1 downto 0) is its_sync;
    constant C_NONE    : std_logic_vector(its'length-1 downto 0) := (others => '0');
    variable v_its     : std_logic_vector(its'length-1 downto 0);
    variable v_n       : natural;
  begin
    log(ID_SEQUENCER, "Latency its_i -> itm_o and 1-cycle pulse capture", C_TB_SCOPE);
    wr(GIC_IMR, x"FF", "Unmask every line", clk, sbi_if);
    for i in 0 to its'length-1 loop
      -- Latency
      v_its    := C_NONE;
      v_its(i) := '1';
      set_its(v_its, clk, its);
      v_n := 0;
      loop
        wait until rising_edge(clk);
        v_n := v_n + 1;
        wait until falling_edge(clk);
        exit when itm = '1' or v_n = 10;
      end loop;
      chk_int(v_n, lat(sync(i)), "Line " & integer'image(i) & " latency its_i -> itm_o (cycles), sync=" & std_logic'image(sync(i)));
      set_its(C_NONE, clk, its);
      settle (clk);
      wr (GIC_ISR, x"FF", "Clear every ISR bit", clk, sbi_if);
      chk(GIC_ISR, x"00", "ISR cleared"        , clk, sbi_if);

      -- One cycle pulse
      set_its(v_its , clk, its);
      set_its(C_NONE, clk, its);
      settle (clk);
      chk(GIC_ISR, one_hot(i), "1-cycle pulse on line " & integer'image(i) & " latched", clk, sbi_if);
      wr (GIC_ISR, one_hot(i), "Clear", clk, sbi_if);
    end loop;
    if (its'length > 1) and (sync(0) /= sync(its'length-1))
    then
      log(ID_SEQUENCER, "Mixed synchronizers : latency difference of 2 cycles checked between lines", C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_GIC_latency_pulse_pkg;

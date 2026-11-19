-------------------------------------------------------------------------------
-- Title      : tb_GIC_tests_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_tests_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_GIC : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_GIC_<name>_pkg)
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
use     asylum.string_pkg.all;

library work;
use     work.tb_GIC_bfm_pkg.all;

package tb_GIC_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "reset_values,imr_rw,masked_latched,unmasked_itm,latency_pulse,rw1c,isr_set_again,mask_pending,random,async_reset";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;constant its_sync : in    std_logic_vector -- ITS_SYNC_ENABLE, line i = its_sync(i)
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    );

end package tb_GIC_tests_pkg;

package body tb_GIC_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;constant its_sync : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   its      : out   std_logic_vector
    ;signal   itm      : in    std_logic
    ) is
  begin
    if    string_eq(name, "reset_values")
    then
      work.tb_GIC_reset_values_pkg.run(clk, sbi_if, itm);
    elsif string_eq(name, "imr_rw")
    then
      work.tb_GIC_imr_rw_pkg.run(clk, sbi_if);
    elsif string_eq(name, "masked_latched")
    then
      work.tb_GIC_masked_latched_pkg.run(clk, sbi_if, its, itm);
    elsif string_eq(name, "unmasked_itm")
    then
      work.tb_GIC_unmasked_itm_pkg.run(clk, sbi_if, its, itm);
    elsif string_eq(name, "latency_pulse")
    then
      work.tb_GIC_latency_pulse_pkg.run(its_sync, clk, sbi_if, its, itm);
    elsif string_eq(name, "rw1c")
    then
      work.tb_GIC_rw1c_pkg.run(clk, sbi_if, its, itm);
    elsif string_eq(name, "isr_set_again")
    then
      work.tb_GIC_isr_set_again_pkg.run(clk, sbi_if, its, itm);
    elsif string_eq(name, "mask_pending")
    then
      work.tb_GIC_mask_pending_pkg.run(clk, sbi_if, its, itm);
    elsif string_eq(name, "random")
    then
      work.tb_GIC_random_pkg.run(its_sync, clk, sbi_if, its, itm);
    elsif string_eq(name, "async_reset")
    then
      work.tb_GIC_async_reset_pkg.run(clk, arst_b, sbi_if, its, itm);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_GIC_tests_pkg;

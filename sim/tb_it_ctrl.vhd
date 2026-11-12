-------------------------------------------------------------------------------
-- Title      : tb_it_ctrl
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_it_ctrl.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench for it_ctrl
--              TEST : scenario run after the reset (tb_it_ctrl_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-11  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.GIC_pkg.all;

library work;
use     work.tb_it_ctrl_pkg.all;

entity tb_it_ctrl is
  generic (
    TEST            : string := "edge"  -- Scenario : edge, edge_ack
  );
end entity tb_it_ctrl;

architecture sim of tb_it_ctrl is

  constant C_SCOPE         : string := "TB_IT_CTRL";
  constant C_CLK_PERIOD    : time   := 10 ns;

  signal   clk_i           : std_logic := '0';
  signal   clk_ena         : boolean   := false;
  signal   arst_b_i        : std_logic := '0';
  signal   it_i            : std_logic := '0';
  signal   it_ack_i        : std_logic := '0';
  signal   it_val_o        : std_logic;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");
  arst_b_i <= '0', '1' after 100 ns;

  dut : it_ctrl
    port map
    (clk_i           => clk_i
    ,arstn_i         => arst_b_i
    ,it_i            => it_i
    ,it_val_o        => it_val_o
    ,it_ack_i        => it_ack_i
    );

  p_sequencer : process
  begin
    log(ID_LOG_HDR, "Test " & TEST, C_SCOPE);

    clk_ena <= true;
    wait until arst_b_i = '1';
    wait until falling_edge(clk_i);

    if    TEST = "edge"
    then
      test_edge    (clk_i, it_i, it_ack_i, it_val_o);
    elsif TEST = "edge_ack"
    then
      test_edge_ack(clk_i, it_i, it_ack_i, it_val_o);
    else
      alert(TB_ERROR, "Unknown TEST " & TEST, C_SCOPE);
    end if;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;

-------------------------------------------------------------------------------
-- Title      : tb_it_ctrl
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_it_ctrl.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench for it_ctrl
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_it_ctrl_pkg : edge, edge_ack), each one after
--                           a reset pulse ; "" : build and elaboration only
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-11  1.0      mrosiere Created
-- 2026-11-19  1.1      mrosiere TESTS_LIST instead of TEST, reset pulse
--                               driven by the sequencer before each scenario
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.GIC_pkg.all;
use     asylum.string_pkg.all;

library work;
use     work.tb_it_ctrl_pkg.all;

entity tb_it_ctrl is
  generic (
    TESTS_LIST      : string := ""      -- Scenarios, e.g. "edge,edge_ack"
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
    log(ID_LOG_HDR, "TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not is_test(list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    clk_ena <= true;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, inputs inactive : each scenario starts from reset.
      -- Released on a falling edge, wherever the previous scenario ended
      it_i     <= '0';
      it_ack_i <= '0';
      arst_b_i <= '0';
      wait for 100 ns;
      wait until falling_edge(clk_i);
      arst_b_i <= '1';
      wait until falling_edge(clk_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), clk_i, it_i, it_ack_i, it_val_o);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;

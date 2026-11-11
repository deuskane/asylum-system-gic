-------------------------------------------------------------------------------
-- Title      : tb_it_ctrl_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_it_ctrl_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_it_ctrl (one per TEST value). The lines are
--              driven on the falling edge of clk, it_val is checked after the
--              rising edge.
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

package tb_it_ctrl_pkg is

  constant C_PKG_SCOPE : string := "TB_IT_CTRL_PKG";

  -- A rising edge of it is latched until the acknowledge; a level that stays
  -- high is not latched again; a new edge after the acknowledge is
  procedure test_edge
    (signal   clk      : in  std_logic
    ;signal   it       : out std_logic
    ;signal   it_ack   : out std_logic
    ;signal   it_val   : in  std_logic
    );

  -- A rising edge of it in the cycle of the acknowledge is kept
  procedure test_edge_ack
    (signal   clk      : in  std_logic
    ;signal   it       : out std_logic
    ;signal   it_ack   : out std_logic
    ;signal   it_val   : in  std_logic
    );

end package tb_it_ctrl_pkg;

package body tb_it_ctrl_pkg is

  -- Drive it / it_ack on the falling edge, then wait for the next falling
  -- edge : it_val shows the result of the rising edge in between
  procedure step
    (signal   clk      : in  std_logic
    ;signal   it       : out std_logic
    ;signal   it_ack   : out std_logic
    ;constant it_v     : in  std_logic
    ;constant ack_v    : in  std_logic
    ) is
  begin
    wait until falling_edge(clk);
    it     <= it_v;
    it_ack <= ack_v;
    wait until falling_edge(clk);
  end procedure;

  procedure chk
    (signal   it_val   : in  std_logic
    ;constant exp      : in  std_logic
    ;constant msg      : in  string
    ) is
  begin
    check_value(it_val, exp, error, msg, C_PKG_SCOPE);
  end procedure;

  procedure test_edge
    (signal   clk      : in  std_logic
    ;signal   it       : out std_logic
    ;signal   it_ack   : out std_logic
    ;signal   it_val   : in  std_logic
    ) is
  begin
    log(ID_LOG_HDR, "Rising edge latched until the acknowledge", C_PKG_SCOPE);
    chk (it_val, '0', "it_val = 0 after reset");
    step(clk, it, it_ack, '1', '0');
    chk (it_val, '1', "Rising edge latched");
    step(clk, it, it_ack, '1', '0');
    chk (it_val, '1', "it_val stays set while it stays high");
    step(clk, it, it_ack, '1', '1');
    chk (it_val, '0', "Acknowledge clears it_val");
    step(clk, it, it_ack, '1', '0');
    chk (it_val, '0', "A level that stays high is not latched again");
    step(clk, it, it_ack, '0', '0');
    chk (it_val, '0', "Falling edge not latched");
    step(clk, it, it_ack, '1', '0');
    chk (it_val, '1', "New rising edge latched");
    step(clk, it, it_ack, '0', '1');
    chk (it_val, '0', "Acknowledge clears it_val");
  end procedure;

  procedure test_edge_ack
    (signal   clk      : in  std_logic
    ;signal   it       : out std_logic
    ;signal   it_ack   : out std_logic
    ;signal   it_val   : in  std_logic
    ) is
  begin
    log(ID_LOG_HDR, "Rising edge in the cycle of the acknowledge", C_PKG_SCOPE);
    step(clk, it, it_ack, '1', '0');
    step(clk, it, it_ack, '0', '0');
    chk (it_val, '1', "First edge latched");
    step(clk, it, it_ack, '1', '1');
    chk (it_val, '1', "Edge in the cycle of the acknowledge kept");
    step(clk, it, it_ack, '1', '1');
    chk (it_val, '0', "Acknowledge without edge clears it_val");
  end procedure;

end package body tb_it_ctrl_pkg;

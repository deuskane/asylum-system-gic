-------------------------------------------------------------------------------
-- Title      : tb_GIC_bfm_pkg
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC_bfm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_GIC scenarios : SBI accesses (SBI VIP, zero
--              wait state), checks (counted for the final report), interrupt
--              lines driven on the falling edge of the clock, reset pulse.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-19  1.0      mrosiere Created (helpers of the tb_GIC sequencer)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

package tb_GIC_bfm_pkg is

  constant C_TB_SCOPE  : string := "TB_GIC";

  -- Zero wait state target : any cycle with ready = '0' is an error
  constant C_SBI_CFG   : t_sbi_bfm_config := (
    max_wait_cycles            => 0,
    max_wait_cycles_severity   => error,
    use_fixed_wait_cycles_read => false,
    fixed_wait_cycles_read     => 0,
    clock_period               => -1 ns,
    clock_period_margin        => 0 ns,
    clock_margin_severity      => TB_ERROR,
    setup_time                 => -1 ns,
    hold_time                  => -1 ns,
    bfm_sync                   => SYNC_ON_CLOCK_ONLY,
    match_strictness           => MATCH_EXACT,
    id_for_bfm                 => ID_BFM,
    id_for_bfm_wait            => ID_BFM_WAIT,
    id_for_bfm_poll            => ID_BFM_POLL,
    use_ready_signal           => true
  );

  -- Number of checks (chk, chk_itm, chk_int) since the start of the
  -- simulation, logged at the end by the sequencer
  impure function nb_checks return natural;

  -- SBI write
  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- SBI read and check
  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- Check of itm_o
  procedure chk_itm
    (signal   itm      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    );

  -- Check of an integer (latency)
  procedure chk_int
    (constant val      : in    integer
    ;constant exp      : in    integer
    ;constant msg      : in    string
    );

  -- Wait n rising edges
  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    );

  -- Drive the interrupt lines on a falling edge
  procedure set_its
    (constant v        : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   its      : out   std_logic_vector
    );

  -- Lines are latched in ISR at most 3 cycles after a change (synchronizer)
  procedure settle
    (signal   clk      : in    std_logic
    );

  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

  -- ISR value of a vector of lines (line i = bit i)
  function to_isr
    (constant v        : in    std_logic_vector
    ) return std_logic_vector;

  -- ISR value with only bit i set
  function one_hot
    (constant i        : in    natural
    ) return std_logic_vector;

end package tb_GIC_bfm_pkg;

package body tb_GIC_bfm_pkg is

  type t_counter is protected
    procedure increment;
    impure function get return natural;
  end protected t_counter;

  type t_counter is protected body
    variable cnt : natural := 0;

    procedure increment is
    begin
      cnt := cnt + 1;
    end procedure;

    impure function get return natural is
    begin
      return cnt;
    end function;
  end protected body t_counter;

  shared variable checks : t_counter;

  impure function nb_checks return natural is
  begin
    return checks.get;
  end function;

  procedure wr
    (constant addr     : in    unsigned
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_write(addr_value => addr
             ,data_value => data
             ,msg        => msg
             ,clk        => clk
             ,sbi_if     => sbi_if
             ,scope      => C_TB_SCOPE
             ,config     => C_SBI_CFG
             );
  end procedure;

  procedure chk
    (constant addr     : in    unsigned
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_check(addr_value  => addr
             ,data_exp    => data
             ,msg         => msg
             ,clk         => clk
             ,sbi_if      => sbi_if
             ,alert_level => error
             ,scope       => C_TB_SCOPE
             ,config      => C_SBI_CFG
             );
    checks.increment;
  end procedure;

  procedure chk_itm
    (signal   itm      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    ) is
  begin
    check_value(itm, exp, error, msg, C_TB_SCOPE);
    checks.increment;
  end procedure;

  procedure chk_int
    (constant val      : in    integer
    ;constant exp      : in    integer
    ;constant msg      : in    string
    ) is
  begin
    check_value(val, exp, error, msg, C_TB_SCOPE);
    checks.increment;
  end procedure;

  procedure cycles
    (constant n        : in    natural
    ;signal   clk      : in    std_logic
    ) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

  procedure set_its
    (constant v        : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   its      : out   std_logic_vector
    ) is
  begin
    wait until falling_edge(clk);
    its <= v;
  end procedure;

  procedure settle
    (signal   clk      : in    std_logic
    ) is
  begin
    cycles(4, clk);
    wait until falling_edge(clk);
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait for 100 ns;
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
  end procedure;

  function to_isr
    (constant v        : in    std_logic_vector
    ) return std_logic_vector is
  begin
    return std_logic_vector(resize(unsigned(v), 8));
  end function;

  function one_hot
    (constant i        : in    natural
    ) return std_logic_vector is
    variable res : std_logic_vector(8-1 downto 0) := (others => '0');
  begin
    res(i) := '1';
    return res;
  end function;

end package body tb_GIC_bfm_pkg;

-------------------------------------------------------------------------------
-- Title      : tb_GIC
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM/SBI self-checking testbench for sbi_GIC
--              NB_LINES  : number of interrupt lines (1 to 8)
--              SYNC_MASK : ITS_SYNC_ENABLE, bit i = synchronizer on line i
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.GIC_pkg.all;
use     asylum.GIC_csr_pkg.all;

entity tb_GIC is
  generic (
    NB_LINES  : positive := 8;  -- Number of interrupt lines
    SYNC_MASK : natural  := 0   -- ITS_SYNC_ENABLE (bit i : line i)
  );
end entity tb_GIC;

architecture sim of tb_GIC is

  constant C_SCOPE      : string  := "TB_GIC";
  constant C_ADDR_WIDTH : natural := GIC_ADDR_WIDTH;
  constant C_DATA_WIDTH : natural := GIC_DATA_WIDTH;
  constant C_NB_RANDOM  : natural := 32;

  constant C_ITS_SYNC_ENABLE : std_logic_vector(NB_LINES-1 downto 0) :=
    std_logic_vector(to_unsigned(SYNC_MASK mod 2**NB_LINES, NB_LINES));

  -- Zero wait state target : any cycle with ready = '0' is an error
  constant C_SBI_CFG    : t_sbi_bfm_config := (
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

  signal clk_i          : std_logic := '0';
  signal clk_ena        : boolean   := true;
  signal arst_b_i       : std_logic := '0';

  signal sbi_ini        : sbi_ini_t(addr (C_ADDR_WIDTH-1 downto 0),
                                    wdata(C_DATA_WIDTH-1 downto 0));
  signal sbi_tgt        : sbi_tgt_t(rdata(C_DATA_WIDTH-1 downto 0));

  signal sbi_if         : t_sbi_if(addr (C_ADDR_WIDTH-1 downto 0),
                                   wdata(C_DATA_WIDTH-1 downto 0),
                                   rdata(C_DATA_WIDTH-1 downto 0));

  signal its_i          : std_logic_vector(NB_LINES-1 downto 0) := (others => '0');
  signal itm_o          : std_logic;

begin

  clock_generator(clk_i, clk_ena, 20 ns, "TB Clock");

  ins_dut : sbi_GIC
    generic map (
      NAME            => "GIC",
      ITS_SYNC_ENABLE => C_ITS_SYNC_ENABLE
    )
    port map (
      clk_i           => clk_i,
      arst_b_i        => arst_b_i,
      sbi_ini_i       => sbi_ini,
      sbi_tgt_o       => sbi_tgt,
      its_i           => its_i,
      itm_o           => itm_o
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  p_sequencer : process
    variable v_checks : natural  := 0;
    variable v_seed1  : positive := 3;
    variable v_seed2  : positive := 77 + NB_LINES*256 + SYNC_MASK;
    variable v_r      : real;
    variable v_imr    : std_logic_vector(7 downto 0);
    variable v_its    : std_logic_vector(NB_LINES-1 downto 0);
    variable v_isr    : std_logic_vector(7 downto 0);
    variable v_clr    : std_logic_vector(7 downto 0);
    variable v_n      : natural;
    variable v_exp    : natural;

    procedure wr(constant addr : in unsigned; constant data : in std_logic_vector; constant msg : in string) is
    begin
      sbi_write(addr, data, msg, clk_i, sbi_if, C_SCOPE, shared_msg_id_panel, C_SBI_CFG);
    end procedure;

    procedure chk(constant addr : in unsigned; constant data : in std_logic_vector; constant msg : in string) is
    begin
      sbi_check(addr, data, msg, clk_i, sbi_if, error, C_SCOPE, shared_msg_id_panel, C_SBI_CFG);
      v_checks := v_checks + 1;
    end procedure;

    procedure chk_itm(constant exp : in std_logic; constant msg : in string) is
    begin
      check_value(itm_o, exp, error, msg, C_SCOPE);
      v_checks := v_checks + 1;
    end procedure;

    procedure chk_int(constant val, exp : in integer; constant msg : in string) is
    begin
      check_value(val, exp, error, msg, C_SCOPE);
      v_checks := v_checks + 1;
    end procedure;

    procedure cycles(constant n : in natural) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk_i);
      end loop;
    end procedure;

    -- Drive the interrupt lines on a falling edge
    procedure set_its(constant v : in std_logic_vector) is
    begin
      wait until falling_edge(clk_i);
      its_i <= v;
    end procedure;

    -- Lines are latched in ISR at most 3 cycles after a change (synchronizer)
    procedure settle is
    begin
      cycles(4);
      wait until falling_edge(clk_i);
    end procedure;

    function to_isr(v : std_logic_vector) return std_logic_vector is
    begin
      return std_logic_vector(resize(unsigned(v), 8));
    end function;

    function one_hot(i : natural) return std_logic_vector is
      variable res : std_logic_vector(7 downto 0) := (others => '0');
    begin
      res(i) := '1';
      return res;
    end function;

    function lat(i : natural) return natural is
    begin
      -- 1 cycle for the ISR register, 2 more with the synchronizer
      if C_ITS_SYNC_ENABLE(i) = '1' then
        return 3;
      else
        return 1;
      end if;
    end function;

    procedure do_reset is
    begin
      arst_b_i <= '0';
      wait for 100 ns;
      arst_b_i <= '1';
      wait until rising_edge(clk_i);
    end procedure;

    constant C_ALL : std_logic_vector(NB_LINES-1 downto 0) := (others => '1');
    constant C_NONE: std_logic_vector(NB_LINES-1 downto 0) := (others => '0');

  begin
    sbi_if <= init_sbi_if_signals(C_ADDR_WIDTH, C_DATA_WIDTH);
    do_reset;

    log(ID_LOG_HDR, "NB_LINES = " & integer'image(NB_LINES) & ", ITS_SYNC_ENABLE = " & to_string(C_ITS_SYNC_ENABLE, BIN, AS_IS), C_SCOPE);

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T1 : Reset values", C_SCOPE);
    -------------------------------------------------------------------------
    chk(GIC_ISR, x"00", "ISR reset value");
    chk(GIC_IMR, x"00", "IMR reset value (all lines masked)");
    chk_itm('0', "itm_o after reset");

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T2 : IMR read/write (lines inactive)", C_SCOPE);
    -------------------------------------------------------------------------
    for v in 0 to 3 loop
      v_imr := std_logic_vector(to_unsigned((v * 85 + 17) mod 256, 8));
      wr (GIC_IMR, v_imr, "Write IMR");
      chk(GIC_IMR, v_imr, "Read back IMR");
    end loop;
    wr (GIC_IMR, x"FF", "Write IMR 0xFF");
    chk(GIC_IMR, x"FF", "Read back IMR 0xFF");
    chk(GIC_ISR, x"00", "ISR still 0 (no active line)");

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T3 : Masked lines are not latched", C_SCOPE);
    -------------------------------------------------------------------------
    wr (GIC_IMR, x"00", "Mask every line");
    set_its(C_ALL);
    settle;
    chk(GIC_ISR, x"00", "ISR = 0 with every line active and masked");
    chk_itm('0', "itm_o = 0 with every line masked");
    set_its(C_NONE);
    settle;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T4 : Only the unmasked line is latched (every line active)", C_SCOPE);
    -------------------------------------------------------------------------
    for i in 0 to NB_LINES-1 loop
      wr (GIC_IMR, one_hot(i), "Unmask line " & integer'image(i));
      set_its(C_ALL);
      settle;
      chk(GIC_ISR, one_hot(i), "ISR = line " & integer'image(i) & " only");
      chk_itm('1', "itm_o = 1");
      set_its(C_NONE);
      settle;
      chk(GIC_ISR, one_hot(i), "ISR bit stays set after the line falls (latched)");
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " (write 1)");
      chk(GIC_ISR, x"00", "ISR cleared");
      wait until falling_edge(clk_i);
      chk_itm('0', "itm_o = 0 after the clear");
    end loop;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T5 : Latency its_i -> itm_o and 1-cycle pulse capture", C_SCOPE);
    -------------------------------------------------------------------------
    wr(GIC_IMR, x"FF", "Unmask every line");
    for i in 0 to NB_LINES-1 loop
      -- Latency
      v_its    := C_NONE;
      v_its(i) := '1';
      set_its(v_its);
      v_n := 0;
      loop
        wait until rising_edge(clk_i);
        v_n := v_n + 1;
        wait until falling_edge(clk_i);
        exit when itm_o = '1' or v_n = 10;
      end loop;
      chk_int(v_n, lat(i), "Line " & integer'image(i) & " latency its_i -> itm_o (cycles), sync=" & std_logic'image(C_ITS_SYNC_ENABLE(i)));
      set_its(C_NONE);
      settle;
      wr (GIC_ISR, x"FF", "Clear every ISR bit");
      chk(GIC_ISR, x"00", "ISR cleared");

      -- One cycle pulse
      set_its(v_its);
      set_its(C_NONE);
      settle;
      chk(GIC_ISR, one_hot(i), "1-cycle pulse on line " & integer'image(i) & " latched");
      wr (GIC_ISR, one_hot(i), "Clear");
    end loop;
    if NB_LINES > 1 and C_ITS_SYNC_ENABLE(0) /= C_ITS_SYNC_ENABLE(NB_LINES-1) then
      log(ID_SEQUENCER, "Mixed synchronizers : latency difference of 2 cycles checked between lines", C_SCOPE);
    end if;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T6 : rw1c : write 1 clears, write 0 has no effect", C_SCOPE);
    -------------------------------------------------------------------------
    wr(GIC_IMR, x"FF", "Unmask every line");
    set_its(C_ALL);
    set_its(C_NONE);
    settle;
    v_isr := to_isr(C_ALL);
    chk(GIC_ISR, v_isr, "Every line latched, ISR bits above NB_LINES stay 0");
    wr (GIC_ISR, x"00", "Write 0x00 : no effect");
    chk(GIC_ISR, v_isr, "ISR unchanged");
    wr (GIC_ISR, x"55", "Write 0x55 : clear even bits");
    v_isr := v_isr and x"AA";
    chk(GIC_ISR, v_isr, "Only the even bits are cleared");
    wait until falling_edge(clk_i);
    chk_itm(or v_isr, "itm_o = OR(ISR)");
    wr (GIC_ISR, x"AA", "Write 0xAA : clear odd bits");
    chk(GIC_ISR, x"00", "ISR cleared");
    wait until falling_edge(clk_i);
    chk_itm('0', "itm_o = 0");

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T7 : ISR bit set again when the source stays active", C_SCOPE);
    -------------------------------------------------------------------------
    for i in 0 to NB_LINES-1 loop
      v_its    := C_NONE;
      v_its(i) := '1';
      set_its(v_its);
      settle;
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " while the source is active");
      -- The clear wins during one cycle, the active source sets the bit again on the next cycle
      chk(GIC_ISR, x"00"      , "ISR bit cleared during one cycle");
      chk(GIC_ISR, one_hot(i) , "ISR bit set again (source still active)");
      wait until falling_edge(clk_i);
      chk_itm('1', "itm_o = 1 (source still active)");
      set_its(C_NONE);
      settle;
      wr (GIC_ISR, one_hot(i), "Clear line " & integer'image(i) & " after the source falls");
      chk(GIC_ISR, x"00", "ISR stays cleared");
    end loop;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T8 : Masking a latched line does not clear it", C_SCOPE);
    -------------------------------------------------------------------------
    set_its(C_ALL);
    settle;
    wr (GIC_IMR, x"00", "Mask every line, sources still active");
    chk(GIC_ISR, to_isr(C_ALL), "ISR bits stay set after masking");
    wait until falling_edge(clk_i);
    chk_itm('1', "itm_o stays 1");
    wr (GIC_ISR, x"FF", "Clear every bit");
    settle;
    chk(GIC_ISR, x"00", "ISR stays 0 (lines masked although active)");
    chk_itm('0', "itm_o = 0");
    set_its(C_NONE);
    settle;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T9 : " & integer'image(C_NB_RANDOM) & " random IMR / line patterns : ISR = OR(IMR and its), itm_o = OR(ISR)", C_SCOPE);
    -------------------------------------------------------------------------
    v_isr := x"00";
    for n in 1 to C_NB_RANDOM loop
      uniform(v_seed1, v_seed2, v_r);
      v_imr := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)), 8));
      uniform(v_seed1, v_seed2, v_r);
      v_its := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)) mod 2**NB_LINES, NB_LINES));
      wr(GIC_IMR, v_imr, "Random IMR");
      set_its(v_its);
      set_its(C_NONE);
      settle;
      v_isr := v_isr or (v_imr and to_isr(v_its));
      chk(GIC_ISR, v_isr, "ISR accumulates the unmasked lines");
      wait until falling_edge(clk_i);
      chk_itm(or v_isr, "itm_o = OR(ISR)");
      -- clear a random subset
      uniform(v_seed1, v_seed2, v_r);
      v_clr := std_logic_vector(to_unsigned(integer(floor(v_r * 256.0)), 8));
      wr(GIC_ISR, v_clr, "Clear a random subset");
      v_isr := v_isr and not v_clr;
      chk(GIC_ISR, v_isr, "ISR after the clear");
    end loop;

    -------------------------------------------------------------------------
    log(ID_LOG_HDR, "T10 : Asynchronous reset", C_SCOPE);
    -------------------------------------------------------------------------
    wr(GIC_IMR, x"FF", "Unmask every line");
    set_its(C_ALL);
    set_its(C_NONE);
    settle;
    chk_itm('1', "itm_o = 1 before reset");
    do_reset;
    chk(GIC_ISR, x"00", "ISR after reset");
    chk(GIC_IMR, x"00", "IMR after reset");
    chk_itm('0', "itm_o after reset");

    log(ID_LOG_HDR, "Number of checks : " & integer'image(v_checks), C_SCOPE);
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process;

end architecture sim;

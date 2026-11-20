-------------------------------------------------------------------------------
-- Title      : tb_GIC
-- Project    : GIC
-------------------------------------------------------------------------------
-- File       : tb_GIC.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM/SBI self-checking testbench for sbi_GIC
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_GIC_tests_pkg), each one after a reset
--                           pulse ; "" : build and elaboration only
--              NB_LINES   : number of interrupt lines (1 to 8)
--              SYNC_MASK  : ITS_SYNC_ENABLE, bit i = synchronizer on line i
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-- 2026-11-19  1.1      mrosiere TESTS_LIST, one package per scenario
--                               (tb_GIC_<name>_pkg), helpers in
--                               tb_GIC_bfm_pkg, reset pulse before each
--                               scenario
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.GIC_pkg.all;
use     asylum.GIC_csr_pkg.all;

library work;
use     work.tb_GIC_bfm_pkg.all;
use     work.tb_GIC_tests_pkg.all;

entity tb_GIC is
  generic (
    TESTS_LIST : string   := "";  -- Scenarios, e.g. "reset_values,rw1c"
    NB_LINES   : positive := 8;   -- Number of interrupt lines
    SYNC_MASK  : natural  := 0    -- ITS_SYNC_ENABLE (bit i : line i)
  );
end entity tb_GIC;

architecture sim of tb_GIC is

  constant C_SCOPE      : string  := "TB_GIC";
  constant C_ADDR_WIDTH : natural := GIC_ADDR_WIDTH;
  constant C_DATA_WIDTH : natural := GIC_DATA_WIDTH;

  constant C_ITS_SYNC_ENABLE : std_logic_vector(NB_LINES-1 downto 0) :=
    std_logic_vector(to_unsigned(SYNC_MASK mod 2**NB_LINES, NB_LINES));

  -- Same value with an ascending range : the DUT maps ITS_SYNC_ENABLE and its_i
  -- by position (rightmost element = line 0), whatever their bounds and direction
  constant C_ITS_SYNC_ENABLE_ASC : std_logic_vector(0 to NB_LINES-1) := C_ITS_SYNC_ENABLE;

  signal clk_i          : std_logic := '0';
  signal clk_ena        : boolean   := true;
  signal arst_b_i       : std_logic := '0';

  signal sbi_ini        : sbi_ini_t(addr (C_ADDR_WIDTH-1 downto 0),
                                    wdata(C_DATA_WIDTH-1 downto 0));
  signal sbi_tgt        : sbi_tgt_t(rdata(C_DATA_WIDTH-1 downto 0));

  signal sbi_if         : t_sbi_if(addr (C_ADDR_WIDTH-1 downto 0),
                                   wdata(C_DATA_WIDTH-1 downto 0),
                                   rdata(C_DATA_WIDTH-1 downto 0));

  -- Bounds not starting at 0 on purpose : line i = its_i(i+1)
  signal its_i          : std_logic_vector(NB_LINES downto 1) := (others => '0');
  signal itm_o          : std_logic;

begin

  clock_generator(clk_i, clk_ena, 20 ns, "TB Clock");

  dut : sbi_GIC
    generic map (
      NAME            => "GIC",
      ITS_SYNC_ENABLE => C_ITS_SYNC_ENABLE_ASC
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
  begin
    log(ID_LOG_HDR, "NB_LINES = " & integer'image(NB_LINES) & ", ITS_SYNC_ENABLE = " & to_string(C_ITS_SYNC_ENABLE, BIN, AS_IS) & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, bus and lines inactive : each scenario starts from reset
      sbi_if <= init_sbi_if_signals(C_ADDR_WIDTH, C_DATA_WIDTH);
      its_i  <= (others => '0');
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), C_ITS_SYNC_ENABLE, clk_i, arst_b_i, sbi_if, its_i, itm_o);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process;

end architecture sim;

-------------------------------------------------------------------------------
-- Title      : sbi_GIC_synth_top
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_GIC_synth_top.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Synthesis check top (lint_ghdl, lint_ghdl_synth) : sbi_GIC with flat and
-- constrained ports (sbi_GIC has unconstrained SBI and its_i ports and cannot
-- be a synthesis top), and it_ctrl (in the hdl fileset, not instantiated by
-- sbi_GIC). SBI address / data width : SBI_ADDR_WIDTH / SBI_DATA_WIDTH.
-- NB_LINES sets the length of its_i, ITS_SYNC_ENABLE is forwarded (NAME is
-- only in sbi_tgt.info, not connected).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.sbi_pkg.all;

entity sbi_GIC_synth_top is
  generic (
    NB_LINES         : positive := 8;
    ITS_SYNC_ENABLE  : std_logic_vector(NB_LINES-1 downto 0) := (others => '0')
  );
  port (
    clk_i         : in  std_logic;
    arst_b_i      : in  std_logic;

    -- Bus (SBI)
    cs_i          : in  std_logic;
    re_i          : in  std_logic;
    we_i          : in  std_logic;
    addr_i        : in  std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
    wdata_i       : in  std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    ready_o       : out std_logic;
    rdata_o       : out std_logic_vector(SBI_DATA_WIDTH-1 downto 0);

    -- Interrupt Interface (sbi_GIC)
    its_i         : in  std_logic_vector(NB_LINES-1 downto 0);
    itm_o         : out std_logic;

    -- it_ctrl
    it_i          : in  std_logic;
    it_val_o      : out std_logic;
    it_ack_i      : in  std_logic
  );
end entity sbi_GIC_synth_top;

architecture rtl of sbi_GIC_synth_top is

  signal sbi_ini       : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0),
                                   wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt       : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

begin

  sbi_ini.cs        <= cs_i;
  sbi_ini.re        <= re_i;
  sbi_ini.we        <= we_i;
  sbi_ini.addr      <= addr_i;
  sbi_ini.wdata     <= wdata_i;
  ready_o           <= sbi_tgt.ready;
  rdata_o           <= sbi_tgt.rdata;

  ins_sbi_GIC : entity asylum.sbi_GIC
    generic map (
      ITS_SYNC_ENABLE => ITS_SYNC_ENABLE
    )
    port map (
      clk_i           => clk_i,
      arst_b_i        => arst_b_i,
      sbi_ini_i       => sbi_ini,
      sbi_tgt_o       => sbi_tgt,
      its_i           => its_i,
      itm_o           => itm_o
    );

  ins_it_ctrl : entity asylum.it_ctrl
    port map (
      clk_i           => clk_i,
      arstn_i         => arst_b_i,
      it_i            => it_i,
      it_val_o        => it_val_o,
      it_ack_i        => it_ack_i
    );

end architecture rtl;

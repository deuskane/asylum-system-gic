-- Generated VHDL Module for GIC


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.GIC_csr_pkg.ALL;
library asylum;
use     asylum.csr_pkg.ALL;
library asylum;
use     asylum.pbi_pkg.all;

--==================================
-- Module      : GIC
-- Description : CSR for GIC
-- Width       : 8
--==================================
entity GIC_registers is
  port (
    -- Clock and Reset
    clk_i      : in  std_logic;
    arst_b_i   : in  std_logic;
    -- Bus
    pbi_ini_i  : in  pbi_ini_t;
    pbi_tgt_o  : out pbi_tgt_t;
    -- CSR
    sw2hw_o    : out GIC_sw2hw_t;
    hw2sw_i    : in  GIC_hw2sw_t
  );
end entity GIC_registers;

architecture rtl of GIC_registers is

  signal   sig_wcs   : std_logic;
  signal   sig_we    : std_logic;
  signal   sig_waddr : std_logic_vector(pbi_ini_i.addr'length-1 downto 0);
  signal   sig_wdata : std_logic_vector(pbi_ini_i.wdata'length-1 downto 0);
  signal   sig_wbusy : std_logic;

  signal   sig_rcs   : std_logic;
  signal   sig_re    : std_logic;
  signal   sig_raddr : std_logic_vector(pbi_ini_i.addr'length-1 downto 0);
  signal   sig_rdata : std_logic_vector(pbi_tgt_o.rdata'length-1 downto 0);
  signal   sig_rbusy : std_logic;

  signal   sig_busy  : std_logic;

  constant INIT_isr : std_logic_vector(8-1 downto 0) :=
             "00000000" -- value
           ;
  signal   isr_wcs       : std_logic;
  signal   isr_we        : std_logic;
  signal   isr_wdata     : std_logic_vector(8-1 downto 0);
  signal   isr_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   isr_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   isr_wbusy     : std_logic;

  signal   isr_rcs       : std_logic;
  signal   isr_re        : std_logic;
  signal   isr_rdata     : std_logic_vector(8-1 downto 0);
  signal   isr_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   isr_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   isr_rbusy     : std_logic;

  constant INIT_imr : std_logic_vector(8-1 downto 0) :=
             "00000000" -- enable
           ;
  signal   imr_wcs       : std_logic;
  signal   imr_we        : std_logic;
  signal   imr_wdata     : std_logic_vector(8-1 downto 0);
  signal   imr_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   imr_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   imr_wbusy     : std_logic;

  signal   imr_rcs       : std_logic;
  signal   imr_re        : std_logic;
  signal   imr_rdata     : std_logic_vector(8-1 downto 0);
  signal   imr_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   imr_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   imr_rbusy     : std_logic;

begin  -- architecture rtl

  -- Interface 
  sig_wcs   <= pbi_ini_i.cs;
  sig_we    <= pbi_ini_i.we;
  sig_waddr <= pbi_ini_i.addr;
  sig_wdata <= pbi_ini_i.wdata;

  sig_rcs   <= pbi_ini_i.cs;
  sig_re    <= pbi_ini_i.re;
  sig_raddr <= pbi_ini_i.addr;
  pbi_tgt_o.rdata <= sig_rdata;
  pbi_tgt_o.busy <= sig_busy;

  sig_busy  <= sig_wbusy when sig_we = '1' else
               sig_rbusy when sig_re = '1' else
               '0';

  gen_isr: if (True)
  generate
  --==================================
  -- Register    : isr
  -- Description : Interruption Status Register
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw1c
  -- Hw Access   : rw
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 8
  --==================================


    isr_rcs     <= '1' when     (sig_raddr(GIC_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,GIC_ADDR_WIDTH))) else '0';
    isr_re      <= sig_rcs and sig_re and isr_rcs;
    isr_rdata   <= (
      0 => isr_rdata_sw(0), -- value(0)
      1 => isr_rdata_sw(1), -- value(1)
      2 => isr_rdata_sw(2), -- value(2)
      3 => isr_rdata_sw(3), -- value(3)
      4 => isr_rdata_sw(4), -- value(4)
      5 => isr_rdata_sw(5), -- value(5)
      6 => isr_rdata_sw(6), -- value(6)
      7 => isr_rdata_sw(7), -- value(7)
      others => '0');

    isr_wcs     <= '1' when       (sig_waddr(GIC_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,GIC_ADDR_WIDTH)))   else '0';
    isr_we      <= sig_wcs and sig_we and isr_wcs;
    isr_wdata   <= sig_wdata;
    isr_wdata_sw(7 downto 0) <= isr_wdata(7 downto 0); -- value
    isr_wdata_hw(7 downto 0) <= hw2sw_i.isr.value; -- value
    sw2hw_o.isr.value <= isr_rdata_hw(7 downto 0); -- value

    ins_isr : csr_reg
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_isr
        ,MODEL         => "rw1c"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => isr_wdata_sw
        ,sw_rd_o       => isr_rdata_sw
        ,sw_we_i       => isr_we
        ,sw_re_i       => isr_re
        ,sw_rbusy_o    => isr_rbusy
        ,sw_wbusy_o    => isr_wbusy
        ,hw_wd_i       => isr_wdata_hw
        ,hw_rd_o       => isr_rdata_hw
        ,hw_we_i       => hw2sw_i.isr.we
        ,hw_sw_re_o    => sw2hw_o.isr.re
        ,hw_sw_we_o    => sw2hw_o.isr.we
        );

  end generate gen_isr;

  gen_isr_b: if not (True)
  generate
    isr_rcs     <= '0';
    isr_rbusy   <= '0';
    isr_rdata   <= (others => '0');
    isr_wcs      <= '0';
    isr_wbusy    <= '0';
    sw2hw_o.isr.value <= "00000000";
    sw2hw_o.isr.re <= '0';
    sw2hw_o.isr.we <= '0';
  end generate gen_isr_b;

  gen_imr: if (True)
  generate
  --==================================
  -- Register    : imr
  -- Description : Interruption Mask Register
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : enable
  -- Description : 0: interrupt is disable, 1: interrupt is enable
  -- Width       : 8
  --==================================


    imr_rcs     <= '1' when     (sig_raddr(GIC_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,GIC_ADDR_WIDTH))) else '0';
    imr_re      <= sig_rcs and sig_re and imr_rcs;
    imr_rdata   <= (
      0 => imr_rdata_sw(0), -- enable(0)
      1 => imr_rdata_sw(1), -- enable(1)
      2 => imr_rdata_sw(2), -- enable(2)
      3 => imr_rdata_sw(3), -- enable(3)
      4 => imr_rdata_sw(4), -- enable(4)
      5 => imr_rdata_sw(5), -- enable(5)
      6 => imr_rdata_sw(6), -- enable(6)
      7 => imr_rdata_sw(7), -- enable(7)
      others => '0');

    imr_wcs     <= '1' when       (sig_waddr(GIC_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,GIC_ADDR_WIDTH)))   else '0';
    imr_we      <= sig_wcs and sig_we and imr_wcs;
    imr_wdata   <= sig_wdata;
    imr_wdata_sw(7 downto 0) <= imr_wdata(7 downto 0); -- enable
    sw2hw_o.imr.enable <= imr_rdata_hw(7 downto 0); -- enable

    ins_imr : csr_reg
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_imr
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => imr_wdata_sw
        ,sw_rd_o       => imr_rdata_sw
        ,sw_we_i       => imr_we
        ,sw_re_i       => imr_re
        ,sw_rbusy_o    => imr_rbusy
        ,sw_wbusy_o    => imr_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => imr_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.imr.re
        ,hw_sw_we_o    => sw2hw_o.imr.we
        );

  end generate gen_imr;

  gen_imr_b: if not (True)
  generate
    imr_rcs     <= '0';
    imr_rbusy   <= '0';
    imr_rdata   <= (others => '0');
    imr_wcs      <= '0';
    imr_wbusy    <= '0';
    sw2hw_o.imr.enable <= "00000000";
    sw2hw_o.imr.re <= '0';
    sw2hw_o.imr.we <= '0';
  end generate gen_imr_b;

  sig_wbusy <= 
    isr_wbusy when isr_wcs = '1' else
    imr_wbusy when imr_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    isr_rbusy when isr_rcs = '1' else
    imr_rbusy when imr_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    isr_rdata when isr_rcs = '1' else
    imr_rdata when imr_rcs = '1' else
    (others => '0'); -- Bad Address, return 0
end architecture rtl;

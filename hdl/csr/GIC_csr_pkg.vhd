-- Generated VHDL Package for GIC

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.sbi_pkg.all;
--==================================
-- Module      : GIC
-- Description : CSR for GIC
-- Width       : 8
--==================================

package GIC_csr_pkg is

  --==================================
  -- Register    : isr
  -- Description : Interruption Status Register
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw1c
  -- Hw Access   : rw
  -- Hw Type     : reg
  --==================================
  type GIC_isr_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record GIC_isr_sw2hw_t;

  type GIC_isr_hw2sw_t is record
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record GIC_isr_hw2sw_t;

  --==================================
  -- Register    : imr
  -- Description : Interruption Mask Register
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type GIC_imr_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : enable
  -- Description : 0: interrupt is disable, 1: interrupt is enable
  -- Width       : 8
  --==================================
    enable : std_logic_vector(8-1 downto 0);
  end record GIC_imr_sw2hw_t;

  ------------------------------------
  -- Structure GIC_t
  ------------------------------------
  type GIC_sw2hw_t is record
    isr : GIC_isr_sw2hw_t;
    imr : GIC_imr_sw2hw_t;
  end record GIC_sw2hw_t;

  type GIC_hw2sw_t is record
    isr : GIC_isr_hw2sw_t;
  end record GIC_hw2sw_t;

  constant GIC_ADDR_WIDTH : natural := 1;
  constant GIC_DATA_WIDTH : natural := 8;

  ------------------------------------
  -- Component
  ------------------------------------
component GIC_registers is
  port (
    -- Clock and Reset
    clk_i      : in  std_logic;
    arst_b_i   : in  std_logic;
    -- Bus
    sbi_ini_i  : in  sbi_ini_t;
    sbi_tgt_o  : out sbi_tgt_t;
    -- CSR
    sw2hw_o    : out GIC_sw2hw_t;
    hw2sw_i    : in  GIC_hw2sw_t
  );
end component GIC_registers;


end package GIC_csr_pkg;

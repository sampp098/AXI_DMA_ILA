library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXIS_Cache_HDL_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S_AXI_CTRL
		C_S_AXI_CTRL_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_CTRL_ADDR_WIDTH	: integer	:= 5;

		-- Parameters of Axi Slave Bus Interface S_AXIS_input
		C_S_AXIS_input_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M_AXIS_output
		C_M_AXIS_output_TDATA_WIDTH	: integer	:= 32;
		C_M_AXIS_output_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        signal row_or_col_o : out std_logic := '0';

        signal write_stream_done_o  : out std_logic := '0';
        signal read_stream_done_o : out std_logic := '0';
        
        signal start_read_stream_pulse_o : out std_logic := '0';
        signal start_write_stream_pulse_o: out std_logic := '0';
        
        signal start_read_stream_monitor   : out std_logic_vector(1 downto 0) := "00";
        signal start_write_stream_monitor  : out std_logic_vector(1 downto 0) := "00";
        signal read_stream_pointer_monitor : out std_logic_vector(5 downto 0) := "000000";
        signal write_stream_pointer_monitor: out std_logic_vector(5 downto 0) := "000000";
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface S_AXI_CTRL
		s_axi_ctrl_aclk	: in std_logic;
		s_axi_ctrl_aresetn	: in std_logic;
		s_axi_ctrl_awaddr	: in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
		s_axi_ctrl_awprot	: in std_logic_vector(2 downto 0);
		s_axi_ctrl_awvalid	: in std_logic;
		s_axi_ctrl_awready	: out std_logic;
		s_axi_ctrl_wdata	: in std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
		s_axi_ctrl_wstrb	: in std_logic_vector((C_S_AXI_CTRL_DATA_WIDTH/8)-1 downto 0);
		s_axi_ctrl_wvalid	: in std_logic;
		s_axi_ctrl_wready	: out std_logic;
		s_axi_ctrl_bresp	: out std_logic_vector(1 downto 0);
		s_axi_ctrl_bvalid	: out std_logic;
		s_axi_ctrl_bready	: in std_logic;
		s_axi_ctrl_araddr	: in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
		s_axi_ctrl_arprot	: in std_logic_vector(2 downto 0);
		s_axi_ctrl_arvalid	: in std_logic;
		s_axi_ctrl_arready	: out std_logic;
		s_axi_ctrl_rdata	: out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
		s_axi_ctrl_rresp	: out std_logic_vector(1 downto 0);
		s_axi_ctrl_rvalid	: out std_logic;
		s_axi_ctrl_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_input
		s_axis_input_aclk	: in std_logic;
		s_axis_input_aresetn	: in std_logic;
		s_axis_input_tready	: out std_logic;
		s_axis_input_tdata	: in std_logic_vector(C_S_AXIS_input_TDATA_WIDTH-1 downto 0);
		s_axis_input_tkeep	: in std_logic_vector((C_S_AXIS_input_TDATA_WIDTH/8)-1 downto 0);
		s_axis_input_tlast	: in std_logic;
		s_axis_input_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M_AXIS_output
		m_axis_output_aclk	: in std_logic;
		m_axis_output_aresetn	: in std_logic;
		m_axis_output_tvalid	: out std_logic;
		m_axis_output_tdata	: out std_logic_vector(C_M_AXIS_output_TDATA_WIDTH-1 downto 0);
		m_axis_output_tkeep	: out std_logic_vector((C_M_AXIS_output_TDATA_WIDTH/8)-1 downto 0);
		m_axis_output_tlast	: out std_logic;
		m_axis_output_tready	: in std_logic
	);
end AXIS_Cache_HDL_v1_0;

architecture arch_imp of AXIS_Cache_HDL_v1_0 is

	-- component declaration
	component AXIS_Cache_HDL_v1_0_S_AXI_CTRL is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		input_reg0 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg1 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg2 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg3 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg4 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg5 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg6 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        input_reg7 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        output_reg0 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg1 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg2 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg3 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg4 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg5 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg6 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        output_reg7 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component AXIS_Cache_HDL_v1_0_S_AXI_CTRL;
	
	signal   write_stream_pointer  : integer :=0;
	signal   read_stream_pointer : integer :=0;
	constant MAX_WORDS     : integer :=32;
	
	type word   is array(31 downto 0) of std_logic;
	type memory is array(31 downto 0) of word;
	
	signal cache : memory := (others => (others =>'0'));
	
	signal row_or_col : std_logic := '0';--reg0
	signal start_read_stream : std_logic := '0';--reg1
	signal start_write_stream: std_logic := '0';--reg2
	signal write_stream_done  : std_logic := '0';--reg3
	signal read_stream_done : std_logic := '0';--reg4
	
	signal start_read_stream_pulse : std_logic := '0';
	signal start_write_stream_pulse: std_logic := '0';
	signal read_stream_pulse_ff : std_logic := '0';
	signal write_stream_pulse_ff: std_logic := '0';
	
	signal reg0 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg1 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg2 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg3 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg4 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg5 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg6 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	signal reg7 : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
	
	type rstate is ( idle,
	 				busy,
	 				finish);
	type wstate is ( idle,
	 				busy,
	 				finish);

	 signal read_stream_state  : rstate ;
	 signal write_stream_state : wstate ;
	 signal output_tlast       : std_logic := '0';
begin

-- Instantiation of Axi Bus Interface S_AXI_CTRL
AXIS_Cache_HDL_v1_0_S_AXI_CTRL_inst : AXIS_Cache_HDL_v1_0_S_AXI_CTRL
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_CTRL_ADDR_WIDTH
	)
	port map (
	    input_reg0 => reg0,
        input_reg1 => reg1,
        input_reg2 => reg2,
        input_reg3 => reg3,
        input_reg4 => reg4,
        input_reg5 => reg5,
        input_reg6 => reg6,
        input_reg7 => reg7,
                   
        output_reg0 => reg0,   
        output_reg1 => reg1,
        output_reg2 => reg2,
        output_reg3 => open,
        output_reg4 => open,
        output_reg5 => reg5,
        output_reg6 => reg6,
        output_reg7 => reg7,
		S_AXI_ACLK	=> s_axi_ctrl_aclk,
		S_AXI_ARESETN	=> s_axi_ctrl_aresetn,
		S_AXI_AWADDR	=> s_axi_ctrl_awaddr,
		S_AXI_AWPROT	=> s_axi_ctrl_awprot,
		S_AXI_AWVALID	=> s_axi_ctrl_awvalid,
		S_AXI_AWREADY	=> s_axi_ctrl_awready,
		S_AXI_WDATA	=> s_axi_ctrl_wdata,
		S_AXI_WSTRB	=> s_axi_ctrl_wstrb,
		S_AXI_WVALID	=> s_axi_ctrl_wvalid,
		S_AXI_WREADY	=> s_axi_ctrl_wready,
		S_AXI_BRESP	=> s_axi_ctrl_bresp,
		S_AXI_BVALID	=> s_axi_ctrl_bvalid,
		S_AXI_BREADY	=> s_axi_ctrl_bready,
		S_AXI_ARADDR	=> s_axi_ctrl_araddr,
		S_AXI_ARPROT	=> s_axi_ctrl_arprot,
		S_AXI_ARVALID	=> s_axi_ctrl_arvalid,
		S_AXI_ARREADY	=> s_axi_ctrl_arready,
		S_AXI_RDATA	=> s_axi_ctrl_rdata,
		S_AXI_RRESP	=> s_axi_ctrl_rresp,
		S_AXI_RVALID	=> s_axi_ctrl_rvalid,
		S_AXI_RREADY	=> s_axi_ctrl_rready
	);
-- Instantiation of Axi Bus Interface S_AXIS_input
-- Instantiation of Axi Bus Interface S_AXIS_input
-- Instantiation of Axi Bus Interface S_AXIS_input
    process(s_axis_input_aclk)
	begin
	  if (rising_edge (s_axis_input_aclk)) then
	    if(s_axis_input_aresetn = '0') then
	      cache <= (others => (others =>'0'));

	      read_stream_state <= idle;
	      read_stream_done<= '0';
	      read_stream_pointer <= 0;
	      s_axis_input_tready <= '0';
	    else
	      if (read_stream_state = idle) then
	           if(start_read_stream_pulse='1')then
	              read_stream_state <= busy;
                  read_stream_done<= '0';
                  read_stream_pointer <= 0;
                  s_axis_input_tready <= '1';
	           else
	              read_stream_state <= idle;
                  read_stream_done<= '0';
                  read_stream_pointer <= 0;
                  s_axis_input_tready <= '0';
	           end if;
	      elsif (read_stream_state = busy) then
	           if(s_axis_input_tvalid= '1' and read_stream_pointer < MAX_WORDS-1)then
	              read_stream_state <= busy;
                  read_stream_pointer <=  read_stream_pointer+1;
                  s_axis_input_tready <= '1';
                  if(row_or_col = '0')then
                  --row
                       for i in 0 to 31 loop
                           cache(read_stream_pointer)(i) <= s_axis_input_tdata(i);
                       end loop;
                  else
                  --col
                       for i in 0 to 31 loop
                           cache(i)(read_stream_pointer) <= s_axis_input_tdata(i);
                       end loop;
                  end if;
               elsif(s_axis_input_tvalid= '1' and read_stream_pointer >= MAX_WORDS-1)then
                  if(s_axis_input_TLAST = '1')then
                       read_stream_state <= idle;
                       s_axis_input_tready <= '0';
                  else
                       read_stream_state <= finish;
                       s_axis_input_tready <= '1';
                  end if;
                  read_stream_done<= '1';
                  read_stream_pointer <= 0;
                  
                  if(row_or_col = '0')then
                  --row
                       for i in 0 to 31 loop
                           cache(read_stream_pointer)(i) <= s_axis_input_tdata(i);
                       end loop;
                  else
                  --col
                       for i in 0 to 31 loop
                           cache(i)(read_stream_pointer) <= s_axis_input_tdata(i);
                       end loop;
                  end if;
                  
               else
                  
               end if;
	      elsif (read_stream_state = finish)then
	           if(s_axis_input_TLAST = '1')then
	              read_stream_state <= idle;
                  read_stream_done<= '0';
                  read_stream_pointer <= 0;
                  s_axis_input_tready <= '0';
	           else
	              read_stream_state <= finish;
                  read_stream_done<= '0';
                  read_stream_pointer <= 0;
                  s_axis_input_tready <= '1';
	           end if;
	      else
	      
	      end if;
	    end if;
	  end if;
	end process;

-- Instantiation of Axi Bus Interface M_AXIS_output
-- Instantiation of Axi Bus Interface M_AXIS_output
-- Instantiation of Axi Bus Interface M_AXIS_output
    process(s_axis_input_aclk)
	begin
	  if (rising_edge (s_axis_input_aclk)) then
	    if(s_axis_input_aresetn = '0') then
	      write_stream_done <= '0';
	      write_stream_pointer <= 0;
	      write_stream_state <= idle;
	      output_tlast <= '0';
	      m_axis_output_tvalid <= '0';
	    else
	    
	       if(write_stream_state = idle) then
	           if(start_write_stream_pulse='1' ) then --start a transaction
	               write_stream_done <= '0';
                   write_stream_pointer <= 0;
                   write_stream_state <= busy;
                   output_tlast <= '0';
	               m_axis_output_tvalid <= '0';
	           else
	               write_stream_done <= '0';
                   write_stream_pointer <= 0;
                   write_stream_state <= idle;
                   output_tlast <= '0';
	               m_axis_output_tvalid <= '0';
	           end if;
	       elsif(write_stream_state = busy)then
	           if(m_axis_output_tready = '1' and write_stream_pointer < MAX_WORDS-1) then--continue transaction befor the last transaction
	               for i in 0 to 31 loop
	                   m_axis_output_tdata(i) <= cache(write_stream_pointer)(i);
	               end loop;
	               write_stream_done <= '0';
                   write_stream_pointer <= write_stream_pointer+1;
                   write_stream_state <= busy;
                   output_tlast <= '0';
	               m_axis_output_tvalid <= '1';
	           elsif(m_axis_output_tready = '1' and (write_stream_pointer = MAX_WORDS-1)) then--Last transaction
	               for i in 0 to 31 loop
	                   m_axis_output_tdata(i) <= cache(write_stream_pointer)(i);
	               end loop;
	               write_stream_done <= '1';
                   write_stream_pointer <= 0;
                   write_stream_state <= finish;
                   output_tlast <= '1';
	               m_axis_output_tvalid <= '1';
	           else
	           
	           end if;
	       
	       elsif(write_stream_state = finish)then
	           if(m_axis_output_tready = '1' and  output_tlast = '1') then
	               write_stream_done <= '1';
                   write_stream_pointer <= 0;
                   write_stream_state <= idle;
                   output_tlast <= '0';
	               m_axis_output_tvalid <= '0';
	           else
	           
	           end if;
	       end if;

	    end if;
	  end if;
	end process;
    
    read_pulse: process(s_axis_input_aclk)
    begin
        if rising_edge(s_axis_input_aclk) then
            read_stream_pulse_ff <= start_read_stream;
            if start_read_stream = '1' and read_stream_pulse_ff ='0' then
                start_read_stream_pulse <='1';
            else
                start_read_stream_pulse <='0';
            end if;
        end if;
    end process;
    
    write_pulse: process(s_axis_input_aclk)
    begin
        if rising_edge(s_axis_input_aclk) then
            write_stream_pulse_ff <= start_write_stream;
            if start_write_stream = '1' and write_stream_pulse_ff ='0' then
                start_write_stream_pulse <='1';
            else
                start_write_stream_pulse <='0';
            end if;
        end if;
    end process;
    
	-- Add user logic here
    row_or_col <= reg0(0);--reg0
	start_read_stream <= reg1(0);--reg1
	start_write_stream<= reg2(0);--reg2
	
	reg3(0)    <= write_stream_done;--reg3
	reg4(0)    <= read_stream_done;--reg4
    m_axis_output_tkeep <= (others => '1');
	
	--debug
	row_or_col_o <=row_or_col;

    write_stream_done_o <=write_stream_done;
    read_stream_done_o  <=read_stream_done;
        
    start_read_stream_pulse_o <=start_read_stream_pulse;
    start_write_stream_pulse_o <=start_write_stream_pulse;

	m_axis_output_tlast <= output_tlast;
	
	start_read_stream_monitor <= "00" when read_stream_state = idle   else
	                             "01" when read_stream_state = busy   else
	                             "10" when read_stream_state = finish else
	                             "11";
    start_write_stream_monitor <= "00" when write_stream_state = idle   else
	                              "01" when write_stream_state = busy   else
	                              "10" when write_stream_state = finish else
	                              "11";
    read_stream_pointer_monitor<= std_logic_vector(to_unsigned(read_stream_pointer, read_stream_pointer_monitor'length));
    write_stream_pointer_monitor<= std_logic_vector(to_unsigned(write_stream_pointer, write_stream_pointer_monitor'length));
	-- User logic ends

end arch_imp;
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 
 
entity lab4 is 
    generic ( 
     
        STABLE_CYCLES : positive := 1_000_000 
    ); 
    port ( 
        clk          : in  STD_LOGIC; 
        i_sw_raw     : in  STD_LOGIC; 
        i_rst        : in  STD_LOGIC;
        o_led        : out STD_LOGIC; 
        o_dbg_stable : out STD_LOGIC 
    ); 
end entity lab4; 
 
architecture rtl of lab4 is 

    -- Example: 20 ms * 50 MHz = 1,000,000 cycles. 
    function clog2(n : positive) return natural is 
        variable temp : natural := n - 1; 
        variable bits : natural := 0; 
    begin 
        while temp > 0 loop 
            temp := temp / 2; 
            bits := bits + 1; 
        end loop; 
        if bits = 0 then 
            return 1; 
-`  -        ---else -
            return bits; 
        end if; 
    end function; 

    constant COUNTER_BITS   : natural := clog2(STABLE_CYCLES); 
    constant TERMINAL_COUNT : UNSIGNED(COUNTER_BITS-1 downto 0) := 
        to_unsigned(STABLE_CYCLES - 1, COUNTER_BITS); 


    signal rst_synced : STD_LOGIC;
    signal sw_active  : STD_LOGIC;


    signal sw_sync1   : STD_LOGIC; 
    signal sw_sync2   : STD_LOGIC; 

 
    signal sw_stable    : STD_LOGIC; 
    signal stable_count : UNSIGNED(COUNTER_BITS-1 downto 0) := (others => '0'); 

 
    signal evt_cur       : STD_LOGIC; 
    signal evt_prev      : STD_LOGIC; 
    signal release_event : STD_LOGIC; 


    signal led_state : STD_LOGIC := '0'; 

begin 

  
    rst_synced <= not i_rst;    
    sw_active  <= not i_sw_raw; 

 

    process(clk) 
    begin 
        if rising_edge(clk) then 

            if rst_synced = '1' then 
                sw_sync1     <= '0'; 
                sw_sync2     <= '0'; 
                sw_stable    <= '0'; 
                stable_count <= (others => '0'); 

            else 
                -- 2-FF Synchronize
                sw_sync1 <= sw_active; 
                sw_sync2 <= sw_sync1; 

                --Debounce
                if sw_sync2 = sw_stable then 
                    stable_count <= (others => '0'); 

                elsif stable_count = TERMINAL_COUNT then 
                    sw_stable    <= sw_sync2; 
                    stable_count <= (others => '0'); 

                else 
                    stable_count <= stable_count + 1; 
                end if; 
            end if; 
        end if; 
    end process; 




    release_event <= evt_prev and (not evt_cur); 

    process(clk) 
    begin 
        if rising_edge(clk) then 

            if rst_synced = '1' then 
                evt_cur   <= '0'; 
                evt_prev  <= '0'; 
                led_state <= '0'; 

            else 
                evt_prev <= evt_cur; 
                evt_cur  <= sw_stable; 

      
                if release_event = '1' then 
                    led_state <= not led_state; 
                end if; 
            end if; 
        end if; 
    end process; 

    
    o_led        <= led_state; 
    o_dbg_stable <= sw_stable; 

end architecture rtl;
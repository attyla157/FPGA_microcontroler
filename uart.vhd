


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity UART is
 Port (  
          CLK : in std_logic;
          RESET:in std_logic;       
          IOWR:in std_logic;
          IORD:in Std_logic;
          IOOUT:out std_logic_vector(7 downto 0);
          IOADR,IOIN:in std_logic_vector(7 downto 0);
          TX :out std_logic
  );
end UART;

architecture Behavioral of UART is
    Signal UCTR: std_logic_vector( 7 downto 0); -- control register
alias UCTR_EN: std_logic is UCTR(0);

    Signal UDR : std_logic_vector (7 downto 0); -- data register

    signal UF: std_logic_vector( 7 downto 0); -- flag register
alias UF_TXC: std_logic is UF(1); -- transfer complete;
alias UF_UDRE: std_logic is UF(0); -- flaga usart data ready

signal Shift_register: std_logic_vector(9 downto 0):= "1--------1";
    signal shift_count :unsigned (7 downto 0 ):= x"00";

begin

    process (reset, CLK)
    --variable place
     variable adress: std_logic_vector( 7 downto 0 );
     variable data: std_logic_vector( 7 downto 0 );
     variable reg:std_logic_vector(7 downto 0);
    begin
     -- code place
        if( RESET = '1') then 
            UCTR <= x"00";
            UDR <= x"00";
            UF <= x"00";
            shift_count <= x"00";
         elsif rising_edge(CLK) then 
           
           Shift_register(8 downto 1) <= UDR;
          -- if uart enable
          
                if(UCTR_EN = '1') then 
                 -- if transfer complete load another data from register
                   
                     UF_UDRE <= '1'; --gotowi na nowe dane 
                     TX <= shift_register(0); -- przesinuęcie na wyjsie nowego bitu
                    
                     Shift_register <= std_logic_vector(shift_right( unsigned(Shift_register),1));
                     shift_count <= shift_count + 1;
                     
                     if(shift_count = 10) then -- jesli przesunięte wszystko to transfer complete =1;
                        UF_TXC <='1';
                        Shift_register(8 downto 1) <= UDR;
                        UF_UDRE <= '0';
                      else
                        UF_UDRE <= '1'; 
                      end if;
                     
                     
                     --komunikacja 
                     
                     if IOWR = '1' then -- jeśli na lini IOWR jest 1 znaczy że mc chce wpisywać dane 
                        adress := IOADR;
                         data := IOIN;
                         case adress is  
                            when x"10" =>
                                UCTR <= data;
                            when x"11" =>
                                UDR <= data;
                            when x"12" =>
                                UF <= data;
                            when others =>
                                NULL;
                         end case;
                      end if;
                      
                      if IORD = '1' then -- jeśli na lini IORD jest 1 znaczy że mc chce odczytywać dane dane 
                            adress := IOADR;
                            reg:=UF;
                         --IOOUT;
                            case adress is  
                                when x"10" =>
                                    IOOUT <= UCTR;
                                when x"11" =>
                                   IOOUT <= UDR;
                                when x"12" =>
                                   IOOUT <= reg;
                                    
                                   UF <=x"00";
                                when others => 
                                    NULL;
                            end case;
                       end if;
                     
                   end if;
                   
                   
                 end if;
                 
                       
                              
    end process;

end Behavioral;

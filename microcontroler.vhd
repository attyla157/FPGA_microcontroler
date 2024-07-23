


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;




entity sekwencer_rozkazow is
  Port ( Z :in std_logic;
         CLK : in std_logic;
          RESET:in std_logic;
          INT:in std_logic;
          IOWR:out std_logic;
          IORD:out Std_logic;
          IOADR,IOOUT:out std_logic_vector(7 downto 0);
          IOIN:in std_logic_vector(7 downto 0);
           
        
          GPIO: out std_logic_vector( 7 downto 0) 
  );
end sekwencer_rozkazow;

architecture Behavioral of sekwencer_rozkazow is
-- pamiec programu
type rom_t is array (0 to 31) of std_logic_vector(15 downto 0);
--kody rozkazow FORMAT C_KOD & arg (przyklad C_OUTP & x"ff")
constant C_NOP: STD_LOGIC_VECTOR (7 downto 0 ) := x"00"; -- brak operacji
--constant C_OUTP: STD_LOGIC_VECTOR (7 downto 0 ) := x"01"; -- zmiana stanu wyjsc
--constant C_B: STD_LOGIC_VECTOR (7 downto 0 ) := x"02"; -- skok do komorki pamieci   
constant C_BZ: STD_LOGIC_VECTOR (7 downto 0 ) := x"03"; -- skok warunkowy jesli Z==1

--kody rozkazow wraz z maskami do rozpoznowania komend

-- ROZKAZY TYPU R ( DWA REJESTRY) 00
constant M_CMOV:std_logic_vector (15 downto 0) := "0000000000------"; -- maska -- MOV Rd,Rs  zawartosc RS dp RD (Rd <- Rs)
constant C_MOV: std_logic_vector (9 downto 0) :="0000000000"; --kod rozkau

constant M_CLD:std_logic_vector (15 downto 0) := "0000000001------"; --LD Rd,Rs zaladuj do Rd wartosc z RAM na ktora wskazuje Rs (Rd <-RAM(Rs))
constant C_LD: std_logic_vector (9 downto 0) := "0000000001";

constant M_CST:std_logic_vector(15 downto 0):="0000000010------"; --ST Rd,Rs RAM(RD) <- Rs zapisanie wartosći RS do ROM o adresie w RD
constant C_ST:std_logic_vector(9 downto 0):="0000000010";

constant M_CADC:std_logic_vector(15 downto 0):="0000000011------";  -- ADC RD, RS (Rd <- Rd+Rs+c)
constant C_ADC:std_logic_vector(9 downto 0):="0000000011";

constant M_CSBC:std_logic_vector(15 downto 0):="0000000100------";  -- SBS Rd,Rs (Rd <- Rd - Rs - C)
constant C_SBC:std_logic_vector(9 downto 0):="0000000100";

constant M_CMUL:std_logic_vector(15 downto 0):="0000000101------";  -- MUL Rd, Rs (Rd+1,Rd <-Rd * Rs) bez znaku
constant C_MUL:std_logic_vector(9 downto 0):="0000000101";

constant M_CMULS:std_logic_vector(15 downto 0):="0000000110------";  -- MULS Rd, Rs (Rd+1,Rd <-Rd * Rs)  ze znakiem
constant C_MULS:std_logic_vector(9 downto 0):="0000000110";

constant M_CAND:std_logic_vector(15 downto 0):="0000000111------";  
constant C_AND:std_logic_vector(9 downto 0):="0000000111";

constant M_COR:std_logic_vector(15 downto 0):="0000001000------";  
constant C_OR:std_logic_vector(9 downto 0):="0000001000";

constant M_CXOR:std_logic_vector(15 downto 0):="0000001001------";  
constant C_XOR:std_logic_vector(9 downto 0):="0000001001";

constant M_CCP:std_logic_vector(15 downto 0):="0000001010------";   -- porownanie zawartosci rejestwrow
constant C_CP:std_logic_vector(9 downto 0):="0000001010";


-- ROZKAZY TYPU I (REJESTR I STALA) 01 oraz 11

constant M_CLDI:std_logic_vector (15 downto 0) := "01000-----------"; -- LDI, Rd, k wpisuje stala K do rejestru Rd
constant C_LDI: std_logic_vector (4 downto 0) :="01000";

constant M_CLDS:std_logic_vector (15 downto 0) :="01001-----------"; -- LDS Rd,K (Rd <- RAM(K)) zaladuj do Rd wartosc z RAM o adresie K
constant C_LDS:std_logic_vector(4 downto 0):= "01001";

constant M_CSTS:std_logic_vector(15 downto 0):="01010-----------";  --STS K,RS  (RAM(K) <- Rs) zawartosc  Rs do RAM o adresie Rs
constant C_STS: std_logic_vector( 4 downto 0) :="01010" ;

constant M_CADCI:std_logic_vector(15 downto 0):="01011-----------";  -- ADCI RD,K (Rd <- Rd + K + C)
constant C_ADCI: std_logic_vector( 4 downto 0) :="01011" ;

constant M_CSBCI:std_logic_vector(15 downto 0):="01100-----------";  -- SBCI Rd,rs (Rd <- Rd - K -C)
constant C_SBCI: std_logic_vector( 4 downto 0) :="01100" ;

constant M_CANDI:std_logic_vector(15 downto 0):="01101-----------";  
constant C_ANDI: std_logic_vector( 4 downto 0) :="01101" ;

constant M_CORI:std_logic_vector(15 downto 0):="01110-----------";  
constant C_ORI: std_logic_vector( 4 downto 0) :="01110" ;

constant M_CXORI:std_logic_vector(15 downto 0):="01111-----------";  
constant C_XORI: std_logic_vector( 4 downto 0) :="01111" ;

constant M_CCPI:std_logic_vector(15 downto 0):="11000-----------";  
constant C_CPI: std_logic_vector( 4 downto 0) :="11000" ;

constant M_CBRBS:std_logic_vector(15 downto 0):="11001-----------"; -- skok warunkowy  wzgledny gdy S==1
constant C_BRBS: std_logic_vector(4 downto 0):= "11001";

constant M_CBRBC:std_logic_vector(15 downto 0):="11010-----------"; -- skok warunkowy  wzgledny gdy S==0
constant C_BRBC: std_logic_vector(4 downto 0):= "11010";

constant M_COUTP:std_logic_vector(15 downto 0):="11011-----------"; -- output
constant C_OUTP: std_logic_vector(4 downto 0):= "11011";

constant M_CINP:std_logic_vector(15 downto 0):="11100-----------"; -- input
constant C_INP: std_logic_vector(4 downto 0):= "11100";

-- ROZKAZY TYLKO Z PARAMETREM 10

constant M_CB: std_logic_vector(15 downto 0):="10000000--------";
constant C_B: std_logic_vector(7 downto 0):= "10000000";

constant M_CBSET:std_logic_vector(15 downto 0):="10000001--------"; -- ustaw SREG tam gdzie 1
constant C_BSET: std_logic_vector(7 downto 0):= "10000001";

constant M_CBCLR:std_logic_vector(15 downto 0):="10000010--------"; -- uwyczysc SREG tam gdzie 1
constant C_BCLR: std_logic_vector(7 downto 0):= "10000010";

constant M_CRB:std_logic_vector(15 downto 0):="10000011--------"; -- skok bezwarunkowy wzgledny
constant C_RB: std_logic_vector(7 downto 0):= "10000011";

constant M_CRCALL:std_logic_vector(15 downto 0):="10000100--------"; -- podprogram
constant C_RCALL: std_logic_vector(7 downto 0):= "10000100";

constant M_CCALL:std_logic_vector(15 downto 0):="10000101--------"; -- podprogram
constant C_CALL: std_logic_vector(7 downto 0):= "10000101";

constant M_CRET:std_logic_vector(15 downto 0):="10000110--------"; -- powrót z podprogramu
constant C_RET: std_logic_vector(7 downto 0):= "10000110";

constant M_CRETI:std_logic_vector(15 downto 0):="10000111--------"; -- powrót z przerwania
constant C_RETI: std_logic_vector(7 downto 0):= "10000111";
--pamaiec ram  32 komorki 8 bit 

type ram_array is array (0 to 31) of std_logic_vector(7 downto 0);
signal RAM: ram_array;

--rejestry ogolnego przeznaczenia R0-R7
type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
signal R: reg_array;

--stos
type stack_array is array(0 to 15) of std_logic_vector( 7 downto 0);
signal STACK: stack_array; -- stos
signal SPTR: unsigned(2 downto 0):= "000"; -- wskaznik stosu

-- rejestr statusowy
signal SREG: std_logic_vector(7 downto 0):= x"00";
signal SREGM: std_logic_vector(7 downto 0):= x"00";
alias SREG_C: std_logic is SREG(0);
alias SREG_Z: std_logic is SREG(1);
alias SREG_N: std_logic is SREG(2);
alias SREG_S: std_logic  is SREG(4);


-- kod programu
constant ROM: rom_t := (
C_LDI & "001" & x"01", --rejestr TCR wraz ze startem
C_LDI & "010" & "01000011", -- znak C w kodzie asci
C_LDI & "011" & "00110000", -- znak cyrfy 0 w kodzie ASCII


C_OUTP & "001" & x"00",-- wystawienie rejestru 1 na adres timera( uruchomienie timera)

C_INP & "100" & x"09", --pobranie rejestru spod adresu 18( UF) do rejsetru 4
C_ANDI & "100" & x"02", --
C_CPI & "100" & x"02", -- if TXC then wyslij nowe 
C_BRBS & "001" &x"02" ,

c_b & x"04", --else skok do lini 4

C_OUTP & "010" & x"11", -- wyslanie litery C do rejestru usart
C_INP & "100" & x"12", --pobranie rejestru spod adresu 18( UF) do rejsetru 4
C_ANDI & "100" & x"02", --
C_CPI & "100" & x"02",--sprawdzenie flagi complete
C_BRBS & "001" &x"02", --skok warunkowy 
C_b & x"0A", 
C_OUTP & "011" & x"12",
C_ADCI & "011" & x"01",
C_INP & "100" & x"12", --pobranie rejestru spod adresu 18( UF) do rejsetru 4
C_ANDI & "100" & x"02", --
C_CPI & "100" & x"02",--sprawdzenie flagi complete
C_BRBS & "001" &x"02",
C_b & x"09", 

C_B & x"04", -- skok do początku programu
others => x"0000");


signal PC: unsigned( 7 downto 0) := x"00"; -- Program Counter (Licznik programu)
signal IR: std_logic_vector(15 downto 0); -- caly rozkaz (polaczone kod i argument)
alias OPCODE: std_logic_vector(7 downto 0) is IR(15 downto 8); -- kod rozkazu   
alias ARG: std_logic_vector(7 downto 0) is IR(7 downto 0); -- argument rozkau

alias ARG_RD: std_logic_vector(2 downto 0) is IR(5 downto 3);
alias ARG_RS: std_logic_vector(2 downto 0) is IR(2 downto 0);

alias ARG_K: std_logic_vector(7 downto 0) is IR(7 downto 0);
alias ARG_ID: std_logic_vector(2 downto 0) is IR(10 downto 8);

signal is_read: std_logic_vector(3 downto 0);

type state_t is (S_FETCH, S_EX);
signal state: state_t;

begin

process(RESET, CLK)
    variable src1, src2: signed(7 downto 0);
    variable res: signed(8 downto 0);
    variable res_mul: unsigned(15 downto 0);
    variable res_mul_s: signed(15 downto 0);
begin
    if RESET = '1' then
        state <= S_FETCH;
        GPIO <= x"00";
        PC <= x"00";
        R <= (others => "UUUUUUUU"); --  nie jestem pewny czy resetować wartosi do zera czy do UUUUUUUU
        RAM <= (others => "UUUUUUUU");
    elsif rising_edge(CLK) then
        
            case state is
            
                when S_FETCH =>
                    IR <= ROM(to_integer(unsigned(PC)));
                   --oposnienei cyklu w odczycie i zapisie 
                   --stdmatch
                   
                   
                   
                    if std_match(IR, M_COUTP) then 
                        IOWR <= '1'; -- czy resetować to po cyklu?
                    elsif std_match(IR,M_CINP) then 
                        IORD <= '1';
                        is_read(3) <= '1';
                    end if;
                   
                   
                    state <= S_EX;
                    
                when S_EX =>
                    PC <= PC + 1;  
                     IOWR <= '0'; --resetowanie io write         
                     IORD <= '0';
                     IOOUT <=x"00";
                      if (is_read(3)= '1' ) then  -- odczyt
                               R(to_integer(unsigned(is_read( 2 downto 0)))) <= IOIN;
                        end if;   
                        
                                                     
                    if std_match(IR , M_CMOV)  then 
                        R(to_integer(unsigned(ARG_RD))) <= R(to_integer(unsigned(ARG_RS)));
                     
                    elsif std_match(IR, M_CLDI) then 
                        R(to_integer(unsigned(ARG_ID))) <= ARG_K;
                        
                    elsif std_match (IR, M_CLD) then 
                         R(to_integer(unsigned(ARG_RD))) <= RAM(to_integer(unsigned(ARG_RS)));
                     
                     elsif std_match(IR, M_CLDS) then 
                        R(to_integer(unsigned(ARG_ID))) <= RAM(to_integer(unsigned(ARG_K)));
                        
                      elsif std_match(IR, M_CST) then 
                         RAM(to_integer(unsigned(R(to_integer(unsigned(ARG_RD)))))) <=   R(to_integer(unsigned(ARG_RS)));
                         
                       elsif std_match(IR, M_CSTS) then 
                         RAM(to_integer(unsigned(ARG_K))) <=   R(to_integer(unsigned(ARG_ID)));  
                        
                       elsif std_match(IR,M_CB ) then 
                            PC <= unsigned(ARG_K);
                           
                            
                       elsif std_match(IR,M_CBSET) then
                            SREG <= SREG or ARG_K;
                       
                       elsif std_match(IR, M_CBCLR) then 
                             SREG <= SREG and not ARG_K;
                       
                       elsif std_match(IR, M_CADC) then 
                            src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                            src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;    
                            --uwzglednnianaie bitu przeniesiena
                            res:= "00000000" & SREG_C;
                            res:= res + ('0'& src1) +('0' & src2);
                            
                            SREG_C <= res(8); -- przeniesienie
                            
                            -- oblicznaie flagi Zero
                            if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;
                             -- przypisanie wartosci do rejestru wyhsciowegp
                             R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res(7 downto 0));    
                     
                        elsif std_match(IR, M_CADCI) then 
                            src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                            src2 := signed(ARG_K) ;  
                            
                            res:= "00000000" & SREG_C;
                            res:= res + ('0'& src1) +('0' & src2);
                            
                             SREG_C <= res(8); -- przeniesienie
                            
                            -- oblicznaie flagi Zero
                            if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;
                             -- przypisanie wartosci do rejestru wyhsciowegp
                             R(to_integer(unsigned(ARG_ID))) <= std_logic_vector(res(7 downto 0));    
                   
                         elsif std_match(IR,M_CSBC) then
                                src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                                src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                                
                                res:= "00000000" & SREG_C;
                                res:= ('0'& src1) -('0' & src2)- res;
                               SREG_C <= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7)) ;

                                 -- oblicznaie flagi Zero
                            if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;
                             -- flaga negative
                              if res(7 downto 0) < x"00" then 
                                    SREG_N <= '1';
                             else
                                    SREG_N <= '0';
                             end if  ;
                              R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res(7 downto 0));
                               
                    elsif std_match(IR,M_CSBCI) then 
                                src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                                src2 := signed(ARG_K) ;  
   --obczaic na liscie rozkazow jak to jest z tym przeniesiem                              
                                res:= "00000000" & SREG_C;
                                res:= ('0'& src1) -('0' & src2)- res;
                                SREG_C <= (not src1(7) and  src2(7)) or (src2(7) and res(7)) or (res(7) and src1(7)); -- przeniesienie
                                 if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;
                     R(to_integer(unsigned(ARG_ID))) <= std_logic_vector(res(7 downto 0)); 
                      
                      elsif std_match(IR,M_CMUL) then 
                            src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                            src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                            res_mul:= x"0000";
                            
                            res_mul := unsigned(src1)*unsigned( src2);
                            
                               if res_mul(15 downto 0) = x"0000" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                             R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res_mul(7 downto 0));
                             R(to_integer(unsigned(ARG_RD)) + 1 ) <= std_logic_vector(res_mul(15 downto 8));                      
                    
                      
                     elsif std_match(IR, M_CMULS) then 
                            src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                            src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                            res_mul:= x"0000";
                            
                            res_mul_s := src1* src2;
                            
                             if res_mul_s(15 downto 0) = x"0000" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                             
                             if res_mul_s(15 downto 0) < x"0000" then 
                                    SREG_N <= '1';
                             else
                                    SREG_N <= '0';
                             end if;
                            R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res_mul_s(7 downto 0));
                            R(to_integer(unsigned(ARG_RD)) + 1 ) <= std_logic_vector(res_mul_s(15 downto 8));   
                    elsif std_match(IR, M_CAND) then 
                         src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                         src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                         res:= "000000000";
                         
                         res:= '0' & (src1 and src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                       R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res(7 downto 0));
                   
                    elsif std_match (IR, M_CANDI) then 
                         src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                         src2 := signed(ARG_K) ;  
                         res:= "000000000";
                         
                        res:= '0' &(src1 and src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                       R(to_integer(unsigned(ARG_ID))) <= std_logic_vector(res(7 downto 0));
                   
                   elsif std_match(IR,M_COR) then
                           src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                         src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                         res:= "000000000";
                         
                         res:= '0' &(src1 or src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                        R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res(7 downto 0));
                   
                   elsif std_match(IR, M_CORI) then 
                       src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                         src2 := signed(ARG_K) ;  
                         res:= "000000000";
                         
                         res:= '0' &(src1 or src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                        R(to_integer(unsigned(ARG_ID))) <= std_logic_vector(res(7 downto 0));
                    
                     elsif std_match(IR,M_CXOR) then
                           src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                         src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                         res:= "000000000";
                         
                         res:= '0' &(src1 xor src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                        R(to_integer(unsigned(ARG_RD))) <= std_logic_vector(res(7 downto 0));
                   
                   elsif std_match(IR, M_CXORI) then 
                       src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                         src2 := signed(ARG_K) ;  
                         res:= "000000000";
                         
                         res:= '0' &(src1 xor src2);
                        if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if;
                        R(to_integer(unsigned(ARG_ID))) <= std_logic_vector(res(7 downto 0));
                    -- sprawdzicz komenty czy argument Rd jest poprawnie wpisany a nie powinien być ID 
			--w przypadku komendy ze stałą
			
			elsif std_match(IR,M_CRB) then 
			PC <= unsigned(signed(PC) + signed(ARG_RD));
			
			elsif std_match(IR,M_CBRBS) then 
			     if SREG(to_integer(unsigned(ARG_ID))) = '1' then
			         
			          PC <= unsigned(signed(PC) + signed(ARG_K));
			      else 
			         NULL;
			         end if;
			         
			elsif std_match(IR,M_CBRBC) then 
			if SREG(to_integer(unsigned(ARG_ID))) = '0' then
			         
			          PC <= unsigned(signed(PC) + signed(ARG_K));
			      else 
			         NULL;
			         end if;
	
	         elsif std_match(IR,M_CCP) then 
	            src1 := signed(R(to_integer(unsigned(ARG_RD))))  ;                
                 src2 := signed(R(to_integer(unsigned(ARG_RS)))) ;  
                                
                                res:= "00000000" & SREG_C;
                                res:= ('0'& src1) -('0' & src2)- res;
                               SREG_C <= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7)) ;

                                 -- oblicznaie flagi Zero
                            if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;
                             -- flaga negative
                              if res(7 downto 0) < x"00" then 
                                    SREG_N <= '1';
                             else
                                    SREG_N <= '0';
                             end if  ;
                             
           elsif std_match(IR, M_CCPI) then 
                             src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                                src2 := signed(ARG_K) ;  
   --obczaic na liscie rozkazow jak to jest z tym przeniesiem                              
                                res:= "00000000" & SREG_C;
                                res:= ('0'& src1) -('0' & src2)- res;
                                SREG_C <= (not src1(7) and  src2(7)) or (src2(7) and res(7)) or (res(7) and src1(7)); -- przeniesienie
                                 if res(7 downto 0) = x"00" then 
                                    SREG_Z <= '1';
                             else
                                    SREG_Z <= '0';
                             end if  ;          
            elsif std_match(IR, M_COUTP) then 
                             src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                             src2 := signed(ARG_K) ; 
                             
                             IOADR <= std_logic_vector(src2);
                             IOOUT <=std_logic_vector(src1);
            elsif std_match(IR, M_CINP) then 
                            src1 := signed(R(to_integer(unsigned(ARG_ID))))  ;                
                             src2 := signed(ARG_K) ; 
                             IOADR <= std_logic_vector(src2);
                             is_read(2 downto 0) <= ARG_ID;
             elsif std_match(IR,M_CRCALL) then 
                    STACK(to_integer(unsigned(SPTR))) <= std_logic_vector(signed(PC) + 1);   
                     SPTR <= SPTR +1;
                     PC <= PC + unsigned(ARG);
              elsif std_match(IR,M_CCALL) then 
                    STACK(to_integer(unsigned(SPTR))) <= std_logic_vector(signed(PC) + 1);   
                     SPTR <= SPTR +1;
                     PC <= unsigned(ARG);
                            
              elsif std_match(IR,M_CRET)  then 
                    PC <= unsigned(STACK(TO_INTEGER(SPTR - 1)));
                    SPTR <= SPTR-1;
                    
               elsif std_match(IR,M_CRETi)  then 
                    PC <= unsigned(STACK(TO_INTEGER(SPTR - 1)));
                    SPTR <= SPTR-1;
                                  
                     end if;  
                     state <= S_FETCH;                    
    end case;
    end if;
end process;

end Behavioral;


--C_LDI & "001" & x"35", -- załadowanie wartości x35 do rejestru R1
--C_LDI & "010" & x"12", -- załadowanie wartości x12 do rejestru R2
--C_ADC & "010" & "001", -- dodanie zawartości rejestru R1 do rejestru R2
--C_ADCI & "010" & x"21", -- dodanie stałej x21 do rejestru R2
---- Tutaj należy umieścić analogiczny kod, sprawdzający działanie
---- pozostałych zaimplementowanych rozkazów. Należy również sprawdzić
---- wpływ flagi C, którą można modyfikować rozkazami BSET i BCLR

--C_SBC & "010" & "001", --odejmij r1 od r2
--C_sbci & "010" & x"11",
--C_MUL & "010" & "001",
--C_MULS & "010" & "001",

--C_and & "010" & "001",
--C_andi & "010" & x"15",
--c_or & "010" & "001",--10line
--c_ori & "010" & x"11",
--c_xor & "010" & "001",
--c_xori & "010" & x"11",

----potęgowanie 
--C_LDI & "001" & x"00", -- zerowanie rejestrow r1 oraz r2
--C_LDI & "100" & x"03",-- zaladowanie 1 do r2
--C_LDI & "000" & x"01", -- zaladownnie potegowanej liczby do R0
--C_LDI & "010" & x"03", --zaladowanie 5 do licznika petli (R2) 17linijka
--C_BCLR & x"01", -- wyczyszczenie rejestru statusowego na pozycji "Z"
--C_MUL & "000" & "100", --mnozenie zawartosci R0
--C_BCLR & x"01",
--C_SBCI & "010" & x"01",

--C_BRBC & "001" & "11111100", -- 



--C_B & x"00", -- skok do początku programu
--others => x"0000");
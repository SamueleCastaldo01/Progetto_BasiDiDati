--*************************************************************************
--*								trigger							  		  *	
--*************************************************************************
--1.Trigger per popolare la tabella magazzino,rispettando la data di arrivo, in caso lo strumento arriva dopo rispetto la data locale,
-- viene inserito nella tab str_in arrivo, più un incremento sul prezzo, rispetto al prezzo pagato e al prezzo base in caso di annullamento dell'ordine, 
--quindi viene viene eliminato anche il prodotto nel magazzino

create or replace trigger Pop_Magazzino
after insert or delete on lista_ordine     
for each row 

declare                              
incremento number;  
b_prezzo number;
diff	number;
data_a date;

begin
if inserting then   --se è un inserimento
select prezzo into b_prezzo from strumento where n_serie=:new.n_serie;   --prezzo base strumento
	select data_arrivo into data_a from ordine  where id_ordine=:new.id_ordine;  --data arrivo
		diff:=b_prezzo-:new.prezzo;       --differenza prezzo base con il prezzo pagato

if (b_prezzo>=100 and b_prezzo<=199) then    --varie condizioni per incrementare il prezzo finale del prodotto   
 	incremento:=diff+10;
 		end if;
if (b_prezzo>=200 and b_prezzo<=399) then
	incremento:=diff+20;
		end if;
if (b_prezzo>=400 and b_prezzo<=699) then
	incremento:=diff+30;
		end if;
if (b_prezzo>=700 and b_prezzo<=1200) then
	incremento:=diff+40;
		end if;
if (b_prezzo>1200) then
	incremento:=diff+50;
		end if;
if (data_a<=sysdate) then     --confronto data di arrivo, con la data locale
	insert into magazzino values(:new.n_serie,:new.prezzo+incremento);  --inserimento nel magazzino
		end if;
if (data_a>sysdate) then          --inserimento strumento, nella tabella dei prodotti che devono arrivare
	insert into str_in_arrivo values(:new.n_serie,:new.prezzo+incremento,data_a);
		end if;
end if;


if deleting then
	delete from magazzino where n_serie=:old.n_serie; --elimina in caso viene eliminata una riga
		end if;
end;
/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
--2.Tn caso di acquisti, bisogna verificare che il prodotto alla quale si vuole acquistare, sta nel magazzino,
--dopodiché verificare se è stato già prenotato da un altro cliente, in caso contrario si può procedere all'acquisto,
--l'oggetto viene automaticamente eliminato dal magazzino, in caso di acquisto. E se l'oggetto era stato prenotato dallo stesso cliente e dopo acquistato, viene eliminato sia dal magazzino e sia dalla prenotazione
--verificare anche se lo strumento sta in promo(tramite data e seriale dello strumento), viene scalato il prezzo rispetto a quello che si inserisce
-- E verificare, che il prezzo d'acquisto, non superi il prezzo incrementato(magazzino) e non sia al di sotto del prezzo comprato(lista_ordine)
create or replace trigger acqui
before insert on acquista
for each row

declare
n_prodotto number;
n_preno 	number;
n_ssn  	number;
data_p date;
prez_b number;
prez_m number;
n_promo number;
scon number;
dtproi date;
dtprof date;
ta exception;
tp exception;
tprez exception;
tdat exception;

begin
select prezzo into prez_b from lista_ordine where n_serie=:new.n_serie;  --prezzo pagato
select prezzo into prez_m from magazzino where n_serie=:new.n_serie;     --prezzo magazzino
select count(*) into n_prodotto from magazzino where n_serie=:new.n_serie; --controllo prodotto magazzino
select count(*) into n_preno from prenotazione where n_serie=:new.n_serie;   --controllo prodotto prenotazione
select count(*) into n_ssn from prenotazione where ssn=:new.ssn and n_serie=:new.n_serie; --controllo prodotto prenotazione, stesso cliente
if (n_preno=1) then
	select data_prenotazione into data_p from prenotazione where ssn=:new.ssn;  --controllo data prenotazione, con data acquisto
		end if;

select count(*) into n_promo from promozione where n_serie=:new.n_serie;  --controllo promozione strumento
if (n_promo=1) then   --se abbiamo la promozione
	select sconto into scon from promozione where n_serie=:new.n_serie;   --sconto
	select data_inizio into dtproi from promozione where n_serie=:new.n_serie;   --data inizio
	select data_fine into dtprof from promozione where n_serie=:new.n_serie;   --data fine
	if (dtproi<sysdate and dtprof>sysdate) then   --verifica data promo
		:new.prezzo:=:new.prezzo-scon;    --applica lo sconto
	end if;
		end if;

if (:new.prezzo<=prez_b or :new.prezzo>prez_m) then   --controllo prezzo, per non andare in perdita(guadagno)
	raise tprez;
		end if;
if (n_prodotto=0) then   --non presente in magazzino
	raise ta;
		end if;
if (n_prodotto>=1 and n_preno=1 and n_ssn=0) then  --presente nel magazzino, ma già prenotato da un altro cliente
	raise tp;
		end if;
if (data_p>:new.data_acquisto and n_ssn=1) then   --data prenotazione maggiore di data acquisto strumento prenotato dallo stesso cliente
	raise tdat;
		end if;
if (n_prodotto>=1 and n_preno=0) then    --presente in magazzino, e non prenotato	 
	delete from magazzino where n_serie=:new.n_serie;
		end if;
if (n_ssn=1 and data_p<:new.data_acquisto) then          --presente in magazzino, e stato prenotato dallo stesso cliete
	delete from magazzino where n_serie=:new.n_serie;      --viene eliminato sia dal magazzino, che dalla prenotazione
	delete from prenotazione where n_serie=:new.n_serie;
end if;

exception                          
when ta then
	raise_application_error(-20001,'prodotto non presente nel magazzino');
when tp then
	raise_application_error(-20001,'prodotto gia prenotato da un altro cliente');
when tprez then
	raise_application_error(-20001,'Il prezzo non e giusto');
when tdat then
	raise_application_error(-20001,'data non corretta');
end;	
/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--3.In caso di prenotazione cliente bisogna verificare che il prodotto sia presente in magazzino, oppure ci restituisce errore
create or replace trigger preno
before insert on prenotazione
for each row

declare  
n_prodotto number;
te exception;

begin
select count(*) into n_prodotto from magazzino where n_serie=:new.n_serie;

if (n_prodotto=0) then
raise te;
end if;

exception                          
when te then
	raise_application_error(-20001,'prodotto non presente nel magazzino');
end;
/
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--4.Per poter inserire una promozione il prodotto deve essere presente in magazzino
create or replace trigger promo
before insert on promozione
for each row

declare
n_prodotto number;
ti exception;

begin
select count(*) into n_prodotto from magazzino where n_serie=:new.n_serie;
if (n_prodotto=0) then
raise ti;
end if;

exception                          
when ti then
	raise_application_error(-20001,'prodotto non presente nel magazzino');
end;
/
-----------------------------------------------------------------------------------------------------------------------------
--5.Inserimento strumenti che stanno nella tabella str_arrivo, nel magazzino, verificando la condizione della data locale. In caso positivo, il prodotto viene inserito
--nel magazzino e cancellato nella tabella str_in_arrivo
--verificare che se la prenotazione è stata effettuata da più di 1 anno, viene eliminata
create or replace trigger str_arrivo
before insert on registro
for each row

declare 
data_a date;
cursor c1 is select n_serie,prezzo,data_arrivo from str_in_arrivo;
cursor c2 is select n_serie,ssn,data_prenotazione from prenotazione;
riga c1%rowtype;
riga2 c2%rowtype;

begin             --data arrivo strumenti, per essere inseriti nel magazzino, tramite la data di arrivo e la data attuale 
open c1;
fetch c1 into riga;
while c1%found loop
if (riga.data_arrivo<sysdate) then
	insert into magazzino values(riga.n_serie,riga.prezzo);
		delete str_in_arrivo where n_serie=riga.n_serie;
		end if;
fetch c1 into riga;
end loop;
close c1;

open c2;                   --verifica della prenotazione effettuata da più di un anno
fetch c2 into riga2;
while c2%found loop
if(trunc(sysdate)-riga2.data_prenotazione>365) then
delete prenotazione where n_serie=riga2.n_serie;
end if;
fetch c2 into riga2;
end loop;
close c2;
end;
/
---------------------------------------------------------------------------------------------------------------------------------------
--6.Tramite il mese attuale, verificare tramite la tabella registro il conteggio dei giorni lavorativi effettuati nel mese corrente, in base alla tabella dipendente_negozio/n_giorni_lavorativi 
--e verificare che la data inserita non sia ripetuta più volte
create or replace trigger gest_dipen
before insert on registro
for each row

declare
n_gio number;
h_gio number;
data date;
cursor c1 is select data_presenza from registro where cf=:new.cf;
ti exception;
t2 exception;

begin         
select n_giorni_lavorativi into h_gio from dipendente_negozio where cf=:new.cf;      --giorni lavorativi di quel dipendente
select count(*) into n_gio from registro where cf=:new.cf and  to_char(data_presenza, 'mm-yy')=to_char(sysdate, 'mm-yy');   --conteggio giorni lavo dipen_negozio, nel mese attuale
if (n_gio>h_gio) then
raise ti;
end if;

open c1;       --verifica se la nuova data è già presente nel registro
fetch c1 into data;
while c1%found loop
if (data=:new.data_presenza) then   
raise t2;
end if;
fetch c1 into data;
end loop;
close c1;

exception                          
when ti then
	raise_application_error(-20001,'ha superato il numero di giorni lavorativi mensili');
	when t2 then
	raise_application_error(-20001,'la data gia e stata inserita');
end;
/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--7. controllare quando si aggiunge un ordine, che il responsabile sia corretto,
--e non sia un semplice dipendente_negozio
create or replace trigger ver_ord
before insert on ordine
for each row

declare
t1 exception;
n_resp number;

begin
select count(*) into n_resp    ---0 false (ID responsabile non corretto)
from dipendente_negozio
where cf=:new.responsabile and discriminatore='RESPON_FORN';

if (n_resp=0) then
raise t1;
end if;

exception
when t1 then
	raise_application_error(-20001,'ID responsabile non corretto');
end;
/
------------------------------------------------------------------------------------------------------------------------------------------------------
--8. capo negozio non deve essere superiore a una persona, responsabile fornitura non deve essere superiore a due persone
-- e il dipendente del negozio non deve essere superiore a 5 persone
create or replace trigger n_dip_neg
before insert on dipendente_negozio
for each row

declare
n_dip number;
n_resp number;
n_cap  number;
ti exception;
t5 exception;
t4 exception;

begin
if (:new.discriminatore='DIPENDENTE') then
select count(*) into n_dip from dipendente_negozio where DISCRIMINATORE='DIPENDENTE';
end if;
if (:new.discriminatore='CAPO_NEGOZIO') then
select count(*) into n_cap from dipendente_negozio where DISCRIMINATORE='CAPO_NEGOZIO';
end if;
if (:new.discriminatore='RESPON_FORN') then
select count(*) into n_resp from dipendente_negozio where DISCRIMINATORE='RESPON_FORN';
end if;
if (n_resp>=2) then
raise ti;
end if;
if(n_cap>=1) then
raise t5;
end if;
if(n_dip>=5) then
raise t4;
end if;

exception    
when ti then
    raise_application_error(-20001,'I respon_forn non possono essere maggiori di 2');
when t5 then
    raise_application_error(-20001,'Il capo e unico');    
when t4 then
    raise_application_error(-20001,'I dipendenti non possono essere piu di 5 persone');
end;
/
----------------------------------------------------------------------------------------------------------------------------











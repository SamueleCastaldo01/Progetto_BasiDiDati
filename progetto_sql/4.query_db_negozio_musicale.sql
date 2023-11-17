--**********************************************************************************
--*						procedure e funzioni                                       * 
--**********************************************************************************
--set serveroutput on;

--1.strumenti presenti nel magazzino, e  confronto con il prezzo base dello strumento rispetto a quello del magazzino:prezzo acquisto, prezzo vendita,
--guadagno stimanto e totale del guadagno stimato.
create or replace procedure str_maga
is
cursor c1 is select magazzino.n_serie as num_serie,marca,categoria,strumento.prezzo as prezzo_base,lista_ordine.prezzo as prezzo_acquisto,magazzino.prezzo as prezzo_vendita
from magazzino join strumento on magazzino.n_serie=strumento.n_serie  --visualizza: n_serie, marca,categoria,prezzo_b,prezzo_a,prezzo_v; dalle tabelle:magazzino,strumento,lista_ordine
join lista_ordine on lista_ordine.n_serie=magazzino.n_serie;
riga c1%rowtype;
guad_stim number;
somm number:=0;

begin
open c1;
fetch c1 into riga;
while c1%found loop
guad_stim:=riga.prezzo_vendita-riga.prezzo_acquisto;  --guadagno stimato
dbms_output.put_line('N_SERIE: '||riga.num_serie||'		'||'|MARCA: '||riga.marca||'		'||'|CATEGORIA: '||riga.categoria||'	  '||'|PREZZO_BASE: '||riga.prezzo_base||'$'||'		'||'|PREZZO_ACQUISTO: '||riga.prezzo_acquisto||'$'||'	 '||'|PREZZO_VENDITA: '||riga.prezzo_vendita||'$'||'	 '||'|GUADAGNO_STIMATO: '||guad_stim||'$');
dbms_output.put_line('_______________________________________________________________________________________________________________________________________________________________________________________________');
fetch c1 into riga;   
somm:=somm+guad_stim;   --guadagno totale
end loop;
close c1;

dbms_output.put_line('Guadagno totale stimato: '||somm||'$');  --stampa guadagno totale
end;
/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--2.unisce la tabella acquista,strumento,cliente e visualizza:n_serie,marca,categoria,c_nome,c_cognome,prezzo_a,prezzo_v.
--In più guadagno calcoliamo il guadagno totale e il guadagno effettivo(differenza=guad_tot-prezzo_a)
create or replace procedure str_acqui
is
cursor c1 is select acquista.n_serie as num_serie,marca,categoria,c_nome,c_cognome,acquista.prezzo as prezzo_finale,lista_ordine.prezzo as prezzo_acquisto
from acquista join strumento on acquista.n_serie=strumento.n_serie
join cliente on acquista.ssn=cliente.ssn
join lista_ordine on acquista.n_serie=lista_ordine.n_serie;
riga c1%rowtype;
guad_tot number:=0;
prezz_acq number:=0;
diff number:=0;

begin
open c1;
fetch c1 into riga;
while c1%found loop
dbms_output.put_line('N_SERIE: '||riga.num_serie||'		'||'MARCA: '||riga.marca||'		'||'CATEGORIA: '||riga.categoria||'		'||'C_NOME: '||riga.c_nome||'		'||'C_COGNOME: '||riga.c_cognome||'		'||'PREZZO_FINALE: '||riga.prezzo_finale||'$');
dbms_output.put_line('_____________________________________________________________________________________________________________________________________________________________________');
fetch c1 into riga;
guad_tot:=guad_tot+riga.prezzo_finale;    --calcolo guadagno totale
prezz_acq:= prezz_acq+riga.prezzo_acquisto; --calcolo prezzo_a
end loop;
close c1;

diff:=guad_tot-prezz_acq;     --differenza
dbms_output.put_line('Guadagno totale: '||guad_tot||'$');  --stampa guadagno totale
dbms_output.put_line('Guadagno effettivo: '||diff||'$');  --stampa guadagno effettivo
end;
/
---------------------------------------------------------------------------------------------------------------------------------------------------------
--3.unisce le tabelle:prenotazione,strumento,cliente e visualizza: id_preno,n_serie,categoria,marca,c_nome,c_cognome,data_preno
create or replace procedure str_preno
is
cursor c1 is select id_prenotazione,prenotazione.n_serie as num_serie,categoria,marca,c_nome,c_cognome,data_prenotazione
from prenotazione join strumento on strumento.n_serie=prenotazione.n_serie
join cliente on prenotazione.ssn=cliente.ssn;
riga c1%rowtype;


begin
open c1;
fetch c1 into riga;
while c1%found loop
dbms_output.put_line('ID_PRENO: '||riga.id_prenotazione||'		'||'N.SERIE: '||riga.num_serie||'		'||'CATEGORIA: '||riga.categoria||'		'||'MARCA: '||riga.marca||'		'||'C_NOME: '||riga.c_nome||'		'||'C_COGNOME: '||riga.c_cognome||'		'||'DATA_PRENO: '||riga.data_prenotazione);
dbms_output.put_line('__________________________________________________________________________________________________________________________________________________________________________________');
fetch c1 into riga;
end loop;
close c1;
end;
/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--4.unisce le tabelle: ordine,fornitore,lista_ordine e visualizza: id_ordine,numero_strumenti per ordine,prezzo_totale per ordine,f_nome,responsabile che ha effettuato l'ordine
create or replace procedure visual_ordine
is
cursor c1 is select id_ordine,n_strum,prezzo_tot,f_nome,responsabile
from ordine join fornitore on ordine.id_fornitore=fornitore.id_fornitore,
(select id_ordine as id,count(*) as n_strum,sum(prezzo) as prezzo_tot
from lista_ordine
group by id_ordine)
where id_ordine=id;
riga c1%rowtype;
prezz_tot_spes number:=0;

begin
open c1;
fetch c1 into riga;
while c1%found loop
dbms_output.put_line('ID_ORDINE: '||riga.id_ordine||'		'||'N.STRUM: '||riga.n_strum||'		'||'PREZZO_TOT: '||riga.prezzo_tot||'		'||'F_NOME: '||riga.f_nome||'		'||'RESPONSABILE: '||riga.responsabile);
dbms_output.put_line('__________________________________________________________________________________________________________________________________________________________________________________');
prezz_tot_spes:=prezz_tot_spes+riga.prezzo_tot;   --prezzo totale speso
fetch c1 into riga;
end loop;
close c1;
dbms_output.put_line('Prezzo totale speso: '||prezz_tot_spes);  --stampa prezzo totale speso
end;
/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--5.unisce le tabelle:prenotazione,acquista,cliente. Fa visualizzare i clienti che hanno effettuato la prenotazione e in un secondo momento hanno acquistato lo strumento prenotato
create or replace procedure vis_pren_acq
is
cursor c1 is select prenotazione.n_serie as num_serie, prezzo,cliente.ssn as cf,data_prenotazione,data_acquisto
from prenotazione join acquista on prenotazione.n_serie=acquista.n_serie
join cliente on acquista.ssn=cliente.ssn
where acquista.ssn=prenotazione.ssn and data_acquisto>data_prenotazione;
riga c1%rowtype;

begin
open c1;
fetch c1 into riga;
while c1%found loop
dbms_output.put_line('N_SERIE: '||riga.num_serie||'		'||'PREZZO: '||riga.prezzo||'		'||'CF: '||riga.cf||'		'||'DATA_PRENO: '||riga.data_prenotazione||'		'||'DATA_ACQ: '||riga.data_acquisto);
dbms_output.put_line('__________________________________________________________________________________________________________________________________________________________________________________');
fetch c1 into riga;
end loop;
close c1;

end;
/
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--6.aumento del salario del 10%, per chi fa più ore di lavoro
create or replace procedure bonus_dipen
is
max_o_cf varchar(30);
nome varchar(20);
cognome varchar(20);

begin
select cf into max_o_cf    --trova il cf dell'impegato che ottiene l'aumento, cioè colui che ha lavorato più ore
from registro
group by cf
having sum(ore_lavoro)=
(select max(sum(ore_lavoro)) from registro group by cf);
select d_nome,d_cognome into nome,cognome from dipendente_negozio where cf=max_o_cf;  --trova il nome e cognome del max_o_cf

update dipendente_negozio set salario=salario*1.1 where cf=max_o_cf;   --aggiornamento della trupla
dbms_output.put_line('Salario aumentato al dipendente: '||nome ||' '||cognome);   --stampa nome e cognome

end;
/
-----------------------------------------------------------------------------------------------------------------------------------------------------
--7.eliminazione data presenza nella tabella registro, maggiori dei due mesi attuali.
create or replace procedure elim_registro
is
data date:=add_months(sysdate,-2);   --scalo di due mesi, rispetto alla data attuale
begin
delete from registro where not to_char(data, 'mm,yy')<to_char(data_presenza, 'mm,yy');    --confronto solo il mese e l'anno, ed elimina se rispetta la condizione
dbms_output.put_line('Sono state eliminate le date delle presenze che sono maggiori degli ultimi due mesi');
end;
/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
--alcune query implementabili come procedure
--1.strumenti presenti nel magazzino, più confronto con prezzo base strumento, rispetto a quello del magazzino
select magazzino.n_serie,marca,categoria,strumento.prezzo as prezzo_base,lista_ordine.prezzo as prezzo_acquisto,magazzino.prezzo as prezzo_vendita
from magazzino join strumento on magazzino.n_serie=strumento.n_serie
join lista_ordine on lista_ordine.n_serie=magazzino.n_serie

--2.strumenti venduti, più nome e cognome cliente e prezzo finale
select acquista.n_serie,marca,categoria,c_nome,c_cognome,acquista.prezzo as prezzo_finale
from acquista join strumento on acquista.n_serie=strumento.n_serie
join cliente on acquista.ssn=cliente.ssn

--3.strumenti (categoria, marca) prenotati, nome e cognome cliente
select id_prenotazione,prenotazione.n_serie,categoria,marca,c_nome,c_cognome,data_prenotazione
from prenotazione join strumento on strumento.n_serie=prenotazione.n_serie
join cliente on prenotazione.ssn=cliente.ssn

--4.per ogni ordine, quantità di strumenti,e il prezzo dell'ordine
select id_ordine,count(*) as n_strumenti,sum(prezzo)
from lista_ordine
group by id_ordine 

--5.query di sopra combinando la tabella ordine, per visualizzare anche il fornitore e il responsabile
select id_ordine,n_strum,prezzo_tot,id_fornitore,responsabile
from ordine,
(select id_ordine as id,count(*) as n_strum,sum(prezzo) as prezzo_tot
from lista_ordine
group by id_ordine)
where id_ordine=id

--6.visualizzare nome fornitore, e nome e cognome responsabile, nella tabella ordine
select id_ordine,f_nome,d_nome,d_cognome,data_acquisto,data_arrivo
from ordine join fornitore on ordine.id_fornitore=fornitore.id_fornitore
join dipendente_negozio on responsabile=cf

--7.valore del magazzino
select sum(prezzo) as prezzo_tot_maga
from magazzino

--8.guadagno stiamo totale
select sum(guadagno_stim)
from magazzino

--9.il dipendente che guadagna di più e quello che guadagna di meno
select d_nome,d_cognome,salario,discriminatore
from dipendente_negozio,
(select max(salario) as max_sal,min(salario) as min_sal
from dipendente_negozio)
where salario=max_sal or salario=min_sal

--10.stessa query scritta in maniera diversa
select d_nome,d_cognome,salario,discriminatore
from dipendente_negozio
where salario=
(select max(salario) from dipendente_negozio)
or salario=
(select min(salario) from dipendente_negozio)

--11.modello marca strumenti in promozione
select id_promo,n_serie,marca,tipo,categoria,sconto,data_inizio,data_fine
from promozione natural join strumento

--12.numero giorni lavorativi, e numero di ore totali mensili dalla tabella registro per ogni dipendente, con nome e cognome
select d_nome,d_cognome,gio_lav_mensile,ore_lavoro_mensile
from dipendente_negozio,
(select cf as ciffo,count(*) as gio_lav_mensile,sum(ore_lavoro) as ore_lavoro_mensile
from registro
group by cf)
where cf=ciffo

--13.strumenti che sono stati prenotati e successivamente sono stati acquistati, con nome e cognome cliente
select prenotazione.n_serie, prezzo,c_nome,c_cognome,data_prenotazione,data_acquisto
from prenotazione join acquista on prenotazione.n_serie=acquista.n_serie
join cliente on acquista.ssn=cliente.ssn
where acquista.ssn=prenotazione.ssn and data_acquisto>data_prenotazione  
*/
---------------------------------------------------------------------------------------------------------------------------





















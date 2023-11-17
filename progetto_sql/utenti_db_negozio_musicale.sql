--alter session set "_ORACLE_SCRIPT"=true;    --in caso di problemi con la crezione utente
--creazione utenti
create user Boss identified by admin;
create user cliente identified by cliente;
create user resp_fornitura identified by resp_fornitura;
create user dipen_negozio identified by dipen_negozio;
grant all privileges to Boss;    --boss

--cliente
grant connect, create session to cliente;
grant select on Boss.strumento to cliente; 
grant select on Boss.magazzino to cliente;

--responsabile fornitura
grant connect, create session to resp_fornitura;
grant execute on Boss.str_maga to resp_fornitura;
grant execute on Boss.str_acqui to resp_fornitura;
grant execute on Boss.visual_ordine to resp_fornitura;
grant execute on Boss.str_preno to resp_fornitura;
grant execute on Boss.vis_pren_acq to resp_fornitura;
grant execute on Boss.bonus_dipen to resp_fornitura;
grant execute on Boss.elim_registro to resp_fornitura;
	grant select on Boss.strumento to resp_fornitura;
	grant select on Boss.prenotazione to resp_fornitura;
		grant all on Boss.dipendente_negozio to resp_fornitura;
		grant all on Boss.registro to resp_fornitura;
		grant all on Boss.lista_ordine to resp_fornitura;
		grant all on Boss.ordine to resp_fornitura;
grant select,insert,update on Boss.magazzino to resp_fornitura;
grant select,insert,update on Boss.fornitore to resp_fornitura;
grant select,insert on Boss.acquista to resp_fornitura;

--dipendente negozio
grant connect, create session to dipen_negozio;
grant execute on Boss.str_maga to dipen_negozio;
grant execute on Boss.str_acqui to dipen_negozio;
grant execute on Boss.str_preno to dipen_negozio;
grant execute on Boss.vis_pren_acq to dipen_negozio;
grant select on Boss.strumento to dipen_negozio;
grant select on Boss.lista_ordine to dipen_negozio;
grant select on Boss.magazzino to dipen_negozio;
grant select on Boss.cliente to dipen_negozio;
grant select,insert,update on Boss.promozione to dipen_negozio;
grant all on Boss.prenotazione to dipen_negozio;
grant select,insert on Boss.acquista to dipen_negozio;


--la prenotazione e l'acquisto vengono fatti dal dipendente, tramite richiesta da parte del cliente
--revoke select,insert,update on Boss.registro from dipen_negozio; --esempio di revoca, system
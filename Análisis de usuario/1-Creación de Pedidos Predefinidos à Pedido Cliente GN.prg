
/*

   Grupo: Compras
   
   El análisis está asociado a la pantalla SBO y el análisis está disponible cuando la pantalla no tiene ningún registro seleccionado (fin de fichero)
   Descripción: Solo tiene la consulta, no hace nada más ni tiene parámetros y solo saca centros activos.
   
   
   Variables:
      - 1: Tipo D; Nombre "Fecha Pedido Inicial"
      - 2: Tipo D; Nombre "Fecha Pedido Final"
      - 3: Tipo C; Nombre "Cliente Inicial"
      - 4: Tipo C; Nombre "Cliente final"
      - 5: Tipo D; Nombre "Fecha envío Proveedor Inicial"
      - 6: Tipo D; Nombre "Fecha envío Proveedor Final"
   
*/


***** Verificar se existem artigos nos documentos predefinidos que tenham staus inactivo *****
***** PSB 16102018 *****

Text to Stsql textmerge noshow

   Select 
      num_predef=U_REQTIPO.reqno
      ,Descripcion=U_REQTIPO.design
      ,st.ref
      ,descripcion=st.design
      ,Estado='Inactivo' 
   from 
      st
   inner join 
      U_REQTIPOL on U_REQTIPOL.ref=st.ref
   Inner join 
      U_REQTIPO on U_REQTIPOL.U_REQTIPOstamp=U_REQTIPO.U_REQTIPOstamp
   where
      st.inactivo=1
   order by 
      1 
EndText


If u_sqlexec(stsql,'crsst') and reccount ('crsst')>0 then
select crsst
mostrameisto ("crsst","Articulos inactivos existentes nos Predefinidos")

If !pergunta("Desea continuar creando las solicitudes de cliente con los artículos inactivos?", 2, "", .t.)
	mensagem("Operacíon Cancelada pelo utilizador","DIRECTA")
	Return .f.
Endif


Endif


****************************************************************************************************
**Emissão de requisições de materiais**
**
**Última Alteração: 08/04/2014 16:00  (Fernando Fontes)
**Última Alteração: 26/11/2014   (Inclusao de geracao de encomendas a FL)
****************************************************************************************************
** esta versão actualiza a data do centro de custo com a data prevista para a próxima emissão de requisição
**o comportamento deste alerta permite que não sejam emitidas linhas de requisições novas antes do tempo (com base no periodo definido para emissão da requisição)
**############    ALTERAR   #########################
**numero Interno do dossier e armazem
	m.ndosMerc=1
       m.ndos=1
*       m.narmazem=25
	   m.ToleranciaDias=30

m.dataapartir=#3#

*msg(astr(val(m.dataapartir)))

*msg(astr(val(dtosql(date()))))

*msg(substr(m.dataapartir, 7,2)+"."+substr(m.dataapartir, 5,2)+"."+substr(m.dataapartir, 1, 4))

m.ToleranciaDias=ctod(substr(m.dataapartir,7,2)+"."+substr(m.dataapartir,5,2)+"."+substr(m.dataapartir,1, 4))-date()

*msg(astr(m.ToleranciaDias))


*m.dataapartir='20240415'
**-m.ToleranciaDias
**msg(astr(m.dataapartir))


** FF ** 2023-09-13-- Atualização de data estado de envio com base na última data de pedido extraordinário
**
TEXT TO STR1 TEXTMERGE NOSHOW
update e set e.datae=lastdate.fecha 
from
 cu inner join u_reqestado e on cu.custamp=e.custamp
inner join 
(
select bi.ccusto,bi.ref,fecha=max(bo.dataobra) from bo (nolock) inner join bi (nolock) on bo.bostamp=bi.bostamp
where bo.ndos =1 and bi.ref<>''
group by bi.ccusto,bi.ref
) as lastdate on cu.cct=lastdate.ccusto and e.ref=lastdate.ref
where cu.u_temreq=1 and lastdate.fecha>e.datae
ENDTEXT

str2="Erro ao atualizar dats de estado pelos pedidos extraordinarios!"

		*******faz a actualização
*** FF ** 21-09-2023 ** em reunião com as compras decidiu-se que nãos e faria esta atualização para não estar a colcoar datas diferentes em produtos dos mesmos centros
***		IF not u_sqlexec(str1,"actDataEstado")
***			*u_sqlexec("ROLLBACK TRANSACTION")
***			U_PCLOG(.F.,str2)
***			Throw
***		ELSE
***			fecha("actDataEstado")
***		ENDIF
**
** FF ** 2023-09-13-- Atualização de data estado de envio com base na última data de pedido extraordinário




**##############################################
set point to "."
m_file=""
m.ndocum=''
m.obrano=0
m.nrec=""
***2011-05-31 acrescentado para controlar requisições de venda
m.rVenda=0
m.RVendaAnterior=2
m.tipo=""
m.retipo=""
m.rendos=0
m.reano=0
m.rendocum=''
m.periodo=0
m.ccustoactual=''
m.nlinhas=0
m.mcontador=0
m.dbname=""
m.lordem=0
*******2011-07-19*******passa a agrupar as requisições tipo por local de entrega
**acrescentada coluna ccustoCAB como critério de ordenação e separação de documentos
*************
********* define a pesquisa de requisições tipo ********

text to m.selectregistos textmerge noshow
/* FF ** 2014-04-08 - paa evitar entrega antes da data prevista */

select  rendocum=ccustoCab+convert (varchar(8),case when cureqdata>data then cureqdata else data end,112),	ccustoCab
,	case when cureqdata>data then cureqdata else data end as 	data
,	localentrega,	cct,	descricao,	custamp,	reqno,	requisicao,	nome,	nome2,	morada,	codpost,	local,	ncont,	no,	estab,	ref,	qtt,	periodo,	u_armazem,	u_reqhora,	Rvenda,	RCons,u_cctprov
from
(
/* query para requisições de materiais */
select 
/* FF ** 20140408 ** acrescentada coluna para controlar o agrupamento por data de entrega prevista ***/
rendocum=str(case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end )
	+ convert (varchar(8),isnull( iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqdatai),112)
,cu.u_reqdatai as cureqdata,
case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as ccustoCab,
data=isnull(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqdatai),case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as localentrega
, cu.cct,cu.descricao, cu.custamp,r.reqno,requisicao=r.design,cu.u_cctprov,
cl.nome,cl.nome2,cl.morada,cl.codpost,cl.local, cl.ncont, cl.no, cl.estab,
l.ref,l.qtt,l.periodo,u_armazem=1/*cct.u_armazem*/,cu.u_reqhora, Rvenda=0, RCons=0
 from cu inner join u_reqtipo r on cu.u_reqno=r.reqno
--inner join cu cct on cu.u_ccsuperv=cct.cct
inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
inner join st on l.ref=st.ref 
inner join cl on cu.u_nocl=cl.no and cu.u_estabcl=cl.estab
 left outer join u_reqestado e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
where cu.u_temreq=1 and cu.u_reqdatai<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate())
and iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,isnull(e.datae,0)),dateadd(dd,30*l.periodo,isnull(e.datae,0)))<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate()) 
and cu.u_reqdatai<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate()) 
and st.inactivo=0 and st.bloqueado=0 and cu.inactivo=0 
-- SRC - acrescentado para excluir as linhas que tenham fornecedor preenchido
and isnull(l.flno,0)=0

and (case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end) between #1# and #2#

--'60062'
--order by cu.cct,isnull(dateadd(mm,l.periodo,e.datae),cu.u_reqdatai) desc,l.periodo,l.ref
union all
/* query para consumíveis */
select 
/* FF ** 20140408 ** acrescentada coluna para controlar o agrupamento por data de entrega prevista ***/
rendocum=str(case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end )
+
convert (varchar(8), isnull(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqcdata) 
,112)
,cu.u_reqcdata as cureqdata,
case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as ccustoCab,
--l.periodo,e.datae,cu.u_reqcdata,
data= 			isnull(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqcdata) 
,case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as localentrega
, cu.cct,cu.descricao, cu.custamp,r.reqno,requisicao=r.design,cu.u_cctprov,
cl.nome,cl.nome2,cl.morada,cl.codpost,cl.local, cl.ncont, cl.no, cl.estab,
l.ref,l.qtt,l.periodo,u_armazem=1/*cct.u_armazem*/,cu.u_reqhora, Rvenda=0, RCons=1
 from cu inner join u_reqtipo r on cu.u_reqCno=r.reqno
--inner join cu cct on cu.u_ccsuperv=cct.cct
inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
inner join st on l.ref=st.ref 
inner join cl on cu.u_nocl=cl.no and cu.u_estabcl=cl.estab
 left outer join u_reqcestado (nolock) e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
where cu.u_temreqC=1 and cu.u_reqcdata<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate())
and iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,isnull(e.datae,0)),dateadd(dd,30*l.periodo,isnull(e.datae,0))) < dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate()) 
and st.inactivo=0 and st.bloqueado=0 and cu.inactivo=0 
-- SRC - acrescentado para excluir as linhas que tenham fornecedor preenchido
and isnull(l.flno,0)=0

and cu.cct between #1# and #2#

--'68152'
--and (case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end)='64801'

union all
/* query para requisições de venda */
select 
/* FF ** 20140408 ** acrescentada coluna para controlar o agrupamento por data de entrega prevista ***/
rendocum= str( cu.cct ) +'v'+
	convert (varchar(8),isnull(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqVdata),112)
,cu.u_reqvdata as cureqdata,
case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as ccustoCab,
data=isnull(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)),cu.u_reqVdata),case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end as localentrega
, cu.cct,cu.descricao, cu.custamp,r.reqno,requisicao=r.design,cu.u_cctprov,
cl.nome,cl.nome2,cl.morada,cl.codpost,cl.local, cl.ncont, cl.no, cl.estab,
l.ref,l.qtt,l.periodo,u_armazem=1/*cct.u_armazem*/,cu.u_reqhora , Rvenda=1, Rcons=0
from cu inner join u_reqtipo r on cu.u_reqVno=r.reqno
--inner join cu cct on cu.u_ccsuperv=cct.cct
inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
inner join st on l.ref=st.ref 
inner join cl on cu.u_nocl=cl.no and cu.u_estabcl=cl.estab
 left outer join u_reqVestado e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
where cu.u_temreqV=1 and cu.u_reqVdata<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate())
and iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,isnull(e.datae,0)),dateadd(dd,30*l.periodo,isnull(e.datae,0)))<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate()) 
and cu.u_reqVdata<dateadd(dd,<<astr(m.ToleranciaDias)>>,getdate()) 
and st.inactivo=0 and st.bloqueado=0 and cu.inactivo=0 
-- SRC - acrescentado para excluir as linhas que tenham fornecedor preenchido
and isnull(l.flno,0)=0

and (case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end) between #1# and #2#

--and cu.cct=#1#
--'68152'
--and (case when cu.u_reqentrg ='' then cu.cct else cu.u_reqentrg end)='60062'
) as tabela
order by Rvenda,1,Rcons,2 desc,cct,periodo,ref
--ordena por rvenda,ccustoCab,data decrescente e ccusto linhas

endtext
*msg(m.selectregistos)
*return
*****************2010-08-03****************
** não passar artigos que estejam inactivos
*******************************************
** os documentos a emitir serão agrupados por centro de custo (todas as linhas do centro de custo no mesmo documento)
** para evitar a emissão de documentos com uma data (de arranque) no passado, as linhas são ordenadas por data decrescente
*******************************************
TRY
*************** vai buscar os dados para emitir as requisições ************* 
*msg(m.selectregistos)
*return .f.
if u_sqlexec(m.selectregistos,'retfich') and reccount("retfich")>0


	**historico
		m.dataini=str(year(date()),4)+strzero(month(date()),2,0)+strzero(day(date()),2,0)
		m.horaini=right(transform(datetime()),8)
	**Instancia Dossiers Internos
		do dbfusebo
		do dbfusebo2
		do dbfusebi
		do dbfusebi2

	 ** criar os cursores de dossiers vazios
		u_sqlexec([select * from bo where 1=0],[mbocursor])
		u_sqlexec([select * from bo2 where 1=0],[mbo2cursor])
		u_sqlexec([select * from bi where 1=0],[mbicursor])
		u_sqlexec([select * from bi2 where 1=0],[mbicursor2])
		** Historico Materiais
		u_sqlexec([select * from u_reqestado where 1=0],[mreqestado]) 
		** Historico Vendas
		u_sqlexec([select * from u_reqVestado where 1=0],[mreqVestado]) 
		** Historico Consumiveis
		u_sqlexec([select * from u_reqcestado (nolock) where 1=0],[mreqCestado]) 
	  * limpar os cursores
		select mbocursor
		delete for .t.
		select mbicursor
		delete for .t.
		select mbo2cursor
		delete for .t.
		select mbicursor2
		delete for .t.
		select mreqestado
		delete for .t.
		select mreqVestado
		delete for .t.
		select mreqCestado
		delete for .t.
	 **ler a configuração do dossier interno
		do tsread with "",m.ndos  
	 ** vai buscar o nome do dossier','directa')
		m.nmdos=""
		if u_sqlexec("select nmdos from ts where ndos="+astr(m.ndos),'nomedoc')
			m.nmdos=alltrim(nomedoc.nmdos) 
			fecha('nomedoc')
		endif

	SELECT RETFICH

	GOTO TOP
	timeouton()
	m.nRecProc=0
	m.nTotRec=reccount("RETFICH")
	m.ano=year(retfich.data)			
	SCAN 
 
		m.nRecProc=m.nRecProc+1
*******2011-07-19*******passa a agrupar as requisições tipo por local de entrega
**		m.rendocum=retfich.cct
**        m.ccusto=m.rendocum
**		m.rendocum=retfich.ccustoCAB
** FF ** 20140408 ** acrescentada coluna para controlar o agrupamento por data de entrega prevista ***
		m.rendocum=retfich.rendocum
        m.ccusto=retfich.cct
********************
		m.entity = retfich.no 
		m.estab = retfich.estab 
        m.nome = retfich.nome
        m.nome2 = retfich.nome2
		m.descricao=retfich.descricao
		m.morada=alltrim(retfich.morada)
		m.local=alltrim(retfich.local)
		m.codpost=alltrim(retfich.codpost)
		m.ncont=alltrim(retfich.ncont)
        m.nrec=retfich.reqno
        m.requisicao=retfich.requisicao
		m.periodo=retfich.periodo
        m.custamp=retfich.custamp
		m.reqhora=retfich.u_reqhora
		m.ccustoentrprov=retfich.u_cctprov
**msg(astr(m.ccustoentrprov))
***2011-05-31 acrescentado para controlar requisições de venda
		m.rVenda=retfich.rVenda
***2012-01-06 acrescentado para controlar requisições de consumiveis
		m.rCons=retfich.rCons
		m.ref=retfich.ref
***** ATRIBUI VALOR DE ARMAZEM 2014-01-03
*		m.narmazem=retfich.u_armazem
		**Verifica se Preenche Cabeçalho
		if alltrim(m.ndocum)<>alltrim(m.rendocum) or m.Rvenda<>m.rVendaAnterior
			m.ndocum=m.rendocum
			m.rVendaAnterior=m.Rvenda
			m.preencheBO = .t.
		else
			m.preencheBO = .f.
		endif
		** preencher o cabeçalho','directa')
		if m.preencheBO = .t.
*msg("entrei1")
			m.etotaldeb=0
			m.etotalcusto=0
	
			**calcula o numero sequencial do dossier','directa')
			**m.sel="select max(obrano)+1 as pno from bo (nolock) where ndos=" + astr(m.ndos) + " and boano=" +str(year(RETFICH.DATA),4)
***Alterado para numeração continua em 18122015-PSB
			m.sel="select max(obrano)+1 as pno from bo (nolock) where ndos=" + astr(m.ndos)
			IF u_sqlexec(m.sel ,"NUMERAOBRANO")
				if m.obrano = 0
					if lower(astr(NUMERAOBRANO.pno)) = ".null."
						m.obrano=1
					else
						m.obrano=NUMERAOBRANO.pno
					endif
				else
					m.obrano=m.obrano+1
				endif
				FECHA("NUMERAOBRANO")	
			ELSE
				**escreve o erro no log u_importa','directa')
				U_PCLOG(.f.,"No puedo calcular el siguiente número del Dossier Interno! Logística: Emisión Solicitud!")
				Throw		
			ENDIF
			WAIT WINDOW "A criar cabeçalho" nowait noclear
			select mbo2cursor
			append blank
			select mbocursor
			append blank
			m.cctlinhas=""
			***************2010-08-03**************
			**preencher o local de entrega no cabeçalho
			**
			if !empty(retfich.localentrega)
				TEXT TO M.SQL2 TEXTMERGE NOSHOW
<<				>>select cu.cct,cu.descricao, cl.nome,cl.nome2,cl.morada,cl.codpost,cl.local, cl.ncont, cl.no, cl.estab
<<				>>from cu (nolock) inner join cl (nolock) on cu.u_nocl=cl.no and cu.u_estabcl=cl.estab
<<				>>where cu.cct='<<alltrim(retfich.localentrega)>>' and cu.inactivo=0
				ENDTEXT
**msg(m.sql2)
				if u_sqlexec(m.sql2,'localentrega') and reccount('localentrega')>0
					m.entity=localentrega.no
					m.estab=localentrega.estab
					m.nome=localentrega.nome
					m.nome2=localentrega.nome2
					m.descricao=localentrega.descricao
					m.morada=localentrega.morada
					m.local=localentrega.local
					m.codpost=localentrega.codpost
					m.ncont=localentrega.ncont
					**se tem outro centro de custo de entrega, actualiza apenas descrição e morada no cabeçalho
					**m.ccusto=localentrega.cct
					**se tem outro cct de entrega, coloca a descrição do cct das linhas em observações
					m.cctlinhas=retfich.descricao
				endif
			endif
			***************************************
			replace mbocursor.no with m.entity
			replace mbocursor.estab with m.estab
			replace mbocursor.nome with m.nome
			replace mbocursor.memissao with 'EURO'
            *******criar stamp do dossier********
			m.bostamp=u_stamp(recno("mbocursor"))
			replace mbocursor.bostamp with m.bostamp
			*************************************
			replace mbocursor.ndos with m.ndos
			m.dataobra=ctod(strzero(day(RETFICH.data),2,0)+'.'+strzero(month(RETFICH.data),2,0)+'.'+str(year(RETFICH.data),4))
			replace mbocursor.dataobra with m.dataobra
			replace mbocursor.ousrdata with date()
			replace mbocursor.ousrhora with astr(time())
			replace mbocursor.ousrinis with M_CHINIS
			replace mbocursor.usrdata with date()
			replace mbocursor.usrhora with astr(time())
			replace mbocursor.usrinis with M_CHINIS
			replace mbocursor.boano with year(RETFICH.data)
			replace mbocursor.obrano with m.obrano
			replace mbocursor.nmdos with m.nmdos
			replace mbocursor.moeda with 'PTE ou EURO'
		*nome da requisicao','directa')
			Replace mbocursor.obs with m.requisicao
            replace mbocursor.marca with astr(m.nrec)
			replace mbocursor.maquina with m.ccustoentrprov
		* preenche os dados do Cliente','directa')
			replace mbocursor.nome with m.nome
			replace mbocursor.nome2 with m.nome2
			replace mbocursor.u_descrcc with m.descricao
			replace mbocursor.morada with m.morada
			replace mbocursor.local with m.local
			replace mbocursor.codpost with m.codpost
			m.mordadescarga= alltrim(m.morada) +"-"+alltrim(m.local)
			replace mbocursor.trab3 with m.mordadescarga
			replace mbocursor.ncont with m.ncont
**2015-07-07 ** pssa a usar o ccusto de entrega no cabeçalho
			replace mbocursor.ccusto with retfich.ccustoCAB
			replace mbocursor.obs with m.reqhora
			replace mbocursor.trab5 with m.cctlinhas
**2014-04-01 ** FF ** Acrescentado para controlar se foi criada automaticamente
			replace mbocursor.logi8 with .t.
			replace mbocursor.logi5 with .t.
***2011-05-31 acrescentado para controlar requisições de venda
			if m.rVenda=1
				replace mbocursor.logi8 with .t.
			else
				replace mbocursor.logi8 with .f.
			endif
*****
			m.preencheBO=.f.
		endif
***** PARA COLOCAR ARMAZEM NA BO2
			m.narmazem=retfich.u_armazem        
			select mbo2cursor
		replace mbo2cursor.bo2stamp with m.bostamp
		replace mbo2cursor.armazem  with m.narmazem
		WAIT WINDOW "A criar linhas" nowait noclear
		**-------------------------------------------------------------------
		**criar linhas' ,'directa')
        m.quantidade=retfich.qtt
		m.sel=[select epcusto, epcpond from st where ref=']+m.ref +[']
		if u_sqlexec(m.sel,"mystk")	and reccount("mystk")>0
            select mystk
**			m.epcpond=mystk.epcpond 
**            m.edebito=mystk.epcpond 
** ff * preços de custo passam a ser o custo
			m.epcpond=mystk.epcusto 
            m.edebito=mystk.epcusto 

            m.epcusto=mystk.epcusto
            m.qtd=m.quantidade
			select mbicursor
*brow
			append blank
				m.lordem=m.lordem+10000	
				replace mbicursor.ref with m.ref
				replace mbicursor.rescli with .t.
**	replace mbicursor.edebito with round(RETFICH.preco/RETFICH.qtt,2)
                replace mbicursor.edebito with m.edebito
				replace mbicursor.qtt with m.qtd
				replace mbicursor.bistamp with u_stamp(recno("mbicursor"))
**                replace mbicursor.obistamp with m.obistamp
**                replace mbicursor.oobistamp with m.obistamp
				replace mbicursor.bostamp with m.bostamp
				replace mbicursor.obrano with m.obrano
				replace mbicursor.ndos with m.ndos
				replace mbicursor.armazem with m.narmazem
				replace mbicursor.dataobra with m.dataobra 
				replace mbicursor.ousrdata with date()
				replace mbicursor.ousrhora with astr(time())
				replace mbicursor.ousrinis with M_CHINIS
				replace mbicursor.usrdata with date()
				replace mbicursor.usrhora with astr(time())
				replace mbicursor.usrinis with M_CHINIS
				replace mbicursor.dataopen with m.dataobra
				replace mbicursor.rdata with m.dataobra
				replace mbicursor.nome with m.nome2
				replace mbicursor.morada with m.morada
				replace mbicursor.local with m.local
				replace mbicursor.codpost with m.codpost
				replace mbicursor.nmdos with m.nmdos
				replace mbicursor.stipo with 4
				replace mbicursor.lordem with m.lordem
				replace mbicursor.litem with astr(m.periodo)
				**actualiza os dados da refª
				do tsread with "",m.ndos  
				Do boactref with '',.t.,'OKPRECOS','mbicursor'
				**actualização do preço de custo para o preco de custo ponderado','directa')
				replace mbicursor.epcusto with m.edebito
**m.epcpond
				replace mbicursor.ccusto with m.ccusto
				replace mbicursor.armazem with m.narmazem
				**calcula os totais"
				do u_bottdeb with 'mbicursor'
				replace mbicursor.eslvu with round((mbicursor.edebito/(1+(mbicursor.iva/100))),2)
				replace mbicursor.esltt with ((mbicursor.edebito/(1+(mbicursor.iva/100)))*mbicursor.qtt)
				m.etotaldeb = m.etotaldeb + mbicursor.esltt
				m.etotalcusto=m.etotalcusto+ round(mbicursor.epcusto*mbicursor.qtt,2)
	**msg(astr(m.etotalcusto))

				**preencher totais da BO
				select mbocursor
				replace mbocursor.etotaldeb with round(m.etotaldeb,2)
				replace mbocursor.ecusto  with round(m.etotalcusto,2)
			**msg(astr(mbocursor.ecusto))
			**movimenta o contador de linhas"
			m.mcontador=m.mcontador+1
			*****actualizar o estado da requisição
		******2011-05-31 *** actualizar apenas o estado das requisições tipo
		if m.rVenda=0 and m.rCons=0
			select mreqestado
			append blank
				replace mreqestado.ref with m.ref
				replace mreqestado.qtt with m.qtd
				replace mreqestado.periodo with m.periodo
				replace mreqestado.u_reqestadostamp with u_stamp(recno("mreqestado"))
                replace mreqestado.custamp with m.custamp
				replace mreqestado.datae with m.dataobra 
				replace mreqestado.ousrdata with date()
				replace mreqestado.ousrhora with astr(time())
				replace mreqestado.ousrinis with M_CHINIS
				replace mreqestado.usrdata with date()
				replace mreqestado.usrhora with astr(time())
				replace mreqestado.usrinis with M_CHINIS
		endif
		*** actualizar apenas o estado das requisições Venda
		if m.rVenda=1 
			select mreqVestado
			append blank
				replace mreqVestado.ref with m.ref
				replace mreqVestado.qtt with m.qtd
				replace mreqVestado.periodo with m.periodo
				replace mreqVestado.u_reqVestadostamp with u_stamp(recno("mreqVestado"))
                replace mreqVestado.custamp with m.custamp
				replace mreqVestado.datae with m.dataobra 
				replace mreqVestado.ousrdata with date()
				replace mreqVestado.ousrhora with astr(time())
				replace mreqVestado.ousrinis with M_CHINIS
				replace mreqVestado.usrdata with date()
				replace mreqVestado.usrhora with astr(time())
				replace mreqVestado.usrinis with M_CHINIS
		endif
		*05-01-2011 *** actualizar apenas o estado das requisições Compra
		if m.rVenda=0 and m.RCons=1
			
			select mreqCestado
			append blank
				replace mreqCestado.ref with m.ref
				replace mreqCestado.qtt with m.qtd
				replace mreqCestado.periodo with m.periodo
				replace mreqCestado.u_reqCestadostamp with u_stamp(recno("mreqCestado"))
                replace mreqCestado.custamp with m.custamp
				replace mreqCestado.datae with m.dataobra 
				replace mreqCestado.ousrdata with date()
				replace mreqCestado.ousrhora with astr(time())
				replace mreqCestado.ousrinis with M_CHINIS
				replace mreqCestado.usrdata with date()
				replace mreqCestado.usrhora with astr(time())
				replace mreqCestado.usrinis with M_CHINIS
					
		endif
*select mreqcestado
*brow
		else
			U_PCLOG(.f.,"El artículo con la referencia "+ m.ref +" no existe en la base de datos "+ m.dbname +" - Logística: Emisión Solicitudes!")
			Throw
		endif
	ENDSCAN
wait window "A entrar nos cursores para fazer os Inserts..." nowait noclear
*mensagem("A entrar nos cursores para fazer os Inserts...",'directa')
if not u_sqlexec("BEGIN TRANSACTION")
	U_PCLOG(.F.,"No se pudo iniciar la transacción !!!!!!!! - Logística: Emisión Solicitudes!")
	Throw
endif
timeouton()
m.nRecProc=0
regua(0,m.nTotRec,"A lanzar los Dossiers "+ astr (m_file) +" - Ventas y Devoluciones ("+astr(m.nTotRec-1)+")...")
**Insert na tabela BO do BackOffice
Select mbocursor
goto top
scan for mbocursor.obrano>0
wait window "A inserir o Dossier Interno com o nº " + astr(Mbocursor.obrano) nowait noclear
m.pcsel=""
m.pcsel=m.pcsel+" INSERT INTO "
m.pcsel=m.pcsel+  "bo "
m.pcsel=m.pcsel+" (bostamp, nmdos, obrano, dataobra, nome,u_descrcc, totaldeb, etotaldeb, tipo, "
m.pcsel=m.pcsel+" smoe4, smoe3, smoe2, smoe1, moetotal, sdeb2, sdeb1, sdeb4, sdeb3, sqtt14, "
m.pcsel=m.pcsel+" sqtt13, sqtt12, sqtt11, sqtt24, sqtt23, sqtt22, sqtt21, vqtt24, vqtt23, vqtt22, vqtt21, "
m.pcsel=m.pcsel+" vendedor, vendnm, stot1, stot2, stot3, stot4, no, obranome, boano, "
m.pcsel=m.pcsel+" fechada, nopat, total, tecnico, tecnnm, marca, maquina,  serie, zona, obs, "
m.pcsel=m.pcsel+" trab1, trab2, trab3, trab4, trab5, ndos, custo, moeda, estab, morada, local, codpost, "
m.pcsel=m.pcsel+" period, tabela1, ncont, logi1, logi2, logi3, logi4, logi5, logi6, logi7, logi8, "
m.pcsel=m.pcsel+" segmento, impresso, userimpresso, fref, ccusto, ncusto, cobranca, infref, lifref, esdeb1, "
m.pcsel=m.pcsel+" esdeb2, esdeb3, esdeb4, evqtt21, evqtt22, evqtt23, evqtt24, estot1, estot2, estot3, "
m.pcsel=m.pcsel+" estot4, etotal, ecusto, bo_2tdesc1, bo_2tdesc2, ebo_2tdes1, ebo_2tdes2, descc, edescc, "
m.pcsel=m.pcsel+" bo_1tvall, bo_2tvall, ebo_1tvall, ebo_2tvall, bo11_bins, bo11_iva, ebo11_bins, ebo11_iva, "
m.pcsel=m.pcsel+" bo21_bins, bo21_iva, ebo21_bins, ebo21_iva, bo31_bins, bo31_iva, ebo31_bins, ebo31_iva, "
m.pcsel=m.pcsel+" bo41_bins, bo41_iva, ebo41_bins, ebo41_iva, bo51_bins, bo51_iva, ebo51_bins, ebo51_iva, "
m.pcsel=m.pcsel+" bo61_bins, bo61_iva, ebo61_bins, ebo61_iva, bo12_bins, bo12_iva, ebo12_bins, ebo12_iva, "
m.pcsel=m.pcsel+" bo22_bins, bo22_iva, ebo22_bins, ebo22_iva, bo32_bins, bo32_iva, ebo32_bins, ebo32_iva, "
m.pcsel=m.pcsel+" bo42_bins, bo42_iva, ebo42_bins, ebo42_iva, bo52_bins, bo52_iva, ebo52_bins, ebo52_iva, "
m.pcsel=m.pcsel+" bo62_bins, bo62_iva, ebo62_bins, ebo62_iva, bo_totp1, bo_totp2, ebo_totp1, ebo_totp2, edi, "
m.pcsel=m.pcsel+" memissao, nome2, pastamp, snstamp, mastamp, origem, orinopat, iiva, iunit, itotais, "
m.pcsel=m.pcsel+" iunitiva, itotaisiva, site, pnome, pno, cxstamp, cxusername, ssstamp, ssusername, alldescli, "
m.pcsel=m.pcsel+" alldesfor, series, series2, quarto, ocupacao, tabela2, obstab2, iemail, inome, situacao, lang, "
m.pcsel=m.pcsel+" ean, iecacodisen, boclose, tpstamp, tpdesc, emconf, statuspda, aprovado, ousrinis, "
m.pcsel=m.pcsel+" ousrdata, ousrhora, usrinis, usrdata, usrhora, marcada)"
m.pcsel=m.pcsel+" VALUES( '"
m.pcsel=m.pcsel+Astr(Mbocursor.bostamp)+"','"+Astr(Mbocursor.nmdos)+"','"+Astr(Mbocursor.obrano)+"','"+Astr(dtos(Mbocursor.dataobra))+"','"+Astr(Mbocursor.nome)+"','"+Astr(Mbocursor.u_descrcc)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.totaldeb)+"','"+Astr(Mbocursor.etotaldeb)+"','"+Astr(Mbocursor.tipo)+"','"+Astr(Mbocursor.smoe4)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.smoe3)+"','"+Astr(Mbocursor.smoe2)+"','"+Astr(Mbocursor.smoe1)+"','"+Astr(Mbocursor.moetotal)+"','"+Astr(Mbocursor.sdeb2)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.sdeb1)+"','"+Astr(Mbocursor.sdeb4)+"','"+Astr(Mbocursor.sdeb3)+"','"+Astr(Mbocursor.sqtt14)+"','"+Astr(Mbocursor.sqtt13)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.sqtt12)+"','"+Astr(Mbocursor.sqtt11)+"','"+Astr(Mbocursor.sqtt24)+"','"+Astr(Mbocursor.sqtt23)+"','"+Astr(Mbocursor.sqtt22)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.sqtt21)+"','"+Astr(Mbocursor.vqtt24)+"','"+Astr(Mbocursor.vqtt23)+"','"+Astr(Mbocursor.vqtt22)+"','"+Astr(Mbocursor.vqtt21)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.vendedor)+"','"+Astr(Mbocursor.vendnm)+"','"+Astr(Mbocursor.stot1)+"','"+Astr(Mbocursor.stot2)+"','"+Astr(Mbocursor.stot3)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.stot4)+"','"+Astr(Mbocursor.no)+"','"+Astr(Mbocursor.obranome)+"','"+Astr(Mbocursor.boano)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.fechada)+"','"+Astr(Mbocursor.nopat)+"','"+Astr(Mbocursor.total)+"','"+Astr(Mbocursor.tecnico)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.tecnnm)+"','"+Astr(Mbocursor.marca)+"','"+Astr(Mbocursor.maquina)+"','"+Astr(Mbocursor.serie)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.zona)+"','"+Astr(Mbocursor.obs)+"','"+Astr(Mbocursor.trab1)+"','"+Astr(Mbocursor.trab2)+"','"+Astr(Mbocursor.trab3)+"','" 
m.pcsel=m.pcsel+Astr(Mbocursor.trab4)+"','"+Astr(Mbocursor.trab5)+"','"+Astr(Mbocursor.ndos)+"','"+Astr(Mbocursor.custo)+"','"+Astr(Mbocursor.moeda)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.estab)+"','"+Astr(Mbocursor.morada)+"','"+Astr(Mbocursor.local)+"','"+Astr(Mbocursor.codpost)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.period)+"','"+Astr(Mbocursor.tabela1)+"','"+Astr(Mbocursor.ncont)+"','"+Astr(Mbocursor.logi1)+"','"+Astr(Mbocursor.logi2)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.logi3)+"','"+Astr(Mbocursor.logi4)+"','"+Astr(Mbocursor.logi5)+"','"+Astr(Mbocursor.logi6)+"','"+Astr(Mbocursor.logi7)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.logi8)+"','"+Astr(Mbocursor.segmento)+"','"+Astr(Mbocursor.impresso)+"','"+Astr(Mbocursor.userimpresso)+"','"+Astr(Mbocursor.fref)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ccusto)+"','"+Astr(Mbocursor.ncusto)+"','"+Astr(Mbocursor.cobranca)+"','"+Astr(Mbocursor.infref)+"','"+Astr(Mbocursor.lifref)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.esdeb1)+"','"+Astr(Mbocursor.esdeb2)+"','"+Astr(Mbocursor.esdeb3)+"','"+Astr(Mbocursor.esdeb4)+"','"+Astr(Mbocursor.evqtt21)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.evqtt22)+"','"+Astr(Mbocursor.evqtt23)+"','"+Astr(Mbocursor.evqtt24)+"','"+Astr(Mbocursor.estot1)+"','"+Astr(Mbocursor.estot2)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.estot3)+"','"+Astr(Mbocursor.estot4)+"','"+Astr(Mbocursor.etotal)+"','"+Astr(Mbocursor.ecusto)+"','"+Astr(Mbocursor.bo_2tdesc1)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.bo_2tdesc2)+"','"+Astr(Mbocursor.ebo_2tdes1)+"','"+Astr(Mbocursor.ebo_2tdes2)+"','"+Astr(Mbocursor.descc)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.edescc)+"','"+Astr(Mbocursor.bo_1tvall)+"','"+Astr(Mbocursor.bo_2tvall)+"','"+Astr(Mbocursor.ebo_1tvall)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo_2tvall)+"','"+Astr(Mbocursor.bo11_bins)+"','"+Astr(Mbocursor.bo11_iva)+"','"+Astr(Mbocursor.ebo11_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo11_iva)+"','"+Astr(Mbocursor.bo21_bins)+"','"+Astr(Mbocursor.bo21_iva)+"','"+Astr(Mbocursor.ebo21_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo21_iva)+"','"+Astr(Mbocursor.bo31_bins)+"','"+Astr(Mbocursor.bo31_iva)+"','"+Astr(Mbocursor.ebo31_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo31_iva)+"','"+Astr(Mbocursor.bo41_bins)+"','"+Astr(Mbocursor.bo41_iva)+"','"+Astr(Mbocursor.ebo41_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo41_iva)+"','"+Astr(Mbocursor.bo51_bins)+"','"+Astr(Mbocursor.bo51_iva)+"','"+Astr(Mbocursor.ebo51_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo51_iva)+"','"+Astr(Mbocursor.bo61_bins)+"','"+Astr(Mbocursor.bo61_iva)+"','"+Astr(Mbocursor.ebo61_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo61_iva)+"','"+Astr(Mbocursor.bo12_bins)+"','"+Astr(Mbocursor.bo12_iva)+"','"+Astr(Mbocursor.ebo12_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo12_iva)+"','"+Astr(Mbocursor.bo22_bins)+"','"+Astr(Mbocursor.bo22_iva)+"','"+Astr(Mbocursor.ebo22_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo22_iva)+"','"+Astr(Mbocursor.bo32_bins)+"','"+Astr(Mbocursor.bo32_iva)+"','"+Astr(Mbocursor.ebo32_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo32_iva)+"','"+Astr(Mbocursor.bo42_bins)+"','"+Astr(Mbocursor.bo42_iva)+"','"+Astr(Mbocursor.ebo42_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo42_iva)+"','"+Astr(Mbocursor.bo52_bins)+"','"+Astr(Mbocursor.bo52_iva)+"','"+Astr(Mbocursor.ebo52_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo52_iva)+"','"+Astr(Mbocursor.bo62_bins)+"','"+Astr(Mbocursor.bo62_iva)+"','"+Astr(Mbocursor.ebo62_bins)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo62_iva)+"','"+Astr(Mbocursor.bo_totp1)+"','"+Astr(Mbocursor.bo_totp2)+"','"+Astr(Mbocursor.ebo_totp1)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ebo_totp2)+"','"+Astr(Mbocursor.edi)+"','"+Astr(Mbocursor.memissao)+"','"+Astr(Mbocursor.nome2)+"','"+Astr(Mbocursor.pastamp)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.snstamp)+"','"+Astr(Mbocursor.mastamp)+"','"+Astr(Mbocursor.origem)+"','"+Astr(Mbocursor.orinopat)+"','"+Astr(Mbocursor.iiva)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.iunit)+"','"+Astr(Mbocursor.itotais)+"','"+Astr(Mbocursor.iunitiva)+"','"+Astr(Mbocursor.itotaisiva)+"','"+Astr(Mbocursor.site)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.pnome)+"','"+Astr(Mbocursor.pno)+"','"+Astr(Mbocursor.cxstamp)+"','"+Astr(Mbocursor.cxusername)+"','"+Astr(Mbocursor.ssstamp)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ssusername)+"','"+Astr(Mbocursor.alldescli)+"','"+Astr(Mbocursor.alldesfor)+"','"+Astr(Mbocursor.series)+"','"+Astr(Mbocursor.series2)+"','"
m.pcsel=m.pcsel+Astr(Mbocursor.quarto)+"','"+Astr(Mbocursor.ocupacao)+"','"+Astr(Mbocursor.tabela2)+"','"+Astr(Mbocursor.obstab2)+"','"+Astr(Mbocursor.iemail)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.inome)+"','"+Astr(Mbocursor.situacao)+"','"+Astr(Mbocursor.lang)+"','"+Astr(Mbocursor.ean)+"','"+Astr(Mbocursor.iecacodisen)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.boclose)+"','"+Astr(Mbocursor.tpstamp)+"','"+Astr(Mbocursor.tpdesc)+"','"+Astr(Mbocursor.emconf)+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.statuspda)+"','"+Astr(Mbocursor.aprovado)+"','"+Astr(Mbocursor.ousrinis)+"','"+Astr(dtos(Mbocursor.ousrdata))+"','"  
m.pcsel=m.pcsel+Astr(Mbocursor.ousrhora)+"','"+Astr(Mbocursor.usrinis)+"','"+Astr(dtos(Mbocursor.usrdata))+"','"+Astr(Mbocursor.usrhora)+"','"
m.pcsel=m.pcsel+Astr(Mbocursor.marcada)+"'"  
m.pcsel=m.pcsel+" )"
**substituir .t. por 1 e .f. por 0
m.pcsel=STRTRAN(m.pcsel, '.T.', '1')  
m.pcsel=STRTRAN(m.pcsel, '.F.', '0')  
*mensagem(m.pcsel,'directa')
IF not u_sqlexec(m.pcsel,"INSERTBO")
	*u_sqlexec("ROLLBACK TRANSACTION")
	m.msg="Error al insertar el encabezado de un Dossier. El número del documento original en importación es "+ astr (mbocursor.ndos) +" - "+ astr (mbocursor.obrano) +" - Logística: Importación"
	U_PCLOG(.F.,m.msg)
mensagem(m.pcsel,'directa')
	Throw
ELSE
	FECHA("INSERTBO")
ENDIF
wait window "A inserir os dados extra do Dossier Interno com o nº " + astr(Mbocursor.obrano) nowait noclear
*******
**Insert na tabela BO2 do BackOffice
******
Select mbo2cursor
goto top
scan for alltrim(mbo2cursor.bo2stamp)==alltrim(mbocursor.bostamp)
	m.pcsel=""
	m.pcsel=m.pcsel+chr(13)+chr(10)
	m.pcsel=m.pcsel +" INSERT INTO "
	m.pcsel=m.pcsel + "bo2 "
	m.pcsel=m.pcsel +" ([bo2stamp],armazem) values ('" + Astr(Mbo2cursor.bo2stamp)+"',"+astr(Mbo2cursor.armazem)+")"
	m.pcsel=m.pcsel +chr(13)+chr(10)
*mensagem(m.pcsel,'directa')
IF not u_sqlexec(m.pcsel,"INSERTBO2")
	*u_sqlexec("ROLLBACK TRANSACTION")
	m.msg="Error al insertar el encabezado 2 de un Dossier. El número del documento original en importación es "+ astr (mbocursor.ndos) +" - "+ astr (mbocursor.obrano) +" - Logística: Importación"
	U_PCLOG(.F.,m.msg)
*mensagem(m.pcsel,'directa')
	Throw
ELSE
	FECHA("INSERTBO2")
ENDIF
endscan
**Insert na tabela BI do BackOffice
Select mbicursor
goto top
scan for alltrim(mbicursor.bostamp)==alltrim(mbocursor.bostamp)
m.nRecProc=m.nRecProc+1
regua(1,m.nRecProc)
Set message to "Fernando Fontes - Processando o registo nº "+astr(m.nRecProc)+"/"+astr(m.nTotRec-1)
m.pcsel=""
m.pcsel=m.pcsel+" INSERT INTO "
m.pcsel=m.pcsel+  "bi "
m.pcsel=m.pcsel+" (bistamp, nmdos, obrano, ref, design, qtt, qtt2, iva, tabiva, armazem, pu, debito, prorc, stipo, no, pcusto, serie, nopat, fno, "
m.pcsel=m.pcsel+" nmdoc, ndoc, ndos, forref, txiva, lobs, ldossier, obranome, fechada, dataobra, "
m.pcsel=m.pcsel+" tecnico, maquina, marca, zona, litem, vumoeda, resfor, rescli, resrec, iprint, lobs2, litem2, lobs3, estab, resusr, ar2mazem, "
m.pcsel=m.pcsel+" composto, compostoori, lrecno, lordem, fmarcada, producao, local, morada, codpost, nome, vendedor, vendnm, tabfor, tabela1, descli, reff, "
m.pcsel=m.pcsel+" lote, ivaincl, cor, tam, segmento, bofref, bifref, grau, partes, partes2, altura, largura, espessura, biserie, infref, lifref, uni2qtt, "
m.pcsel=m.pcsel+" epu, edebito, eprorc, epcusto, ttdeb, ettdeb, ttmoeda, adoc, binum1, binum2, codigo, cpoc, stns, obistamp, oobistamp, usr1, usr2, usr3, "
m.pcsel=m.pcsel+" usr4, usr5, usr6, usalote, texteis, unidade, unidad2, oftstamp, ofostamp, promo, epromo, familia, sattotal, noserie, slvu, eslvu, sltt, "
m.pcsel=m.pcsel+" esltt, slvumoeda, slttmoeda, ncmassa, ncunsup, ncvest, nccod, ncinteg, classif, classifc, posic, desconto, desc2, desc3, desc4, "
m.pcsel=m.pcsel+" desc5, desc6, series, series2, ccusto, ncusto, num1, fechabo, oobostamp, ltab1, ltab2, ltab3, ltab4, ltab5, fami, pctfami, adjudicada, "
m.pcsel=m.pcsel+" tieca, etieca, mtieca, volume, iecasug, iecagrad, iecacodisen, peso, pbruto, codfiscal, dgeral, temoci, temomi, temsubemp, encargo, "
m.pcsel=m.pcsel+" eencargo, custoind, ecustoind, tiposemp, pvok, boclose, quarto, emconf, efornecedor, efornec, efornestab, cativo, optstamp, "
m.pcsel=m.pcsel+" oristamp, temeco, ecoval, eecoval, tecoval, etecoval, ecoval2, eecoval2, tecoval2, etecoval2, econotcalc, bostamp, ousrinis, ousrdata, "
m.pcsel=m.pcsel+" ousrhora, usrinis, usrdata, usrhora, marcada, dataopen, rdata)"
m.pcsel=m.pcsel+" VALUES( '"
m.pcsel=m.pcsel+Astr(Mbicursor.bistamp)+"','"+Astr(Mbicursor.nmdos)+"','"+Astr(Mbicursor.obrano)+"','"+Astr(Mbicursor.ref)+"','"
m.pcsel=m.pcsel+STRTRAN(Astr(Mbicursor.design), "'", "´")+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.qtt)+"','"+Astr(Mbicursor.qtt2)+"','"+Astr(Mbicursor.iva)+"','"+Astr(Mbicursor.tabiva)+"','"+Astr(Mbicursor.armazem)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.pu)+"','"+Astr(Mbicursor.debito)+"','"+Astr(Mbicursor.prorc)+"','"+Astr(Mbicursor.stipo)+"','"+Astr(Mbicursor.no)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.pcusto)+"','"+Astr(Mbicursor.serie)+"','"+Astr(Mbicursor.nopat)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.fno)+"','"+Astr(Mbicursor.nmdoc)+"','"+Astr(Mbicursor.ndoc)+"','"+Astr(Mbicursor.ndos)+"','"+Astr(Mbicursor.forref)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.txiva)+"','"+Astr(Mbicursor.lobs)+"','"+Astr(Mbicursor.ldossier)+"','"+Astr(Mbicursor.obranome)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.fechada)+"','"+Astr(dtos(Mbicursor.dataobra))+"','"+Astr(Mbicursor.tecnico)+"','"+Astr(Mbicursor.maquina)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.marca)+"','"+Astr(Mbicursor.zona)+"','"+Astr(Mbicursor.litem)+"','"+Astr(Mbicursor.vumoeda)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.resfor)+"','"+Astr(Mbicursor.rescli)+"','"+Astr(Mbicursor.resrec)+"','"+Astr(Mbicursor.iprint)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.lobs2)+"','"+Astr(Mbicursor.litem2)+"','"+Astr(Mbicursor.lobs3)+"','"+Astr(Mbicursor.estab)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.resusr)+"','"+Astr(Mbicursor.ar2mazem)+"','"+Astr(Mbicursor.composto)+"','"+Astr(Mbicursor.compostoori)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.lrecno)+"','"+Astr(Mbicursor.lordem)+"','"+Astr(Mbicursor.fmarcada)+"','"+Astr(Mbicursor.producao)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.local)+"','"+Astr(Mbicursor.morada)+"','"+Astr(Mbicursor.codpost)+"','"+Astr(Mbicursor.nome)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.vendedor)+"','"+Astr(Mbicursor.vendnm)+"','"+Astr(Mbicursor.tabfor)+"','"+Astr(Mbicursor.tabela1)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.descli)+"','"+Astr(Mbicursor.reff)+"','"+Astr(Mbicursor.lote)+"','"+Astr(Mbicursor.ivaincl)+"','"+Astr(Mbicursor.cor)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.tam)+"','"+Astr(Mbicursor.segmento)+"','"+Astr(Mbicursor.bofref)+"','"+Astr(Mbicursor.bifref)+"','"+Astr(Mbicursor.grau)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.partes)+"','"+Astr(Mbicursor.partes2)+"','"+Astr(Mbicursor.altura)+"','"+Astr(Mbicursor.largura)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.espessura)+"','"+Astr(Mbicursor.biserie)+"','"+Astr(Mbicursor.infref)+"','"+Astr(Mbicursor.lifref)+"','"+Astr(Mbicursor.uni2qtt)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.epu)+"','"+Astr(Mbicursor.edebito)+"','"+Astr(Mbicursor.eprorc)+"','"+Astr(Mbicursor.epcusto)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.ttdeb)+"','"+Astr(Mbicursor.ettdeb)+"','"+Astr(Mbicursor.ttmoeda)+"','"+Astr(Mbicursor.adoc)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.binum1)+"','"+Astr(Mbicursor.binum2)+"','"+Astr(Mbicursor.codigo)+"','"+Astr(Mbicursor.cpoc)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.stns)+"','"+Astr(Mbicursor.obistamp)+"','"+Astr(Mbicursor.oobistamp)+"','"+Astr(Mbicursor.usr1)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.usr2)+"','"+Astr(Mbicursor.usr3)+"','"+Astr(Mbicursor.usr4)+"','"+Astr(Mbicursor.usr5)+"','"+Astr(Mbicursor.usr6)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.usalote)+"','"+Astr(Mbicursor.texteis)+"','"+Astr(Mbicursor.unidade)+"','"+Astr(Mbicursor.unidad2)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.oftstamp)+"','"+Astr(Mbicursor.ofostamp)+"','"+Astr(Mbicursor.promo)+"','"+Astr(Mbicursor.epromo)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.familia)+"','"+Astr(Mbicursor.sattotal)+"','"+Astr(Mbicursor.noserie)+"','"+Astr(Mbicursor.slvu)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.eslvu)+"','"+Astr(Mbicursor.sltt)+"','"+Astr(Mbicursor.esltt)+"','"+Astr(Mbicursor.slvumoeda)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.slttmoeda)+"','"+Astr(Mbicursor.ncmassa)+"','"+Astr(Mbicursor.ncunsup)+"','"+Astr(Mbicursor.ncvest)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.nccod)+"','"+Astr(Mbicursor.ncinteg)+"','"+Astr(Mbicursor.classif)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.classifc)+"','"+Astr(Mbicursor.posic)+"','"+Astr(Mbicursor.desconto)+"','"+Astr(Mbicursor.desc2)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.desc3)+"','"+Astr(Mbicursor.desc4)+"','"+Astr(Mbicursor.desc5)+"','"+Astr(Mbicursor.desc6)+"','"+Astr(Mbicursor.series)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.series2)+"','"+Astr(Mbicursor.ccusto)+"','"+Astr(Mbicursor.ncusto)+"','"+Astr(Mbicursor.num1)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.fechabo)+"','"+Astr(Mbicursor.oobostamp)+"','"+Astr(Mbicursor.ltab1)+"','"+Astr(Mbicursor.ltab2)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.ltab3)+"','"+Astr(Mbicursor.ltab4)+"','"+Astr(Mbicursor.ltab5)+"','"+Astr(Mbicursor.fami)+"','"+Astr(Mbicursor.pctfami)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.adjudicada)+"','"+Astr(Mbicursor.tieca)+"','"+Astr(Mbicursor.etieca)+"','"+Astr(Mbicursor.mtieca)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.volume)+"','"+Astr(Mbicursor.iecasug)+"','"+Astr(Mbicursor.iecagrad)+"','"+Astr(Mbicursor.iecacodisen)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.peso)+"','"+Astr(Mbicursor.pbruto)+"','"+Astr(Mbicursor.codfiscal)+"','"+Astr(Mbicursor.dgeral)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.temoci)+"','"+Astr(Mbicursor.temomi)+"','"+Astr(Mbicursor.temsubemp)+"','"+Astr(Mbicursor.encargo)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.eencargo)+"','"+Astr(Mbicursor.custoind)+"','"+Astr(Mbicursor.ecustoind)+"','"+Astr(Mbicursor.tiposemp)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.pvok)+"','"+Astr(Mbicursor.boclose)+"','"+Astr(Mbicursor.quarto)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.emconf)+"','"+Astr(Mbicursor.efornecedor)+"','"+Astr(Mbicursor.efornec)+"','"+Astr(Mbicursor.efornestab)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.cativo)+"','"+Astr(Mbicursor.optstamp)+"','"+Astr(Mbicursor.oristamp)+"','"+Astr(Mbicursor.temeco)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.ecoval)+"','"+Astr(Mbicursor.eecoval)+"','"+Astr(Mbicursor.tecoval)+"','"+Astr(Mbicursor.etecoval)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.ecoval2)+"','"+Astr(Mbicursor.eecoval2)+"','"+Astr(Mbicursor.tecoval2)+"','"+Astr(Mbicursor.etecoval2)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.econotcalc)+"','"+Astr(Mbicursor.bostamp)+"','"+Astr(Mbicursor.ousrinis)+"','"+Astr(dtos(Mbicursor.ousrdata))+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.ousrhora)+"','"+Astr(Mbicursor.usrinis)+"','"+Astr(dtos(Mbicursor.usrdata))+"','"+Astr(Mbicursor.usrhora)+"','"
m.pcsel=m.pcsel+Astr(Mbicursor.marcada)+"','"+Astr(dtos(Mbicursor.dataopen))+"','"+Astr(dtos(Mbicursor.rdata))+"'" 
m.pcsel=m.pcsel+" )"
m.pcsel=m.pcsel+chr(13)+chr(10)
m.pcsel=STRTRAN(m.pcsel, '.T.', '1')
m.pcsel=STRTRAN(m.pcsel, '.F.', '0')
*mensagem(m.pcsel,'directa')
IF not u_sqlexec(m.pcsel,"insertbi")
	*u_sqlexec("ROLLBACK TRANSACTION")
	U_PCLOG(.F.,"Error al insertar una línea del Dossier Interno. El número de línea en el archivo es "+ astr (recno (" Mbicursor ")) +" - Replicación C!")
	Throw
ELSE
	FECHA("insertbi")
ENDIF
endscan
endscan
********actualizar o estado das requisições (TIPO)
*msg('mreqestado')
Select mreqestado
*brow
goto top
scan 
	IF not u_sqlexec([select c=count(*) from u_reqestado where custamp=?mreqestado.custamp and ref=?mreqestado.ref and periodo=?mreqestado.periodo],"estados")
		*u_sqlexec("ROLLBACK TRANSACTION")
		U_PCLOG(.F.,"Error al comprobar el estado del pedido - Logística!")
		Throw
	ELSE
		select estados
		if estados.c>0
		****já existe faz o update
TEXT TO STR1 TEXTMERGE NOSHOW
update u_reqestado 
set datae='<<astr(dtos(mreqestado.datae))>>', usrdata='<<astr(dtos(mreqestado.usrdata))>>',
 usrhora='<<astr(mreqestado.usrhora)>>', usrinis='<<astr(mreqestado.usrinis)>>' 
where custamp='<<mreqestado.custamp>>' and ref='<<mreqestado.ref>>' and periodo=<<mreqestado.periodo>> 
ENDTEXT
			str2="Erro ao actualizar estado da requisição - Logística!"
		else
		****não existe faz o insert
TEXT TO STR1 TEXTMERGE NOSHOW
insert u_reqestado (ref ,qtt, periodo, u_reqestadostamp ,custamp ,datae ,ousrdata ,ousrhora ,ousrinis ,usrdata ,usrhora ,usrinis ) 
values(
'<<mreqestado.ref>>' ,
<<mreqestado.qtt>> ,
<<mreqestado.periodo>> ,
'<<mreqestado.u_reqestadostamp>>' ,
'<<mreqestado.custamp>>' ,
'<<astr(dtos(mreqestado.datae))>>' ,
'<<astr(dtos(mreqestado.ousrdata))>>' ,
'<<astr(mreqestado.ousrhora)>>' ,
'<<astr(mreqestado.ousrinis)>>' ,
'<<astr(dtos(mreqestado.usrdata))>>' ,
'<<astr(mreqestado.usrhora)>>' ,
'<<astr(mreqestado.usrinis)>>'
)
ENDTEXT
			str2="Erro ao inserir estado da requisição - Logística!"
		endif
		FECHA("estados")
*mensagem(str1,'directa')
		*******faz a actualização
		IF not u_sqlexec(str1,"actestado")
			*u_sqlexec("ROLLBACK TRANSACTION")
			U_PCLOG(.F.,str2)
			Throw
		ELSE
			fecha("actestado")
		ENDIF
	ENDIF
endscan
********actualizar a data que se pretende emitir a próxima requisição (TIPO)
*msg('mreqestado 2')
Select mreqestado
*brow
goto top
scan 
		**actualiza a data próxima data de emissão do ccusto com base na data em que foi emitido + o periodo da primeira linha"
		if m.ccustoactual<>mreqestado.custamp
		** vai actualizar também a data do centro de custo com a data de emissão do documento 
			m.ccustoactual=mreqestado.custamp
			TEXT TO STR3 TEXTMERGE NOSHOW
				--select novadata=min(dateadd(mm,e.periodo,e.datae)) 
				select novadata=min(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae))) 
				from cu inner join u_reqtipo r on cu.u_reqno=r.reqno 
				inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
				inner join st (nolock) on l.ref=st.ref 
				inner join u_reqestado e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
				where e.custamp='<<mreqestado.custamp>>'
			ENDTEXT
**msg(str3)
			IF not u_sqlexec(STR3,'novadata')
				U_PCLOG(.F.,"Error al comprobar la siguiente fecha en la tabla de estados - Logística!")
				Throw
			else
				*update 
				TEXT TO STR1 TEXTMERGE NOSHOW
					update cu set  u_reqdatai='<<astr(dtos(novadata.novadata))>>' where custamp='<<m.ccustoactual>>'
				ENDTEXT
				str2="Error al actualizar la fecha del centro de coste - Logística! " + STR1
				fecha("novadata")
				*******faz a actualização
				IF not u_sqlexec(str1,"actestado")
					*u_sqlexec("ROLLBACK TRANSACTION")
*		mensagem('***** TIPO *****     '+str1,'directa')
					U_PCLOG(.F.,str2)
					Throw
				ELSE
					fecha("actestado")
				ENDIF
			endif
		endif
endscan
************************** 2011-05-31 ***************************
**** alteração para controlar também as requisições de venda ****
*****************************************************************
********actualizar o estado das requisições (Venda)
*msg('reqvestado')
Select mreqVestado
goto top
scan 
	IF not u_sqlexec([select c=count(*) from u_reqVestado where custamp=?mreqVestado.custamp and ref=?mreqVestado.ref and periodo=?mreqVestado.periodo],"estados")
		*u_sqlexec("ROLLBACK TRANSACTION")
		U_PCLOG(.F.,"Error al comprobar el estado del pedido - Logística!")
		Throw
	ELSE
		select estados
		if estados.c>0
		****já existe faz o update
TEXT TO STR1 TEXTMERGE NOSHOW
update u_reqVestado 
set datae='<<astr(dtos(mreqVestado.datae))>>', usrdata='<<astr(dtos(mreqVestado.usrdata))>>',
 usrhora='<<astr(mreqVestado.usrhora)>>', usrinis='<<astr(mreqVestado.usrinis)>>' 
where custamp='<<mreqVestado.custamp>>' and ref='<<mreqVestado.ref>>' and periodo=<<mreqVestado.periodo>> 
ENDTEXT
			str2="Error al actualizar el estado del pedido - Logística!"
		else
		****não existe faz o insert
TEXT TO STR1 TEXTMERGE NOSHOW
insert u_reqVestado (ref ,qtt, periodo, u_reqVestadostamp ,custamp ,datae ,ousrdata ,ousrhora ,ousrinis ,usrdata ,usrhora ,usrinis ) 
values(
'<<mreqVestado.ref>>' ,
<<mreqVestado.qtt>> ,
<<mreqVestado.periodo>> ,
'<<mreqVestado.u_reqVestadostamp>>' ,
'<<mreqVestado.custamp>>' ,
'<<astr(dtos(mreqVestado.datae))>>' ,
'<<astr(dtos(mreqVestado.ousrdata))>>' ,
'<<astr(mreqVestado.ousrhora)>>' ,
'<<astr(mreqVestado.ousrinis)>>' ,
'<<astr(dtos(mreqVestado.usrdata))>>' ,
'<<astr(mreqVestado.usrhora)>>' ,
'<<astr(mreqestado.usrinis)>>'
)
ENDTEXT
			str2="Error al insertar el estado del pedido - Logística!"
		endif
		FECHA("estados")
*mensagem(str1,'directa')
		*******faz a actualização
		IF not u_sqlexec(str1,"actestado")
			*u_sqlexec("ROLLBACK TRANSACTION")
			U_PCLOG(.F.,str2)
			Throw
		ELSE
			fecha("actestado")
		ENDIF
	ENDIF
endscan
********actualizar a data que se pretende emitir a próxima requisição (Venda)
Select mreqVestado
goto top
scan 
		**actualiza a data próxima data de emissão do ccusto com base na data em que foi emitido + o periodo da primeira linha"
		if m.ccustoactual<>mreqVestado.custamp
		** vai actualizar também a data do centro de custo com a data de emissão do documento 
			m.ccustoactual=mreqVestado.custamp
			TEXT TO STR3 TEXTMERGE NOSHOW
				--select novadata=min(dateadd(mm,e.periodo,e.datae)) 
				select novadata=min(iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae))) 
				from cu inner join u_reqtipo r on cu.u_reqVno=r.reqno 
				inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
				inner join st (nolock) on l.ref=st.ref 
				inner join u_reqVestado e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
				where e.custamp='<<mreqVestado.custamp>>'
			ENDTEXT
**msg(str3)
			IF not u_sqlexec(STR3,'novadata')
				U_PCLOG(.F.,"Error al comprobar la siguiente fecha en la tabla de estados - Logística!")
				Throw
			else
				*update 
				TEXT TO STR1 TEXTMERGE NOSHOW
					update cu set  u_reqVdata='<<astr(dtos(novadata.novadata))>>' where custamp='<<m.ccustoactual>>'
				ENDTEXT
				str2="Error al actualizar la fecha del centro de coste - Logística!"
		*mensagem(str1, 'directa')
				fecha("novadata")
				*******faz a actualização
				IF not u_sqlexec(str1,"actestado")
					*u_sqlexec("ROLLBACK TRANSACTION")
*mensagem('***** VENDA *****     '+str1,'directa')
					U_PCLOG(.F.,str2)
					Throw
				ELSE
					fecha("actestado")
				ENDIF
			endif
		endif
endscan

**********************************************************
******* 2011-05-31 *** fim de alteração req venda ********
**********************************************************

************************** 2012-01-05 ***************************
**** alteração para controlar também as requisições Consumiveis ****
*****************************************************************
*msg('inicio de consumiveis')
********actualizar o estado das requisições (Consumiveis)
*msg('reqcestado')
Select mreqCestado
*brow
goto top
scan 
	IF not u_sqlexec([select c=count(*) from u_reqcestado (nolock) where custamp=?mreqCestado.custamp and ref=?mreqCestado.ref and periodo=?mreqCestado.periodo],"estados")
		*u_sqlexec("ROLLBACK TRANSACTION")
		U_PCLOG(.F.,"Error al comprobar el estado del pedido - Logística!")
		Throw
	ELSE
		select estados
		if estados.c>0
		****já existe faz o update
		TEXT TO STR1 TEXTMERGE NOSHOW
			update u_reqCestado 
			set datae='<<astr(dtos(mreqCestado.datae))>>', usrdata='<<astr(dtos(mreqCestado.usrdata))>>',
			usrhora='<<astr(mreqCestado.usrhora)>>', usrinis='<<astr(mreqCestado.usrinis)>>' 
			where custamp='<<mreqCestado.custamp>>' and ref='<<mreqCestado.ref>>' and periodo=<<mreqCestado.periodo>> 
		ENDTEXT
			str2="Error al actualizar el estado del pedido - Logística!"
		else
		****não existe faz o insert
tEXT TO STR1 TEXTMERGE NOSHOW
insert u_reqCestado (ref ,qtt, periodo, u_reqCestadostamp ,custamp ,datae ,ousrdata ,ousrhora ,ousrinis ,usrdata ,usrhora ,usrinis ) 
values(
'<<mreqCestado.ref>>' ,
<<mreqCestado.qtt>> ,
<<mreqCestado.periodo>> ,
'<<mreqCestado.u_reqCestadostamp>>' ,
'<<mreqCestado.custamp>>' ,
'<<astr(dtos(mreqCestado.datae))>>' ,
'<<astr(dtos(mreqCestado.ousrdata))>>' ,
'<<astr(mreqCestado.ousrhora)>>' ,
'<<astr(mreqCestado.ousrinis)>>' ,
'<<astr(dtos(mreqCestado.usrdata))>>' ,
'<<astr(mreqCestado.usrhora)>>' ,
'<<astr(mreqCestado.usrinis)>>'
)
ENDTEXT
			str2="Error al insertar el estado del pedido - Logística!"
		endif
		FECHA("estados")
*mensagem(str1,'directa')
		*******faz a actualização
		IF not u_sqlexec(str1,"actestado")
			*u_sqlexec("ROLLBACK TRANSACTION")
			U_PCLOG(.F.,str2)
			Throw
		ELSE
*msg(str1)
			fecha("actestado")
		ENDIF
	ENDIF
endscan
********actualizar a data que se pretende emitir a próxima requisição (Consumiveis)
Select mreqCestado
*brow
goto top
scan 
		**actualiza a data próxima data de emissão do ccusto com base na data em que foi emitido + o periodo da primeira linha"
		if m.ccustoactual<>mreqCestado.custamp
		** vai actualizar também a data do centro de custo com a data de emissão do documento 
			m.ccustoactual=mreqCestado.custamp
			TEXT TO STR3 TEXTMERGE NOSHOW
				select novadata=			
				min( iif(l.periodo=round(l.periodo,0) ,dateadd(mm,l.periodo,e.datae),dateadd(dd,30*l.periodo,e.datae)) 
                    )			
				--min(dateadd(mm,e.periodo,e.datae)) 
				from cu inner join u_reqtipo r on cu.u_reqcno=r.reqno 
				inner join u_reqtipol l on r.u_reqtipostamp=l.u_reqtipostamp
				inner join st (nolock) on l.ref=st.ref 
				inner join u_reqcestado (nolock) e on cu.custamp=e.custamp and l.ref=e.ref and l.periodo=e.periodo
				where e.custamp='<<mreqCestado.custamp>>'
			ENDTEXT
*			mensagem(str3, 'directa')
**msg(str3)
			IF not u_sqlexec(STR3,'novadata')
		
			U_PCLOG(.F.,"Erro ao verificar proxima data na tabela de estados - Logística!")
				Throw
			else
				*update 
				TEXT TO STR1 TEXTMERGE NOSHOW
					update cu set  u_reqCdata='<<astr(dtos(novadata.novadata))>>' where custamp='<<m.ccustoactual>>'
			
				ENDTEXT
				str2="Erro ao actualizar a data do centro de custo - Logística!"
				fecha("novadata")
				*******faz a actualização
				IF not u_sqlexec(str1,"actestado")
					*u_sqlexec("ROLLBACK TRANSACTION")
*	mensagem('***** Consumiveis*****     '+str3+'      ++++++     '+str1,'directa')
					U_PCLOG(.F.,str2)
					Throw
				ELSE
					fecha("actestado")
				ENDIF
			endif
		endif
endscan

*****************************************************************
******* 2011-05-31 *** fim de alteração req Consumiveis ********
*****************************************************************
regua(2)
Set message to "FF"
**wait window "Inseridos "+ astr (m.nlinhas) +" registros con ÉXITO! - Logística: Importación!" nowait noclear
wait window "Inseridos documentos de pedido de cliente con ÉXITO! - Logística: Importación!" nowait noclear
u_sqlexec("select @@error as err",'sequas')
if sequas.err = 0
	If Not u_sqlexec("COMMIT TRANSACTION")
		**u_sqlexec("ROLLBACK TRANSACTION")
		U_PCLOG(.F.,"ROLLBACK TRANSACTION - Erro no COMMIT TRANSACTION  ")
		Throw
	else
select retfich
go top
m.reportdata=retfich.data
**brow
		U_PCLOG(.T.,"Se generaron pedidos para fechas a partir de "+dtoc(m.reportdata))
	Endif
else
	**u_sqlexec("ROLLBACK TRANSACTION")
	U_PCLOG(.F.,"ROLLBACK TRANSACTION - No se pudo insertar documentos internos - @@error<>0 - Replicação C!")
	Throw
endif
fecha('sequas')
fecha("mbocursor")
fecha("mbicursor")
fecha("mbicursor2")
fecha("mbo2cursor")
fecha("mreqestado")
fecha("mreqVestado")
fecha("mreqCestado")
fecha("mystk")
***********fim da rotina***********
Else
    MSG('No existen datos para crear los pedidos!')
endif
CATCH TO oException
if oexception.ErrorNo <> 2071
	*Histórico
	m.datafim=str(year(date()),4)+strzero(month(date()),2,0)+strzero(day(date()),2,0)
	m.horafim=right(transform(datetime()),8)
	u_sqlexec("ROLLBACK TRANSACTION")
	m.apc="exec uFF_errorlog '" +astr(padl(seconds(),10,'_')) + "','"
	m.apc=m.apc+ m_file+"','"+ m.dataini + "','" + m.horaini + "','" + m.datafim + "','" + m.horafim + "'," 
	m.apc=m.apc+ "0,0,' ',0,' ',' ','ERRO DA ROTINA DE IMPORTAÇÃO - "
	m.errr=left(alltrim(astr(oException.Message)),210) 
	m.errr=STRTRAN(m.errr, "'", "#")
	m.apc=m.apc + m.errr + "'"
 	u_sqlexec(m.apc,'Errors')
	regua(2)
	Set message to "FF"
	_Screen.Draw
	actform("Ocorreu um error rotina de Importação ... VER O LOG NA TABELA U_IMPORTA","SEARCH")
	deactform()
	timeouton()
endif
set point to ","
ENDTRY
deactform()
timeouton()
WAIT WINDOW "OK" nowait 




FUNCTION U_PCLOG
Lparameters m.sucesso, m.logdescr
	m.apc=''
	
	*Historico
	m.datafim=str(year(date()),4)+strzero(month(date()),2,0)+strzero(day(date()),2,0)
	m.horafim=right(transform(datetime()),8)
	if m.sucesso
		m.apc="exec uFF_errorLog '" + left(m_file,15)+astr(padl(seconds(),10,'_')) + "','"
		m.apc=m.apc+m_file+"','"+ m.dataini + "','" + m.horaini + "','" + m.datafim + "','" + m.horafim + "'," 
		m.apc=m.apc+"1,1,'BO + BI + BO2'," + astr(m.nlinhas) + ",'Safira',' ','OK - " + astr(m.logdescr) + "'"
	else
		u_sqlexec("ROLLBACK TRANSACTION")
		m.apc="exec uFF_errorLog '" + left(m_file,15)+astr(padl(seconds(),10,'_')) + "','"
		m.apc=m.apc+m_file+"','"+ m.dataini + "','" + m.horaini + "','" + m.datafim + "','" + m.horafim + "'," 
		m.apc=m.apc+"1,0,'BO + BI + BO2'," + astr(m.nlinhas) + ",'Safira',' ','" + astr(m.logdescr) + "'"
	endif
	*mensagem(m.apc, 'directa')
	u_sqlexec(m.apc,'ErrorLog')
	msg(astr(m.logdescr))
	regua(2)
	Set message to "FF"
	_Screen.Draw
	actform(astr(m.logdescr),"SEARCH")
	deactform()
	timeouton()
ENDFUNC

FUNCTION U_FF_PARTEDOC
Lparameters m.entradaX, m.ndosX, m.anoX, m.documentoX, m.docX
     m.EntradaX=left(m.docx,3)
     m.ndosX=val(substr(m.docX,4,3))
     m.anoX=val(substr(m.docX,8,4))
     m.documentoX=val(substr(m.docX,13))
ENDFUNC

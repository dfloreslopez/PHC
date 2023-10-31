*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: ALT+P
*Pantalla: SBO
*Tipo: Programa
*Última modificación/revisión: 19/10/2023
*Descripción: 
* Muestra una pantalla con las cantidades enviadas de los últimos 5 pedidos.
* Hace una mezcla en esos 5 útimos pedidos, primero pone los pedidos a proveedor y si hay menos de 5 lo rellena con pedidos de cliente.
* Permite introducir las cantidades a pedir. Al aceptar introduce las líneas con la información de 
* los artículos y las cantidades introducidas.
* La pantalla autorellena los artículos con las cantidades del documento actual. Esto sirve para que compras pueda abrir el documento 
* y ver las cantidades introducidas por el supervisor junto a los últimos 5 pedidos.
*****

x=.F.
h=.F.
Try
	h=sbo.adding
	x=sbo.editing
Catch
	x=.F.
	h=.F.
Finally
Endtry

Select bo
If bo.fechada
   Msg("El pedido está cerrado, no se puede mostrar la ventana.")
   Return .f.
Endif

If !h And !x Then
   SBO.ShowSave()
Endif

m_ccusto=bo.ccusto

*	m_ndos alterado para o do pedido a fornecedor (2) (antes era ndos 1 para pedido a cliente) ***** PSS 04OUT2023
* Sobre qué documento interno vamos a trabajar:
* El 1 es pedido de cliente.
* El 2 es pedido a proveedor.

***
* Actualización 19/10/2023:
* A partir de ahora, m_ndos siempre será pedidos a proveedor.
* La consulta de pedidos anteriores, tendrá en cuenta tanto pedidos a proveedor como pedidos a cliente, para mostrar los 5 últimos:

***

* Si tenemos pulsadas las teclas de control forzamos a pedido de cliente siempre.
*If user_dfControlTeclas()
*	m_ndos=1
*Else
*	m_ndos=2
*	* Si no mostraremos los pedidos a proveedor si hay alguno (aunque sea solo uno) y los pedidos de cliente si no hay ninguna a proveedor:
*	TEXT to sqldatas noshow textmerge
*	   select * from Pedidos_anteriores_ccusto(<<m_ccusto>>,<<m_ndos>>)
*	ENDTEXT
*	If !u_sqlexec(sqldatas,'curPedidos') or reccount()=0
*		m_ndos=1
*	Endif
*
*Endif
m_ndos=2

****** ########## ROTINA PARA OBTER DADOS DO CCUSTO (TESTE)
* Cogemos dirección y plafon y asignamos al parte:
TEXT to sqlMorada noshow textmerge

   select 
      rTrim(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada)) as morada,
      cu.u_plffmate,
      cu.u_anoini 
   from 
      cl (nolock) 
   join
      cl2 (nolock) on cl2.cl2stamp=cl.clstamp
   join 
      cu (nolock) on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl where cu.cct='<<bo.ccusto>>'

ENDTEXT
If u_sqlexec(sqlMorada,'curMorada')
   select bo
   replace bo.trab3 with curMorada.morada
   m_plafond=curMorada.u_plffmate
Endif

* Ahora vamos a coger la media mesual del coste para el centro:
u_sqlexec([select datediff (MM,']+astr(dtosql(bo.dataobra))+[',']+astr(dtosql(curcl.u_anoini))+[') as meses],"curmeses")
if abs(curmeses.meses)>=12

   u_sqlexec([select avg(bo.etotaldeb) as media, dateadd(month,-12,']+astr(dtosql(bo.dataobra))+[') as datai from bo (nolock) where bo.ndos=']+astr(m_ndos)+[' and bo.dataobra > dateadd(month,-12,']+astr(dtosql(bo.dataobra))+[')],"curmedia" )

   m_media=round(curmedia.media,2)
   m_datai12=dtosql(curmedia.datai)
   m_datacalc=right(alltrim(m_datai12),2)+'.'+left(right(alltrim(m_datai12),4),2)+'.'+left(alltrim(m_datai12),4)
   m_datacalc=m_datacalc

else

   u_sqlexec([select avg(bo.etotaldeb) as media, ']+astr(dtosql(curcl.u_anoini))+[' as datai from bo (nolock) where bo.ndos=']+astr(m_ndos)+[' and bo.dataobra > ']+astr(dtosql(curcl.u_anoini))+['],"curmedia" )

   m_media=round(curmedia.media,2)
   m_datacalc=right(alltrim(curmedia.datai),2)+'.'+left(right(alltrim(curmedia.datai),4),2)+'.'+left(alltrim(curmedia.datai),4)
   m_datacalc=m_datacalc

endif

* El importe del coste del pedido anterior:
if u_sqlexec([select top 1 bo.etotaldeb as total from bo (nolock) where bo.ndos=']+astr(m_ndos)+[' and bo.ccusto=']+astr(bo.ccusto)+[' order by bo.dataobra desc],"curpedido") and reccount()>0

   m_pedido=round(Nvl(curpedido.total,0),2)

else

   m_pedido=0

endif

m_titbrow=[Plafond ]+m_ccusto+[: ]+alltrim(astr(m_plafond))+[ Media Mensual: ]+alltrim(astr(m_media))+[ Fecha Cálculo: ]+alltrim(astr(m_datacalc))+[ Último Pedido: ]+alltrim(astr(m_pedido))

***** ########## FIM DE ROTINA PARA OBTER DADOS DO CCUSTO


*	m_ndos=bo.ndos
m_clno=bo.no
m_clestab=bo.estab
m_dt1=''
m_dt2=''
m_dt3=''
m_dt4=''
m_dt5=''

m_Query_dt1=''
m_Query_dt2=''
m_Query_dt3=''
m_Query_dt4=''
m_Query_dt5=''

m_Query_Ped1=0
m_Query_Ped2=0
m_Query_Ped3=0
m_Query_Ped4=0
m_Query_Ped5=0

m_ndos1=m_ndos
m_ndos2=m_ndos
m_ndos3=m_ndos
m_ndos4=m_ndos
m_ndos5=m_ndos

if empty(m_clno)
   msg('Por favor, seleccione un cliente antes de intentar seleccionar artículos.')
   return .f.
endif
	
***** Recolhe datas anteriores, la función de sql server devuelve las últimas 5 fechas de pedido para el cliente y establecimiento dado:
TEXT to sqldatas noshow textmerge
   select * from DF_Pedidos_anteriores_ccusto(<<m_ccusto>>)
ENDTEXT

*** select * from Datas_anteriores(<<m_clno>>,<<m_clestab>>,<<m_ndos>>)
*** select * from Datas_anteriores(1,0,45)
If !u_sqlexec(sqldatas,'crsdatas')
   Msg('No se han encontrado pedidos de cliente del centro de coste seleccionado ('+m_ccusto+').')
   Return .F.
Else

   * Ahora vamos cogiendo cada fecha de pedido y la metemos cada una en una variable:
   Select crsdatas
   go top
   Locate For crsdatas.linea='1'
   If Found()
		* El título de la columna del pedido 1:
      If crsdatas.ndos=1
	     m_dt1=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"("+iif(crsdatas.Ordinario, "O", "E")+")"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
	   Else
		  m_dt1=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"(P)"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
      EndIf
      * Dejamos la fecha en formato yyyymmdd para poder usarla en las consultas
      m_Query_dt1=DToC(crsdatas.dataobra, 1)
      m_Query_Ped1=crsdatas.pedido
      m_ndos1=crsdatas.ndos
   Endif
   Select crsdatas
   Locate For crsdatas.linea='2'
   If Found()
      If crsdatas.ndos=1
	     m_dt2=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"("+iif(crsdatas.Ordinario, "O", "E")+")"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
	   Else
	  	  m_dt2=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"(P)"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
      EndIf
      * Dejamos la fecha en formato yyyymmdd para poder usarla en las consultas
      m_Query_dt2=DToC(crsdatas.dataobra, 1)
      m_Query_Ped2=crsdatas.pedido
      m_ndos2=crsdatas.ndos
   Endif
   Select crsdatas
   Locate For crsdatas.linea='3'
   If Found()
      If crsdatas.ndos=1
	     m_dt3=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"("+iif(crsdatas.Ordinario, "O", "E")+")"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
	   Else
		  m_dt3=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"(P)"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
      EndIf
      * Dejamos la fecha en formato yyyymmdd para poder usarla en las consultas
      m_Query_dt3=DToC(crsdatas.dataobra, 1)
      m_Query_Ped3=crsdatas.pedido
      m_ndos3=crsdatas.ndos
   Endif
   Select crsdatas
   Locate For crsdatas.linea='4'
   If Found()
      If crsdatas.ndos=1
	     m_dt4=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"("+iif(crsdatas.Ordinario, "O", "E")+")"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
	   Else
		  m_dt4=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"(P)"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
      EndIf
      * Dejamos la fecha en formato yyyymmdd para poder usarla en las consultas
      m_Query_dt4=DToC(crsdatas.dataobra, 1)
      m_Query_Ped4=crsdatas.pedido
      m_ndos4=crsdatas.ndos
   Endif
   Select crsdatas
   Locate For crsdatas.linea='5'
   If Found()
      If crsdatas.ndos=1
	     m_dt5=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"("+iif(crsdatas.Ordinario, "O", "E")+")"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
	  Else
		 m_dt5=StrTran(dtoc(crsdatas.dataobra), ".", "/")+"(P)"+iif(year(crsdatas.fechaenvio)>1900,"-F.Env.:"+StrTran(dtoc(crsdatas.fechaenvio), ".", "/"),"")
      EndIf
      * Dejamos la fecha en formato yyyymmdd para poder usarla en las consultas
      m_Query_dt5=DToC(crsdatas.dataobra, 1)
      m_Query_Ped5=crsdatas.pedido
      m_ndos5=crsdatas.ndos
   Endif
Endif
***** select dataobra from Datas_anteriores(<<m_clno>>,<<m_clestab>>,<<m_ndos>>)

TEXT to sqlcommand noshow textmerge
   select 
      ref, 
      design, 
      sum(qtt) as qtt1, 
      sum(qtt2) as qtt2, 
      sum(qtt3) as qtt3, 
      sum(qtt4) as qtt4, 
      sum(qtt5) as qtt5, 
      0 as Enc, 
      idlinha
   from (
      select 
         bi.ref, 
         bi.design, 
         qtt, 
         0 as qtt2 ,
         0 as qtt3 ,
         0 as qtt4,
         0 as qtt5, 
         1 as idlinha
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.obrano=<<m_Query_Ped1>> 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos1>>

      union all
      select 
         bi.ref, 
         bi.design, 
         0, 
         qtt,
         0 ,
         0, 
         0, 
         1
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.obrano=<<m_Query_Ped2>> 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos2>>

      union all
      select 
         bi.ref, 
         bi.design, 
         0, 
         0, 
         qtt,
         0, 
         0, 
         1
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.obrano=<<m_Query_Ped3>> 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos3>>

      union all
      select 
         bi.ref, 
         bi.design, 
         0, 
         0, 
         0, 
         qtt, 
         0, 
         1
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.obrano=<<m_Query_Ped4>> 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos4>>

      union all
      select 
         bi.ref, 
         bi.design, 
         0, 
         0, 
         0,
         0, 
         qtt, 
         1
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.obrano=<<m_Query_Ped5>> 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos5>>
      
      union all
      select 
         distinct bi.ref, 
         bi.design, 
         0, 
         0, 
         0,
         0,
         0,
         2
      from 
         bo (nolock) 
      join 
         bi (nolock) on bo.bostamp=bi.bostamp
      join 
         st (nolock) on st.ref=bi.ref and st.inactivo=0
      where 
         bo.dataobra<'<<m_Query_dt1>>' 
         and bi.ref <>'' 
         and bo.ccusto='<<m_ccusto>>' 
         and bo.ndos=<<m_ndos>> 
         and bi.ref not in (select 
                              distinct bi.ref 
                           from 
                              bi
                           join 
                              bo on bo.bostamp=bi.bostamp
                           where
                              bo.obrano in (<<m_Query_Ped1>>, <<m_Query_Ped2>>, <<m_Query_Ped3>>, <<m_Query_Ped4>>, <<m_Query_Ped5>>)
                              )

   ) as encomendasanteriores
   group by 
      ref, design, idlinha
   order by 
      idlinha

ENDTEXT

* msg(sqlcommand)

   xFlagEscolha=.F.
   m.escolheu = .F.
   If u_sqlexec(sqlcommand,'curstref') Then

***** Preencher coluna com quantidade a pedir com informação que consta das linhas do documento ***** PSS 04OUT2023
		Select curstref
		Go top
		scan
			m_refx=curstref.ref
			select bi
			locate for bi.ref=m_refx
				if found()
					Replace curstref.enc with bi.qtt
				endif
		endscan
*****
		Do While !xFlagEscolha
			Select curstref
			Goto Top
			=CursorSetProp('Buffering',5,'curstref' )
			Declare list_tit(8), list_cam(8), list_pic(8), list_ronly(8), list_tam(8)
			*, list_combo(8), list_valid(8), list_rot(8)
			list_tit(1)="Referencia"
			list_cam(1)="curstref.ref"
			list_ronly(1)=.T.
			list_tam(1)=8*18
			list_pic(1)=""
         
			list_tit(2)="Descripción"
			list_cam(2)="curstref.design"
			list_ronly(2)=.T.
			list_tam(2)=8*55
			list_pic(2)=""
			
         *list_tit(3)=m_dt1+chr(10)+chr(13)+m_dt1
         list_tit(3)=m_dt1
			list_cam(3)="curstref.qtt1"
			list_ronly(3)=.T.
			list_tam(3)=8*16
			list_pic(3)=""
			*			list_valid(3)=""
			list_tit(4)=m_dt2
			list_cam(4)="curstref.qtt2"
			list_ronly(4)=.T.
			list_tam(4)=8*16
			list_pic(4)=""
			*			list_valid(4)=""
			list_tit(5)=m_dt3
			list_cam(5)="curstref.qtt3"
			list_ronly(5)=.T.
			list_tam(5)=8*16
			list_pic(5)=""
			*			list_valid(5)=""
			list_tit(6)=m_dt4
			list_tam(6)=8*16
			list_ronly(6)=.T.
			list_pic(6)=""
			list_cam(6)="curstref.qtt4"
			*			list_rot(6)=""
			list_tit(7)=m_dt5
			list_tam(7)=8*8
			list_pic(7)=""
			list_ronly(7)=.T.
			list_cam(7)="curstref.qtt5"
			*			list_rot(7)=""
			list_tit(8)="A pedir"
			list_tam(8)=8*8
			list_cam(8)="curstref.enc"
			list_pic(8)=""
			*			list_rot(8)=""

			*!* Realce Dinâmico das linhas com alterações (em que o valor a satisfazer é diferente de zero) a BOLD
			mcampobold="curstref.enc<>0"
			m.escolheu = .F.
*			browlist("Artículos a encomendar",'curstref',"", .T., .F., .F., .T., .F., "", .F., .T.)
			browlist(m_titbrow,'curstref',"", .T., .F., .F., .T., .F., "", .F., .T.)
			xFlagEscolha = .T.
         *If m.escolheu And pergunta('¿Quieres introducir los artículos con cantidades a pedir a las líneas del documento?',.F.)
			*	xFlagEscolha=.T.
			*Endif
			*If !m.escolheu And pergunta('¿Quieres cancelar la introducción de artículos?',.F.)
			*	xFlagEscolha=.T.
			*Endif
		Enddo
	Endif

	*If xFlagEscolha and m.escolheu
   If m.escolheu

***** Eliminar as linhas com referência ***** PSS 04OUT2023

      Select bi
      * DA 2023/10/31: Borramos los que tengan referencia y estén marcados como artículos que vienen de la selección:
      delete for !empty(bi.ref) and rTrim(bi.u_obs)='ARTICULOS_SELECCIONADOS'

*****

		Select curstref
		Go Top
		Scan
			If curstref.enc>0
				*****.T. And crsrefs.qttenc>=crsrefs.qttmin
				***** ACRESCENTAR DADOS DO FORNECEDOR HABITUAL
				if u_sqlexec ([select st.epv1, st.forref, st.tabiva, taxasiva.taxa, st.unidade, st.pcusto, st.epcusto, st.cpoc, st.usr3, st.familia, st.fornec, st.fornestab, st.fornecedor from st (nolock) join taxasiva on st.tabiva=taxasiva.codigo where st.ref=']+astr(alltrim(curstref.ref))+['],'curst')
***brow
				else
					msg('Ha ocurrido un problema al obtener informacion del artículo: '+astr(alltrim(curstref.ref))+'.'+chr(13)+'. Processo cancelado.')
					return .f.
				endif
				Select bi
				*					Append Blank
				Do boine2in
				Replace bi.ref With curstref.ref
				Replace bi.qtt With curstref.enc
				Replace bi.Design With curstref.Design
				
            select curst
					Replace bi.forref With curst.forref
				*					Replace bi.armazem With 11110
					Replace bi.tabiva With curst.tabiva
					Replace bi.iva With curst.taxa
					Replace bi.unidade With curst.unidade
					Replace bi.pcusto With curst.pcusto
					Replace bi.epcusto With curst.epcusto
               Replace bi.cpoc With curst.cpoc
               Replace bi.usr3 With curst.usr3
               Replace bi.familia With curst.familia
			   Replace bi.efornec with curst.fornec
			   Replace bi.efornestab with curst.fornestab
			   Replace bi.efornecedor with curst.fornecedor
            * DA 2023/10/31: Marcar registros para eliminar solo los que vienen desde la pantalla de "Selección de artículos":
            Replace bi.u_obs with 'ARTICULOS_SELECCIONADOS'
				*					Replace bi.edebito With curst.epv1
				*					Replace bi.ettdeb with curst.epv1*curst.enc
				select bi
***brow
***				Do boactref with '',.t.,'OKPRECOS','BI'
				Do u_bottdeb With 'BI', .F.
			Else
				*					If curstref.sel=.T.
				*						m_refserro=m_refserro+': '+Alltrim(curstref.ref)
				*					Endif
			Endif
		Endscan

	Endif

* Wait Window "SALIR" Timeout 0.3
Return .F.

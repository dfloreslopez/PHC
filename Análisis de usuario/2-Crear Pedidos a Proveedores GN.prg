
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


**Xdata=#1#

m.entregaselmar="00300001201"



** FF ** 20190618 ** pedido para aparecer na grelha a descrição do CC em vez do nome do cliente

TEXT To xsql textmerge noshow
   Select
      Cast(0 As Bit) 'Sel',
      bo.bostamp,
      bo.Obrano,
      bo.Dataobra,
      bo.no,
      bo.u_descrcc as nome/*bo.nome*/,
      bo.etotaldeb,
      bo.ccusto,
      logi8N=
         case
            when bo.logi8= 1 then
               'Sí'
            else
               'No'
         End,
      --,logi7N=case when bo.logi7= 1 then 'Sí' else 'No' End
      bo.logi8
      --, bo.logi7
      from
         bo (nolock)
      where
         bo.ndos=1 and bo.logi6=0
      order by
         bo.dataobra, bo.obrano
ENDTEXT

**msg(astr(xsql))

If u_sqlexec(xsql ,"MPedidosClientes")


	** Agora vamos ao Browlist Editável
	Declare list_tit(7),list_cam(7),list_tam(7),list_pic(7),list_ronly(7)

	list_tit(1)="Seleccionar"
	list_tit(2)="Núm. pedido"
	list_tit(3)="Fecha"
	list_tit(4)="Núm. cliente"
	list_tit(5)="Nombre cliente"
	list_tit(6)="Centro Trabajo Entrega"
	list_tit(7)="¿Facturable?"
	**list_tit(8)=""


	list_cam(1)="MPedidosClientes.Sel"
	list_cam(2)="MPedidosClientes.Obrano"
	list_cam(3)="MPedidosClientes.DataObra"
	list_cam(4)="MPedidosClientes.no"
	list_cam(5)="MPedidosClientes.nome"
	list_cam(6)="MPedidosClientes.ccusto"
	list_cam(7)="MPedidosClientes.logi8N"
	**list_cam(8)=0




	list_ronly(1)=.F.
	list_ronly(2)=.T.
	list_ronly(3)=.T.
	list_ronly(4)=.T.
	list_ronly(5)=.T.
	list_ronly(6)=.T.
	list_ronly(7)=.T.
	**list_ronly(8)=.T.



	list_pic=""
	list_pic(1)="LOGIC"
	**list_pic()="LOGIC"


	list_tam(1)=8*5
	list_tam(2)=8*5
	list_tam(3)=8*10
	list_tam(4)=8*5
	list_tam(5)=8*5
	list_tam(6)=8*5
	list_tam(7)=8*5
	**list_tam(8)=8*5

	m.escolheu=.F.
	** Chamamos o browlist
	browlist('Selección de Pedidos de clientes','MPedidosClientes','MPedidosClientes',.T.,.F.,.F.,.T.,.F.,'',.T.)

	If m.escolheu

		m.stringdossier=""
		m.count=0
		Select MPedidosClientes
		Scan

			If MPedidosClientes.sel=.T.  Then

				If m.count=0 Then
					m.stringdossier=MPedidosClientes.bostamp
				Else
					m.stringdossier=m.stringdossier+"','"+MPedidosClientes.bostamp
				Endif

				m.count=m.count+1
			Endif

		Endscan




	TEXT to ssql textmerge noshow

      Select
         data,
         ref,
         design,
         qtt=sum(mqtt),
         edebito=sum(edebito),
         ettdeb=sum(ettdeb),
         familia,
         stns,
         cpoc,
         desconto,
         desc2,
         ccusto,
         forref,
         fornecedor,
         FORNEC,
         FORNESTAB,
         ExiteFornec,
         logi8,
         logi7,
         epcusto=sum(mepcusto),
         epcustototal=sum(epcustototal),
         Entrega,
         bostamp,
         obrano,
         bistamp,
         inactivo
      from
         (Select
            data=bo.dataobra,
            ref=bi.ref,
            bi.Design,
            mqtt=sum(qtt),
            edebito=sum(bi.edebito),
            ettdeb=sum(bi.ettdeb),
            bi.familia,
            bi.stns,
            bi.cpoc,
            bi.desconto,
            bi.desc2,
            bi.ccusto,
            st.forref,
            st.fornecedor,
            st.FORNEC,
            st.FORNESTAB,
            ExiteFornec=isnull((select no from fl (nolock) where no=st.FORNEC),0),
            bo.logi8,
            bo.logi7,
            mepcusto=sum(bi.epcusto),
            epcustototal=sum(round(bi.epcusto*bi.qtt,2)),
            Entrega=
               case
                  when (select fl.U_ENTRSELM from fl (nolock) where no=st.FORNEC) = 1 then
                     '<<m.entregaselmar>>'
                  when  bo.logi7 = 1 then
                     '<<m.entregaselmar>>'
                  When bo.maquina<>'' then
                     bo.maquina
                  else
                     bo.ccusto
               end,
            bo.bostamp,
            bo.obrano,
            bi.bistamp,
            st.inactivo

      From
         bo (nolock)
      inner join
         bi (nolock) on bi.bostamp=bo.bostamp
      inner join
         st (nolock) on st.ref=bi.ref
      where
         bo.bostamp in ('<<m.stringdossier>>')
      Group by
         bi.ref,bi.familia,bo.trab3,bo.dataobra,bi.design,bi.stns,bi.cpoc,bi.desconto,bi.desc2,st.forref,st.fornecedor,
         st.fornec,st.fornestab,bo.logi8,bo.logi7,bo.maquina,bo.ccusto,bi.ccusto,bo.bostamp,bo.obrano,bi.bistamp,st.inactivo
      ) as tb
      group by
         data,ref,design,familia, stns,cpoc, desconto, desc2,forref,fornecedor,FORNEC,FORNESTAB,ExiteFornec,logi8,logi7,Entrega,ccusto,bostamp,obrano,bistamp, inactivo
         Order by fornec,entrega,data,logi8

   ENDTEXT

   *msg(ssql)

		If u_sqlexec(ssql,'crbi') And Reccount('crbi')>0 Then

         m.stringRefSinPro=""
         m.stringRefInactiva=""
         Select crbi
			Scan

				If crbi.fornec =0 Then
					
               m.stringRefSinPro=m.stringRefSinPro + 'Pedido de cliente: '+ astr(obrano)+' referencia: '+astr(crbi.ref)+' centro de coste: '+crbi.ccusto+CHR(13)+CHR(10)

               *msg('Existe a referência' + astr(crbi.ref)+ ' sem proveedor (' + crbi.ccusto + '). No se á realizado . Operacion Cancelada!'  )
					* Return .F.
				Endif

				If crbi.inactivo Then
					
               m.stringRefInactiva=m.stringRefInactiva + 'Pedido de cliente: '+ astr(obrano)+' referencia: '+astr(crbi.ref)+' centro de coste: '+crbi.ccusto+CHR(13)+CHR(10)

					*Return .F.
				Endif

			Endscan

         If !Empty(m.stringRefInactiva)
            Msg('Las siguientes referencias están inactivas (descatalogadas): '+CHR(13)+CHR(10)+m.stringRefInactiva)
         Endif

         If !Empty(m.stringRefSinPro)
            Msg('Las siguientes referencias no tienen proveedor: '+CHR(13)+CHR(10)+m.stringRefSinPro)
         Endif

         If !Empty(m.stringRefSinPro) Or !Empty(m.stringRefInactiva)
            Msg('Debe arreglar los errores indicados en los mensajes anteriores para poder crear los pedidos a proveedor. ¡¡No se hace nada!!')
            Return .F.
         Endif

			contador=0
			xoldfornec=0
			xoldentrega=''
			xoldata=''
			xolfat=.f.
			Select crbi
			Scan

				xfono=crbi.fornec
				xFoestab=crbi.FORNESTAB
				xentrega=crbi.entrega
				xadata=crbi.Data
				xfat=crbi.logi8

				* Revisar este código, porque es el que indica un nuevo pedido de proveedor, y queremos uno por cada pedido de cliente:
            If xfono <> xoldfornec or xoldentrega<>xentrega or xoldata<>xadata or xoldfat<>xfat  Then

					xoldfornec=xfono
					xoldentrega=xentrega
					xoldata=xadata
					xoldfat=xfat
					contador=contador+1

					**msg('Novo fornecedor')


					**Select bi
					**Goto Top
					If contador >1 Then
						Do BOTOTS With .T.
						sbo.localrefrescar()
						sbo.Bok1.Okbuttomdef1.Click()

                  * Después de guardar, marcamos el pedido de cliente como Pedido de proveedor creado:
                  TEXT to usql textmerge noshow
                     Update
                        bo
                     set
                        logi6=1 -- Creado pedido a proveedor
                     where
                        bo.bostamp='<<xbostamp>>'
                  ENDTEXT
                  *Msg(usql)

                  u_sqlexec(usql)

					Endif
					doread('BO', 'SBO')
					sbo.newndos(2)
					sbo.dointroduzir

               xbostamp=crbi.bostamp

					**********Introduzido em 08_07_2013 PSB *********************************

					**	If Val(left(xData,4)) < Year(Date()) Then
					**	xdataano=(left(xData,4))
					**msg(astr(xdataano))

					**	u_sqlexec("select max(obrano) as ultobra from bo where ndos=2 and boano= "+astr(xdataano)+"  ", 'nobra')

					**Select nobra
					**Replace bo.obrano With nobra.ultobra+1
					**Replace bo.boano With Year(xData)
					**Endif

					*********************************************************************

               TEXT to clsql textmerge noshow
						select no, nome, morada, local, ncont, codpost,estab,U_ENTRSELM from fl (nolock) where no=<<xFono>> and estab=<<xFoestab>>
					ENDTEXT

					u_sqlexec(clsql,'crag')

					Select crag
					Goto Top
					* DA 2023/10/25: Ponemos la fecha del pedido de cliente al pedido a proveedor:
               Replace bo.dataobra With crbi.data
					Replace bo.no With crag.no
					Replace bo.Nome With crag.Nome
					Replace bo.morada With crag.morada
					Replace bo.codpost With crag.codpost
					Replace bo.Local With crag.Local
					Replace bo.ncont With crag.ncont
					Replace bo.ccusto With astr(crbi.Entrega)

					If    crbi.entrega= '1' Then
						Replace bo.trab3 With 'Selmar SA'
						Replace bo.u_descrcc With ''
					Else

						TEXT to cusql textmerge noshow

									Select moradaentr=ltrim(rtrim(cl.morada)) +' - '+ltrim(rtrim(cl.local)),cu.descricao  from cu (nolock)
									inner join cl (nolock) on cu.u_nocl=cl.no and cu.u_estabcl=cl.estab
									where cu.cct='<<Alltrim(astr(crbi.Entrega))>>'
						ENDTEXT
						

***Msg(astr(cusql))

						If u_sqlexec(cusql,'Crsmcl') And Reccount('crsmcl') >0 Then
							Replace bo.trab3 With Crsmcl.moradaentr
							Replace bo.u_descrcc With Crsmcl.descricao
						Endif
					Endif


					**Replace bo.trab3 With crbi.trab3
					Replace bo.logi8 With crbi.logi8
					Replace bo.logi7 With crbi.logi7
					
***msg('ok111')
					Select bo2
                                         **brow
					Replace bo2.XPDDATA with crbi.data

					* PARA PROBAR EN LA PRÓXIMA GENERACIÓN DE PARTES DE REPOSICIÓN:
               *If u_sqlexec("select U_OBSREP, U_OBSENT from cu join bo on cu.cct='"+crbi.ccusto+"'", 'curObs')
                * Select curObs
                * Replace bo3.U_OBSREP With curObs.U_OBSREP
                * Replace bo3.U_OBSENT With curObs.U_OBSENT
               *Endif

					**Select nobra
					**Replace bo.obrano With nobra.ultobra+1
					**Replace bo.boano With Year(xData)

					Select bi
					Delete For .T.

				Endif

				Select bi
				Goto Bottom
				Do boine2in
				If !Empty(crbi.ref) Then
					Replace bi.ref With crbi.ref
				Else
					**Replace bi.ref With crbi.oref
				Endif
				Do BOACTREF With '',.T.,'OKPRECOS','bi'
				Replace bi.Design With crbi.Design
				Replace bi.qtt With crbi.qtt
				**Replace bi.edebito With crbi.edebito
				**Replace bi.ettdeb With crbi.ettdeb
				Replace bi.edebito With crbi.epcusto
				Replace bi.ettdeb With crbi.epcustototal
				Replace bi.bifref With crbi.ref
				Replace bi.desconto With crbi.desconto
				Replace bi.desc2 With crbi.desc2
				**Replace bi.oobistamp With crbi.bistamp
				Replace bi.ccusto With crbi.ccusto

            * El bistamp del origen para asociar las líneas:
            Replace bi.oobistamp With crbi.bistamp


				Do u_bottdeb With 'bi'
				Replace bi.cpoc With crbi.cpoc

				Do BOTOTS With .T.

			Endscan

			Select bi
			Goto Top
			sbo.localrefrescar()

			sbo.Bok1.Okbuttomdef1.Click()

          * Después de guardar, marcamos el pedido de cliente como Pedido de proveedor creado:
         TEXT to usql textmerge noshow
            Update
               bo
            set
               logi6=1 -- Creado pedido a proveedor
            where
               bo.bostamp='<<xbostamp>>'
         ENDTEXT
         *Msg(usql)

         u_sqlexec(usql)

		Endif

	Endif
   Msg("Proceso terminado correctamente.")

Else
	Messagebox("Error al buscar pedidos. Consulta " + xsql)
Endif

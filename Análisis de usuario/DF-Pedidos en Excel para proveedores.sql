
/*
   Grupo: Compras
   Descripción: Muestra los pedidos a proveedor para generar el listado para el proveedor de los seleccionados.
   
   Variables:
      - 1: Tipo D; Nombre "Desde fecha"
      - 2: Tipo D; Nombre "Hasta fecha"
   
*/





text to sql1 textmerge noshow

   Select 
      Cast(0 As Bit) 'Seleccionar',
      Proveedor= bo.nome,
      Pedido=str(bo.obrano),
      Fecha=convert(varchar(10), bo.dataobra, 103),
      Cuenta=bo.ccusto,
      Nombre=u_descrcc,
      Direccion=iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada),
		CP=iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST),
		Poblacion=iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL),
		Provincia=iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO),
      Referencia= isnull((Select forref from st (nolock) where ref=bi.ref),''),
      DESCRIPCION=bi.design,
      CANTIDAD=qtt,
      FACTURABLE=case when bo.logi8=1 
                     then "Sí"
                 else "No"
                 end,
      InstruccionesEntrega=cu.U_OBSENT,
      ObservacionesReposicion=cu.U_OBSREP,
      BISTAMP=BI.BISTAMP,
      BOSTAMP=BO.BOSTAMP
      
   from 
      bo (nolock)
   inner join 
      bi (nolock) on bi.bostamp=bo.bostamp
   inner join 
      st (nolock) on bi.ref=st.ref
   left join
      cu (nolock) on cu.cct=bo.ccusto
   left join 
      cl (nolock) on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
   left join 
      cl2 (nolock) on cl2.cl2stamp=cl.clstamp
   where 
      bo.ndos=2
      and bo.dataobra between #1# and #2#
      and bi.qtt>0 and bo.U_DATAREVP='19000101' and bo.fechada=0
   order by bo.obrano
endtext

*u_sqlexec(sql1,'PedPro')

If u_sqlexec(sql1,'PedPro')

	* Mostraremos un browse para seleccionar los registros que queremos exportar a Excel y marcar como enviados:
	
   Declare list_tit(16),list_cam(16),list_tam(16),list_pic(16),list_ronly(16)

	list_tit(1)="Seleccionar"
	list_tit(2)="Proveedor"
	list_tit(3)="Pedido"
	list_tit(4)="Fecha"
	list_tit(5)="Cuenta"
	list_tit(6)="Nombre"
	list_tit(7)="Dirección"
	list_tit(8)="CP"
	list_tit(9)="Población"
	list_tit(10)="Provincia"
	list_tit(11)="Referencia"
	list_tit(12)="Descripción"
	list_tit(13)="Cantidad"
	list_tit(14)="Facturable"
	list_tit(15)="Instrucciones entrega"
	list_tit(16)="Observaciones reposición"

	list_cam(1)="PedPro.Seleccionar"
	list_cam(2)="PedPro.Proveedor"
	list_cam(3)="PedPro.Pedido"
	list_cam(4)="PedPro.Fecha"
	list_cam(5)="PedPro.Cuenta"
	list_cam(6)="PedPro.Nombre"
	list_cam(7)="PedPro.Direccion"
	list_cam(8)="PedPro.CP"
	list_cam(9)="PedPro.Poblacion"
	list_cam(10)="PedPro.Provincia"
	list_cam(11)="PedPro.Referencia"
	list_cam(12)="PedPro.Descripcion"
	list_cam(13)="PedPro.Cantidad"
	list_cam(14)="PedPro.Facturable"
	list_cam(15)="PedPro.InstruccionesEntrega"
	list_cam(16)="PedPro.ObservacionesReposicion"

	list_ronly(1)=.F.
	list_ronly(2)=.T.
	list_ronly(3)=.T.
	list_ronly(4)=.T.
	list_ronly(5)=.T.
	list_ronly(6)=.T.
	list_ronly(7)=.T.
	list_ronly(8)=.T.
	list_ronly(9)=.T.
	list_ronly(10)=.T.
	list_ronly(11)=.T.
	list_ronly(12)=.T.
	list_ronly(13)=.T.
	list_ronly(14)=.T.
	list_ronly(15)=.T.
	list_ronly(16)=.T.

	list_pic=""
	list_pic(1)="LOGIC"

	list_tam(1)=8*5
	list_tam(2)=8*5
	list_tam(3)=8*5
	list_tam(4)=8*5
	list_tam(5)=8*5
	list_tam(6)=8*10
	list_tam(7)=8*10
	list_tam(8)=8*5
	list_tam(9)=8*10
	list_tam(10)=8*10
	list_tam(11)=8*5
	list_tam(12)=8*10
	list_tam(13)=8*5
	list_tam(14)=8*5
	list_tam(15)=8*10
	list_tam(16)=8*10

	m.escolheu=.F.
	* Llamamos al browlist:
	browlist('Selección de Pedidos de proveedor','PedPro','PedPro',.T.,.F.,.F.,.T.,.F.,'',.T.)
   
	If m.escolheu
		
      m.stringDoc=""
      m.stringBO=""
		m.count=0
		Select PedPro
		Scan

			If PedPro.Seleccionar=.T.  Then

				If m.count=0 Then
					m.stringDoc=PedPro.BISTAMP
               m.stringBO=PedPro.BOSTAMP
				Else
					m.stringDoc=m.stringDoc+"','"+PedPro.BISTAMP
					m.stringBO=m.stringBO+"','"+PedPro.BOSTAMP
				Endif

				m.count=m.count+1
			Endif

		Endscan

      If Pergunta("¿Marcamos los pedidos seleccionados como enviados al proveedor?Si selecciona Sí, estos pedidos no volverán a salir en esta ventana.")
         TEXT to marcadoPedidos textmerge noshow
            update bo set U_DATAREVP=cast(Getdate() as date) where bostamp in ('<<m.stringBO>>')
         ENDTEXT
         u_sqlexec(marcadoPedidos,'marcaPed')
         
      endif

		TEXT to ExtraccionProveedor textmerge noshow

         Select 
            Proveedor=rTrim(bo.nome),
            Pedido=bo.obrano,
            Fecha=convert(varchar(10), bo.dataobra, 103),
            Cuenta=rTrim(bo.ccusto),
            Nombre=rTrim(u_descrcc),
            Direccion=rTrim(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada)),
            CP=rTrim(iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST)),
            Poblacion=rTrim(iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL)),
            Provincia=rTrim(iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO)),
            Referencia= rTrim(isnull((Select forref from st (nolock) where ref=bi.ref),'')),
            DESCRIPCION=rTrim(bi.design),
            CANTIDAD=qtt,
            FACTURABLE=case when bo.logi8=1 then 
                           "Sí"
                       else 
                           "No"
                       end,
            InstruccionesEntrega=cu.U_OBSENT
            
         from 
            bo (nolock)
         inner join 
            bi (nolock) on bi.bostamp=bo.bostamp
         inner join 
            st (nolock) on bi.ref=st.ref
         left join
            cu (nolock) on cu.cct=bo.ccusto
         left join 
            cl (nolock) on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
         left join 
            cl2 (nolock) on cl2.cl2stamp=cl.clstamp
         where 
            bi.BISTAMP in ('<<m.stringDoc>>')
         order by bo.obrano

		ENDTEXT
      
      * Msg(ExtraccionProveedor)

      u_sqlexec(ExtraccionProveedor,'sqltmp')

      *If reccount('sqltmp')=0
      *   mensagem("No se han extraido pedidos para proveedores",'Directa')
      *endif
      
      *mostrameisto("sqltmp","Extracción para el proveedor.")
      
   Endif
      
Else
	Messagebox("Error al buscar los registros.")
Endif


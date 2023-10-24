*****

*<REFACTORIZAR>*
   * AQUI TENEMOS QUE QUITAR LA PETICIÓN DE FECHAS Y NÚMEROS DE FACTURA Y TRABAJAR CON LA LISTA DE REGISTROS, MOSTRAMOS VENTANA PARA SELECCIONAR REGISTROS
   * Y A LOS MARCADOS LES ENVIAMOS UN EMAIL.
   * REVISAR EL ENVÍO DE EMAIL Y VER SI PODEMOS HACER UNA FUNCIÓN DE USUARIO USANDO EL OBJETO OLE DE OUTLOOK, ASÍ PODEMOS ENVIAR USANDO OFFICE 64BITS Y 
   * VER SI SE PUEDE INSERTAR UNA FIRMA AL CORREO.

*/<REFACTORIZAR>*

* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: F8
*Pantalla: SFT
*Tipo: Programa
*Última modificación/revisión: 24/10/2023
*Descripción: 
* Asignar un centro de coste a la línea en la que estamos.
* Pide un texto y lo busca en nombre o código con % delante y detrás.
* Luego muestra una lista con los centros que coinciden con esos criterios.
*****

Select FT
m_ft_ndoc=FT.ndoc
If Inlist(m_ft_ndoc,1,12,19,10,16,20,21,17,22,11,18,14,13)  Then

	xregistos=0

	xDataproc=getnome('Indique la fecha de las facturas a enviar por email?', Date())
	xFNO=Getnome('¿Desde qué número de factura enviamos?', 1, , , , , , , , 1, 999999, , )
*** Getnome(Ctitulo, xdefeito, cnotas, cpicture, nbutao, lpasswordmode, ccombrws, lretlistindex, ccaption, nvalormin, nvalormax, ctypeget, objparametros)

	TEXT to Fsql textmerge noshow
      select * from (
      select CAST(0 AS BIT) as envia
      --, case when cl_2.c2email='' or cl_2.c2email is null then  cl.c2email else cl_2.c2email end  as email
      --,case when ft2.email='' or ft2.email is null then cl.cobemail else ft2.email end as email
      ,case when ft3.u_emailpdf='' or ft3.u_emailpdf is null then cl2.emaildoc else ft3.u_emailpdf end as email
      --,cl.cobemail as email
      --,cl2.u_emailpdf as email
      , ft.fno, ft.nome,ft.fdata,FT.etotal, Ft.no,FTstamp,ano=year(ft.fdata),ft.nmdoc,convert(numeric(10,0),ft.ndoc) as ndoc
      ,isnull((select top 1 bo.estab
      from bi(NOLOCK) inner join bo (nolock) on bi.bostamp=bo.bostamp
      inner join fi (nolock) on fi.bistamp=bi.bistamp
      where fi.ftstamp=ft.ftstamp and fi.bistamp<>''

      union all
      select top 1 ft_2.estab from ft(NOLOCK) as ft_2 inner join fi on fi.ftstamp=ft_2.ftstamp where fi.fistamp in
      (select fi_2.ofistamp  from fi (nolock) as fi_2 where fi_2.ftstamp=ft.ftstamp)
      and fi.fistamp<>''
      ),0) as estab
      --, case when cl_2.u_nosupply ='0' or cl_2.u_nosupply is null then cl.u_nosupply else cl_2.u_nosupply end as supplier

      ,(select top 1 titulo from ftiduc where (ndos=ft.ndoc and IMPDEF=1) or (docmulti=1 and impdef=1)) as layout
      --,CAST(0 AS BIT) as gerarpdf
            from ft (nolock)	
            inner join ft3 (nolock) on ft.ftstamp=ft3.ft3stamp
            join  cl (nolock) on ft.no=cl.no and ft.estab=cl.estab
            join cl2 (nolock) on cl.clstamp=cl2.cl2stamp
            left join cl (nolock) as cl_2 on cl_2.no=ft.no and cl_2.estab=isnull((select top 1 bo.estab
      from bi(NOLOCK) inner join bo (nolock) on bi.bostamp=bo.bostamp
      inner join fi (nolock) on fi.bistamp=bi.bistamp
      where fi.ftstamp=ft.ftstamp and fi.bistamp<>''

      union all
      select top 1 ft_2.estab from ft(NOLOCK) as ft_2 inner join fi on fi.ftstamp=ft_2.ftstamp where fi.fistamp in
      (select fi_2.ofistamp  from fi (nolock) as fi_2 where fi_2.ftstamp=ft.ftstamp)
      and fi.fistamp<>''
      ),0)) as tblx
             where  tblx.fdata='<<dtos(xdataproc)>>' and tblx.ndoc=<<FT.ndoc>> and tblx.fno>=<<xFNO>> and tblx.email <> ''
      order by tblx.fno

	ENDTEXT

***	msg(astr(Fsql ))

	If !u_sqlexec(Fsql,'CrPagaf')
		msg("Error al buscar valores")
	Else

		=CursorSetProp('Buffering',5,'Crpagaf' )

		Declare list_tit(7), list_cam(7), list_pic(7), list_ronly(7), list_tam(7), list_combo(7), list_valid(7), list_rot(7)


		list_tit(1)="Enviar"
		list_cam(1)="Crpagaf.envia"
		list_ronly(1)=.F.
		list_pic(1)="LOGIC"
		list_tam(1)=8
		list_valid(1)=""
		list_rot(1)=""

		list_tit(2)="Fecha"
		list_cam(2)="Crpagaf.fdata"
		list_ronly(2)=.T.
		list_pic(2)=""
		list_tam(2)=8*10
		list_valid(2)=""
		list_rot(2)=""

		list_tit(3)="Nº Factura"
		list_cam(3)="CrPagaf.fno"
		list_ronly(3)=.T.
		list_pic(3)="999999999"
		list_tam(3)=8*10
		list_valid(3)=""
		list_rot(3)=""

		list_tit(4)="Nº cliente"
		list_cam(4)="CrPagaf.no"
		list_ronly(4)=.T.
		list_pic(4)="999999999"
		list_tam(4)=8*10
		list_valid(4)=""
		list_rot(4)=""

		list_tit(5)="Nombre"
		list_cam(5)="Crpagaf.nome"
		list_ronly(5)=.T.
		list_pic(5)=""
		list_tam(5)=8*55
		list_valid(5)=""
		list_rot(5)=""

		list_tit(6)="Valor"
		list_cam(6)="crpagaf.etotal"
		list_ronly(6)=.T.
		list_pic(6)=Substr(m.m_eurpic, 3)
		list_tam(6)=8*20
		list_valid(6)=""
		list_rot(6)=""

		list_tit(7)="Email"
		list_cam(7)="crpagaf.email"
		list_ronly(7)=.F.
		list_pic(7)=""
		list_tam(7)=8*30
		list_valid(7)=""
		list_rot(7)=""

*		list_tit(7)="GERAR PDF"
*		list_cam(7)="Crpagaf.gerarpdf"
*		list_ronly(7)=.F.
*		list_pic(7)="LOGIC"
*		list_tam(7)=8
*		list_valid(7)=""
*		list_rot(7)=""


		m.escolheu = .F.

		browlist("Envio de Facturas a clientes por email",'Crpagaf',"meuteste", .T., .F., .F., .T., .F., "", .F., .T.)

		If m.escolheu

			regua(2)

			xregistos=0
			mntotal=Reccount('crpagaf')
			regua(0,mntotal,"Enviando facturas por email masivo...")
			Select crpagaf
			Scan

				If crpagaf.envia=.T. 
*** Or crpagaf.gerarpdf=.T. Then


					regua[1,recno(),"Enviando factura Nº"+astr(FT.fno)+' ('+astr(recno())+'/'+astr(mntotal)+')']


					navega("FT",crpagaf.ftstamp)
					Wait Window + "A posicionar no registo...	" Timeout 0.5
					SFT.doactualizar




					** Define o ano da pasta onde é guardado o documento
					manodoc=crpagaf.ano

***					mcaminho=Alltrim(McaminhoBase)+Alltrim(astr(manodoc))+'\'
***				McaminhoBase ='\\labhfile02.derichebourg.com\DbgDrive\Documentos\'
				McaminhoBase ='g:\phc\phcesprd\tmp\'
***				McaminhoBase ='C:\PHC\TMP\facEmail\'
***				mcaminho=Alltrim(McaminhoBase)+Alltrim(astr(manodoc))+'\'
				mcaminho=Alltrim(McaminhoBase)

					** Criar directoria para ficheiros
					If Directory(McaminhoBase) Then
						If Directory(mcaminho) Then
						Else
							Md (mcaminho)
						Endif
					Endif


				myemail=Alltrim(crpagaf.email)

***				myemail='net.pruebas.gruponet@gmail.com'

***				mnomeficheiro=Alltrim(crpagaf.nmdoc)+" nº "+ iif(crpagaf.fno<0,"Rascunho",astr(crpagaf.fno))+" ("+left(astr(crpagaf.fdata),10)+") "+ alltrim(crpagaf.nome)
				mnomeficheiro="Factura_NET__"+astr(crpagaf.fno)
*** msg(mnomeficheiro)

***				mnomeficheiro='testefactura'

				m.ndoc=crpagaf.ndoc
				**cTitIDU = "1 - Fatura"
				cTitIDU =ltrim(crpagaf.layout)
				if empty( cTitIDU)
				msg('No fue posible determinar qué plantilla de impresión utilizar.'+chr(13)+'Proceso cancelado.')
				return .f.
				endif
				xFile= mcaminho+mnomeficheiro+".pdf"
***		msg(astr(m.ndoc)+[,]+cTitIDU +[,]+xFile)
				IduToPdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",nvl(m.ndoc,0),nvl(cTitIDU,'') ,nvl(xFile,''),"","NO",.F.,"ONETOMANY")


				If  !Empty(crpagaf.email) Then
					TEXT TO m_body TEXTMERGE NOSHOW
                  Estimado cliente. 

                  Adjunto encontrarán nuestra factura en formato PDF. 
                  Si tienen cualquier duda/consulta pueden ponerse en contacto con nosotros en este mismo mail indicando el número de factura o en el telf. 662960733

                  Gracias. 
                  Un saludo. 

                  Atte. Vanesa Manresa. 

                  GRUPONET 

               endtext
					m_To=myemail
**					m_Subject= []  + Alltrim(astr(crpagaf.supplier)) + [ | Invoice ] + Alltrim(astr(FT.fno))
					m_Subject= "Factura de Grupo Net"
					m_Body=m_body
					m_Attachments=xFile
					l_OpenClient=.f.
					l_Quiet=.F.


						u_sendmail(m_To,m_Subject,m_Body,m_Attachments,l_OpenClient,l_Quiet)

						xregistos=xregistos+1
					Endif


				Endif

			Endscan
			** Fecha regua
			regua(2)
			mensagem("Han sido enviadas "+Alltrim(astr(xregistos))+" facturas de clientes por email.",'DIRECTA')
		Endif

		fecha("Crpagaf")


	Endif
Endif
Return .T.

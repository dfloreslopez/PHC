*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: SHIFT+F4
*Pantalla: SBO
*Tipo: Programa
*Última modificación/revisión: 20/10/2023
*Descripción: 
* Crea los partes de trabajo desde los servicios.
* Según las condiciones introducidas en el servicio.
*****

Select ts
mvar_ndos_origem=ts.ndos
mvar_ndos_destino=116
If Inlist(mvar_ndos_origem,16)

		Create Cursor xVars ( no N(5), tipo c(1), Nome c(40), Pict c(100), lOrdem N(10), nValor N(18,5), cValor c(250), lValor l, dValor d, tBval M )
		Select xVars
		Append Blank
		Replace xVars.no With 1
		Replace xVars.tipo With "D"
		Replace xVars.Nome With "Data Inicio"
		Replace xVars.Pict With ""
		Replace xVars.lOrdem With 1
		Replace xVars.dValor With Date()
		Select xVars
		Append Blank
		Replace xVars.no With 2
		Replace xVars.tipo With "D"
		Replace xVars.Nome With "Data Fim"
		Replace xVars.Pict With ""
		Replace xVars.lOrdem With 2
		Replace xVars.dValor With Date()

		m.Escolheu = .F.
		m.mCaption = "Datos para filtrar copias."
		docomando("do form usqlvar with 'xvars',m.mCaption,.t.")
		If Not m.Escolheu
			mensagem("Selección de datos interrumpida!","DIRECTA")
			mvar_erro= .T.
		Else
			Select xVars
			Locate
			mvardataini=dtosql(xVars.dValor)
			Select xVars
			Skip
			mvardatafim=dtosql(xVars.dValor)
			mvar_erro=.F.
		Endif
	mvar_resposta=.F.
	mvar_resposta=pergunta("¿Desea crear los registros de Partes de Trabajo que faltan a partir de las fechas seleccionadas?",2,"Creará los registros de Partes de Trabajo que faltam a partir de las fechas seleccionadas.",.T.)
	If mvar_resposta= .T.
	
		**msg(astr(mvardataini))
		**msg(astr(mvardatafim))
		fecha("CRS_RESULT")
		TEXT TO msql_codigo TEXTMERGE NOSHOW
	exec sp_copiar_documentos_serv_periodico <<mvar_ndos_origem>>,<<mvar_ndos_destino>>,'<<astr(mvardataini)>>','<<astr(mvardatafim)>>'
		ENDTEXT
		If u_Sqlexec (msql_codigo, "CRS_RESULT") And mvar_erro=.F.
			Select CRS_RESULT
			mvar_resulta=CRS_RESULT.Error
			If !Empty(mvar_resulta)
				msg("Error al ejecutar la inserción (0.1). "+ astr(mvar_resulta))
			Else
				msg("Los documentos de la Partes de Trabajo se creron con éxito.")
			Endif
		Else
			msg("Error al ejecutar la inserción (0.2)")
		Endif
	Endif
Else
	msg("Esta tecla no se puede ejecutar en el documento actual.")
Endif


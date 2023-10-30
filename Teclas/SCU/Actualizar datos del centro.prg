*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: CTRL + F2
*Pantalla: SCU
*Tipo: Programa
*Última modificación/revisión: 30/10/2023
*Descripción: 
* Actualiza ciertos datos de los centros de coste, sobre todo relacionados con la zona, 
* que es está relacionado con una tabla que indica la referencia a usar para partes de trabajo.
* También actualiza el nombre del supervisor
*****


TRY
   If pergunta('Vamos a actualizar los datos de todos los centros de coste desde su registro de cliente/establecimiento:'+Chr(13)+;
      'Se actualizarán los campos ZONA, CÓDIGO DE PROVINCIA, PROVINCIA y nombre de supervisor.'+Chr(13)+Chr(13)+;
      '¿Continuamos?', 2, "", .T.)

      regua(2)
      regua(1,2,"Ejecutando consulta...")

      Local msel
      Local msel2

      text to m.msel textmerge noshow 

            UPDATE xCU SET U_ZONA=
               (CASE 
                  WHEN CL.CODPROVINCIA='35' OR CL.CODPROVINCIA='38' THEN 'CANARIAS'
                  WHEN CL.CODPROVINCIA='51' OR CL.CODPROVINCIA='52' THEN 'CEUTA Y MELILLA'
                  WHEN CL.PAIS<>'1' THEN 'EXTRANJERO' -- No nacional (extranjero)
                  ELSE 'PENINSULA'
               END),
               U_CODDIST=CL.CODPROVINCIA,
               U_DISTRITO=CL.DISTRITO
               from cu xCU
               inner join cl on cl.no=xCU.u_nocl and cl.estab=xCU.u_estabcl

      endtext 

      text to m.msel2 textmerge noshow 

            UPDATE xCU SET xCU.U_SUP=SUPERVISOR.NOME
               from cu xCU
               inner join U_SUPCOO SUPERVISOR on XCU.U_NOSUPER=SUPERVISOR.CM

      endtext 


      if u_sqlexec(m.msel) and u_sqlexec(m.msel2)
         msg("Se actualizaron los datos de los centros .")
      else 
         msg("Error al actualizar los centros. Consulta el análisis interno.")
      endif

      regua(2)

   Endif

CATCH TO oe 
	DIMENSION laErrUserVars[2]
	laErrUserVars=""
	IF !EMPTY(oe.UserValue)
		laErrUserVars[1]=oe.Uservalue
		laErrUserVars[2]="Atención:"
	ELSE
		TEXT TO laErrUserVars[1] TEXTMERGE NOSHOW PRETEXT 7
			Erro:		<<oe.Message>>
			Linha:		<<oe.Lineno>>
			Programa:	<<oe.Procedure>>
			Conteudo:	<<oe.LineContents>>
		ENDTEXT
		laErrUserVars[2]="Error en la ejecución de "+oe.procedure
	ENDIF
	IF UPPER(oe.UserValue)="X"
		WAIT WINDOW "..." NOWAIT
	ELSE
		MESSAGEBOX(laErrUserVars[1],16,laErrUserVars[2])
	ENDIF
Finally
   * Cerrar la barra de progreso:
   regua(2)
ENDTRY

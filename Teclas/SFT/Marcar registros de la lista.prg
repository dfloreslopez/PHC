*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: F2
*Pantalla: SFT
*Tipo: Programa
*Última modificación/revisión: 25/10/2023
*Descripción: 
* Marcar registros de la tabla de facturas (FT).
* Hay un documento que explica el proceso al completo, tanto a nivel de usuario como técnico.
*****


TRY

   local mvar_Titulos, mvar_Campos, mvar_Tam, mvar_Consulta

   mvar_Titulos = "Seleccionar, Factura, Nombre, Fecha"
   mvar_Campos = "envia,Factura, nombre, fecha"
   mvar_Tam = "20,20, 60, 12"
   mvar_Consulta = "select CAST(0 AS BIT) as envia, FNO AS FACTURA, nome as Nombre, fdata as Fecha, ftstamp from FT WHERE FTSTAMP IN (##mvar_Stamp##)"

   user_dfMarcado(mvar_Titulos, mvar_Campos, mvar_Tam, mvar_Consulta, "FT")

CATCH TO oe 
	DIMENSION laErrUserVars[2]
	laErrUserVars=""
	IF !EMPTY(oe.UserValue)
		laErrUserVars[1]=oe.Uservalue
		laErrUserVars[2]="Atenção:"
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
	If Used(lcCur)
		fecha(lcCur)
	EndIf
	Select (lnAlias)
ENDTRY

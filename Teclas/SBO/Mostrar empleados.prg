*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: CTRL+F8
*Pantalla: SBO
*Tipo: Programa
*Última modificación/revisión: 19/10/2023
*Descripción: 
* Muestra una pantalla con los empleados que han realizado visitas en un parte de trabajo.
*****

TRY
   LOCAL lnALias,lcSql,lcWord,lcCur, cWhere
   STORE "" TO lcSql,lcWord,lcCur
   STORE 0 TO lnAlias
   lnAlias = SELECT(0)
   lcCur = "Y"+Sys(3)
   If bo.ndos<>116
      Throw "Esta tecla solo funciona si estamos en partes de trabajo."
   Endif


   If Reccount("bo")>0
      cWhere = "BOSTAMP='"+BO.BOSTAMP+"'"
   ELSE
      cWhere = '(1=1)'
   Endif
   TEXT TO lcSql NOSHOW TEXTMERGE PRETEXT 7
      Select PARTE,CODIGO,DNI,NOMBRE, convert(nvarchar, FECHA, 103) as FECHA, HORADESDE, HORAHASTA, HDI, HNO, HFE, TIPO FROM U_WOEMPLOYEE
      WHERE <<cWhere>>
      ORDER BY ORDEN
   ENDTEXT
   * MSG(lcSql)
   u_sqlexec(lcSql,lcCur)
   If Reccount(lcCur)=0
      fecha(lcCur)
      Throw "No hay empleados en el parte de la pantalla."
   ENDIF
   DECLARE list_cam[11],list_tam[11],list_pic[11],list_tit[11],list_ronly[11]
   list_cam[1] = lcCur+".PARTE"
   list_tam[1] = 100
   list_pic[1] = ""
   list_tit[1] = "PARTE"
   list_ronly[1] = .T.
   list_cam[2] = lcCur+".CODIGO"
   list_tam[2] = 100
   list_pic[2] = ""
   list_tit[2] = "Código"
   list_ronly[2] = .T.
   list_cam[3] = lcCur+".DNI"
   list_tam[3] = 100
   list_pic[3] = ""
   list_tit[3] = "DNI"
   list_ronly[3] = .T.
   list_cam[4] = lcCur+".NOMBRE"
   list_tam[4] = 100
   list_pic[4] = ""
   list_tit[4] = "NOMBRE"
   list_ronly[4] = .T.
   list_cam[5] = lcCur+".FECHA"
   list_tam[5] = 100
   list_pic[5] = ""
   list_tit[5] = "FECHA"
   list_ronly[5] = .T.
   list_cam[6] = lcCur+".HORADESDE"
   list_tam[6] = 100
   list_pic[6] = ""
   list_tit[6] = "HORA DESDE"
   list_ronly[6] = .T.
   list_cam[7] = lcCur+".HORAHASTA"
   list_tam[7] = 100
   list_pic[7] = ""
   list_tit[7] = "HORA HASTA"
   list_ronly[7] = .T.
   list_cam[8] = lcCur+".HDI"
   list_tam[8] = 100
   list_pic[8] = ""
   list_tit[8] = "HORAS DIURNO"
   list_ronly[8] = .T.
   list_cam[9] = lcCur+".HNO"
   list_tam[9] = 100
   list_pic[9] = ""
   list_tit[9] = "HORAS NOCTURNO"
   list_ronly[9] = .T.
   list_cam[10] = lcCur+".HFE"
   list_tam[10] = 100
   list_pic[10] = ""
   list_tit[10] = "HORAS FESTIVO"
   list_ronly[10] = .T.
   list_cam[11] = lcCur+".TIPO"
   list_tam[11] = 100
   list_pic[11] = ""
   list_tit[11] = "TIPO EMPLEADO"
   list_ronly[11] = .T.


   m.escolheu = .F.
   BROWLIST("Visor de empleados del parte",lcCur,Sys(2015),.F.,.F.,.F.,.F.,.T.,"",.T.,.F.)
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
		laErrUserVars[2]="Erro na Execução de "+oe.procedure
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

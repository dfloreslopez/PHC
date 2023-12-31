*****
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


TRY
   LOCAL lnALias,lcSql,lcWord,lcCur
   STORE "" TO lcSql,lcWord,lcCur
   STORE 0 TO lnAlias
   lnAlias = SELECT(0)
   lcCur = "Y"+Sys(3)
   If Reccount("ft")=0
      Throw "Esta opción solo funciona con un documento en pantalla."
   Endif
   If Reccount("fi")=0
      Throw "Esta opción solo funciona si el documento tiene al menos una línea."
   EndIf
   lcWord = GETNOME("Búsqueda en código y nombre de centros de coste","","Introduzca la palabra a buscar","",1)
   If Empty(lcWord)
      Throw "Debe introducir un texto para buscar."
   EndIf
   TEXT TO lcSql NOSHOW TEXTMERGE PRETEXT 7
      Select descricao,cct FROM cu (nolock)
      WHERE (descricao LIKE '%<<Alltrim(lcWord)>>%' or cct  LIKE '%<<Alltrim(lcWord)>>%'   )
      AND (u_fimdef=CONVERT(Datetime,'19000101',112) OR u_fimdef>?ft.fdata) 
      ORDER BY descricao
   ENDTEXT
   u_sqlexec(lcSql,lcCur)
   If Reccount(lcCur)=0
      fecha(lcCur)
      Throw "No se han encontrado centros de coste conteniendo el texto '"+Alltrim(lcWord)+"'."
   ENDIF
   DECLARE list_cam[2],list_tam[2],list_pic[2],list_tit[2],list_ronly[2]
   list_cam[1] = lcCur+".descricao"
   list_tam[1] = 300
   list_pic[1] = ""
   list_tit[1] = "Descrição"
   list_ronly[1] = .T.
   list_cam[2] = lcCur+".cct"
   list_tam[2] = 100
   list_pic[2] = ""
   list_tit[2] = "Código"
   list_ronly[2] = .T.
   m.escolheu = .F.
   BROWLIST("Seleccione centro de coste",lcCur,Sys(2015),.F.,.F.,.F.,.F.,.T.,"",.T.,.F.)
   If m.escolheu
      If !MEXENDO("FT",.T.)
         SFT.ShowSave()
      EndIf
      Select fi
      Replace fi.ficcusto	WITH &lcCur..cct IN fi
      
      *** Colocar focus ***
      FOR EACH mf IN _SCREEN.FORMS 
         IF ALLTRIM(UPPER(mf.NAME))== 'SFT'
            FOR EACH obj in mf.Pageframe1.page1.cont1.grid1.objects
               IF alltrim(upper(obj.controlsource)) =="FI.FICCUSTO"
                  obj.Setfocus()
                  EXIT
               ENDIF
            ENDFOR
            EXIT
         ENDIF
      ENDFOR
   ENDIF
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

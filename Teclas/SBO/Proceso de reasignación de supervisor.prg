TRY

   LOCAL lnALias,lcSql,lcWord,lcCur
   local mvar_Stamp, mvar_Lista, msql_codigo, lenCampos, my_i, mvar_respuesta
   local mvar_Titulos, mvar_Campos, mvar_Tam, mvar_Consulta, mvar_supervisor

   STORE "" TO lcSql,lcWord,lcCur
   STORE 0 TO lnAlias
   lnAlias = SELECT(0)
   lcCur = "Y"+Sys(3)

   Select ts
   mvar_ndos=ts.ndos
   If !Inlist(ts.ndos,16,116)
      Throw "Esta opción solo funciona para las pantallas de servicios y partes."
   Endif

   If Reccount("BO")=0
      Throw "Debe tener registros en la lista de la pantalla para ejecutar está opción."
   Endif

   mvar_Stamp=""

   mvar_Tabla="BO"
   mvar_Lista=mvar_Tabla+"LIST"

   * Control de que tenemos registros en la lista de la pantalla.
   select &mvar_Lista
   If Reccount(mvar_Lista)=0
      Throw "Debe haber registros en la lista (a través de un filtro, por ejemplo) para poder ejecutar esta opción."
   Endif

   mvar_supervisor = GETNOME("Código de supervisor a asignar masivamente","","Introduzca el código de supervisor a asignar","",1)
   If Empty(mvar_supervisor)
      Throw "Debe introducir un código de supervisor para asignar."
   EndIf

   msql_codigo = "select cmdesc from u_supcoo where cct='"+mvar_supervisor+"'"
   If !u_sqlexec(msql_codigo,'curSupervisor_df')
      Throw "No se ha podido coger los datos del supervisor."+Chr(13)+"Consulta: "+msql_codigo
   Endif

   If Used('curSupervisor_df') and Reccount('curSupervisor_df')=0
      Throw "No se encuentra el supervisor introducido: "+mvar_supervisor+". No se puede hacer ningún cambio."
   Endif

   mvar_respuesta=.F.
   mvar_respuesta=pergunta("Hay "+aStr(Reccount(mvar_Lista))+" registros filtrados, es posible que el proceso tarde mucho en mostrar la lista de registros a modificar."+Chr(13)+;
      "El supervisor a asignar será: "+mvar_supervisor+", "+curSupervisor_df.cmdesc+"."+Chr(13)+Chr(13)+;
      "¿Desea continuar?",2,"",.T.)
   If NOT mvar_respuesta
      Throw "Proceso cancelado por el usuario."
   Endif

   * Nos creamos una cadena con todos los stamp de los registros de la lista.
   mvar_StampField = mvar_Lista+"."+mvar_Tabla+"STAMP"
   select &mvar_Lista
   scan
      mvar_Stamp=mvar_Stamp+"'"+(Eval(mvar_StampField))+"',"
   Endscan
   * Quitamos la coma final.
   mvar_Stamp=SubStr(mvar_Stamp, 1, Len(mvar_Stamp)-1)

   msql_codigo = "select CAST(0 AS BIT) as envia, SERIE AS codigo, S.CMDESC AS Nombresupervisor, OBRANO, "+mvar_Tabla+"STAMP as "+mvar_Tabla+"STAMP from "+mvar_Tabla+" LEFT join U_SUPCOO S ON SERIE=S.CCT WHERE "+mvar_Tabla+"STAMP IN ("+mvar_Stamp+")"
   If !u_sqlexec(msql_codigo,'curCambioMasivo_df')
      Throw "No se ha podido coger los registros de la lista."+Chr(13)+"Consulta: "+msql_codigo
   Endif

   lenCampos = 4
   mvar_Titulos = "Seleccionar, Supervisor, Nombre, Nº documento"
   mvar_Campos = "envia, codigo, NombreSupervisor, OBRANO"
   mvar_Tam = "20,20,60,20"
   split(mvar_Titulos, "df_aTitulos", ",")
   split(mvar_Campos, "df_aCampos", ",")
   split(mvar_Tam, "df_aTam", ",")   

   Declare list_tit(lenCampos), list_cam(lenCampos), list_pic(lenCampos), list_ronly(lenCampos), list_tam(lenCampos)
   for my_i=1 to lenCampos
         
         list_tit(my_i)=df_aTitulos(my_i)
         list_cam(my_i)='curCambioMasivo_df.'+df_aCampos(my_i)
         * msg(list_cam(my_i))
         list_ronly(my_i)=.F.
         list_pic(my_i)="LOGIC"
         If my_i>1
            list_ronly(my_i)=.T.
            list_pic(my_i)=""
         Endif
         list_tam(my_i)=Val(df_aTam(my_i))

   endfor

   m.escolheu = .F.

   If used("curCambioMasivo_df") and RecCount("curCambioMasivo_df")>0
      browlist("Modificación de supervisor en documentos internos.", 'curCambioMasivo_df',"cambioMasivo", .T., .F., .F., .T., .F., "", .F., .T.)
   Endif
   If NOT m.escolheu
      Throw "No se ha seleccionado ningún registro a cambiar."
   Endif

   mvar_Stamp = ""
   Select curCambioMasivo_df
   Scan
      If curCambioMasivo_df.envia
         mvar_Stamp = mvar_Stamp + "'"+Eval("curCambioMasivo_df."+mvar_Tabla+"stamp")+"',"
      Endif
   Endscan

   if Empty(mvar_Stamp)
      Throw "No se han seleccionado registros. No se modifica nada."
   Endif

   mvar_Stamp = SubStr(mvar_Stamp, 1, Len(mvar_Stamp)-1)
   
   * Necesitamos actualizar campos:
      * SERIE: CENTRO DE COSTE DEL SUPERVISOR
   
   TEXT TO msql_codigo TEXTMERGE NOSHOW
      update doc
      set 
         doc.SERIE='<<mvar_supervisor>>'
      from 
         <<mvar_Tabla>> doc
      where 
         doc.<<mvar_tabla + "stamp">> in (<<mvar_Stamp>>)
   ENDTEXT

   * msg(msql_codigo)
   
   If !u_sqlexec(msql_codigo,'curCambioMasivo_df')
      Throw "No se ha podido cambiar masivamente los supervisores. Consulta: "+msql_codigo
   Endif

   msg("Registros modificados correctamente. Consulta: "+Chr(13)+msql_codigo)

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

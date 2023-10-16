local lnCount

* Control del documento interno en el que nos encontramos (esta opción es solo para partes de trabajo).
Select ts
mvar_ndos_origem=ts.ndos
If NOT Inlist(mvar_ndos_origem,116)
   Msg("Esta opción solo se puede ejecutar desde 'Partes de trabajo'.")
   return
Endif

mvar_Stamp=""

* Control de que tenemos registros en la lista de la pantalla.
select bolist
If Reccount('bolist')=0
   Msg("Debe haber registros en la lista (a través de un filtro, por ejemplo) para poder ejecutar esta opción.")
   return
Endif

lnCount = 0
* Nos creamos una cadena con todos los stamp de los registros de la lista.
select bolist
scan
	mvar_Stamp=mvar_Stamp+"'"+BOLIST.BOSTAMP+"',"
   lnCount = lnCount +1
Endscan

mvar_respuesta=.F.
mvar_respuesta=pergunta("Esta opción copiará los pdf de los partes de trabajo finalizados, que se encuentren en la lista de registros, a una carpeta que seleccione el usuario."+Chr(13)+;
   "Hay "+aStr(lnCount)+" partes en la lista."+Chr(13)+Chr(13)+"¿Desea continuar?",2,"Copia de pdf de partes finalizados a una carpeta",.T.)
If NOT mvar_respuesta
   return
Endif

* Quitamos la coma final.
mvar_Stamp=SubStr(mvar_Stamp, 1, Len(mvar_Stamp)-1)

* Y cogemos todos los números de parte.
TEXT TO msql_codigo TEXTMERGE NOSHOW
   select cast(1 as bit) as Envia, OBRANO as parte, no, nome, dataobra, dtclose from bo WHERE BOSTAMP IN (<<mvar_Stamp>>)
ENDTEXT

If !u_sqlexec(msql_codigo,'crPartes')
	msg("No se ha podido coger los números de parte para guardarlos."+Chr(13)+"Consulta: "+msql_codigo)
   RETURN 
Endif

* Vamos a mostrar una lista para seleccionar de qué partes queremos copiar los pdf:
=CursorSetProp('Buffering',5,'crPartes' )

Declare list_tit(6), list_cam(6), list_pic(6), list_ronly(6), list_tam(6), list_combo(6), list_valid(6), list_rot(6)

list_tit(1)="Copiar PDF"
list_cam(1)="crPartes.envia"
list_ronly(1)=.F.
list_pic(1)="LOGIC"
list_tam(1)=8*10
list_valid(1)=""
list_rot(1)=""

list_tit(2)="Nº parte"
list_cam(2)="crPartes.parte"
list_ronly(2)=.T.
list_pic(2)=""
list_tam(2)=8*10
list_valid(2)=""
list_rot(2)=""

list_tit(3)="Nº cliente"
list_cam(3)="crPartes.no"
list_ronly(3)=.T.
list_pic(3)="999999999"
list_tam(3)=8*10
list_valid(3)=""
list_rot(3)=""

list_tit(4)="Nombre"
list_cam(4)="crPartes.nome"
list_ronly(4)=.T.
list_pic(4)=""
list_tam(4)=8*65
list_valid(4)=""
list_rot(4)=""

list_tit(5)="Fecha de parte"
list_cam(5)="crPartes.dataobra"
list_ronly(5)=.T.
list_pic(5)=""
list_tam(5)=8*20
list_valid(5)=""
list_rot(5)=""

list_tit(6)="Fecha de fin"
list_cam(6)="crPartes.dtclose"
list_ronly(6)=.T.
list_pic(6)=""
list_tam(6)=8*30
list_valid(6)=""
list_rot(6)=""

m.escolheu = .F.

browlist("Copia de pdf de partes finalizados a una carpeta",'crPartes',"meuteste", .T., .F., .F., .T., .F., "", .F., .T.)

If !m.escolheu
   return
Endif

lc_RutaDestino =Getdir("G:\","Elija un directorio donde desea guardar los partes","Seleccione")
If lc_RutaDestino==""
   return 
Endif
local objHTTP, ofileSYS

* Creamos objetos para manejo de unidad de red y gestión de archivos:
oNetwork = CreateObject("WScript.Network")
ofileSYS = CreateObject("Scripting.FileSystemObject")
If !(ofileSYS.DriveExists("X")) Then 
	oNetwork.MapNetworkDrive("X:", "\\10.2.177.13\docunet", .f., "1net\phcpartes", "serint2023")
EndIf
lcAction   = "open"

nCopiados = 0
* Y copiamos los partes existentes.
regua(0,RecCount('crPartes'), "Copia de pdf de partes finalizados.")
Select crPartes
Scan

   regua[1,nCopiados,"Parte " + astr(crPartes.PARTE)]
	If crPartes.envia
      * Ruta y nombre del archivo:
      lcFileName = "X:\Documento\22.-OPERATIVA\PARTES\Partes finalizados\" + astr(crPartes.PARTE) + ".pdf"
      If ofileSYS.FileExists(lcFileName)
         * Copia al destino oportuno:
         ofileSYS.CopyFile(lcFileName, lc_RutaDestino+ astr(crPartes.PARTE) + ".pdf")
         If ofileSYS.FileExists(lc_RutaDestino+ astr(crPartes.PARTE) + ".pdf")
            nCopiados=nCopiados+1
         Endif
      Endif
   Endif
   
Endscan

regua(2)

Msg(aStr(nCopiados) + " partes se copiaron correctamente a: "+lc_RutaDestino)

*****
* TECLA DE USUARIO
*Autor: Darío Flores
*Tecla: F10
*Pantalla: SBO
*Tipo: Programa
*Última modificación/revisión: 23/10/2023
*Descripción: 
* Asigna el centro de coste de la cabecera a las líneas que no tengan centro de coste asignado.
*****

mvar_crlf = Chr(10) + Chr(13)

If Empty(bo.ccusto) Then
   Msg("No hay centro de coste asignado a la cabecera del documento.")
   return
Endif



If sbo.editing Or sbo.adding then

   mvar_respuesta=pergunta("Este proceso asignará el centro de coste de la cabecera ("+bo.ccusto+")"+mvar_crlf+;
      " a las líneas que no tengan centro de coste."+mvar_crlf+mvar_crlf+;
      "¿Desea continuar?",2,"",.T.)
   If NOT mvar_respuesta
      Msg("Proceso cancelado por el usuario.")
      return
   Endif

	Select bi
	Scan
		If Empty(bi.ccusto) Then
			Replace bi.ccusto With bo.ccusto
		Endif
	Endscan
else
	Msg("No se puede actualizar las líneas es necesario que la pantalla esté en modo de edición.")
Endif

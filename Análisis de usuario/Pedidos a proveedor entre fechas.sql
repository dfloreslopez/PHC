
/*
   Grupo: Control Gestión
   Descripción: Solo tiene la consulta, no hace nada más ni tiene parámetros y solo saca centros activos.
   
   Variables:
      - 1: Tipo D; Nombre "Fecha Pedido Inicial"
      - 2: Tipo D; Nombre "Fecha Pedido Final"
      - 3: Tipo C; Nombre "Cliente Inicial"
      - 4: Tipo C; Nombre "Cliente final"
      - 5: Tipo D; Nombre "Fecha envío Proveedor Inicial"
      - 6: Tipo D; Nombre "Fecha envío Proveedor Final"
      
   
*/


select 
   isnull(convert(varchar(16),bo.obrano),'') as 'Pedido provedor'
   ,bo.ccusto as 'Centro de coste'
   ,bo.u_descrcc as 'Nombre proveedor'
   ,convert(varchar(10), bo.dataobra, 103) as 'Fecha pedido Proveedor'
   ,bi.ref as Referencia
   ,bi.design as Descripción
   ,bi.epcusto as Precio
   ,bi.qtt as Cantidad
   ,bi.epcusto*bi.qtt as 'Total coste'
   ,bi.familia as 'Código familia'
   ,stfami.nome as Familia
   ,case when box.logi8=1
   then 'Si'
   else 'No'
   end as Facturable
   ,case when box.logi5=1
   then 'Ordinaria'
   else 'Extraordinaria'
   end as 'Tipo reposicion'
   ,convert(varchar(10), bo.u_datarevp, 103) as 'Fecha envío proveedor'
   ,cl.localentrega as 'Agrupación'
from 
   bo (nolock)
join 
   bi (nolock) on bo.bostamp=bi.bostamp
join 
   stfami (nolock) on bi.familia=stfami.ref
left join 
   bi bix (nolock) on bix.oobistamp=bi.bistamp
left join 
   bo box (nolock) on bix.bostamp=box.bostamp
join
   cu on cu.cct=bo.ccusto
join 
   cl on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
where 
   bo.dataobra between #1# and #2#
   and bo.ccusto between #3# and #4#
   and bo.U_DATAREVP between #5# and #6#
   and bo.ndos=2
   and bi.obrano>0
order by
	bo.obrano
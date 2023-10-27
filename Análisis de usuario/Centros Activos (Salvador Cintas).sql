/*
   Grupo: Control Gestión
   Descripción: Solo tiene la consulta, no hace nada más ni tiene parámetros y solo saca centros activos.
*/


select 
   Empresa='SILNETPHCPROD'
   ,CIF=isnull((select ncont from  SILNETPHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Agrupación'=isnull((select CL.LOCALENTREGA from SILNETPHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Centro de Coste'=cu.cct
   ,'Nombre Centro de Coste'=cu.descricao
   ,'DT'=       cu.u_coord
   ,'Supervisor'=cu.u_sup
   ,'Publico/Privado'=CU.U_INSIGNIA          
   ,'Calle'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada),'')
   ,'Ciudad'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL),'')
   ,'Provincia'=isnull(iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO),'')
   ,'Código Postal'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST),'')
   ,'Codigo DT'=CU.U_CCCOORD
   ,'Codigo supervisor'=CU.U_CCSUPERV
from 
   SILNETPHCPROD..cu cu 
left join
   SILNETPHCPROD..cl cl on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
left join
   SILNETPHCPROD..cl2 cl2 on cl2.cl2stamp=cl.clstamp
where 
   cu.inactivo=0
   
union   
   
select 
   Empresa='CEE_CCVV_PHCPROD'
   ,CIF=isnull((select ncont from  CEE_CCVV_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Agrupación'=isnull((select CL.LOCALENTREGA from CEE_CCVV_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Centro de Coste'=cu.cct
   ,'Nombre Centro de Coste'=cu.descricao
   ,'DT'=       cu.u_coord
   ,'Supervisor'=cu.u_sup
   ,'Publico/Privado'=CU.U_INSIGNIA          
   ,'Calle'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada),'')
   ,'Ciudad'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL),'')
   ,'Provincia'=isnull(iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO),'')
   ,'Código Postal'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST),'')
   ,'Codigo DT'=CU.U_CCCOORD
   ,'Codigo supervisor'=CU.U_CCSUPERV
from 
   CEE_CCVV_PHCPROD..cu cu 
left join
   CEE_CCVV_PHCPROD..cl cl on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
left join
   CEE_CCVV_PHCPROD..cl2 cl2 on cl2.cl2stamp=cl.clstamp
where 
   cu.inactivo=0

union

select 
   Empresa='CEE_MADRID_PHCPROD'
   ,CIF=isnull((select ncont from  CEE_MADRID_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Agrupación'=isnull((select CL.LOCALENTREGA from CEE_MADRID_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Centro de Coste'=cu.cct
   ,'Nombre Centro de Coste'=cu.descricao
   ,'DT'=       cu.u_coord
   ,'Supervisor'=cu.u_sup
   ,'Publico/Privado'=CU.U_INSIGNIA          
   ,'Calle'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada),'')
   ,'Ciudad'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL),'')
   ,'Provincia'=isnull(iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO),'')
   ,'Código Postal'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST),'')
   ,'Codigo DT'=CU.U_CCCOORD
   ,'Codigo supervisor'=CU.U_CCSUPERV
from 
   CEE_MADRID_PHCPROD..cu cu 
left join
   CEE_MADRID_PHCPROD..cl cl on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
left join
   CEE_MADRID_PHCPROD..cl2 cl2 on cl2.cl2stamp=cl.clstamp
where 
   cu.inactivo=0

union

select 
   Empresa='CEE_MURCIA_PHCPROD'
   ,CIF=isnull((select ncont from  CEE_MURCIA_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Agrupación'=isnull((select CL.LOCALENTREGA from CEE_MURCIA_PHCPROD..cl cl (nolock) where cl.estab=0 and cl.no=cu.u_nocl ),'')
   ,'Centro de Coste'=cu.cct
   ,'Nombre Centro de Coste'=cu.descricao
   ,'DT'=       cu.u_coord
   ,'Supervisor'=cu.u_sup
   ,'Publico/Privado'=CU.U_INSIGNIA          
   ,'Calle'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_moralt<>'', cl2.u_moralt, cl.morada),'')
   ,'Ciudad'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_localalt<>'', cl2.u_localalt, CL.LOCAL),'')
   ,'Provincia'=isnull(iif(CL2.U_USAMOALT=1 and cl2.U_DEPAALT<>'', cl2.U_DEPAALT, CL.DISTRITO),'')
   ,'Código Postal'=isnull(iif(CL2.U_USAMOALT=1 and cl2.u_codpalt<>'', cl2.u_codpalt, CL.CODPOST),'')
   ,'Codigo DT'=CU.U_CCCOORD
   ,'Codigo supervisor'=CU.U_CCSUPERV
from 
   CEE_MURCIA_PHCPROD..cu cu 
left join
   CEE_MURCIA_PHCPROD..cl cl on cl.no=cu.u_nocl and cl.estab=cu.u_estabcl
left join
   CEE_MURCIA_PHCPROD..cl2 cl2 on cl2.cl2stamp=cl.clstamp
where 
   cu.inactivo=0

/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_field_operation
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura DEVICE (medidores)
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Tipo Corrida>: 0=Normal, 1=Reducida
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_field_operation.h";

/* Variables Globales */
int   giTipoCorrida;

FILE	*pFileMedidorUnx;

char	sArchMedidorUnx[100];
char	sArchMedidorAux[100];
char	sArchMedidorDos[100];
char	sSoloArchivoMedidor[100];

char	sArchLog[100];
char	sPathSalida[100];
char	FechaGeneracion[9];	
char	MsgControl[100];
$char	fecha[9];
long	lCorrelativo;

long	cantProcesada;
long 	cantPreexistente;
long	iContaLog;

char     gsDesdeFmt[9];
char     gsHastaFmt[9];

/* Variables Globales Host */
$ClsCorte	regCorte;
$ClsExtent  regExt;
$char       gsFechaDesde[20];
$char       gsFechaHasta[20];

char	sMensMail[1024];	

$WHENEVER ERROR CALL SqlException;

void main( int argc, char **argv ) 
{
$char 	nombreBase[20];
time_t 	hora;
FILE	*fp;
int		iFlagMigra=0;
int 	iFlagEmpla=0;
$long lNroCliente;
int   iIndex;
long  lCantCorte=0;
long  lCantRepo=0;
long  lCantExtent=0;

	if(! AnalizarParametros(argc, argv)){
		exit(0);
	}
	
   setlocale(LC_ALL, "en_US.UTF-8");
   
	hora = time(&hora);
	
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));
	
	strcpy(nombreBase, argv[1]);
	
	$DATABASE :nombreBase;	
	
	$SET LOCK MODE TO WAIT 600;
	$SET ISOLATION TO DIRTY READ;
	
   CreaPrepare();

	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
	if(!AbreArchivos()){
		exit(1);	
	}

	cantProcesada=0;
	cantPreexistente=0;
	iContaLog=0;
	
   fp=pFileMedidorUnx;
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/
/*
   $OPEN curClientes;

   while(LeoCliente(&lNroCliente)){
*/   
      /* Cursor de Cortes */
   	/*$OPEN curCortes USING :lNroCliente;*/
      if(giTipoCorrida==3){
         $OPEN curCortes USING :gsFechaDesde, :gsFechaHasta;
      }else{
         $OPEN curCortes;
      }
   
   	while(LeoCortes(&regCorte)){
   		if (!GenerarPlano(fp, regCorte, regExt, "C", 0)){
            printf("Fallo GenearPlano\n");
   			exit(1);	
   		}
         lCantCorte++;         
   		if(strcmp(regCorte.fecha_reposicion, "") != 0){
      		if (!GenerarPlano(fp, regCorte, regExt, "R", 0)){
               printf("Fallo GenearPlano\n");
      			exit(1);	
      		}
            lCantRepo++;
         }			
   	}
   	$CLOSE curCortes;
      
      iIndex=1;
      /* Cursor de Extension */
      /*$OPEN curExtent USING :lNroCliente;*/
      if(giTipoCorrida==3){
         $OPEN curExtent USING :gsFechaDesde, :gsFechaHasta;
      }else{
         $OPEN curExtent;
      }
            
   	while(LeoExtent(&regExt)){
   		if (!GenerarPlano(fp, regCorte, regExt, "E", iIndex)){
            printf("Fallo GenearPlano\n");
   			exit(1);	
   		}
         iIndex++;
         lCantExtent++;
      }
            
      $CLOSE curExtent;
/*      
      cantProcesada++;
   }
   			
   $CLOSE curClientes;      
*/   
	CerrarArchivos();

	FormateaArchivos();

	$CLOSE DATABASE;

	$DISCONNECT CURRENT;

	/* ********************************************
				FIN AREA DE PROCESO
	********************************************* */

/*	
	if(! EnviarMail(sArchResumenDos, sArchControlDos)){
		printf("Error al enviar mail con lista de respaldo.\n");
		printf("El mismo se pueden extraer manualmente en..\n");
		printf("     [%s]\n", sArchResumenDos);
	}else{
		sprintf(sCommand, "rm -f %s", sArchResumenDos);
		iRcv=system(sCommand);			
	}
*/
	printf("==============================================\n");
	printf("FIELD OPERATION\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
   printf("Cortes Procesados :      %ld \n",lCantCorte);
   printf("Repos Procesados :       %ld \n",lCantRepo);
   printf("Extents Procesados :     %ld \n",lCantExtent);
	printf("==============================================\n");
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));						

	hora = time(&hora);
	printf("\nHora de finalizacion del proceso : %s\n", ctime(&hora));

	if(iContaLog>0){
		printf("Existen registros en el archivo de log.\nFavor de revisar.\n");	
	}
	printf("Fin del proceso OK\n");	

	exit(0);
}	

short AnalizarParametros(argc, argv)
int		argc;
char	* argv[];
{
   memset(gsFechaDesde, '\0', sizeof(gsFechaDesde));
   memset(gsFechaHasta, '\0', sizeof(gsFechaHasta));

   memset(gsDesdeFmt, '\0', sizeof(gsDesdeFmt));
   memset(gsHastaFmt, '\0', sizeof(gsHastaFmt));

	if(argc < 3 || argc >5 ){
		MensajeParametros();
		return 0;
	}
	
   giTipoCorrida=atoi(argv[2]);
   
   if(argc == 5){
      giTipoCorrida=3;
      strcpy(gsFechaDesde, argv[3]);
      strcat(gsFechaDesde, " 00:00");
      strcpy(gsFechaHasta, argv[4]);
      strcat(gsFechaHasta, " 23:59");
      
      sprintf(gsDesdeFmt, "%c%c%c%c%c%c%c%c", gsFechaDesde[0],gsFechaDesde[1],gsFechaDesde[2],gsFechaDesde[3],
            gsFechaDesde[5],gsFechaDesde[6],gsFechaDesde[8],gsFechaDesde[9]);
            
      sprintf(gsHastaFmt, "%c%c%c%c%c%c%c%c", gsFechaHasta[0],gsFechaHasta[1],gsFechaHasta[2],gsFechaHasta[3],
            gsFechaHasta[5],gsFechaHasta[6],gsFechaHasta[8],gsFechaHasta[9]);
      
   }
	
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
		printf("	<Tipo Corrida> 0=Normal, 1=Reducida, 3=Delta.\n");
      printf("	<Fecha Desde (Opcional)> aaaa-mm-dd.\n");
      printf("	<Fecha Hasta (Opcional)> aaaa-mm-dd.\n");
      
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   
   memset(sTitulos, '\0', sizeof(sTitulos));
	
	memset(sArchMedidorUnx,'\0',sizeof(sArchMedidorUnx));
	memset(sArchMedidorAux,'\0',sizeof(sArchMedidorAux));
   memset(sArchMedidorDos,'\0',sizeof(sArchMedidorDos));
	memset(sSoloArchivoMedidor,'\0',sizeof(sSoloArchivoMedidor));
	memset(sFecha,'\0',sizeof(sFecha));

	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
	RutaArchivos( sPathSalida, "SALESF" );
   
	alltrim(sPathSalida,' ');

	sprintf( sArchMedidorUnx  , "%sT1FIELD_OPERATION.unx", sPathSalida );
   sprintf( sArchMedidorAux  , "%sT1FIELD_OPERATION.aux", sPathSalida );
   sprintf( sArchMedidorDos  , "%senel_care_fieldoperation_t1_%s_%s.csv", sPathSalida, gsFechaDesde, gsHastaFmt);

	strcpy( sSoloArchivoMedidor, "T1FIELD_OPERATION.unx");

	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
	if( !pFileMedidorUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
		return 0;
	}
	
   strcpy(sTitulos, "\"Tipo de registro\";");
   strcat(sTitulos, "\"Fecha actual\";");
   strcat(sTitulos, "\"Monto\";");
   strcat(sTitulos, "\"Description\";");      
   strcat(sTitulos, "\"Acción realizada\";");   
   strcat(sTitulos, "\"Rol ejecutor\";");
   strcat(sTitulos, "\"Evento\";");
   strcat(sTitulos, "\"Fecha evento\";");
   strcat(sTitulos, "\"External Id\";");
   strcat(sTitulos, "\"Situación encontrada\";");
   strcat(sTitulos, "\"Suministro\";");
   strcat(sTitulos, "\"Observaciones\";");
   strcat(sTitulos, "\"Motivo\";");
   strcat(sTitulos, "\"Estado\";");
   strcat(sTitulos, "\"Dias\"");
   strcat(sTitulos, "\n");                           
   
   fprintf(pFileMedidorUnx, sTitulos);
      
	return 1;	
}

void CerrarArchivos(void)
{
	fclose(pFileMedidorUnx);

}

void FormateaArchivos(void){
char	sCommand[1000];
int	iRcv, i;
$char	sPathCp[100];
$char sClave[7];
	
	memset(sCommand, '\0', sizeof(sCommand));
	memset(sPathCp, '\0', sizeof(sPathCp));
   strcpy(sClave, "SALEFC");
   	
	$EXECUTE selRutaPlanos INTO :sPathCp using :sClave;

   if ( SQLCODE != 0 ){
     printf("ERROR.\nSe produjo un error al tratar de recuperar el path destino del archivo.\n");
     exit(1);
   }

   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchMedidorUnx, sArchMedidorAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchMedidorAux, sArchMedidorDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchMedidorDos);
	iRcv=system(sCommand);

	
	sprintf(sCommand, "cp %s %s", sArchMedidorDos, sPathCp);
	iRcv=system(sCommand);
  
   sprintf(sCommand, "rm %s", sArchMedidorUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchMedidorAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchMedidorDos);
   iRcv=system(sCommand);
	
}

void CreaPrepare(void){
$char sql[10000];
$char sAux[1000];

	memset(sql, '\0', sizeof(sql));
	memset(sAux, '\0', sizeof(sAux));

	/******** Fecha Actual Formateada ****************/
	strcpy(sql, "SELECT TO_CHAR(TODAY, '%Y%m%d') FROM dual ");
	
	$PREPARE selFechaActualFmt FROM $sql;

	/******** Fecha Actual  ****************/
	strcpy(sql, "SELECT TO_CHAR(TODAY, '%d/%m/%Y') FROM dual ");
	
	$PREPARE selFechaActual FROM $sql;	

	/******** Cursor CLIENTES  ****************/	
	strcpy(sql, "SELECT c.numero_cliente FROM cliente c ");
if(giTipoCorrida==1){	
   strcat(sql, ", migra_sf ma ");
}   
	
	strcat(sql, "WHERE c.estado_cliente = 0 ");
	strcat(sql, "AND c.tipo_sum != 5 ");
   /*strcat(sql, "AND c.tipo_sum NOT IN (5, 6) ");*/
	/*strcat(sql, "AND c.sector NOT IN (81, 82, 85, 88, 90) ");*/
	strcat(sql, "AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm ");
	strcat(sql, "WHERE cm.numero_cliente = c.numero_cliente ");
	strcat(sql, "AND cm.fecha_activacion < TODAY ");
	strcat(sql, "AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY)) ");	
if(giTipoCorrida==1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}   

	$PREPARE selClientes FROM $sql;
	
	$DECLARE curClientes CURSOR WITH HOLD FOR selClientes;

   /******** Cursor Cortes  ****************/
	strcpy(sql, "SELECT c.numero_cliente, ");
	strcat(sql, "TO_CHAR(c.fecha_corte, '%Y-%m-%dT%H:%M:00.000Z'), ");
	strcat(sql, "TO_CHAR(c.fecha_reposicion, '%Y-%m-%dT%H:%M:00.000Z'), ");
	strcat(sql, "c.saldo_exigible, ");
	strcat(sql, "c.motivo_corte, ");
	strcat(sql, "c.motivo_repo, ");
	strcat(sql, "c.accion_corte, ");
	strcat(sql, "c.accion_rehab, ");
	strcat(sql, "c.funcionario_corte, ");
	strcat(sql, "c.funcionario_repo, ");
	strcat(sql, "TO_CHAR(c.fecha_ini_evento, '%Y-%m-%dT%H:%M:00.000Z'), ");
	strcat(sql, "TO_CHAR(c.fecha_sol_repo, '%Y-%m-%dT%H:%M:00.000Z'), ");
	strcat(sql, "c.sit_encon, ");
	strcat(sql, "c.sit_rehab, ");
   strcat(sql, "t1.descripcion, ");
   strcat(sql, "c.corr_corte, ");
   strcat(sql, "c.corr_repo ");   
	strcat(sql, "FROM correp c, cliente l, tabla t1 ");
if(giTipoCorrida==1){
   strcat(sql, ", migra_sf ma ");
}   
	strcat(sql, "WHERE c.numero_cliente = l.numero_cliente ");
   if(giTipoCorrida==3){
      strcat(sql, "AND c.fecha_corte BETWEEN ? AND ? ");
   }else{
      strcat(sql, "AND c.fecha_corte >= TODAY-365 ");
   }
   strcat(sql, "AND l.estado_cliente = 0 ");
	strcat(sql, "AND t1.nomtabla = 'CORMOT' ");
	strcat(sql, "AND t1.sucursal = '0000' ");
	strcat(sql, "AND t1.codigo = c.motivo_corte ");
	strcat(sql, "AND t1.fecha_activacion <= TODAY ");
	strcat(sql, "AND (t1.fecha_desactivac IS NULL OR t1.fecha_desactivac > TODAY) ");   
if(giTipoCorrida==1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}   
	strcat(sql, "ORDER BY 2 ASC ");   
   
	$PREPARE selCortes FROM $sql;
	
	$DECLARE curCortes CURSOR WITH HOLD FOR selCortes;
   
   /******** Cursor Extensión Plazo  ****************/
	strcpy(sql, "SELECT c.numero_cliente, ");
	strcat(sql, "TO_CHAR(c.fecha_solicitud, '%Y-%m-%dT%H:%M:00.000Z'), ");
	strcat(sql, "c.cod_motivo, ");
   strcat(sql, "c.motivo, ");
	strcat(sql, "c.rol, ");
	strcat(sql, "CASE ");
	strcat(sql, "	WHEN c.fecha_anterior + c.dias > TODAY THEN 'Active' ");
	strcat(sql, "  ELSE 'Completed' ");
	strcat(sql, "END estado, ");
	strcat(sql, "c.dias ");
	strcat(sql, "FROM corplazo c, cliente l ");
if(giTipoCorrida==1){
   strcat(sql, ", migra_sf ma ");
}   
	strcat(sql, "WHERE c.numero_cliente = l.numero_cliente ");
   strcat(sql, "AND l.estado_cliente = 0 ");
   if(giTipoCorrida==3){
      strcat(sql, "AND c.fecha_solicitud BETWEEN ? AND ? ");
   }else{
      strcat(sql, "AND c.fecha_solicitud >= TODAY-365 ");
   }
if(giTipoCorrida==1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}   
   
	strcat(sql, "ORDER BY 2 ASC ");
   
	$PREPARE selExtent FROM $sql;
	
	$DECLARE curExtent CURSOR WITH HOLD FOR selExtent;

	/******** Select Path de Archivos ****************/
	strcpy(sql, "SELECT valor_alf ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'PATH' ");
	strcat(sql, "AND codigo = ? ");
	strcat(sql, "AND sucursal = '0000' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL ) ");

	$PREPARE selRutaPlanos FROM $sql;


}

void FechaGeneracionFormateada( Fecha )
char *Fecha;
{
	$char fmtFecha[9];
	
	memset(fmtFecha,'\0',sizeof(fmtFecha));
	
	$EXECUTE selFechaActualFmt INTO :fmtFecha;
	
	strcpy(Fecha, fmtFecha);
	
}

void RutaArchivos( ruta, clave )
$char ruta[100];
$char clave[7];
{

	$EXECUTE selRutaPlanos INTO :ruta using :clave;

    if ( SQLCODE != 0 ){
        printf("ERROR.\nSe produjo un error al tratar de recuperar el path destino del archivo.\n");
        exit(1);
    }
}

long getCorrelativo(sTipoArchivo)
$char		sTipoArchivo[11];
{
$long iValor=0;

	$EXECUTE selCorrelativo INTO :iValor using :sTipoArchivo;
	
    if ( SQLCODE != 0 ){
        printf("ERROR.\nSe produjo un error al tratar de recuperar el correlativo del archivo tipo %s.\n", sTipoArchivo);
        exit(1);
    }	
    
    return iValor;
}

short LeoCliente(lNroCliente)
$long *lNroCliente;
{
   $long nroCliente;
   
   $FETCH curClientes INTO :nroCliente;
   
    if ( SQLCODE != 0 ){
        return 0;
    }
   
   *lNroCliente = nroCliente;

   return 1;
}


short LeoCortes(reg)
$ClsCorte *reg;
{
	InicializaCorte(reg);

	$FETCH curCortes INTO
      :reg->numero_cliente,
      :reg->fecha_corte,
      :reg->fecha_reposicion,
      :reg->saldo_exigible,
      :reg->motivo_corte,
      :reg->motivo_repo,
      :reg->accion_corte,
      :reg->accion_rehab,
      :reg->funcionario_corte,
      :reg->funcionario_repo,
      :reg->fecha_ini_evento,
      :reg->fecha_sol_repo,
      :reg->sit_encon,
      :reg->sit_rehab,
      :reg->desc_motivo_corte,
      :reg->corr_corte,
      :reg->corr_repo;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Cortes !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

   alltrim(reg->fecha_corte, ' ');
   alltrim(reg->fecha_reposicion, ' ');
   alltrim(reg->fecha_ini_evento, ' ');
   alltrim(reg->fecha_sol_repo, ' ');
   alltrim(reg->funcionario_corte, ' ');
   alltrim(reg->funcionario_repo, ' ');
   alltrim(reg->desc_motivo_corte, ' ');
               
	return 1;	
}

void InicializaCorte(reg)
$ClsCorte	*reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   memset(reg->fecha_corte, '\0', sizeof(reg->fecha_corte));
   memset(reg->fecha_reposicion, '\0', sizeof(reg->fecha_reposicion));
   rsetnull(CDOUBLETYPE, (char *) &(reg->saldo_exigible));
   memset(reg->motivo_corte, '\0', sizeof(reg->motivo_corte));
   memset(reg->motivo_repo, '\0', sizeof(reg->motivo_repo));
   memset(reg->accion_corte, '\0', sizeof(reg->accion_corte));
   memset(reg->accion_rehab, '\0', sizeof(reg->accion_rehab));
   memset(reg->funcionario_corte, '\0', sizeof(reg->funcionario_corte));
   memset(reg->funcionario_repo, '\0', sizeof(reg->funcionario_repo));
   memset(reg->fecha_ini_evento, '\0', sizeof(reg->fecha_ini_evento));
   memset(reg->fecha_sol_repo, '\0', sizeof(reg->fecha_sol_repo));
   memset(reg->sit_encon, '\0', sizeof(reg->sit_encon));
   memset(reg->sit_rehab, '\0', sizeof(reg->sit_rehab));
   memset(reg->desc_motivo_corte, '\0', sizeof(reg->desc_motivo_corte));
   rsetnull(CINTTYPE, (char *) &(reg->corr_corte));
   rsetnull(CINTTYPE, (char *) &(reg->corr_repo));

}

void InicializaExtent(reg)
$ClsExtent	*reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   memset(reg->fecha_solicitud, '\0', sizeof(reg->fecha_solicitud));
   memset(reg->cod_motivo, '\0', sizeof(reg->cod_motivo));
   memset(reg->motivo, '\0', sizeof(reg->motivo));
   memset(reg->rol, '\0', sizeof(reg->rol));
   memset(reg->estado, '\0', sizeof(reg->estado));
   rsetnull(CINTTYPE, (char *) &(reg->dias));

}


short LeoExtent(reg)
$ClsExtent *reg;
{
   
   InicializaExtent(reg);
   
   $FETCH curExtent INTO
      :reg->numero_cliente,
      :reg->fecha_solicitud,
      :reg->cod_motivo,
      :reg->motivo,
      :reg->rol,
      :reg->estado,
      :reg->dias;
   
   if(SQLCODE != 0){
      return 0;
   }   
  
   alltrim(reg->motivo, ' ');
   alltrim(reg->rol, ' ');
   alltrim(reg->estado, ' ');
   
   return 1;
}

short GenerarPlano(fp, regCor, regEx, sTipo, index)
FILE 				*fp;
$ClsCorte		regCor;
$ClsExtent     regEx;
char           sTipo[2];
int            index;
{
	char	sLinea[1000];	

	memset(sLinea, '\0', sizeof(sLinea));

   switch(sTipo[0]){
      case 'C':
         /* Tipo de registro */
         strcpy(sLinea, "\"CUTOFF\";");
         /* Fecha actual */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.fecha_corte);
         /* Monto */
         sprintf(sLinea, "%s\"%.02f\";", sLinea, regCor.saldo_exigible);
         /* Description */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.desc_motivo_corte);
         /* Acción realizada */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.accion_corte);
         /* Rol ejecutor */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.funcionario_corte);
         /* Evento */
         strcat(sLinea, "\"\";");
         /* Fecha evento */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.fecha_ini_evento);
         /* External Id */
         sprintf(sLinea, "%s\"%ld%04dCORTFOPARG\";", sLinea, regCor.numero_cliente, regCor.corr_corte);
         /* Situación encontrada */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.sit_encon);
         /* Suministro */
         sprintf(sLinea, "%s\"%ldAR\";", sLinea, regCor.numero_cliente);
         /* Observaciones */
         strcat(sLinea, "\"\";");
         /* Motivo */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.motivo_corte);
         /* Estado */
         strcat(sLinea, "\"Completed\";");
         /* Dias (Vacio) */
         strcat(sLinea, "\"\"");
         
         
         break;
      case 'R':
         /* Tipo de registro */
         strcpy(sLinea, "\"REINSTATEMENT\";");
         /* Fecha actual */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.fecha_reposicion);
         /* Monto */
         sprintf(sLinea, "%s\"%.02f\";", sLinea, regCor.saldo_exigible);
         /* Description */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.motivo_repo);
         /* Acción realizada */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.accion_rehab);
         /* Rol ejecutor */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.funcionario_repo);
         /* Evento */
         strcat(sLinea, "\"\";");
         /* Fecha evento */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.fecha_sol_repo);
         /* External Id */
         sprintf(sLinea, "%s\"%ld%02d%02dREPOFOPARG\";", sLinea, regCor.numero_cliente, regCor.corr_corte, regCor.corr_repo);
         /* Situación encontrada */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.sit_rehab);
         /* Suministro */
         sprintf(sLinea, "%s\"%ldAR\";", sLinea, regCor.numero_cliente);
         /* Observaciones */
         strcat(sLinea, "\"\";");
         /* Motivo */
         sprintf(sLinea, "%s\"%s\";", sLinea, regCor.motivo_repo);
         /* Estado */
         strcat(sLinea, "\"Completed\";");
         /* Dias (vacio) */
         strcat(sLinea, "\"\"");
   
         break;
      case 'E':
         /* Tipo de registro */
         strcpy(sLinea, "\"EXTENSION\";");
         /* Fecha actual */
         sprintf(sLinea, "%s\"%s\";", sLinea, regEx.fecha_solicitud);
         /* Monto (vacio) */
         strcat(sLinea, "\"\";");
         /* Description */
         sprintf(sLinea, "%s\"%s\";", sLinea, regEx.motivo);
         /* Acción realizada (vacio) */
         strcat(sLinea, "\"\";");
         /* Rol ejecutor */
         sprintf(sLinea, "%s\"%s\";", sLinea, regEx.rol);
         /* Evento */
         strcat(sLinea, "\"\";");
         /* Fecha evento */
         strcat(sLinea, "\"\";");
         /* External Id */
         sprintf(sLinea, "%s\"%ld%04dPRORFOPARG\";", sLinea, regEx.numero_cliente, index);
         /* Situación encontrada */
         strcat(sLinea, "\"\";");
         /* Suministro */
         sprintf(sLinea, "%s\"%ldAR\";", sLinea, regEx.numero_cliente);
         /* Observaciones */
         strcat(sLinea, "\"\";");
         /* Motivo */
         sprintf(sLinea, "%s\"%s\";", sLinea, regEx.cod_motivo);
         /* Estado */
         sprintf(sLinea, "%s\"%s\";", sLinea, regEx.estado);
         /* Dias */
         sprintf(sLinea, "%s\"%d\";", sLinea, regEx.dias);
         
         break;      
   }
   
	

	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	

	
	return 1;
}


/****************************
		GENERALES
*****************************/

void command(cmd,buff_cmd)
char *cmd;
char *buff_cmd;
{
   FILE *pf;
   char *p_aux;
   pf =  popen(cmd, "r");
   if (pf == NULL)
       strcpy(buff_cmd, "E   Error en ejecucion del comando");
   else
       {
       strcpy(buff_cmd,"\n");
       while (fgets(buff_cmd + strlen(buff_cmd),512,pf))
           if (strlen(buff_cmd) > 5000)
              break;
       }
   p_aux = buff_cmd;
   *(p_aux + strlen(buff_cmd) + 1) = 0;
   pclose(pf);
}

/*
short EnviarMail( Adjunto1, Adjunto2)
char *Adjunto1;
char *Adjunto2;
{
    char 	*sClave[] = {SYN_CLAVE};
    char 	*sAdjunto[3]; 
    int		iRcv;
    
    sAdjunto[0] = Adjunto1;
    sAdjunto[1] = NULL;
    sAdjunto[2] = NULL;

	iRcv = synmail(sClave[0], sMensMail, NULL, sAdjunto);
	
	if(iRcv != SM_OK){
		return 0;
	}
	
    return 1;
}

void  ArmaMensajeMail(argv)
char	* argv[];
{
$char	FechaActual[11];

	
	memset(FechaActual,'\0', sizeof(FechaActual));
	$EXECUTE selFechaActual INTO :FechaActual;
	
	memset(sMensMail,'\0', sizeof(sMensMail));
	sprintf( sMensMail, "Fecha de Proceso: %s<br>", FechaActual );
	if(strcmp(argv[1],"M")==0){
		sprintf( sMensMail, "%sNovedades Monetarias<br>", sMensMail );		
	}else{
		sprintf( sMensMail, "%sNovedades No Monetarias<br>", sMensMail );		
	}
	if(strcmp(argv[2],"R")==0){
		sprintf( sMensMail, "%sRegeneracion<br>", sMensMail );
		sprintf(sMensMail,"%sOficina:%s<br>",sMensMail, argv[3]);
		sprintf(sMensMail,"%sF.Desde:%s|F.Hasta:%s<br>",sMensMail, argv[4], argv[5]);
	}else{
		sprintf( sMensMail, "%sGeneracion<br>", sMensMail );
	}		
	
}
*/


static char *strReplace(sCadena, cFind, cRemp)
char *sCadena;
char cFind[2];
char cRemp[2];
{
	char sNvaCadena[1000];
	int lLargo;
	int lPos;

	memset(sNvaCadena, '\0', sizeof(sNvaCadena));
	
	lLargo=strlen(sCadena);

    if (lLargo == 0)
    	return sCadena;

	for(lPos=0; lPos<lLargo; lPos++){

       if (sCadena[lPos] != cFind[0]) {
       	sNvaCadena[lPos]=sCadena[lPos];
       }else{
	       if(strcmp(cRemp, "")!=0){
	       		sNvaCadena[lPos]=cRemp[0];  
	       }else {
	            sNvaCadena[lPos]=' ';   
	       }
       }
	}

	return sNvaCadena;
}

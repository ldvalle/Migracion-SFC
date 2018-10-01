/********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_device
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura 
      CONTRATO - LINEA DE CONTRATO Y BILLING PROFILE
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Tipo Corrida> : 0=Normal; 1= Reducida
      <Archivos Genera>: 1= Contrato; 2=Linea Contrato; 3=Billing Profile; 0=Todos
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_contrato.h";

/* Variables Globales */
$char	gsTipoGenera[2];
int   gsArchivoGenera;
int   giTipoCorrida;

FILE	*pFileContrato;
FILE	*pFileLinea;
FILE	*pFileBilling;

char	sArchContratoUnx[100];
char	sArchContratoAux[100];
char	sArchContratoDos[100];
char	sSoloContrato[100];

char	sArchLineaUnx[100];
char	sArchLineaAux[100];
char	sArchLineaDos[100];
char	sSoloLinea[100];

char	sArchBillingUnx[100];
char	sArchBillingAux[100];
char	sArchBillingDos[100];
char	sSoloBilling[100];

char	sArchLog[100];
char	sPathSalida[100];
char	FechaGeneracion[9];	
char	MsgControl[100];
$char	fecha[9];
long	lCorrelativo;

long	cantProcesada;
long 	cantPreexistente;
long	iContaLog;

/* Variables Globales Host */
$ClsCliente	regCliente;
$long lFechaRti;

char	sMensMail[1024];	

$WHENEVER ERROR CALL SqlException;

void main( int argc, char **argv ) 
{
$char 	nombreBase[20];
time_t 	hora;
FILE	*fp;
int		iFlagMigra=0;
int 	iFlagEmpla=0;

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

   $EXECUTE selFechaRti INTO :lFechaRti;

	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
	if(!AbreArchivos()){
		exit(1);	
	}

	cantProcesada=0;
	cantPreexistente=0;
	iContaLog=0;
	
   
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/

   $OPEN curClientes;

   while(LeoCliente(&regCliente)){
      
      if(!PadreEnT23(&regCliente)){
         memset(regCliente.papa_t23, '\0', sizeof(regCliente.papa_t23));
      }
      
      /* CargaAlta1(&regCliente);*/
      if(!CargaAlta2(&regCliente)){
         printf("Falló carga alta de cliente %ld\n", regCliente.numero_cliente);
      }
      
      if(regCliente.tipo_fpago[0]=='D'){
         CargaFormaPago(&regCliente);      
      }
      
      CargaTasa(&regCliente);
      
      switch(gsArchivoGenera){
         case 1:
            GeneraContrato(regCliente);
            break;
         case 2:
            GeneraLinea(regCliente);
            break;
         case 3:
            GeneraBilling(regCliente);
            break;
         case 0:
            GeneraContrato(regCliente);
            GeneraLinea(regCliente);
            GeneraBilling(regCliente);
            break;   
      }

      cantProcesada++;
   }
   			
   $CLOSE curClientes;      
   
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
	printf("CONTRATO\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Clientes Procesados :       %ld \n",cantProcesada);
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

	if(argc != 4 ){
		MensajeParametros();
		return 0;
	}
   
   giTipoCorrida=atoi(argv[2]);
	gsArchivoGenera=atoi(argv[3]);
   
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
		printf("	<Tipo Corrida> 0=Normal, 1=Reducida.\n");
      printf("	<Archivos> 0=Todos; 1=Contrato; 2=Linea; 3= Billing.\n");
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   
   memset(sTitulos, '\0', sizeof(sTitulos));
	
	memset(sArchContratoUnx,'\0',sizeof(sArchContratoUnx));
	memset(sArchContratoAux,'\0',sizeof(sArchContratoAux));
   memset(sArchContratoDos,'\0',sizeof(sArchContratoDos));
	memset(sSoloContrato,'\0',sizeof(sSoloContrato));
	
	memset(sArchLineaUnx,'\0',sizeof(sArchLineaUnx));
	memset(sArchLineaAux,'\0',sizeof(sArchLineaAux));
   memset(sArchLineaDos,'\0',sizeof(sArchLineaDos));
	memset(sSoloLinea,'\0',sizeof(sSoloLinea));

	memset(sArchBillingUnx,'\0',sizeof(sArchBillingUnx));
	memset(sArchBillingAux,'\0',sizeof(sArchBillingAux));
   memset(sArchBillingDos,'\0',sizeof(sArchBillingDos));
	memset(sSoloBilling,'\0',sizeof(sSoloBilling));
   memset(sFecha,'\0',sizeof(sFecha));

	memset(sPathSalida,'\0',sizeof(sPathSalida));


   FechaGeneracionFormateada(sFecha);
   
	RutaArchivos( sPathSalida, "SALESF" );
   
	alltrim(sPathSalida,' ');

	sprintf( sArchContratoUnx  , "%sT1CONTRATO.unx", sPathSalida );
   sprintf( sArchContratoAux  , "%sT1CONTRATO.aux", sPathSalida );
   sprintf( sArchContratoDos  , "%senel_care_contract_t1_%s.csv", sPathSalida, sFecha );
	strcpy( sSoloContrato, "T1CONTRATO.unx");

	sprintf( sArchLineaUnx  , "%sT1LINEA.unx", sPathSalida );
   sprintf( sArchLineaAux  , "%sT1LINEA.aux", sPathSalida );
   sprintf( sArchLineaDos  , "%senel_care_contract_line_t1_%s.csv", sPathSalida, sFecha );
	strcpy( sSoloLinea, "T1LINEA.unx");

	sprintf( sArchBillingUnx  , "%sT1BILLING_PROFILE.unx", sPathSalida );
   sprintf( sArchBillingAux  , "%sT1BILLING_PROFILE.aux", sPathSalida );
   sprintf( sArchBillingDos  , "%senel_care_billingprofile_t1_%s.csv", sPathSalida, sFecha);
	strcpy( sSoloBilling, "T1BILLING_PROFILE.unx");

   switch(gsArchivoGenera){
      case 1:
      	pFileContrato=fopen( sArchContratoUnx, "w" );
      	if( !pFileContrato ){
      		printf("ERROR al abrir archivo %s.\n", sArchContratoUnx );
      		return 0;
      	}

         strcpy(sTitulos,"\"Divisa del contrato\";\"Duración del contrato (meses)\";\"Estado\";\"Fecha de activación\";\"Fecha de inicio del contrato\";\"Fecha final del contrato\";\"Nombre de la cuenta\";\"Nombre del contrato\";\"Tipo de contrato\";\"Compañía\";\"External Id\";\"Contacto\";\"Suministro\";");
         strcat(sTitulos, "\"Actividad Económica\";\"Garantía\";\"Garante\";\"Fin de Garantía\";\"Comienzo de Garantía\";\"Conexión Transitoria\";\"Tipo de Titular\";\"Motivo de Garantía\";\"Tipo de Garantía\";\"Amount To Pay\";\"Connection Charge\";\"Construction Product\";\"Deactivation Date\";\"Payment Terms\";\"Cuenta Contrato\";");
         strcat(sTitulos, "\"Tasa AP\";\"Número de Partida\";\"Cliente Peaje\";\n");
         
         fprintf(pFileContrato, sTitulos);
         
         break;      
      case 2:
      	pFileLinea=fopen( sArchLineaUnx, "w" );
      	if( !pFileLinea ){
      		printf("ERROR al abrir archivo %s.\n", sArchLineaUnx );
      		return 0;
      	}
         
         strcpy(sTitulos,"\"Divisa\";\"Activo\";\"Perfil de Facturación\";\"Contrato\";\"Cantidad\";\"Estado\";\"External ID\";\"CuentaContrato\";\"Perfil de Facturacion agrupador\";\n");
         fprintf(pFileLinea, sTitulos);
         
         break;      
      case 3:
      	pFileBilling=fopen( sArchBillingUnx, "w" );
      	if( !pFileBilling ){
      		printf("ERROR al abrir archivo %s.\n", sArchBillingUnx );
      		return 0;
      	}
         
         /*strcpy(sTitulos,"\"Cuenta\";\"Tipo\";\"Acepta Términos y Condiciones\";\"Nombre de la factura\";\"Banco\";\"Dirección de reparto\";\"Tipo de Documento\";\"Adhesión a Factura Electrónica\";\"External ID\";\"External ID Suministro\";\"Clase de Tarjeta\";\"Numero Tarjeta Crédito\";\"CBU\";\"Entidad Bancaria\";\"CuentaContrato\";\"Número de Cuenta\";\"Tipo de Cuenta\";\"Titular de Tarjeta\";\"Tipo de Reparto\";\"Dirección Postal\";\n");*/
         strcpy(sTitulos,"\"Cuenta\";\"Tipo\";\"Acepta Términos y Condiciones\";\"Nombre de la factura\";\"Dirección de reparto\";\"Tipo de Documento\";\"Adhesión a Factura Electrónica\";\"External ID\";\"External ID Suministro\";\"Clase de Tarjeta\";\"Numero Tarjeta Crédito\";\"CBU\";\"Entidad Bancaria\";\"CuentaContrato\";\"Número de Cuenta\";\"Dirección Postal\";\"Tipo de Reparto\";\"Fecha Factura Digital\";\n");
         fprintf(pFileBilling, sTitulos);
         
         break;      
      case 0:
      	pFileContrato=fopen( sArchContratoUnx, "w" );
      	if( !pFileContrato ){
      		printf("ERROR al abrir archivo %s.\n", sArchContratoUnx );
      		return 0;
      	}

      	pFileLinea=fopen( sArchLineaUnx, "w" );
      	if( !pFileLinea ){
      		printf("ERROR al abrir archivo %s.\n", sArchLineaUnx );
      		return 0;
      	}
   
      	pFileBilling=fopen( sArchBillingUnx, "w" );
      	if( !pFileBilling ){
      		printf("ERROR al abrir archivo %s.\n", sArchBillingUnx );
      		return 0;
      	}

         strcpy(sTitulos,"\"Divisa del contrato\";\"Duración del contrato (meses)\";\"Estado\";\"Fecha de activación\";\"Fecha de inicio del contrato\";\"Fecha final del contrato\";\"Nombre de la cuenta\";\"Nombre del contrato\";\"Tipo de contrato\";\"Compañía\";\"External Id\";\"Contacto\";\"Suministro\";");
         strcat(sTitulos, "\"Actividad Económica\";\"Garantía\";\"Garante\";\"Fin de Garantía\";\"Comienzo de Garantía\";\"Conexión Transitoria\";\"Tipo de Titular\";\"Motivo de Garantía\";\"Tipo de Garantía\";\"Amount To Pay\";\"Connection Charge\";\"Construction Product\";\"Deactivation Date\";\"Payment Terms\";\"Cuenta Contrato\";");
         strcat(sTitulos, "\"Tasa AP\";\"Número de Partida\";\"Cliente Peaje\";\n");
         fprintf(pFileContrato, sTitulos);

         strcpy(sTitulos,"\"Divisa\";\"Activo\";\"Perfil de Facturación\";\"Contrato\";\"Cantidad\";\"Estado\";\"External ID\";\"CuentaContrato\";\"Perfil de Facturacion agrupador\";\n");
         fprintf(pFileLinea, sTitulos);

         /*strcpy(sTitulos,"\"Cuenta\";\"Tipo\";\"Acepta Términos y Condiciones\";\"Nombre de la factura\";\"Banco\";\"Dirección de reparto\";\"Tipo de Documento\";\"Adhesión a Factura Electrónica\";\"External ID\";\"External ID Suministro\";\"Clase de Tarjeta\";\"Numero Tarjeta Crédito\";\"CBU\";\"Entidad Bancaria\";\"CuentaContrato\";\"Número de Cuenta\";\"Tipo de Cuenta\";\"Titular de Tarjeta\";\"Tipo de Reparto\";\"Dirección Postal\";\n");*/
         strcpy(sTitulos,"\"Cuenta\";\"Tipo\";\"Acepta Términos y Condiciones\";\"Nombre de la factura\";\"Dirección de reparto\";\"Tipo de Documento\";\"Adhesión a Factura Electrónica\";\"External ID\";\"External ID Suministro\";\"Clase de Tarjeta\";\"Numero Tarjeta Crédito\";\"CBU\";\"Entidad Bancaria\";\"CuentaContrato\";\"Número de Cuenta\";\"Dirección Postal\";\"Tipo de Reparto\";\"Fecha Factura Digital\";\n");
         fprintf(pFileBilling, sTitulos);
         
         break;
   }

      
	return 1;	
}

void CerrarArchivos(void)
{
   switch(gsArchivoGenera){
      case 1:
         fclose(pFileContrato);
         break;
      case 2:
         fclose(pFileLinea);
         break;
      case 3:
         fclose(pFileBilling);
         break;
      case 0:
         fclose(pFileContrato);
         fclose(pFileLinea);
         fclose(pFileBilling);
         break;   
   }
   
	

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


   switch(gsArchivoGenera){
      case 1:
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchContratoUnx, sArchContratoAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchContratoAux, sArchContratoDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchContratoDos);
      	iRcv=system(sCommand);

      	sprintf(sCommand, "cp %s %s", sArchContratoDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchContratoUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchContratoAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchContratoDos);
         iRcv=system(sCommand);

         break;      
      case 2:
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchLineaUnx, sArchLineaAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchLineaAux, sArchLineaDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchLineaDos);
      	iRcv=system(sCommand);

      	sprintf(sCommand, "cp %s %s", sArchLineaDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchLineaUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchLineaAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchLineaDos);
         iRcv=system(sCommand);

         break;
               
      case 3:
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchBillingUnx, sArchBillingAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchBillingAux, sArchBillingDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchBillingDos);
      	iRcv=system(sCommand);

      	sprintf(sCommand, "cp %s %s", sArchBillingDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchBillingUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchBillingAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchBillingDos);
         iRcv=system(sCommand);

         break;
               
      case 0:   
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchContratoUnx, sArchContratoAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchContratoAux, sArchContratoDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchContratoDos);
      	iRcv=system(sCommand);
         /* ---------------- */
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchLineaUnx, sArchLineaAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchLineaAux, sArchLineaDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchLineaDos);
      	iRcv=system(sCommand);
         
         /* ---------------- */
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchBillingUnx, sArchBillingAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchBillingAux, sArchBillingDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchBillingDos);
      	iRcv=system(sCommand);
         
         /*********************/
         /*********************/
	
      	sprintf(sCommand, "cp %s %s", sArchContratoDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchContratoUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchContratoAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchContratoDos);
         iRcv=system(sCommand);
         
         /*----------------*/
      	sprintf(sCommand, "cp %s %s", sArchLineaDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchLineaUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchLineaAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchLineaDos);
         iRcv=system(sCommand);
         
         /*----------------*/
      	sprintf(sCommand, "cp %s %s", sArchBillingDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchBillingUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchBillingAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchBillingDos);
         iRcv=system(sCommand);
         
         break;   
   
   }

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

   /********* Fecha RTi **********/
	strcpy(sql, "SELECT fecha_modificacion ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'SAPFAC' ");
	strcat(sql, "AND sucursal = '0000' "); 
	strcat(sql, "AND codigo = 'RTI-1' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY) ");
   
   $PREPARE selFechaRti FROM $sql;

	/******** Cursor CLIENTES  ****************/
   strcpy(sql, "SELECT c.numero_cliente, ");
   strcat(sql, "c.corr_facturacion, "); 
	strcat(sql, "TRIM(c.nombre), "); 
	strcat(sql, "c.tipo_fpago, "); 
   strcat(sql, "s1.cod_sf1, "); /* Tipo Reparto */
   strcat(sql, "c.nro_beneficiario, ");
   strcat(sql, "TRIM(t1.cod_sap) || ' - ' || TRIM(t1.descripcion), ");
   strcat(sql, "t2.descripcion, ");
   strcat(sql, "c.minist_repart ");
	strcat(sql, "FROM cliente c, OUTER sap_transforma t1, OUTER tabla t2 ");
   strcat(sql, ", sf_transforma s1 ");   	
if(giTipoCorrida == 1){	
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
   
	strcat(sql, "AND t1.clave = 'BU_TYPE' ");
	strcat(sql, "AND t1.cod_mac = c.actividad_economic ");
	strcat(sql, "AND t2.nomtabla = 'CNRTU' ");
	strcat(sql, "AND t2.sucursal = '0000' ");
	strcat(sql, "AND t2.codigo = c.cod_propiedad ");
	strcat(sql, "AND t2.fecha_activacion <= TODAY ");
	strcat(sql, "AND (t2.fecha_desactivac IS NULL OR t2.fecha_desactivac > TODAY) ");
	strcat(sql, "AND s1.clave = 'TIPREPARTO' ");
	strcat(sql, "AND s1.cod_mac = c.tipo_reparto ");   
   	
if(giTipoCorrida == 1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}

	$PREPARE selClientes FROM $sql;
	
	$DECLARE curClientes CURSOR WITH HOLD FOR selClientes;

   /*********** Fecha Alta ***********/
	strcpy(sql, "SELECT TO_CHAR(MIN(h1.fecha_lectura), '%Y-%m-%d') ");
	strcat(sql, "FROM hislec h1 ");
	strcat(sql, "WHERE h1.numero_cliente = ? ");
	strcat(sql, "AND tipo_lectura = 8 ");
	strcat(sql, "AND h1.fecha_lectura > (SELECT MIN(h2.fecha_lectura) ");
	strcat(sql, "	FROM hislec h2 "); 
	strcat(sql, " 	WHERE h2.numero_cliente = h1.numero_cliente ");
	strcat(sql, "  AND h2.tipo_lectura IN (1,2,3,4) ");
	strcat(sql, "  AND h2.fecha_lectura > ?) ");
   
   $PREPARE selFechaAlta FROM $sql;

	/******** Buscamos el Alta Medidor en ESTOC *********/
	strcpy(sql, "SELECT TO_CHAR(fecha_terr_puser, '%Y-%m-%d') ");
	strcat(sql, "FROM estoc ");
	strcat(sql, "WHERE numero_cliente = ? ");

	$PREPARE selEstoc FROM $sql;

	/******** Select Retiros Medidor *********/	
	strcpy(sql, "SELECT TO_CHAR(MAX(m2.fecha_modif), '%Y-%m-%d') ");
	strcat(sql, "FROM modif m2 ");
	strcat(sql, "WHERE m2.numero_cliente = ? ");
	strcat(sql, "AND m2.codigo_modif = 58 ");

	$PREPARE selRetiro FROM $sql;

	/************ Busca Instalacion **************/
	strcpy(sql, "SELECT NVL(TO_CHAR(MIN(m.fecha_ult_insta), '%Y-%m-%d'), '1995-09-24') ");
	strcat(sql, "FROM medid m ");
	strcat(sql, "WHERE m.numero_cliente = ? ");

	$PREPARE selFechaInstal FROM $sql;	


   /********* Factura Digital **********/
	strcpy(sql, "SELECT TO_CHAR(fecha_alta, '%Y-%m-%d'),  COUNT(*) "); 
	strcat(sql, "FROM clientes_digital ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND fecha_alta <= TODAY ");
	strcat(sql, "AND fecha_baja IS NULL OR fecha_baja > TODAY ");
   strcat(sql, "GROUP BY 1 ");
   
   $PREPARE selDigital  FROM $sql;

	/********* Select Data Debito Debito **********/
	strcpy(sql, "SELECT f.fp_banco, f.fp_nrocuenta, f.fp_cbu, e.tipo ");
	strcat(sql, "FROM forma_pago f, entidades_debito e ");
	strcat(sql, "WHERE f.numero_cliente = ? ");
	strcat(sql, "AND f.fecha_activacion <= TODAY ");
	strcat(sql, "AND (f.fecha_desactivac IS NULL OR f.fecha_desactivac > TODAY) ");
	strcat(sql, "AND e.oficina = f.fp_banco ");
	strcat(sql, "AND e.fecha_activacion <= TODAY ");
	strcat(sql, "AND (e.fecha_desactivac IS NULL OR e.fecha_desactivac > TODAY) ");
	
	$PREPARE selDataDebito FROM $sql;
   
   /*********** Entidad Debito **************/
	strcpy(sql, "SELECT TRIM(nombre) FROM oficinas ");
	strcat(sql, "WHERE sucursal = '0000' ");
	strcat(sql, "AND oficina = ? ");

   $PREPARE selEntiDebito FROM $sql;

   /*********** Trafo Tarjeta **************/
	/*strcpy(sql, "SELECT acronimo_sap, trim(descripcion) ");*/
   strcpy(sql, "SELECT cod_sap, trim(descripcion), trim(acronimo_sap) ");
	strcat(sql, "FROM sap_transforma ");
	strcat(sql, "WHERE clave = 'CARDTYPE' ");
	strcat(sql, "AND cod_mac = ? ");
   
   $PREPARE selTrafoCard FROM $sql;
   
	/******** Select Path de Archivos ****************/
	strcpy(sql, "SELECT valor_alf ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'PATH' ");
	strcat(sql, "AND codigo = ? ");
	strcat(sql, "AND sucursal = '0000' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL ) ");

	$PREPARE selRutaPlanos FROM $sql;

	/********* Select Corporativo T23 **********/
	strcpy(sql, "SELECT NVL(cod_corporativo, '000'), cod_corpo_padre FROM mg_corpor_t23 ");
	strcat(sql, "WHERE numero_cliente = ? ");
	
	$PREPARE selCorpoT23 FROM $sql;

   /********** Tasa AP **********/
	strcpy(sql, "SELECT FIRST 1 partida_municipal ");  
	strcat(sql, "FROM cliente_tasa ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND tasa_exceptuada = 0 ");
	strcat(sql, "AND tasa_anulada = 0 ");
   
   $PREPARE selTasa FROM $sql;
   
   /*** GARANTE ****/
   $PREPARE selGarante FROM "SELECT FIRST 1 d1.numero_dg,
        TO_CHAR(d1.fecha_emision, '%Y-%m-%dT%H:%M:%S.000Z'),
        d1.garante,
        d1.motivo
        FROM depgar d1
        WHERE d1.numero_cliente = ?
        AND d1.fecha_emision = (SELECT MAX(d2.fecha_emision) FROM
            depgar d2
            WHERE d2.numero_cliente = d1.numero_cliente)";
   
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

short LeoCliente(reg)
$ClsCliente *reg;
{
   $int  iCantDigital=0;
   $ClsGarantia  regDg;
   
	InicializaCliente(reg);

	$FETCH curClientes INTO
      :reg->numero_cliente,
      :reg->corr_facturacion,
      :reg->nombre,
      :reg->tipo_fpago,
      :reg->tipo_reparto,
      :reg->nro_beneficiario,
      :reg->codActividadEconomica,
      :reg->tipo_titularidad,
      :reg->minist_repart;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Clientes !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

   $EXECUTE selDigital INTO :reg->sFechaAltaFactuDigital :iCantDigital USING :reg->numero_cliente;

   if(SQLCODE != 0){
      if(SQLCODE != SQLNOTFOUND){
			printf("Error al buscar factura digital para cliente %ld !!!\nProceso Abortado.\n", reg->numero_cliente);
			exit(1);
      }else{
         strcpy(reg->factu_digital, "N");
         memset(reg->sFechaAltaFactuDigital, '\0', sizeof(reg->sFechaAltaFactuDigital));
      }	
   }else{
      if(iCantDigital >0){
         strcpy(reg->factu_digital, "S");
      }else{
         strcpy(reg->factu_digital, "N");   
      }
   }

    $EXECUTE selGarante INTO :regDg.nroDg, 
                            :regDg.sFechaEmision,
                            :regDg.lGarante,
                            :regDg.motivo
                        USING :reg->numero_cliente;
    
    if(SQLCODE !=0){
        reg->dgGarante=-1;
    }else{
        reg->dgGarante = regDg.lGarante;
        strcpy(reg->dgFechaEmision, regDg.sFechaEmision);
    }
        
                            
                            
                            
   alltrim(reg->codActividadEconomica, ' ');
   alltrim(reg->tipo_titularidad, ' ');
   
   return 1;
}



void InicializaCliente(reg)
$ClsCliente	*reg;
{
   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   rsetnull(CLONGTYPE, (char *) &(reg->nro_beneficiario));
   
   memset(reg->nombre, '\0', sizeof(reg->nombre));
   memset(reg->tipo_fpago, '\0', sizeof(reg->tipo_fpago));
   memset(reg->tipo_reparto, '\0', sizeof(reg->tipo_reparto));
   memset(reg->sFechaAlta, '\0', sizeof(reg->sFechaAlta));      
   memset(reg->factu_digital, '\0', sizeof(reg->factu_digital));
   memset(reg->sNombreBanco, '\0', sizeof(reg->sNombreBanco));
   memset(reg->codTarjetaCredito, '\0', sizeof(reg->codTarjetaCredito));
   memset(reg->nroTarjeta, '\0', sizeof(reg->nroTarjeta));
   memset(reg->cbu, '\0', sizeof(reg->cbu));
   memset(reg->codBanco, '\0', sizeof(reg->codBanco));
   
   memset(reg->codActividadEconomica, '\0', sizeof(reg->codActividadEconomica));
   memset(reg->tipo_titularidad, '\0', sizeof(reg->tipo_titularidad));
   memset(reg->sFechaAltaFactuDigital, '\0', sizeof(reg->sFechaAltaFactuDigital));

   rsetnull(CLONGTYPE, (char *) &(reg->minist_repart));
   memset(reg->papa_t23, '\0', sizeof(reg->papa_t23));
   memset(reg->sTasaAP, '\0', sizeof(reg->sTasaAP));
   memset(reg->sPatidaMuni, '\0', sizeof(reg->sPatidaMuni));
   memset(reg->sMarcaTarjeta, '\0', sizeof(reg->sMarcaTarjeta));
   
   rsetnull(CLONGTYPE, (char *) &(reg->dgGarante));
   memset(reg->dgFechaEmision, '\0', sizeof(reg->dgFechaEmision));
   
}


void CargaAlta1(reg)
$ClsCliente *reg;
{

	/* Ahora es la fecha de la primera factura que se migra */
	if(reg->corr_facturacion > 0){
   
      $EXECUTE selFechaAlta INTO :reg->sFechaAlta
         USING :reg->numero_cliente,
               :lFechaRti;
               
      if(SQLCODE != 0){
          if(SQLCODE != 100){
		       printf("Error al buscar fecha de Alta para cliente %ld.\n", reg->numero_cliente);
          }else{
            if(!CargaAlta2(reg)){
      		    printf("No se Encontró fecha de Alta para cliente %ld.\n", reg->numero_cliente);
            }
          
          }
      }else{
         alltrim(reg->sFechaAlta, ' ');
         if(strcmp(reg->sFechaAlta, "")==0){
            if(!CargaAlta2(reg)){
      		    printf("No se encontró fecha de Alta para cliente %ld.\n", reg->numero_cliente);
            }
         }
      }
	}else{

      if(!CargaAlta2(reg)){
		    printf("No se encontró fecha de Alta para cliente %ld.\n", reg->numero_cliente);
      }
	}
}

short CargaAlta2(reg)
$ClsCliente *reg;
{
	$EXECUTE selEstoc into :reg->sFechaAlta using :reg->numero_cliente;

	if(SQLCODE != 0){

		if(SQLCODE != SQLNOTFOUND){
			printf("Error al buscar fecha de RETIRO de medidor para cliente %ld.\n", reg->numero_cliente);
			exit(2);
		}else{
			if(reg->nro_beneficiario > 0){
				$EXECUTE selRetiro  into :reg->sFechaAlta using :reg->nro_beneficiario;
					
				if(SQLCODE != 0){
					if(SQLCODE != SQLNOTFOUND){
						printf("Error al buscar fecha de RETIRO de medidor para cliente antecesor %ld.\n", reg->nro_beneficiario);
						exit(2);
					}else{
						strcpy(reg->sFechaAlta, "1995-09-24");
					}
				}
			}else{
				/* Busco la fecha de instalacion */
				$EXECUTE selFechaInstal into :reg->sFechaAlta using :reg->numero_cliente;
				
				if(SQLCODE != 0){
					strcpy(reg->sFechaAlta, "1995-09-24");
				}
			}
		}
	}

   return 1;
}

void CargaFormaPago(reg)
ClsCliente *reg;
{
$ClsFormaPago  rPago;

   memset(rPago.fp_banco, '\0', sizeof(rPago.fp_banco));
   memset(rPago.fp_nrocuenta, '\0', sizeof(rPago.fp_nrocuenta));
   memset(rPago.fp_cbu, '\0', sizeof(rPago.fp_cbu));
   memset(rPago.tipo, '\0', sizeof(rPago.tipo));
   memset(rPago.nombre, '\0', sizeof(rPago.nombre));

   $EXECUTE selDataDebito INTO
      :rPago.fp_banco,
      :rPago.fp_nrocuenta,
      :rPago.fp_cbu,
      :rPago.tipo
      USING :reg->numero_cliente;
      
      
   if(SQLCODE != 0){
      strcpy(reg->tipo_fpago, "N");
      return;
   } 

   alltrim(rPago.fp_cbu, ' ');
   alltrim(rPago.fp_nrocuenta, ' ');
   
   if(strcmp(rPago.fp_cbu, "")==0){
      /* Es Tarjeta */
      strcpy(reg->nroTarjeta, rPago.fp_nrocuenta);
      
      $EXECUTE selTrafoCard INTO :reg->codTarjetaCredito,
                                 :reg->sNombreBanco,
                                 :reg->sMarcaTarjeta
                                 
                           USING :rPago.fp_banco;
         
   }else{
      /* Es debito */
      strcpy(reg->nroTarjeta, rPago.fp_nrocuenta);
      strcpy(reg->cbu, rPago.fp_cbu);
      strcpy(reg->codBanco, rPago.fp_banco);
      
      $EXECUTE selEntiDebito INTO :reg->sNombreBanco USING :rPago.fp_banco;
   }

}

void GeneraContrato(reg)
$ClsCliente		reg;
{
	char	sLinea[1000];	

	memset(sLinea, '\0', sizeof(sLinea));

   /* Divisa del contrato */
   sprintf(sLinea, "\"ARS\";");
   
   /* Duración del contrato (meses) (vacio) */
   strcat(sLinea, "\"\";");
   
   /* Estado */
   strcat(sLinea, "\"Activated\";");
   
   /* Fecha de activación */
   sprintf(sLinea, "%s\"%sT00:00:00.000Z\";", sLinea, reg.sFechaAlta);
   
   /* Fecha de inicio del contrato */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.sFechaAlta);
   
   /* Fecha final del contrato (vacio) */
   strcat(sLinea, "\"\";");
   
   /* Nombre de la cuenta */
   sprintf(sLinea, "%s\"%ldARG\";", sLinea, reg.numero_cliente);
   
   /* Nombre del contrato */
   alltrim(reg.nombre, ' ');
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.nombre);
   
   /* Tipo de contrato */
   strcat(sLinea, "\"Direct Contract\";");
   
   /* Compañía */
   strcat(sLinea, "\"9\";");
   
   /* External Id */
   sprintf(sLinea, "%s\"%ldCTOARG\";", sLinea, reg.numero_cliente);
   
   /* Contacto */
   sprintf(sLinea, "%s\"%ldARG\";", sLinea, reg.numero_cliente);
   
   /* id suministro */
   sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.numero_cliente);

   /* Actividad Económica */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.codActividadEconomica);
   
   /* Garantía */
   if(reg.dgGarante == -1){
        strcat(sLinea, "\"FALSE\";");
   }else{
        strcat(sLinea, "\"TRUE\";");
   }
   
   /* Garante */
    if(reg.dgGarante > 0){
        sprintf(sLinea, "%s\"%ld\";", sLinea, reg.dgGarante);
   }else{
        strcat(sLinea, "\"\";");
   }   
   
   /* Fin de Garantía */
   strcat(sLinea, "\"\";");
   /* Comienzo de Garantía */
   if(strcmp(reg.dgFechaEmision, "")!=0){
        sprintf(sLinea, "%s\"%s\";", sLinea, reg.dgFechaEmision);
   }else{
        strcat(sLinea, "\"\";");
   }
   /* Conexión Transitoria */
   strcat(sLinea, "\"\";");
   /* Tipo de Titular */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.tipo_titularidad);
   /* Motivo de Garantía */
   strcat(sLinea, "\"\";");
   /* Tipo de Garantía */
   strcat(sLinea, "\"\";");
   /* Amount To Pay */
   strcat(sLinea, "\"\";");
   /* Connection Charge */
   strcat(sLinea, "\"\";");
   /* Construction Product / Budget */
   strcat(sLinea, "\"\";");
   /* Deactivation Date */
   strcat(sLinea, "\"\";");
   /* Payment Terms */
   strcat(sLinea, "\"\";");
   /* Cuenta Contrato */
   sprintf(sLinea, "%s\"%ld\";", sLinea, reg.numero_cliente);
   /* Tasa AP */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.sTasaAP);
   /* Numero Partida */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.sPatidaMuni);
   /* Cliente Peaje */
   strcat(sLinea, "\"FALSE\";");
   
	strcat(sLinea, "\n");
	
	fprintf(pFileContrato, sLinea);	

}

void GeneraLinea(reg)
$ClsCliente		reg;
{
	char	sLinea[1000];	

	memset(sLinea, '\0', sizeof(sLinea));

   /* Divisa */
   strcpy(sLinea, "\"ARS\";");
      
   /* Activo */
   sprintf(sLinea, "%s\"%ldARG\";",sLinea, reg.numero_cliente);
   
   /* Perfil de Facturación */
   sprintf(sLinea, "%s\"%ldBPARG\";",sLinea, reg.numero_cliente);
   
   /* Contrato */
   sprintf(sLinea, "%s\"%ldCTOARG\";",sLinea, reg.numero_cliente);
   
   /* Cantidad */
   strcat(sLinea, "\"1\";");
   
   /* Estado */
   strcat(sLinea, "\"Active\";");
   
   /* External ID */
   sprintf(sLinea, "%s\"%ldLCOARG\";", sLinea, reg.numero_cliente);
   
   /* Cuenta contrato*/
   sprintf(sLinea, "%s\"%ld\";", sLinea, reg.numero_cliente);
   
   /*Perfil de Facturación agrupador*/
   if(strcmp(reg.papa_t23, "")!=0){
      sprintf(sLinea, "%s\"%sBPARG\";", sLinea, reg.papa_t23);
   }else if(reg.minist_repart > 0){
      sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.minist_repart);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   
	strcat(sLinea, "\n");
	
	fprintf(pFileLinea, sLinea);	

}

void GeneraBilling(reg)
$ClsCliente		reg;
{
	char	sLinea[1000];	

	memset(sLinea, '\0', sizeof(sLinea));

   /* Cuenta */
   sprintf(sLinea, "\"%ldARG\";", reg.numero_cliente);
   
   /* Tipo */
   if(reg.tipo_fpago[0]=='D'){
      alltrim(reg.cbu, ' ');
      if(strcmp(reg.cbu, "")==0){
         sprintf(sLinea, "%s\"%s\";", sLinea, reg.sMarcaTarjeta);
      }else{
         strcat(sLinea, "\"D\";");   
      }
   }else{
      strcat(sLinea, "\"\";");   
   }
   
   /* Acepta Términos y Condiciones */
   if(reg.factu_digital[0]=='S'){
      strcat(sLinea, "\"TRUE\";");
   }else{
      strcat(sLinea, "\"FALSE\";");
   }
   
   /* Nombre de la factura */
   sprintf(sLinea, "%s\"%ldARG\";", sLinea, reg.numero_cliente);
   
   /* Banco */
/*   
   alltrim(reg.sNombreBanco, ' ');
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.sNombreBanco);
*/
   
   /* Dirección de reparto */
   if(reg.tipo_reparto[0]=='P'){
      sprintf(sLinea, "%s\"%ld-1ARG\";", sLinea, reg.numero_cliente);
   }else{
      sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, reg.numero_cliente);
   }
   
   
   /* Tipo de Documento */
   /*strcat(sLinea, "\"Factura\";");*/
   strcat(sLinea, "\"\";");
   
   /* Adhesión a Factura Electrónica */
   if(reg.factu_digital[0]=='S'){
      strcat(sLinea, "\"TRUE\";");
   }else{
      strcat(sLinea, "\"FALSE\";");
   }
   
   /* External ID */
   sprintf(sLinea, "%s\"%ldBPARG\";", sLinea, reg.numero_cliente);
   
   /* External ID Suministro */
   sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.numero_cliente);
   
   /* Clase de Tarjeta */
   alltrim(reg.codTarjetaCredito, ' ');
   if(strcmp(reg.codTarjetaCredito,"")!= 0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.codTarjetaCredito);
   }else{
      strcat(sLinea, "\"\";");
   }
                             
   /* Numero Tarjeta Crédito */
   alltrim(reg.nroTarjeta, ' ');
   if(strcmp(reg.nroTarjeta,"")!= 0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.nroTarjeta);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* CBU */
   alltrim(reg.cbu, ' ');
   if(strcmp(reg.cbu,"")!= 0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.cbu);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Entidad Bancaria */
   alltrim(reg.codBanco, ' ');
   if(strcmp(reg.codBanco,"")!= 0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.codBanco);
   }else{
      strcat(sLinea, "\"\";");
   }

   /* CuentaContrato */
   sprintf(sLinea, "%s\"%ld\";", sLinea, reg.numero_cliente);
   
   /* Número de Cuenta */
/*   
   if(strcmp(reg.nroTarjeta,"")!= 0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.nroTarjeta);
   }else{
      strcat(sLinea, "\"\";");
   }
*/   
   strcat(sLinea, "\"\";");
   
   /* Tipo de Cuenta (?) */
   /*strcat(sLinea, "\"\";");*/
   
   /* Titular de Tarjeta */
   /*strcat(sLinea, "\"\";");*/

   /* Dirección Postal */
   if(reg.tipo_reparto[0]=='P'){
      sprintf(sLinea, "%s\"%ld-1ARG\";", sLinea, reg.numero_cliente);
   }else{
      sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, reg.numero_cliente);
   }
   
   /* Tipo de Reparto */
   alltrim(reg.tipo_reparto, ' ');  
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.tipo_reparto);

   /* Fecha Factura Digital */
   alltrim(reg.sFechaAltaFactuDigital, ' ');
   if(strcmp(reg.sFechaAltaFactuDigital, "")!=0){
      sprintf(sLinea, "%s\"%s\";", sLinea, reg.sFechaAltaFactuDigital);
   }else{
      strcat(sLinea, "\"\";");
   }  
   
	strcat(sLinea, "\n");
	
	fprintf(pFileBilling, sLinea);	

}

short PadreEnT23(reg)
$ClsCliente *reg;
{
   $char sCtaCorpo[11];
   memset(sCtaCorpo, '\0', sizeof(sCtaCorpo));
   
   $EXECUTE selCorpoT23 INTO :sCtaCorpo, :reg->papa_t23 USING :reg->numero_cliente;
   
   if(SQLCODE != 0){
      if(SQLCODE != SQLNOTFOUND){
         printf("Error al bucar papa t23 para cliente %ld\n", reg->numero_cliente);
      }
      return 0;
   } 

   alltrim(reg->papa_t23, ' ');
   
   return 1;
}

void CargaTasa(reg)
$ClsCliente *reg;
{

   $EXECUTE selTasa INTO :reg->sPatidaMuni USING :reg->numero_cliente;
   
   if(SQLCODE != 0){
      if(SQLCODE != SQLNOTFOUND){
         printf("Error al bucar tasa TAP para cliente %ld\n", reg->numero_cliente);
      }
      strcpy(reg->sTasaAP, "FALSE");
      return;
   } 
   strcpy(reg->sTasaAP, "TRUE");
   alltrim(reg->sPatidaMuni, ' ');
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



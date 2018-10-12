/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_device
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura Measure & Counter y Consumos
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Tipo Corrida>: 0=Normal, 1=Reducida
		<Archivos Genera> 0=Todos, 1=Measures, 2=Consumos
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_measures.h";

/* Variables Globales */
int   giTipoCorrida;
int   gsArchivoGenera;

FILE	*pFileMedidorUnx;
FILE	*pFileConsumoUnx;

char	sArchMedidorUnx[100];
char	sArchMedidorAux[100];
char	sArchMedidorDos[100];
char	sSoloArchivoMedidor[100];

char	sArchConsumoUnx[100];
char	sArchConsumoAux[100];
char	sArchConsumoDos[100];
char	sArchConsumoDos2[100];
char	sSoloArchivoConsumo[100];

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
$ClsLectura	regLectura;

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

   $OPEN curClientes;

   while(LeoCliente(&lNroCliente)){
   	$OPEN curLecturas USING :lNroCliente;
   
   	while(LeoLecturas(&regLectura)){
         if(gsArchivoGenera==0 || gsArchivoGenera==1){
      		if (!GenerarPlano(fp, regLectura, "A")){
               printf("Fallo GenearPlano\n");
      			exit(1);	
      		}
         }
         if(gsArchivoGenera==0 || gsArchivoGenera==2){
      		if (!GenerarPlanoConsumo(pFileConsumoUnx, regLectura, "A")){
               printf("Fallo GenearPlano Consumo\n");
      			exit(1);	
      		}
         }
   		if(regLectura.tipo_medidor[0]=='R'){
            if(LeoReactiva(&regLectura)){
               if(gsArchivoGenera==0 || gsArchivoGenera==1){
            		if (!GenerarPlano(fp, regLectura, "R")){
                     printf("Fallo GenearPlano\n");
            			exit(1);	
            		}
               }
               if(gsArchivoGenera==0 || gsArchivoGenera==2){
            		if (!GenerarPlanoConsumo(pFileConsumoUnx, regLectura, "R")){
                     printf("Fallo GenearPlano Consumo\n");
            			exit(1);	
            		}
               }
            }         
         }			
   		
   	}
   	
   	$CLOSE curLecturas;
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
	printf("MEASURES - CONSUMOS\n");
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
      printf("	<Archivos Genera> 0=Todos, 1=Measures, 2=Consumos.\n");
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
	
	memset(sArchConsumoUnx,'\0',sizeof(sArchConsumoUnx));
	memset(sArchConsumoAux,'\0',sizeof(sArchConsumoAux));
   memset(sArchConsumoDos,'\0',sizeof(sArchConsumoDos));
	memset(sSoloArchivoConsumo,'\0',sizeof(sSoloArchivoConsumo));

   memset(sFecha,'\0',sizeof(sFecha));
	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
   
	RutaArchivos( sPathSalida, "SALESF" );

	alltrim(sPathSalida,' ');

	sprintf( sArchMedidorUnx  , "%sT1MEASURES.unx", sPathSalida );
   sprintf( sArchMedidorAux  , "%sT1MEASURES.aux", sPathSalida );
   sprintf( sArchMedidorDos  , "%senel_care_measures_counters_t1_%s.csv", sPathSalida, sFecha);

	strcpy( sSoloArchivoMedidor, "T1MEASURES.unx");

	sprintf( sArchConsumoUnx  , "%sT1CONSUMOS.unx", sPathSalida );
   sprintf( sArchConsumoAux  , "%sT1CONSUMOS.aux", sPathSalida );
   sprintf( sArchConsumoDos  , "%senel_care_consumption_t1_%s.csv", sPathSalida, sFecha);

   /*sprintf( sArchConsumoDos2  , "%sT1CONSUMOS2.csv", sPathSalida );*/
   
	strcpy( sSoloArchivoConsumo, "T1CONSUMOS.unx");

   switch(gsArchivoGenera){
      case 0:
      	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
      	if( !pFileMedidorUnx ){
      		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
      		return 0;
      	}
	
         strcpy(sTitulos,"\"Suministro\";\"Fecha Evento\";\"Evento Medicion\";\"Tipo de Medida\";\"Numero Medidor\";\"Constante\";\"Consumo\";\"Lectura\";\"Lectura Terreno\";\"Clave Medicion\";\"Irregularidad de Lectura\";\"Caso de Atencion\";\"Factura\";\"External ID\";\"Fecha Proxima Lectura\";\"CreatedByClient\";\n");
         fprintf(pFileMedidorUnx, sTitulos);
         /* ---------------- */
      	pFileConsumoUnx=fopen( sArchConsumoUnx, "w" );
      	if( !pFileConsumoUnx ){
      		printf("ERROR al abrir archivo %s.\n", sArchConsumoUnx );
      		return 0;
      	}
	
         strcpy(sTitulos,"\"Suministro\";\"Factura\";\"Tipo de consumo\";\"Consumo facturado\";\"Clave de consumo\";\"Tipo de medida\";\"External Id\";\"Fecha del evento\";\"Número Medidor\";\"Coseno Phi\";\n");
         fprintf(pFileConsumoUnx, sTitulos);
         break;
      case 1:
      	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
      	if( !pFileMedidorUnx ){
      		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
      		return 0;
      	}
	
         strcpy(sTitulos,"\"Suministro\";\"Fecha Evento\";\"Evento Medicion\";\"Tipo de Medida\";\"Numero Medidor\";\"Constante\";\"Consumo\";\"Lectura\";\"Lectura Terreno\";\"Clave Medicion\";\"Irregularidad de Lectura\";\"Caso de Atencion\";\"Factura\";\"External ID\";\"Fecha Proxima Lectura\";\"CreatedByClient\";\n");
         fprintf(pFileMedidorUnx, sTitulos);

         break;      
      case 2:
      	pFileConsumoUnx=fopen( sArchConsumoUnx, "w" );
      	if( !pFileConsumoUnx ){
      		printf("ERROR al abrir archivo %s.\n", sArchConsumoUnx );
      		return 0;
      	}
	
         strcpy(sTitulos,"\"Suministro\";\"Factura\";\"Tipo de consumo\";\"Consumo facturado\";\"Clave de consumo\";\"Tipo de medida\";\"External Id\";\"Fecha del evento\";\"Número Medidor\";\"Coseno Phi\";\n");
         fprintf(pFileConsumoUnx, sTitulos);
         break;   
   }
   
/*   
	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
	if( !pFileMedidorUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
		return 0;
	}
	
   strcpy(sTitulos,"\"Suministro\";\"Fecha Evento\";\"Evento Medicion\";\"Tipo de Medida\";\"Numero Medidor\";\"Constante\";\"Consumo\";\"Lectura\";\"Lectura Terreno\";\"Clave Medicion\";\"Irregularidad de Lectura\";\"Caso de Atencion\";\"Factura\";\"External ID\";\"Fecha Proxima Lectura\";\"CreatedByClient\";\n");
   fprintf(pFileMedidorUnx, sTitulos);
*/      
	return 1;	
}

void CerrarArchivos(void)
{
	fclose(pFileMedidorUnx);
	fclose(pFileConsumoUnx);

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
      case 0:
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
         
         /* ------------- */
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchConsumoUnx, sArchConsumoAux);
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchConsumoAux, sArchConsumoDos);
         iRcv=system(sCommand);
         
      	sprintf(sCommand, "chmod 777 %s", sArchConsumoDos);
      	iRcv=system(sCommand);
     
      	sprintf(sCommand, "cp %s %s", sArchConsumoDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchConsumoUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchConsumoAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchConsumoDos);
         iRcv=system(sCommand);
         
         break;               
      case 1:
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

         break;      
      case 2:
         sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchConsumoUnx, sArchConsumoAux);
         /*sprintf(sCommand, "sed 's/$/\r/' < %s > %s", sArchConsumoUnx, sArchConsumoAux);*/
      	iRcv=system(sCommand);
      
         sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchConsumoAux, sArchConsumoDos);
         iRcv=system(sCommand);

      	sprintf(sCommand, "chmod 777 %s", sArchConsumoDos);
      	iRcv=system(sCommand);
     
      	sprintf(sCommand, "cp %s %s", sArchConsumoDos, sPathCp);
      	iRcv=system(sCommand);
        
         sprintf(sCommand, "rm %s", sArchConsumoUnx);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchConsumoAux);
         iRcv=system(sCommand);
      
         sprintf(sCommand, "rm %s", sArchConsumoDos);
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

	/******** Cursor CLIENTES  ****************/	
	strcpy(sql, "SELECT c.numero_cliente FROM cliente c ");
if(giTipoCorrida==1){	
   strcat(sql, ", migra_sf ma ");
}   
	
	strcat(sql, "WHERE c.estado_cliente = 0 ");
   strcat(sql, "AND c.tipo_sum NOT IN (5, 6) ");
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

   /******** Cursor LECTURAS  ****************/
	strcpy(sql, "SELECT h.numero_cliente, ");
	strcat(sql, "h.corr_facturacion, ");
	strcat(sql, "h.tipo_lectura, "); 
	strcat(sql, "TO_CHAR(h.fecha_lectura, '%Y-%m-%d'), ");
	strcat(sql, "h.constante, ");
	strcat(sql, "h.consumo, ");
	strcat(sql, "h.lectura_facturac, ");
	strcat(sql, "h.lectura_terreno, ");
	strcat(sql, "h2.centro_emisor || h2.tipo_docto || h2.numero_factura, ");
	strcat(sql, "h2.indica_refact, ");
   strcat(sql, "TO_CHAR(h2.fecha_facturacion, '%Y-%m-%d'), ");
	strcat(sql, "h.numero_medidor, ");
	strcat(sql, "h.marca_medidor, ");
   strcat(sql, "NVL(h2.coseno_phi, 0)/100, ");
   strcat(sql, "TO_CHAR(h.fecha_lectura + 30, '%Y-%m-%d') ");
	strcat(sql, "FROM hislec h, hisfac h2 ");
	strcat(sql, "WHERE h.numero_cliente = ? ");
	strcat(sql, "AND h.fecha_lectura >= TODAY - 365 ");
	strcat(sql, "AND h.tipo_lectura NOT IN (5, 6, 7) ");
	strcat(sql, "AND h2.numero_cliente = h.numero_cliente ");
	strcat(sql, "AND h2.corr_facturacion = h.corr_facturacion ");
   
	$PREPARE selLecturas FROM $sql;
	
	$DECLARE curLecturas CURSOR WITH HOLD FOR selLecturas;
   
	/******** Sel Modelo Medidor *********/
/*      
	strcpy(sql, "SELECT me.mod_codigo, NVL(mo.tipo_medidor, 'A') FROM medidor me, modelo mo ");
	strcat(sql, "WHERE me.mar_codigo = ? ");
	strcat(sql, "AND me.med_numero = ? ");
	strcat(sql, "AND me.numero_cliente = ? ");
	strcat(sql, "AND mo.mar_codigo = me.mar_codigo ");
	strcat(sql, "AND mo.mod_codigo = me.mod_codigo ");
*/
	strcpy(sql, "SELECT FIRST 1 m.modelo_medidor, NVL(m.tipo_medidor, 'A'), m.estado ");
	strcat(sql, "FROM medid m ");
	strcat(sql, "WHERE m.marca_medidor = ? ");
	strcat(sql, "AND m.numero_medidor = ? ");
	strcat(sql, "AND m.numero_cliente = ? ");
   
   $PREPARE selModMed FROM $sql;
   
	/******** Sel Hislec Rectificado *********/
	strcpy(sql, "SELECT h1.lectura_rectif, h1.consumo_rectif ");
	strcat(sql, "FROM hislec_refac h1 ");
	strcat(sql, "WHERE h1.numero_cliente = ? ");
	strcat(sql, "AND h1.corr_facturacion = ? ");
	strcat(sql, "AND h1.tipo_lectura = ? ");
	strcat(sql, "AND h1.corr_hislec_refac = (SELECT MAX(h2.corr_hislec_refac) ");
	strcat(sql, "	FROM hislec_refac h2 ");
	strcat(sql, " 	WHERE h2.numero_cliente = h1.numero_cliente ");
	strcat(sql, "   AND h2.corr_facturacion = h1.corr_facturacion ");
	strcat(sql, "   AND h2.tipo_lectura = h1.tipo_lectura) ");
   
	$PREPARE selHislecRefac FROM $sql;

	/******** Sel Hislec Reac *********/   
	strcpy(sql, "SELECT lectu_factu_reac, ");
	strcat(sql, "lectu_terreno_reac, ");
	strcat(sql, "consumo_reac ");
	strcat(sql, "FROM hislec_reac ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND corr_facturacion = ? ");
	strcat(sql, "AND tipo_lectura = ? ");

   $PREPARE selHislecReac FROM $sql;

	/******** Sel Hislec Reac Rectificado *********/
	strcpy(sql, "SELECT h1.lectu_rectif_reac, h1.consu_rectif_reac ");
	strcat(sql, "FROM hislec_refac_reac h1 ");
	strcat(sql, "WHERE h1.numero_cliente = ? ");
	strcat(sql, "AND h1.corr_facturacion = ? ");
	strcat(sql, "AND h1.tipo_lectura = ? ");
	strcat(sql, "AND h1.corr_hislec_refac = (SELECT MAX(h2.corr_hislec_refac) ");
	strcat(sql, "	FROM hislec_refac_reac h2 ");
	strcat(sql, " 	WHERE h2.numero_cliente = h1.numero_cliente ");
	strcat(sql, "   AND h2.corr_facturacion = h1.corr_facturacion ");
	strcat(sql, "   AND h2.tipo_lectura = h1.tipo_lectura )" );
   
	$PREPARE selHislecReacRefac FROM $sql;	

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


short LeoLecturas(regLec)
$ClsLectura *regLec;
{
	InicializaLectura(regLec);

	$FETCH curLecturas into
      :regLec->numero_cliente,
      :regLec->corr_facturacion, 
      :regLec->tipo_lectura,
      :regLec->fecha_lectura,
      :regLec->constante,
      :regLec->consumo,  
      :regLec->lectura_facturac,
      :regLec->lectura_terreno,
      :regLec->id_factura,
      :regLec->indica_refact,
      :regLec->fecha_facturacion,
      :regLec->numero_medidor,
      :regLec->marca_medidor,
      :regLec->coseno_phi,
      :regLec->proxLectura;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Lecturas !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

   if(regLec->indica_refact[0]=='S'){
      $EXECUTE selHislecRefac INTO 
         :regLec->lectura_facturac,
         :regLec->consumo
         USING :regLec->numero_cliente,
               :regLec->corr_facturacion,
               :regLec->tipo_lectura;
               
      if ( SQLCODE != 0 ){
         printf("No se encontro hislec rectificado para cliente %ld correlativo %ld\n", regLec->numero_cliente, regLec->corr_facturacion);
      }         
   }
	
   
   $EXECUTE selModMed INTO :regLec->modelo_medidor, :regLec->tipo_medidor, :regLec->estado_medidor
         USING :regLec->marca_medidor,
            :regLec->numero_medidor,
            :regLec->numero_cliente;

   if ( SQLCODE != 0 ){
      printf("Error leyendo medid para cliente %ld correlativo %ld\n", regLec->numero_cliente, regLec->corr_facturacion);
   }         
         
   alltrim(regLec->id_factura, ' ');
            
	return 1;	
}

void InicializaLectura(regLec)
$ClsLectura	*regLec;
{

   rsetnull(CLONGTYPE, (char *) &(regLec->numero_cliente));
   rsetnull(CINTTYPE, (char *) &(regLec->corr_facturacion)); 
   memset(regLec->fecha_lectura, '\0', sizeof(regLec->fecha_lectura));
   rsetnull(CDOUBLETYPE, (char *) &(regLec->constante));
   rsetnull(CLONGTYPE, (char *) &(regLec->consumo));  
   rsetnull(CDOUBLETYPE, (char *) &(regLec->lectura_facturac));
   rsetnull(CDOUBLETYPE, (char *) &(regLec->lectura_terreno));
   memset(regLec->id_factura, '\0', sizeof(regLec->id_factura));
   memset(regLec->indica_refact, '\0', sizeof(regLec->indica_refact));
   memset(regLec->fecha_facturacion, '\0', sizeof(regLec->fecha_facturacion));
	rsetnull(CLONGTYPE, (char *) &(regLec->numero_medidor));
   memset(regLec->marca_medidor, '\0', sizeof(regLec->marca_medidor));
   memset(regLec->modelo_medidor, '\0', sizeof(regLec->modelo_medidor));
   memset(regLec->tipo_medidor, '\0', sizeof(regLec->tipo_medidor));
   rsetnull(CDOUBLETYPE, (char *) &(regLec->coseno_phi));
   memset(regLec->proxLectura, '\0', sizeof(regLec->proxLectura));
   memset(regLec->estado_medidor, '\0', sizeof(regLec->estado_medidor));
}

void InicializaLectuReac(regLec)
$ClsLectura	*regLec;
{

   rsetnull(CLONGTYPE, (char *) &(regLec->consumo));  
   rsetnull(CDOUBLETYPE, (char *) &(regLec->lectura_facturac));
   rsetnull(CDOUBLETYPE, (char *) &(regLec->lectura_terreno));

}


short LeoReactiva(regLec)
$ClsLectura *regLec;
{
   char  sRefactu[2];
   $double  lLectura=0.00;
   $long    lConsumo=0;
    
   strcpy(sRefactu, regLec->indica_refact);
   
   InicializaLectuReac(regLec);
   
   $EXECUTE selHislecReac INTO
      :regLec->lectura_facturac,
      :regLec->lectura_terreno,
      :regLec->consumo
   USING :regLec->numero_cliente,
         :regLec->corr_facturacion,
         :regLec->tipo_lectura;
         
   if ( SQLCODE != 0 ){
      printf("No se encontro Reactiva para cliente %ld correlativo %ld\n", regLec->numero_cliente, regLec->corr_facturacion);
      return 0;
   }         

   if(sRefactu[0]=='S'){
      $EXECUTE selHislecReacRefac INTO :lLectura, :lConsumo
         USING :regLec->numero_cliente,
               :regLec->corr_facturacion,
               :regLec->tipo_lectura;

         if ( SQLCODE != 0 ){
            printf("No se encontro Reactiva Refac para cliente %ld correlativo %ld\n", regLec->numero_cliente, regLec->corr_facturacion);
         }else{
            regLec->lectura_facturac=lLectura;
            regLec->consumo=lConsumo;   
         }         
   }
  
   return 1;
}

short GenerarPlano(fp, regLec, sTipo)
FILE 				*fp;
$ClsLectura		regLec;
char           sTipo[2];
{
	char	sLinea[1000];
   int   iRcv;	

	memset(sLinea, '\0', sizeof(sLinea));
	
   /* Suministro */
   sprintf(sLinea, "\"%ldAR\";", regLec.numero_cliente);
   
   /* Fecha Evento */
   sprintf(sLinea, "%s\"%s\";", sLinea, regLec.fecha_lectura);
   
   /* Evento Medicion (vacio) */
   strcat(sLinea, "\"\";");
   
   /* Tipo de Medida */
   if(sTipo[0]=='A'){
      strcat(sLinea, "\"ACTI\";");
   }else{
      strcat(sLinea, "\"REAC\";");
   }
   
   /* ID Medidor */
   if(regLec.estado_medidor[0]=='I'){
      sprintf(sLinea, "%s\"%ld%ld%s%sDEVARG\";", sLinea, regLec.numero_cliente, regLec.numero_medidor, regLec.marca_medidor, regLec.modelo_medidor);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   
   /* Constante */
   sprintf(sLinea, "%s\"%.05lf\";", sLinea, regLec.constante);
      
   /* Consumo */
   sprintf(sLinea, "%s\"%ld\";", sLinea, regLec.consumo);

   /* Lectura */
   sprintf(sLinea, "%s\"%.0f\";", sLinea, regLec.lectura_facturac);

   /* Lectura Terreno */
   if(risnull(CDOUBLETYPE, (char *)&regLec.lectura_terreno)){
      sprintf(sLinea, "%s\"%.0f\";", sLinea, regLec.lectura_facturac);   
   }else{
      sprintf(sLinea, "%s\"%.0f\";", sLinea, regLec.lectura_terreno);   
   }
   
   /* clave Medicion */
   strcat(sLinea, "\"NORMAL READING\";");

   /* Irregularidad lectura (vacio) */
   strcat(sLinea, "\"\";");

   /* caso de antencion (vacio) */
   strcat(sLinea, "\"\";");

   /* Factura */
   sprintf(sLinea, "%s\"%ld%sINVARG\";", sLinea, regLec.numero_cliente, regLec.id_factura);
   
   /* External ID */
   if(sTipo[0]=='A')
        sprintf(sLinea, "%s\"%ld%dACTIMEDARG\";", sLinea, regLec.numero_cliente, regLec.corr_facturacion);
   else
        sprintf(sLinea, "%s\"%ld%dREACMEDARG\";", sLinea, regLec.numero_cliente, regLec.corr_facturacion);
   
   /* Fecha Prox.Lectura (vacio) */
   sprintf(sLinea, "%s\"%s\";", sLinea, regLec.proxLectura);
   
   /* CreatedByClient */
   strcat(sLinea, "\"False\";");

	strcat(sLinea, "\n");
	
   iRcv=fprintf(fp, sLinea);
   if(iRcv<0){
      printf("Error al grabar lecturas\n");
      exit(1);
   }
   	

	
	return 1;
}

short GenerarPlanoConsumo(fp, regLec, sTipo)
FILE 				*fp;
$ClsLectura		regLec;
char           sTipo[2];
{
	char	sLinea[1000];
   int   iRcv;	

	memset(sLinea, '\0', sizeof(sLinea));
	
   /* Suministro */
   sprintf(sLinea, "\"%ldAR\";", regLec.numero_cliente);
   
   /* Factura */
   sprintf(sLinea, "%s\"%ld%sINVARG\";", sLinea, regLec.numero_cliente, regLec.id_factura);

   /* Tipo de Consumo */
   if(sTipo[0]=='A'){
      strcat(sLinea, "\"ACTI\";");
   }else{
      strcat(sLinea, "\"REAC\";");
   }

   /* Consumo Facturado */
   sprintf(sLinea, "%s\"%ld\";", sLinea, regLec.consumo);

   /* Clave de consumo (vacio) */
   strcat(sLinea, "\"\";");

   /* Tipo de Medida */
   if(sTipo[0]=='A'){
      strcat(sLinea, "\"ACTI\";");
   }else{
      strcat(sLinea, "\"REAC\";");
   }
   
   /* External ID */
   if(sTipo[0]=='A')
        sprintf(sLinea, "%s\"%dACTI%ldCNSARG\";", sLinea, regLec.corr_facturacion, regLec.numero_cliente);
   else
        sprintf(sLinea, "%s\"%dREAC%ldCNSARG\";", sLinea, regLec.corr_facturacion, regLec.numero_cliente);
   
   /* Fecha Facturacion */
   sprintf(sLinea, "%s\"%s\";", sLinea, regLec.fecha_facturacion);

   /* Nro.de Medidor + marca + modelo */
   sprintf(sLinea, "%s\"%ld%s%s\";", sLinea, regLec.numero_medidor, regLec.marca_medidor, regLec.modelo_medidor);
   
   /* Coseno Phi */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, regLec.coseno_phi);

	strcat(sLinea, "\n");
	
	iRcv=fprintf(fp, sLinea);

   if(iRcv < 0){
      printf("Error al escribir Consumos\n");
      exit(1);
   }	
	
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



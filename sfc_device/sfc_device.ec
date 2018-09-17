/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_device
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura DEVICE (medidores)
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_device.h";

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

/* Variables Globales Host */
$ClsMedidor	regMedidor;

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
	
   setlocale(LC_ALL, "es_ES.UTF-8");
   setlocale(LC_NUMERIC, "en_US");
   
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
	
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/

	$OPEN curMedidores;

	fp=pFileMedidorUnx;

	while(LeoMedidores(&regMedidor)){
      if(!CargaEstadoSFC(&regMedidor)){
         printf("Fallo CargaEstadoSFC\n");
         exit(1);
      }
		if (!GenerarPlano(fp, regMedidor)){
         printf("Fallo GenearPlano\n");
			exit(1);	
		}
					
		cantProcesada++;
	}
	
	$CLOSE curMedidores;
			
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
	printf("DEVICE\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Medidores Procesados :       %ld \n",cantProcesada);
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

	if(argc != 3 ){
		MensajeParametros();
		return 0;
	}

   giTipoCorrida = atoi(argv[2]);
   
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
      printf("	<Tipo Corrida> 0=Normal, 1=Reducida.\n");
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   
   memset(sTitulos, '\0', sizeof(sTitulos));
	
	memset(sArchMedidorUnx,'\0',sizeof(sArchMedidorUnx));
	memset(sArchMedidorAux,'\0',sizeof(sArchMedidorAux));
   memset(sArchMedidorDos,'\0',sizeof(sArchMedidorDos));
   memset(sFecha,'\0',sizeof(sFecha));
	memset(sSoloArchivoMedidor,'\0',sizeof(sSoloArchivoMedidor));

	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
   
	RutaArchivos( sPathSalida, "SALESF" );
   
	alltrim(sPathSalida,' ');

	sprintf( sArchMedidorUnx  , "%sT1DEVICE.unx", sPathSalida );
   sprintf( sArchMedidorAux  , "%sT1DEVICE.aux", sPathSalida );
   sprintf( sArchMedidorDos  , "%senel_care_device_t1_%s.csv", sPathSalida, sFecha );

	strcpy( sSoloArchivoMedidor, "T1DEVICE.unx");

	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
	if( !pFileMedidorUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
		return 0;
	}
	
   strcpy(sTitulos,"\"Marca Medidor\";\"Modelo Medidor\";\"Nro.Medidor\";\"Propiedad Medidor\";\"Tipo Medidor\";\"Punto de Suministro\";\"External ID\";\"Estado Medidor\";\"Fecha Ult.Instalacion\";\"Constante\";\"Fecha Fabricacion\";\"Fecha Instalacion\";\n");

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

	/******** Cursor Principal  SFC *************/
	strcpy(sql, "SELECT me.med_numero, "); 
	strcat(sql, "me.mar_codigo, "); 
	strcat(sql, "me.mod_codigo, "); 
	strcat(sql, "me.med_estado, ");
	strcat(sql, "me.med_ubic, ");
	strcat(sql, "me.med_codubic, ");
	strcat(sql, "me.numero_cliente, ");
	strcat(sql, "mo.tipo_medidor, ");
	strcat(sql, "TO_CHAR(m.fecha_prim_insta, '%Y-%m-%d'), ");
	strcat(sql, "TO_CHAR(m.fecha_ult_insta, '%Y-%m-%d'), ");
	strcat(sql, "m.constante, ");
	strcat(sql, "me.med_anio ");
   
	strcat(sql, "FROM medid m, medidor me, modelo mo ");
if(giTipoCorrida == 1){
   strcat(sql, ", migra_sf ma ");
}
	strcat(sql, "WHERE m.estado = 'I' ");
	strcat(sql, "AND me.med_numero = m.numero_medidor ");
	strcat(sql, "AND me.mar_codigo = m.marca_medidor ");
	strcat(sql, "AND me.mod_codigo = m.modelo_medidor ");
     
	strcat(sql, "AND me.med_tarifa = 'T1' "); 
	strcat(sql, "AND me.mar_codigo NOT IN ('000', 'AGE') "); 
	strcat(sql, "AND me.med_anio != 2019 "); 
	strcat(sql, "AND mo.mar_codigo = me.mar_codigo "); 
	strcat(sql, "AND mo.mod_codigo = me.mod_codigo "); 
if(giTipoCorrida == 1){
   strcat(sql, "AND ma.numero_cliente = m.numero_cliente ");
}   

	$PREPARE selMedidores FROM $sql;
	
	$DECLARE curMedidores CURSOR FOR selMedidores;	

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

short LeoMedidores(regMed)
$ClsMedidor *regMed;
{
	InicializaMedidor(regMed);

	$FETCH curMedidores into
		:regMed->numero,
		:regMed->marca,
		:regMed->modelo,
		:regMed->estado,	
		:regMed->med_ubic, 
		:regMed->med_codubic,
		:regMed->numero_cliente,
		:regMed->tipo_medidor,
		:regMed->fecha_prim_insta,
		:regMed->fecha_ult_insta,
		:regMed->constante,
		:regMed->med_anio;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Medidores !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

	
	return 1;	
}

void InicializaMedidor(regMed)
$ClsMedidor	*regMed;
{
   rsetnull(CLONGTYPE, (char *) &(regMed->numero));
	memset(regMed->marca, '\0', sizeof(regMed->marca));
	memset(regMed->modelo, '\0', sizeof(regMed->modelo));
   memset(regMed->estado, '\0', sizeof(regMed->estado));
	memset(regMed->med_ubic, '\0', sizeof(regMed->med_ubic));
	memset(regMed->med_codubic, '\0', sizeof(regMed->med_codubic));
	rsetnull(CLONGTYPE, (char *) &(regMed->numero_cliente));
	memset(regMed->tipo_medidor, '\0', sizeof(regMed->tipo_medidor));
   memset(regMed->estado_sfc, '\0', sizeof(regMed->estado_sfc));
   memset(regMed->fecha_prim_insta, '\0', sizeof(regMed->fecha_prim_insta));
   memset(regMed->fecha_ult_insta, '\0', sizeof(regMed->fecha_ult_insta));
	rsetnull(CFLOATTYPE, (char *) &(regMed->constante));
	rsetnull(CINTTYPE, (char *) &(regMed->med_anio));
	
}

short CargaEstadoSFC(regMed)
$ClsMedidor *regMed;
{

   switch(regMed->estado[0]){
      case 'Z':
      case 'U':
         /* No Disponible*/
         strcpy(regMed->estado_sfc, "R");
         break;
      default:
      	switch(regMed->med_ubic[0]){
      		case 'C':	/* En el cliente*/
               strcpy(regMed->estado_sfc, "I");
               break;
            case 'D':  /* Bodega */
            case 'L':  /* Laboratorio */
            case 'F':  /* En Fabrica */
               strcpy(regMed->estado_sfc, "R");
               break;
            case 'O':  /* Contratista */
            case 'S':	/* En Sucursal */
               strcpy(regMed->estado_sfc, "D");
               break;
         }
         break;
   }
	
	return 1;
}

short GenerarPlano(fp, regMed)
FILE 				*fp;
$ClsMedidor			regMed;
{
	char	sLinea[1000];	

	memset(sLinea, '\0', sizeof(sLinea));
	
   /* Marca Medidor */
   sprintf(sLinea, "\"%s\";", regMed.marca);
   
   /* Modelo Medidor */
   sprintf(sLinea, "%s\"%s\";", sLinea, regMed.modelo);
   
   /* Nro.Medidor */
   sprintf(sLinea, "%s\"%ld\";", sLinea, regMed.numero);
   
   /* Propiedad */
   strcat(sLinea, "\"C\";");
   
   /* Tipo Medidor */
   if(regMed.tipo_medidor[0]=='R'){
      strcat(sLinea, "\"REAC\";");
   }else{
      strcat(sLinea, "\"ACTI\";");
   }
   
   /* Punto Suministro */
   if(regMed.med_ubic[0]=='C'){
      if(regMed.numero_cliente > 0){
         sprintf(sLinea, "%s\"%ldAR\";", sLinea, regMed.numero_cliente);
      }else{
         strcat(sLinea, "\"\";");
      }
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* External ID */
   sprintf(sLinea, "%s\"%ld%s%sDEVARG\";", sLinea, regMed.numero, regMed.marca, regMed.modelo);
   
   /* Estado Medidor */
   sprintf(sLinea, "%s\"%s\";", sLinea, regMed.estado_sfc);

   /* Fecha Ult.Instalacion */
   sprintf(sLinea, "%s\"%s\";", sLinea, regMed.fecha_ult_insta);
   /* Constante */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, regMed.constante);
   
   /* Fecha Fabricación */
   sprintf(sLinea, "%s\"%d\";", sLinea, regMed.med_anio);
   /* Fecha Retiro */
   /*sprintf(sLinea, "%s\"%s\";", sLinea, regMed.fecha_prim_insta);*/
   strcat(sLinea, "\"\";");

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



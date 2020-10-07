/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_convenios
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura DEVICE (medidores)
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Tipo Corrida>: 0 = Normal; 1 = Reducida
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_convenios.h";

/* Variables Globales */
int   giTipoCorrida;
FILE	*pFileUnx;

char	sArchivoUnx[100];
char	sArchivoAux[100];
char	sArchivoDos[100];
char	sSoloArchivo[100];

char	sArchLog[100];
char	sPathSalida[100];
char	FechaGeneracion[9];	
char	MsgControl[100];
$char	fecha[9];
long	lCorrelativo;

long	cantProcesada;
long 	cantPreexistente;
long	iContaLog;

char  gsDesdeFmt[9];
char  gsHastaFmt[9];

/* Variables Globales Host */
$ClsConve	regConve;
$long       glFechaDesde;
$long       glFechaHasta;

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
	
   fp=pFileUnx;
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/
/*
   $OPEN curClientes;

   while(LeoCliente(&lNroCliente)){
*/   
   	/*$OPEN curConve USING :lNroCliente;*/
   $OPEN curConve USING :glFechaDesde, :glFechaHasta;

   	while(LeoConve(&regConve)){
   		if (!GenerarPlano(fp, regConve)){
            printf("Fallo GenearPlano\n");
   			exit(1);	
   		}
   		cantProcesada++;
   	}
   	
   	$CLOSE curConve;
      
/*      
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
	printf("CONVENIOS\n");
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
   char  sFechaDesde[11];
   char  sFechaHasta[11];
   
   memset(sFechaDesde, '\0', sizeof(sFechaDesde));
   memset(sFechaHasta, '\0', sizeof(sFechaHasta));

   memset(gsDesdeFmt, '\0', sizeof(gsDesdeFmt));
   memset(gsHastaFmt, '\0', sizeof(gsHastaFmt));
   
	if(argc < 3  || argc >5){
		MensajeParametros();
		return 0;
	}
	
   giTipoCorrida=atoi(argv[2]);
   
   if(argc==5){
      strcpy(sFechaDesde, argv[3]); 
      strcpy(sFechaHasta, argv[4]);
      rdefmtdate(&glFechaDesde, "dd/mm/yyyy", sFechaDesde); 
      rdefmtdate(&glFechaHasta, "dd/mm/yyyy", sFechaHasta);
      
      sprintf(gsDesdeFmt, "%c%c%c%c%c%c%c%c", sFechaDesde[6], sFechaDesde[7],sFechaDesde[8],sFechaDesde[9],
                  sFechaDesde[3],sFechaDesde[4], sFechaDesde[0],sFechaDesde[1]);      

      sprintf(gsHastaFmt, "%c%c%c%c%c%c%c%c", sFechaHasta[6], sFechaHasta[7],sFechaHasta[8],sFechaHasta[9],
                  sFechaHasta[3],sFechaHasta[4], sFechaHasta[0],sFechaHasta[1]);      
       
   }else{
      glFechaDesde=-1;
      glFechaDesde=-1;
   }
	
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
		printf("	<Tipo Corrida> 0=total, 1=Reducida, 3=Delta.\n");
      printf("	<Fecha Desde> = dd/mm/aaaa.\n");
      printf("	<Fecha Hasta> = dd/mm/aaaa.\n");
      
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   int   iRcv;
   
   memset(sTitulos, '\0', sizeof(sTitulos));
	
	memset(sArchivoUnx,'\0',sizeof(sArchivoUnx));
	memset(sArchivoAux,'\0',sizeof(sArchivoAux));
   memset(sArchivoDos,'\0',sizeof(sArchivoDos));
	memset(sSoloArchivo,'\0',sizeof(sSoloArchivo));
	memset(sFecha,'\0',sizeof(sFecha));

	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
   
	RutaArchivos( sPathSalida, "SALESF" );
   
	alltrim(sPathSalida,' ');

	sprintf( sArchivoUnx  , "%sT1CONVENIOS.unx", sPathSalida );
   sprintf( sArchivoAux  , "%sT1CONVENIOS.aux", sPathSalida );
   sprintf( sArchivoDos  , "%senel_care_agreement_t1_%s_%s.csv", sPathSalida, gsDesdeFmt, gsHastaFmt);

	strcpy( sSoloArchivo, "T1CONVENIOS.unx");

	pFileUnx=fopen( sArchivoUnx, "w" );
	if( !pFileUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchivoUnx );
		return 0;
	}
	
   strcpy(sTitulos, "\"External Id\";");
   strcat(sTitulos, "\"Tipo\";");
   strcat(sTitulos, "\"Opción de Convenio\";");
   strcat(sTitulos, "\"Estado\";");
   strcat(sTitulos, "\"Fecha inicio\";");
   strcat(sTitulos, "\"Fecha fin\";");
   strcat(sTitulos, "\"Deuda inicial\";");
   strcat(sTitulos, "\"Pie\";");
   strcat(sTitulos, "\"Deuda pendiente\";");
   strcat(sTitulos, "\"Valor cuota\";");
   strcat(sTitulos, "\"Valor última cuota\";");
   strcat(sTitulos, "\"Total de cuotas\";");
   strcat(sTitulos, "\"Cuota actual\";");
   strcat(sTitulos, "\"Tasa\";");
   strcat(sTitulos, "\"Contacto\";");
   strcat(sTitulos, "\"Usuario creador\";");
   strcat(sTitulos, "\"Usuario término\";");
   strcat(sTitulos, "\"Total intereses\";");
   strcat(sTitulos, "\"Impuesto interés\";");
   strcat(sTitulos, "\"Descripcion seguro indexado\";");
   strcat(sTitulos, "\"Compañía de seguro\";");
   strcat(sTitulos, "\"Fecha inicio de seguro\";");
   strcat(sTitulos, "\"Fecha término del seguro\";");
   strcat(sTitulos, "\"Valor prima del seguro\";");
   strcat(sTitulos, "\"Número de cuotas\";");
   strcat(sTitulos, "\"Estado seguro\";");
   strcat(sTitulos, "\"Fecha de baja\";");
   strcat(sTitulos, "\"Motivo de baja\";");
   strcat(sTitulos, "\"Suministro\";");
   strcat(sTitulos, "\"Cuenta\";");
   strcat(sTitulos, "\"Company\"");
   strcat(sTitulos, "\n");
   
   iRcv=fprintf(pFileUnx, sTitulos);
   if(iRcv<0){
      printf("Error al grabar CONVENIOS\n");
      exit(1);
   }
   
      
	return 1;	
}

void CerrarArchivos(void)
{
	fclose(pFileUnx);

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

   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchivoUnx, sArchivoAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchivoAux, sArchivoDos);
   iRcv=system(sCommand);
   
/*
   sprintf(sCommand, "unix2dos %s | tr -d '\26' > %s", sArchivoUnx, sArchivoDos);
	iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchivoDos);
	iRcv=system(sCommand);
*/	
	sprintf(sCommand, "cp %s %s", sArchivoDos, sPathCp);
	iRcv=system(sCommand);
  
   sprintf(sCommand, "rm %s", sArchivoUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchivoAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchivoDos);
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

   /******** Cursor CONVE SE modificó para que levante las actualizacion x facturacion ****************/
	strcpy(sql, "SELECT c.numero_cliente, ");
	strcat(sql, "c.corr_convenio, ");
	strcat(sql, "t1.cod_sf1, "); /* opcion convenio */
	strcat(sql, "c.estado, ");
	strcat(sql, "TO_CHAR(c.fecha_creacion, '%Y-%m-%d'), ");
	strcat(sql, "TO_CHAR(c.fecha_termino, '%Y-%m-%d'), ");
	strcat(sql, "c.deuda_origen, ");
	strcat(sql, "c.valor_cuota_ini, ");
	strcat(sql, "c.deuda_convenida, ");
	strcat(sql, "c.valor_cuota, ");
	strcat(sql, "c.numero_tot_cuotas, ");
	strcat(sql, "c.numero_ult_cuota, ");
	strcat(sql, "c.intereses, ");
	strcat(sql, "c.usuario_creacion, "); 
	strcat(sql, "c.usuario_termino ");
	strcat(sql, "FROM conve c, OUTER sf_transforma t1 ");
if(giTipoCorrida==1){
   strcat(sql, ", migra_sf ma ");
}
   strcat(sql, "WHERE c.estado = 'V' ");
   strcat(sql, "AND t1.clave = 'OPCONVE'  ");
   strcat(sql, "AND t1.cod_mac = c.opcion_convenio  ");
if(giTipoCorrida==1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}

	strcat(sql, "UNION ");
	
	strcat(sql, "SELECT c2.numero_cliente, ");
	strcat(sql, "c2.corr_convenio, ");
	strcat(sql, "t2.cod_sf1, "); /* opcion convenio */
	strcat(sql, "c2.estado, ");
	strcat(sql, "TO_CHAR(c2.fecha_creacion, '%Y-%m-%d'), ");
	strcat(sql, "TO_CHAR(c2.fecha_termino, '%Y-%m-%d'), ");
	strcat(sql, "c2.deuda_origen, ");
	strcat(sql, "c2.valor_cuota_ini, ");
	strcat(sql, "c2.deuda_convenida, ");
	strcat(sql, "c2.valor_cuota, ");
	strcat(sql, "c2.numero_tot_cuotas, ");
	strcat(sql, "c2.numero_ult_cuota, ");
	strcat(sql, "c2.intereses, ");
	strcat(sql, "c2.usuario_creacion, "); 
	strcat(sql, "c2.usuario_termino ");
	strcat(sql, "FROM conve c2, OUTER sf_transforma t2 ");
if(giTipoCorrida==1){
   strcat(sql, ", migra_sf ma2 ");
}
	strcat(sql, "WHERE c2.estado != 'V' ");
   strcat(sql, "AND c2.fecha_termino BETWEEN ? AND ? ");
   strcat(sql, "AND t2.clave = 'OPCONVE'  ");
   strcat(sql, "AND t2.cod_mac = c2.opcion_convenio  ");
if(giTipoCorrida==1){
   strcat(sql, "AND ma2.numero_cliente = c2.numero_cliente ");
}   
   
	$PREPARE selConve FROM $sql;
	
	$DECLARE curConve CURSOR WITH HOLD FOR selConve;

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


short LeoConve(reg)
$ClsConve *reg;
{
	InicializaConve(reg);

	$FETCH curConve INTO
      :reg->numero_cliente,
      :reg->corr_convenio,
      :reg->opcion_convenio,
      :reg->estado,
      :reg->fecha_creacion,
      :reg->fecha_termino,
      :reg->deuda_origen,
      :reg->valor_cuota_ini,
      :reg->deuda_convenida,
      :reg->valor_cuota,
      :reg->numero_tot_cuotas,
      :reg->numero_ult_cuota,
      :reg->intereses,
      :reg->usuario_creacion, 
      :reg->usuario_termino;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Lecturas !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			
   
   alltrim(reg->usuario_creacion, ' ');
   alltrim(reg->usuario_termino, ' ');
   alltrim(reg->fecha_termino, ' ');
            
	return 1;	
}

void InicializaConve(reg)
$ClsConve	*reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   rsetnull(CINTTYPE, (char *) &(reg->corr_convenio));
   memset(reg->opcion_convenio, '\0', sizeof(reg->opcion_convenio));
   memset(reg->estado, '\0', sizeof(reg->estado));
   memset(reg->fecha_creacion, '\0', sizeof(reg->fecha_creacion));
   memset(reg->fecha_termino, '\0', sizeof(reg->fecha_termino));
   rsetnull(CDOUBLETYPE, (char *) &(reg->deuda_origen));
   rsetnull(CDOUBLETYPE, (char *) &(reg->valor_cuota_ini));
   rsetnull(CDOUBLETYPE, (char *) &(reg->deuda_convenida));
   rsetnull(CDOUBLETYPE, (char *) &(reg->valor_cuota));
   rsetnull(CINTTYPE, (char *) &(reg->numero_tot_cuotas));
   rsetnull(CINTTYPE, (char *) &(reg->numero_ult_cuota));
   rsetnull(CFLOATTYPE, (char *) &(reg->intereses));
   memset(reg->usuario_creacion, '\0', sizeof(reg->usuario_creacion)); 
   memset(reg->usuario_termino, '\0', sizeof(reg->usuario_termino));

}


short GenerarPlano(fp, reg)
FILE 				*fp;
$ClsConve		reg;
{
	char	sLinea[1000];	
   int   iRcv;
   
	memset(sLinea, '\0', sizeof(sLinea));

   /* External Id */
   sprintf(sLinea, "\"%ld%dAGRARG\";", reg.numero_cliente, reg.corr_convenio );
   /* Tipo */
   strcat(sLinea, "\"\";");
   /* Opción de Convenio */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.opcion_convenio);
   /* Estado */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.estado);
   /* Fecha inicio */
   /*sprintf(sLinea, "%s\"%sT00:00:00.000-03:00\";", sLinea, reg.fecha_creacion);*/
   sprintf(sLinea, "%s\"%sT00:00:00.000Z\";", sLinea, reg.fecha_creacion);
   /* Fecha fin */
   if(strcmp(reg.fecha_termino, "")!= 0 ){
      /*sprintf(sLinea, "%s\"%sT00:00:00.000-03:00\";", sLinea, reg.fecha_termino);*/
      sprintf(sLinea, "%s\"%sT00:00:00.000Z\";", sLinea, reg.fecha_termino);
   }else{
      strcat(sLinea, "\"\";");
   }
   /* Deuda inicial */
   /*sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.deuda_origen);*/
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.deuda_origen);
   /* Pie */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.valor_cuota_ini);
   /* Deuda pendiente */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.deuda_convenida);   
   /* Valor cuota */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.valor_cuota);
   /* Valor última cuota */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.valor_cuota);
   /* Total de cuotas */
   sprintf(sLinea, "%s\"%d\";", sLinea, reg.numero_tot_cuotas);
   /* Cuota actual */
   sprintf(sLinea, "%s\"%d\";", sLinea, reg.numero_ult_cuota);
   /* Tasa */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.intereses);
   /* Contacto */
   sprintf(sLinea, "%s\"%ldARG\";",sLinea, reg.numero_cliente);
   /* Usuario creador */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.usuario_creacion);
   /* Usuario término */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.usuario_termino);
   /* Total intereses */
   strcat(sLinea, "\"\";");
   /* Impuesto interés */
   strcat(sLinea, "\"\";");
   /* Descripcion seguro indexado */
   strcat(sLinea, "\"\";");
   /* Compañía de seguro */
   strcat(sLinea, "\"\";");
   /* Fecha inicio de seguro */
   strcat(sLinea, "\"\";");
   /* Fecha término del seguro */
   strcat(sLinea, "\"\";");
   /* Valor prima del seguro */
   strcat(sLinea, "\"\";");
   /* Número de cuotas */
   sprintf(sLinea, "%s\"%d\";", sLinea, reg.numero_tot_cuotas);
   /* Estado seguro */
   strcat(sLinea, "\"\";");
   /* Fecha de baja */
   strcat(sLinea, "\"\";");
   /* Motivo de baja */
   strcat(sLinea, "\"\";");
   /* Suministro */
   sprintf(sLinea, "%s\"%ldAR\";",sLinea, reg.numero_cliente);
   /* Cuenta */
	sprintf(sLinea, "%s\"%ldARG\";",sLinea, reg.numero_cliente);
   /* Company */
   strcat(sLinea, "\"9\";");

	strcat(sLinea, "\n");
	
	iRcv=fprintf(fp, sLinea);
   if(iRcv<0){
      printf("Error al grabar CONVENIOS\n");
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



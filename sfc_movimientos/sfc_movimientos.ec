/********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_device

	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa :
		Extractor que genera el archivo plano para las estructura MOVIMIENTOS (pagos)

	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
      <Tipo Corrida> : 0=Normal, 1=Reducida

********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_movimientos.h";

/* Variables Globales */
int   giTipoCorrida;

FILE	*pFileUnx;

char	sArchUnx[100];
char	sArchAux[100];
char	sArchDos[100];
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

/* Variables Globales Host */
$ClsPago	regPago;
$char    gsFechaDesde[20];
$char    gsFechaHasta[20];

char     gsDesdeFmt[9];
char     gsHastaFmt[9];

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
$long lCorrPago;
long     iFactu;
long  lCantLineas;
int   iCantFiles;

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
	cantProcesada=0;
	cantPreexistente=0;
	iContaLog=0;

   fp=pFileUnx;
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/
   iCantFiles=1;
   lCantLineas=0;
	if(!AbreArchivos(iCantFiles)){
		exit(1);
	}
/*   
   $OPEN curClientes;

   while(LeoCliente(&lNroCliente, &lCorrPago)){
   
      if(giTipoCorrida ==3){
         $OPEN curPagos USING :lNroCliente, :gsFechaDesde, :gsFechaHasta;
      }else{
         $OPEN curPagos  USING :lNroCliente;
      }
*/
      $OPEN curPagos USING :gsFechaDesde, :gsFechaHasta;
      
   	while(LeoPagos(&regPago)){
   		if (!GenerarPlano(fp, regPago)){
            printf("Fallo GenearPlano\n");
   			exit(1);
   		}
   		iFactu++;
         lCantLineas++;
         if(lCantLineas>450000){
            iCantFiles++;
            fclose(pFileUnx);
            MoverArchivos();
         	if(!AbreArchivos(iCantFiles)){
         		exit(1);
         	}
            lCantLineas=0;
         }
         cantProcesada++;
   	}

   	$CLOSE curPagos;
/*      
      cantProcesada++;
   }

   $CLOSE curClientes;
*/
	CerrarArchivos();

   MoverArchivos();
	/*FormateaArchivos();*/

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
	printf("MOVIMIENTOS\n");
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

	if(argc < 3 || argc > 5 ){
		MensajeParametros();
		return 0;
	}

   giTipoCorrida=atoi(argv[2]);

   memset(gsDesdeFmt, '\0', sizeof(gsDesdeFmt));
   memset(gsHastaFmt, '\0', sizeof(gsHastaFmt));
   
   if(argc==5){
      giTipoCorrida=3;
      strcpy(gsFechaDesde, argv[3]);
      strcat(gsFechaDesde, " 00:00:00");
      strcpy(gsFechaHasta, argv[4]);
      strcat(gsFechaHasta, " 23:59:59");
      
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
      printf("	<Tipo Corrida> 0=Normal, 1=reducida, 3=Delta.\n");
      printf("	<Fecha Desde (Opcional)> aaaa-mm-dd.\n");
      printf("	<Fecha Hasta (Opcional)> aaaa-mm-dd.\n");
}

short AbreArchivos(iCant)
int   iCant;
{
   char  sTitulos[10000];
   $char sFecha[9];
   int   iRcv;
   
   memset(sTitulos, '\0', sizeof(sTitulos));

	memset(sArchUnx,'\0',sizeof(sArchUnx));
	memset(sArchAux,'\0',sizeof(sArchAux));
   memset(sArchDos,'\0',sizeof(sArchDos));
	memset(sSoloArchivo,'\0',sizeof(sSoloArchivo));
	memset(sFecha,'\0',sizeof(sFecha));

	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
	RutaArchivos( sPathSalida, "SALESF" );

	alltrim(sPathSalida,' ');

	sprintf( sArchUnx  , "%sT1MOVIMIENTOS.unx", sPathSalida );
   sprintf( sArchAux  , "%sT1MOVIMIENTOS.aux", sPathSalida );
   sprintf( sArchDos  , "%senel_care_payment_t1_%s_%s_%d.csv", sPathSalida, gsDesdeFmt, gsHastaFmt, iCant );

	strcpy( sSoloArchivo, "T1MOVIMIENTOS.unx");

	pFileUnx=fopen( sArchUnx, "w" );
	if( !pFileUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchUnx );
		return 0;
	}

   strcpy(sTitulos,"\"Cuenta\";");
   strcat(sTitulos, "\"Suministro\";");
   strcat(sTitulos, "\"Tipo de movimiento\";");
   strcat(sTitulos, "\"Número documento\";");
   strcat(sTitulos, "\"Fecha de movimiento\";");
   strcat(sTitulos, "\"Fecha de vencimiento\";");
   strcat(sTitulos, "\"Monto de evento\";");
   strcat(sTitulos, "\"Deuda\";");
   strcat(sTitulos, "\"Tipo de documento\";");
   strcat(sTitulos, "\"Numero interno documento\";");
   strcat(sTitulos, "\"Sentido\";");
   strcat(sTitulos, "\"External Id\";");
   strcat(sTitulos, "\"Factura\";");
   strcat(sTitulos, "\"Monto energía\";");
   strcat(sTitulos, "\"Monto convenio energía\";");
   strcat(sTitulos, "\"Monto productos y servicios\";");
   strcat(sTitulos, "\"Saldo actual\";");
   strcat(sTitulos, "\"Fecha ingreso de pago\";");
   strcat(sTitulos, "\"Fecha ingreso sistema\";");
   strcat(sTitulos, "\"Fecha amortización de pago\";");
   strcat(sTitulos, "\"Monto\";");
   strcat(sTitulos, "\"Medio de pago\";");
   strcat(sTitulos, "\"Lugar de pago\";");
   strcat(sTitulos, "\"Cajero\";");
   strcat(sTitulos, "\"Oficina\";");
   strcat(sTitulos, "\"Intereses\";");
   strcat(sTitulos, "\"Moneda\";");
   strcat(sTitulos, "\"Compañía\";");
   strcat(sTitulos, "\"Impuestos\";");
   strcat(sTitulos, "\"Cuota Convenio\";");

   strcat(sTitulos, "\r\n");

   iRcv=fprintf(pFileUnx, sTitulos);
   if(iRcv < 0){
      printf("Error al escribir Titulos Movimientos\n");
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
/*
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchUnx, sArchAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchAux, sArchDos);
   iRcv=system(sCommand);

	sprintf(sCommand, "chmod 777 %s", sArchDos);
	iRcv=system(sCommand);


	sprintf(sCommand, "cp %s %s", sArchDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchDos);
   iRcv=system(sCommand);
*/
}

void MoverArchivos(){
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

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchUnx, sArchDos);
   iRcv=system(sCommand);

	sprintf(sCommand, "chmod 777 %s", sArchDos);
	iRcv=system(sCommand);


	sprintf(sCommand, "cp %s %s", sArchDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchDos);
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
	strcpy(sql, "SELECT c.numero_cliente, c.corr_pagos FROM cliente c ");
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
/*
	strcat(sql, "AND c.numero_cliente in (4800357,16438731,1264483,4653951,92925, ");
	strcat(sql, "1713531,3462534,4059718,3993280,234141,1193843,4330513,4792161, ");
	strcat(sql, "4720162,1265644,4598873,4718298,1889341,1179409,3462707,1072826, ");
	strcat(sql, "1234103,563665,3173268) ");
*/
	$PREPARE selClientes FROM $sql;

	$DECLARE curClientes CURSOR WITH HOLD FOR selClientes;

   /******** Cursor PAGOS  ****************/
	strcpy(sql, "SELECT h.numero_cliente, ");
	strcat(sql, "h.corr_pagos, ");
	strcat(sql, "h.llave, ");
	strcat(sql, "TO_CHAR(h.fecha_pago, '%Y-%m-%dT%H:%M:%S.000Z'), ");
	strcat(sql, "TO_CHAR(h.fecha_actualiza, '%Y-%m-%dT%H:%M:%S.000Z'), ");
	strcat(sql, "h.tipo_pago, ");
	strcat(sql, "c1.descripcion, ");
	strcat(sql, "h.cajero, ");
	strcat(sql, "h.oficina, ");
	strcat(sql, "h.sucursal, ");
	strcat(sql, "h.valor_pago, ");
	strcat(sql, "h.centro_emisor, ");
	strcat(sql, "h.tipo_docto, ");
	strcat(sql, "h.nro_docto_asociado, ");
	strcat(sql, "c1.tipo_mov, ");
   strcat(sql, "o.nombre ");
	strcat(sql, "FROM hispa h, conce c1, OUTER oficinas o ");
if(giTipoCorrida==1){
   strcat(sql, ", migra_sf ma ");
}
   

   
   if(giTipoCorrida==3){
      strcat(sql, "WHERE h.fecha_pago BETWEEN ? AND ? ");   
   }else{
	   strcat(sql, "WHERE h.numero_cliente = ? ");   
      strcat(sql, "AND h.fecha_actualiza >= TODAY - 370 ");
      /*strcat(sql, "AND h.corr_pagos >= ? ");*/
   }
	strcat(sql, "AND c1.codigo_concepto = h.tipo_pago ");
	strcat(sql, "AND o.oficina = h.oficina ");
	strcat(sql, "AND o.sucursal = '0000' ");
if(giTipoCorrida==1){
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}
/*   
	strcat(sql, "ORDER BY h.corr_pagos ASC ");
*/
	$PREPARE selPagos FROM $sql;

	$DECLARE curPagos CURSOR WITH HOLD FOR selPagos;

	/******** Select Cajero ****************/
	strcpy(sql, "SELECT FIRST 1 nombre FROM cajer ");
	strcat(sql, "WHERE sucursal = ? ");
	strcat(sql, "AND cajero = ? ");

   $PREPARE selCajero FROM $sql;

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

short LeoCliente(lNroCliente, lCorrPago)
$long *lNroCliente;
$long *lCorrPago;
{
   $long nroCliente;
   $long correlativo;

   $FETCH curClientes INTO :nroCliente, :correlativo;

    if ( SQLCODE != 0 ){
        return 0;
    }

    correlativo=correlativo-12;
    if(correlativo <= 0)
      correlativo=1;
      
   *lNroCliente = nroCliente;
   *lCorrPago=correlativo;

   return 1;
}


short LeoPagos(reg)
$ClsPago *reg;
{
$long lCorrRefactu;
$int  iCantidad;
$char sFechaFactuMax[20];

	InicializaPago(reg);

	$FETCH curPagos INTO
      :reg->numero_cliente,
      :reg->corr_pagos,
      :reg->llave,
      :reg->fecha_pago,
      :reg->fecha_actualiza,
      :reg->tipo_pago,
      :reg->descripcion,
      :reg->cajero,
      :reg->oficina,
      :reg->sucursal,
      :reg->valor_pago,
      :reg->centro_emisor,
      :reg->tipo_docto,
      :reg->nro_docto_asociado,
      :reg->tipo_mov,
      :reg->lugarPago;

    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Pagos !!!\nProceso Abortado.\n");
			exit(1);
		}
    }

   $EXECUTE selCajero INTO :reg->nombre_cajero
         USING :reg->sucursal,
               :reg->cajero;

   if ( SQLCODE != 0 ){
      /*printf("Error leyendo nombre Cajero para sucursal %s cajero %s\n", reg->sucursal, reg->cajero);*/
      strcpy(reg->nombre_cajero, reg->cajero);
   }

   alltrim(reg->descripcion, ' ');
   alltrim(reg->nombre_cajero, ' ');
   alltrim(reg->lugarPago, ' ');

	return 1;
}

void InicializaPago(reg)
$ClsPago	*reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   rsetnull(CINTTYPE, (char *) &(reg->corr_pagos));
   rsetnull(CLONGTYPE, (char *) &(reg->llave));

   memset(reg->fecha_pago, '\0', sizeof(reg->fecha_pago));
   memset(reg->fecha_actualiza, '\0', sizeof(reg->fecha_actualiza));
   memset(reg->tipo_pago, '\0', sizeof(reg->tipo_pago));
   memset(reg->descripcion, '\0', sizeof(reg->descripcion));
   memset(reg->cajero, '\0', sizeof(reg->cajero));
   memset(reg->oficina, '\0', sizeof(reg->oficina));
   memset(reg->sucursal, '\0', sizeof(reg->sucursal));

   rsetnull(CDOUBLETYPE, (char *) &(reg->valor_pago));

   memset(reg->centro_emisor, '\0', sizeof(reg->centro_emisor));
   memset(reg->tipo_docto, '\0', sizeof(reg->tipo_docto));

   rsetnull(CLONGTYPE, (char *) &(reg->nro_docto_asociado));

   memset(reg->tipo_mov, '\0', sizeof(reg->tipo_mov));
   memset(reg->nombre_cajero, '\0', sizeof(reg->nombre_cajero));
   memset(reg->lugarPago, '\0', sizeof(reg->lugarPago));
}



short GenerarPlano(fp, reg)
FILE 				*fp;
$ClsPago		reg;
{
	char	sLinea[1000];
   int   iRcv;

	memset(sLinea, '\0', sizeof(sLinea));

   /* Cuenta */
   sprintf(sLinea, "\"%ldARG\";", reg.numero_cliente);

   /* Suministro */
   sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.numero_cliente);

   /* Tipo de movimiento */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.tipo_mov);

   /* Número documento */
   sprintf(sLinea, "%s\"%ld\";", sLinea, reg.llave);

   /* Fecha de movimiento */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_pago);

   /* Fecha de vencimiento */
   strcat(sLinea, "\"\";");

   /* Monto de evento */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.valor_pago);

   /* Deuda */
   strcat(sLinea, "\"\";");

      /* Tipo de documento */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.tipo_pago);

   /* Numero interno documento */
   sprintf(sLinea, "%s\"%ld\";", sLinea, reg.llave);

   /* Sentido */
   strcat(sLinea, "\"C\";");

   /* External Id */
   sprintf(sLinea, "%s\"%ld%ld-%ldMOVARG\";", sLinea, reg.llave, reg.numero_cliente, reg.corr_pagos);

   /* Factura */
   sprintf(sLinea, "%s\"%ld%s%s%ldINVARG\";", sLinea, reg.numero_cliente, reg.centro_emisor, reg.tipo_docto, reg.nro_docto_asociado);

   /* Monto energía */
   strcat(sLinea, "\"\";");
   /* Monto convenio energía */
   strcat(sLinea, "\"\";");
   /* Monto productos y servicios */
   strcat(sLinea, "\"\";");
   /* Saldo actual */
   strcat(sLinea, "\"\";");

   /* Fecha ingreso de pago */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_pago);

   /* Fecha ingreso sistema */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_actualiza);

   /* Fecha amortización de pago */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_actualiza);

   /* Monto */
   sprintf(sLinea, "%s\"%.02lf\";", sLinea, reg.valor_pago);

   /* Medio de pago */
   strcat(sLinea, "\"\";");
   
   /* Lugar de pago */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.lugarPago);

   /* Cajero */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.nombre_cajero);

   /* Oficina */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.oficina);

   /* Intereses */
   strcat(sLinea, "\"\";");
   /* Moneda */
   strcat(sLinea, "\"ARS\";");
   /* Compañía */
   strcat(sLinea, "\"9\";");
   /* Impuestos */
   strcat(sLinea, "\"\";");
   /* Cuota Convenio */
   strcat(sLinea, "\"\";");

	strcat(sLinea, "\r\n");

	iRcv=fprintf(pFileUnx, sLinea);

   if(iRcv < 0){
      printf("Error al escribir Movimientos\n");
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



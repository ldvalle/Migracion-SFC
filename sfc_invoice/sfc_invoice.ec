/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
    Aplicacion: sfc_device
    
	Fecha : 03/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura DEVICE (medidores)
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Tipo Corrida>: 0=Normal 1=Reducida
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_invoice.h";

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
$ClsFactura	regFactura;
$long glFechaDesde;
$long glFechaHasta;

char  gsDesdeFmt[9];
char  gsHastaFmt[9];
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
long     iFactu;
double   dRecargo;
int      iNroArchivo;
long     lLineas;

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
	if(!AbreArchivos(1)){
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
      iFactu=1;
      if(giTipoCorrida==3){
         $OPEN curFacturas USING :lNroCliente, :glFechaDesde, :glFechaHasta;
      }else{
         $OPEN curFacturas USING :lNroCliente;
      }
*/   	
      iNroArchivo=1;
      lLineas=0;

      $OPEN curFacturas USING :glFechaDesde, :glFechaHasta;
      
   	while(LeoFacturas(&regFactura)){
         regFactura.recargoAnterior=getRecargo(regFactura.numero_cliente, regFactura.corr_facturacion);
/*              
         if(iFactu==1){
            dRecargo=regFactura.suma_recargo;
         }else{
            regFactura.recargoAnterior=dRecargo;
      		if (!GenerarPlano(fp, regFactura)){
               printf("Fallo GenearPlano\n");
      			exit(1);	
      		}
            dRecargo=regFactura.suma_recargo;
         }
         regFactura.recargoAnterior=dRecargo;
*/         
   		if (!GenerarPlano(fp, regFactura)){
            printf("Fallo GenearPlano\n");
   			exit(1);	
   		}
         /*dRecargo=regFactura.suma_recargo;*/
         lLineas++;
         
         if(lLineas>4500000){
            CerrarArchivos();
            FormateaArchivos();
            iNroArchivo++;
           	if(!AbreArchivos(iNroArchivo)){
         		exit(1);	
         	}
            lLineas=0;
         }
   		iFactu++;
   	}
   	
   	$CLOSE curFacturas;
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
	printf("INVOICE\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
/*	printf("Clientes Procesados :       %ld \n",cantProcesada);*/
   printf("Facturas Procesadas :       %ld \n",iFactu);
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

   
	if(argc < 3 || argc >5 ){
		MensajeParametros();
		return 0;
	}
	
   giTipoCorrida=atoi(argv[2]);
   
   if(argc == 5){
      giTipoCorrida=3;/* Modo Delta */
      strcpy(sFechaDesde, argv[3]); 
      strcpy(sFechaHasta, argv[4]);

      sprintf(gsDesdeFmt, "%c%c%c%c%c%c%c%c", sFechaDesde[6], sFechaDesde[7],sFechaDesde[8],sFechaDesde[9],
                  sFechaDesde[3],sFechaDesde[4], sFechaDesde[0],sFechaDesde[1]);      

      sprintf(gsHastaFmt, "%c%c%c%c%c%c%c%c", sFechaHasta[6], sFechaHasta[7],sFechaHasta[8],sFechaHasta[9],
                  sFechaHasta[3],sFechaHasta[4], sFechaHasta[0],sFechaHasta[1]);      
      
      rdefmtdate(&glFechaDesde, "dd/mm/yyyy", sFechaDesde); 
      rdefmtdate(&glFechaHasta, "dd/mm/yyyy", sFechaHasta); 
   }else{
      glFechaDesde=-1;
      glFechaHasta=-1;
   }
	
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
		printf("	<Tipo Corrida> 0=Normal, 1=Reducida, 3=Delta.\n");
      printf("	<Fecha Desde (Opcional)> dd/mm/aaaa.\n");
      printf("	<Fecha Hasta (Opcional)> dd/mm/aaaa.\n");

}

short AbreArchivos(inx)
int   inx;
{
   char  sTitulos[10000];
   $char sFecha[9];
   int   iRcv;
   
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

	sprintf( sArchMedidorUnx  , "%sT1INVOICE.unx", sPathSalida );
   sprintf( sArchMedidorAux  , "%sT1INVOICE.aux", sPathSalida );
   sprintf( sArchMedidorDos  , "%senel_care_invoice_t1_%s_%s_%d.csv", sPathSalida, gsDesdeFmt, gsHastaFmt, inx );

	strcpy( sSoloArchivoMedidor, "T1INVOICE.unx");

	pFileMedidorUnx=fopen( sArchMedidorUnx, "w" );
	if( !pFileMedidorUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchMedidorUnx );
		return 0;
	}
	
   strcpy(sTitulos,"\"Fecha de emisi�n\";\"Fecha de vencimiento\";\"Fecha de segundo vencimiento\";\"Intereses\";\"Acceso a la factura\";\"Direcci�n factura\";\"Titular\";\"Otros cargos\";\"Suministro\";\"Saldo anterior\";\"Cantidad de productos y servicios\";\"Impuestos\";\"External ID\";\"Numero Factura\";\"Direccion Facturaci�n (Historico)\";\"Pago\";\"Total\";\"Cargos Fijos\";\"Cargos Variables\";\"Factor Potencia\";\"Tasa Alumbrado P�blico\";\"Recargo\";\"Recargo Anterior\";\"Cuota convenio\";\"CNR\";\"Refacturaci�n\";\"Ahorro %\";\"Factura Digital\";\"Moneda\";\"Valor Energ�a Activa\";\"Valor Energ�a Reactiva\";\"Valor Potencia\";\"Valor Ahorro\";\n");
   iRcv=fprintf(pFileMedidorUnx, sTitulos);

   if(iRcv < 0){
		printf("ERROR al grabar titulos %s.\n", sArchMedidorUnx );
		return 0;
   }
      
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
/*
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchMedidorUnx, sArchMedidorAux);
	iRcv=system(sCommand);
*/
   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchMedidorUnx, sArchMedidorDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchMedidorDos);
	iRcv=system(sCommand);
	
	sprintf(sCommand, "cp %s %s", sArchMedidorDos, sPathCp);
	iRcv=system(sCommand);

   if(iRcv==0){  
      sprintf(sCommand, "rm %s", sArchMedidorUnx);
      iRcv=system(sCommand);
/*   
      sprintf(sCommand, "rm %s", sArchMedidorAux);
      iRcv=system(sCommand);
*/   
      sprintf(sCommand, "rm %s", sArchMedidorDos);
      iRcv=system(sCommand);
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
	strcat(sql, "AND c.tipo_sum != 5 ");
   strcat(sql, "AND c.tipo_sum NOT IN (5, 6) ");
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

   /******** Cursor FACTURAS  ****************/
	strcpy(sql, "SELECT h.numero_cliente, ");
	strcat(sql, "h.corr_facturacion, ");
   strcat(sql, "h.fecha_facturacion, ");
	strcat(sql, "TO_CHAR(h.fecha_facturacion, '%Y-%m-%d'), ");
	strcat(sql, "TO_CHAR(h.fecha_vencimiento1, '%Y-%m-%d'), ");
	strcat(sql, "TO_CHAR(NVL(h.fecha_vencimiento2, h.fecha_vencimiento1), '%Y-%m-%d'), ");
	strcat(sql, "h.suma_intereses, ");
	strcat(sql, "h.suma_cargos_man, ");
	strcat(sql, "h.saldo_anterior, ");
	strcat(sql, "h.suma_impuestos, ");
	strcat(sql, "h.centro_emisor || h.tipo_docto || h.numero_factura, ");
   strcat(sql, "h.numero_factura, ");
	strcat(sql, "h.total_a_pagar, ");
	strcat(sql, "NVL(h.coseno_phi, 0) /100, ");
	strcat(sql, "h.suma_recargo, ");
	strcat(sql, "h.suma_convenio, ");
	strcat(sql, "h.tarifa, ");
	strcat(sql, "h.indica_refact ");
	/*strcat(sql, "FROM hisfac h, cliente c ");*/
   strcat(sql, "FROM hisfac h ");
   
	
   if(giTipoCorrida==3){
      strcat(sql, "WHERE h.fecha_facturacion BETWEEN ? AND ? ");
   }else{
      strcat(sql, "WHERE h.numero_cliente = ? ");
      strcat(sql, "AND h.fecha_facturacion >= TODAY - 420 ");
      strcat(sql, "ORDER BY h.corr_facturacion ASC ");
   }
	/*strcat(sql, "AND c.numero_cliente = h.numero_cliente ");*/
   
	$PREPARE selFacturas FROM $sql;
	
	$DECLARE curFacturas CURSOR WITH HOLD FOR selFacturas;
   
   
	/******** Sel HisFAC Rectificado *********/
	strcpy(sql, "SELECT r.total_refacturado, ");
	strcat(sql, "r.total_impuestos, ");
	strcat(sql, "r.coseno_phi/100, ");
   strcat(sql, "r.corr_refacturacion ");
	strcat(sql, "FROM refac r ");
	strcat(sql, "WHERE r.numero_cliente = ? ");
	strcat(sql, "AND r.fecha_fact_afect = ? ");
	strcat(sql, "AND r.nro_docto_afect = ? ");
   
   
	$PREPARE selRefac FROM $sql;

   /******** Cur Carfac *********/
	strcpy(sql, "SELECT codigo_cargo, SUM(valor_cargo) "); 
	strcat(sql, "FROM carfac ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND corr_facturacion = ? ");
	strcat(sql, "AND codigo_cargo IN ('020', '030', '580', '581', '886', '887', '952') ");
   strcat(sql, "GROUP BY 1 ");
   
	$PREPARE selCarfac FROM $sql;
	
	$DECLARE curCarfac CURSOR WITH HOLD FOR selCarfac;

   /******** Cur carfac_aux *********/
	strcpy(sql, "SELECT codigo_cargo, SUM(valor_cargo) "); 
	strcat(sql, "FROM carfac_aux ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND corr_facturacion = ? ");
	strcat(sql, "AND codigo_cargo IN ('020', '030', '580', '581', '886', '887', '952') ");
   strcat(sql, "GROUP BY 1 ");
   
	$PREPARE selCarfacAux FROM $sql;
	
	$DECLARE curCarfacAux CURSOR WITH HOLD FOR selCarfacAux;

   /********* Factura Digital **********/
	strcpy(sql, "SELECT COUNT(*) "); 
	strcat(sql, "FROM clientes_digital ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND fecha_alta < ? ");
	strcat(sql, "AND (fecha_baja IS NULL OR fecha_baja > ? ) ");
   
   $PREPARE selDigital  FROM $sql;

	/******** Select Path de Archivos ****************/
	strcpy(sql, "SELECT valor_alf ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'PATH' ");
	strcat(sql, "AND codigo = ? ");
	strcat(sql, "AND sucursal = '0000' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL ) ");

	$PREPARE selRutaPlanos FROM $sql;

   /* Busca recargo */
   $PREPARE selRecargo FROM "SELECT suma_recargo FROM hisfac
      WHERE numero_cliente = ?
      AND corr_facturacion = ?";

   
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


short LeoFacturas(reg)
$ClsFactura *reg;
{
$long lCorrRefactu;
$int  iCantidad;
$char sFechaFactuMax[20];

	InicializaFactura(reg);

   memset(sFechaFactuMax, '\0', sizeof(sFechaFactuMax));

	$FETCH curFacturas INTO
      :reg->numero_cliente,
      :reg->corr_facturacion,
      :reg->lFecha_facturacion,
      :reg->fecha_facturacion,
      :reg->fecha_vencimiento1,
      :reg->fecha_vencimiento2,
      :reg->suma_intereses,
      :reg->suma_cargos_man,
      :reg->saldo_anterior,
      :reg->suma_impuestos,
      :reg->id_factura,
      :reg->numero_factura,
      :reg->total_a_pagar, 
      :reg->coseno_phi,
      :reg->suma_recargo,
      :reg->suma_convenio,
      :reg->tarifa,
      :reg->indica_refact;
	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Facturas !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

    alltrim(reg->id_factura, ' ');
    
   if(reg->indica_refact[0]=='N'){
      $OPEN curCarfac USING :reg->numero_cliente, :reg->corr_facturacion;

      while(LeoDetalle(reg, 1)){
         
      }      
      
      $CLOSE curCarfac;
   }else{
      $OPEN curCarfacAux USING :reg->numero_cliente, :reg->corr_facturacion;

      while(LeoDetalle(reg, 2)){
         
      }      
      
      $CLOSE curCarfacAux;
   
/*   
      $EXECUTE selRefac INTO 
         :reg->total_a_pagar,
         :reg->suma_impuestos,
         :reg->coseno_phi,
         :lColRefactu
         USING :reg->numero_cliente,
               :reg->lFecha_facturacion,
               :reg->numero_factura;
               
      if ( SQLCODE != 0 ){
         printf("No se encontro refac para cliente %ld factura %ld\n", reg->numero_cliente, reg->numero_factura);
      }
*/               
   }
   
   iCantidad=0;
   
   sprintf(sFechaFactuMax, "%s 00:00:00", reg->fecha_facturacion);
   
   $EXECUTE selDigital INTO :iCantidad
         USING :reg->numero_cliente,
               :sFechaFactuMax,
               :sFechaFactuMax;

   if ( SQLCODE != 0 ){
      printf("Error leyendo Factura Digital para cliente %ld correlativo %ld", reg->numero_cliente, reg->corr_facturacion);
   }         

   if(iCantidad > 0){
      strcpy(reg->factu_digital, "S");
   }else{
      strcpy(reg->factu_digital, "N");
   }
         
	return 1;	
}

void InicializaFactura(reg)
$ClsFactura	*reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   rsetnull(CINTTYPE, (char *) &(reg->corr_facturacion));
   rsetnull(CDOUBLETYPE, (char *) &(reg->lFecha_facturacion));
   memset(reg->fecha_facturacion, '\0', sizeof(reg->fecha_facturacion));
   memset(reg->fecha_vencimiento1, '\0', sizeof(reg->fecha_vencimiento1));
   memset(reg->fecha_vencimiento2, '\0', sizeof(reg->fecha_vencimiento2));
   rsetnull(CDOUBLETYPE, (char *) &(reg->suma_intereses));
   rsetnull(CDOUBLETYPE, (char *) &(reg->suma_cargos_man));
   rsetnull(CDOUBLETYPE, (char *) &(reg->saldo_anterior));
   rsetnull(CDOUBLETYPE, (char *) &(reg->suma_impuestos));
   memset(reg->id_factura, '\0', sizeof(reg->id_factura));
   rsetnull(CLONGTYPE, (char *) &(reg->numero_factura));
   rsetnull(CDOUBLETYPE, (char *) &(reg->total_a_pagar));
   rsetnull(CDOUBLETYPE, (char *) &(reg->coseno_phi));
   rsetnull(CDOUBLETYPE, (char *) &(reg->suma_recargo));
   rsetnull(CDOUBLETYPE, (char *) &(reg->suma_convenio));
   memset(reg->tarifa, '\0', sizeof(reg->tarifa));
   memset(reg->indica_refact, '\0', sizeof(reg->indica_refact));
   rsetnull(CDOUBLETYPE, (char *) &(reg->cargo_fijo));
   rsetnull(CDOUBLETYPE, (char *) &(reg->cargo_variable));
   rsetnull(CDOUBLETYPE, (char *) &(reg->cargo_tap));
   rsetnull(CDOUBLETYPE, (char *) &(reg->cargo_kit));
   memset(reg->factu_digital, '\0', sizeof(reg->factu_digital));

}


short LeoDetalle(reg,  iTipo)
$ClsFactura *reg;
int         iTipo;
{
$char codCargo[4];
$double  valorCargo;


   if(iTipo == 1){
      $FETCH curCarfac INTO :codCargo, :valorCargo;   
   
   }else{
      $FETCH curCarfacAux INTO :codCargo, :valorCargo;
   
   }

   if(SQLCODE != 0){
      return 0;
   }
   
   if(strcmp(codCargo, "020")==0){
      reg->cargo_fijo = valorCargo;
   }else if(strcmp(codCargo, "030")==0){
      reg->cargo_variable = valorCargo;
   }else if(strcmp(codCargo, "580")==0){
      reg->cargo_tap = valorCargo;   
   }else if(strcmp(codCargo, "581")==0){
      reg->cargo_tap = valorCargo;
   }else if(strcmp(codCargo, "886")==0){
      reg->cargo_tap = valorCargo;   
   }else if(strcmp(codCargo, "887")==0){
      reg->cargo_tap = valorCargo;
   }else if(strcmp(codCargo, "952")==0){
      reg->cargo_kit = valorCargo;
   }

   return 1;
}



short GenerarPlano(fp, reg)
FILE 				*fp;
$ClsFactura		reg;
{
	char	sLinea[1000];	
   int   iRcv;
   
	memset(sLinea, '\0', sizeof(sLinea));

   /* Fecha de emisi�n */
   sprintf(sLinea, "\"%sT00:00:00.000Z\";", reg.fecha_facturacion);
   
   /* Fecha de vencimiento */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_vencimiento1);
   
   /* Fecha de segundo vencimiento */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.fecha_vencimiento2);
   
   /* Intereses */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.suma_intereses);
   
   /* Acceso a la factura (Vacio) */
   strcat(sLinea, "\"http://www.edesur.com.ar/\";");
   
   /* Direcci�n factura (vacio) */
   /*strcat(sLinea, "\"\";");*/
   /*sprintf(sLinea, "%s\"%ld-2\";", sLinea, reg.numero_cliente);*/
   sprintf(sLinea, "%s\"%ldBPARG\";", sLinea, reg.numero_cliente);
   
   /* Titular */
   sprintf(sLinea, "%s\"%ldARG\";", sLinea, reg.numero_cliente);
   
   /* Otros cargos */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.suma_cargos_man);
   
   /* Suministro */
   sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.numero_cliente);
   
   /* Saldo anterior */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.saldo_anterior);
   
   /* Saldos de productos y servicios (cuota kit) */
   if(reg.cargo_kit > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.cargo_kit);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Impuestos */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.suma_impuestos);
   
   /* External ID */
   sprintf(sLinea, "%s\"%ld%sINVARG\";", sLinea,reg.numero_cliente, reg.id_factura);
   
   /* Numero Factura */
   sprintf(sLinea, "%s\"%s\";", sLinea, reg.id_factura);
   
   /* Direccion Facturaci�n (Historico) */
   /*sprintf(sLinea, "%s\"%ld\";", sLinea, reg.numero_cliente);*/
   strcat(sLinea, "\"\";");
   
   /* Pago (vacio) */
   strcat(sLinea, "\"\";");
   
   /* Total */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.total_a_pagar);
   
   /* Cargos Fijos */
   if(reg.cargo_fijo > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.cargo_fijo);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Cargos Variables */
   if(reg.cargo_variable > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.cargo_variable);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Factor Potencia */
   sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.coseno_phi);
   
   /* Tasa Alumbrado P�blico */
   if(reg.cargo_tap > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.cargo_tap);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Recargo */
   if(reg.suma_recargo > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.suma_recargo);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Recargo Anterior */
   if(reg.recargoAnterior > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.recargoAnterior);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Cuota convenio */
   if(reg.suma_convenio > 0.01){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, reg.suma_convenio);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* CNR (Vacio) */
   strcat(sLinea, "\"\";");
   
   /* Refacturaci�n */
   if(reg.indica_refact[0]=='S'){
      strcat(sLinea, "\"Yes\";");
   }else{
      strcat(sLinea, "\"No\";");
   }
   
   /* Ahorro % (vacio) */
   strcat(sLinea, "\"\";");
   
   /* Factura Digital */
   if(reg.factu_digital[0]=='S'){
      strcat(sLinea, "\"TRUE\";");
   }else{
      strcat(sLinea, "\"FALSE\";");
   }

   /* Moneda */
   strcat(sLinea, "\"ARS\";");

   /* Valor Energia Activa */
   strcat(sLinea, "\"\";");
   /* Valor Energia Reactiva  */
   strcat(sLinea, "\"\";");
   /* Valor Potencia */
   strcat(sLinea, "\"\";");
   /* Valor Ahorro % */
   strcat(sLinea, "\"\";");

	strcat(sLinea, "\r\n");
	
   iRcv=fprintf(fp, sLinea);
   if(iRcv < 0){
      printf("Error al grabar Invoice\n");
      exit(1);
   }
	return 1;
}

double getRecargo(nroCliente, corrFactu)
$long nroCliente;
$long corrFactu;
{
   $double  Recargo;
   
   $long corrFactuAnterior = corrFactu-1;
   
   if(corrFactuAnterior<=0){
      Recargo=0.00;   
   }

   $EXECUTE selRecargo INTO :Recargo
      USING :nroCliente,
            :corrFactuAnterior;

   if(SQLCODE != 0)
      Recargo=0.00;
      
      
   return Recargo;
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



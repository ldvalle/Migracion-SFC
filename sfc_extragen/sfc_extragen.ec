/*********************************************************************************
    Proyecto: Migracion al sistema SALES FORCE
    Aplicacion: sfc_extragen
    
	Fecha : 05/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructuras de SALES FORCES
         ADDRESS, CUENTAS, CONTACTOS, POINT DELIVERY, SERVICE PRODUCT y ASSET
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
      <Tipo Corrida> : 0=Activos; 1= No Activos
		<Tipo Corrida> : 0=Normal; 1= Reducida		

********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <synmail.h>

$include "sfc_extragen.h";

/* Variables Globales */
$long glFechaDesde;
$long glFechaHasta;
$char gsFechaDesdeLarga[17];
$char gsFechaHastaLarga[17];
$char gsFechaFile[9];

$long	glNroCliente;
$int	giEstadoCliente;
int	giTipoGenera;
int   giTipoCorrida;

FILE	*fpStreetUnx;
FILE	*fpAddressUnx;
FILE	*fpCuentasUnx;
FILE	*fpContactosUnx;
/*FILE	*fpCuentasContactosUnx;*/
FILE	*fpPointDeliveryUnx;
FILE	*fpServiceProductUnx;
FILE	*fpAssetUnx;
FILE	*fpBajasUnx;

FILE  *fpLog;

char	sArchStreetUnx[100];
char	sArchStreetAux[100];
char	sArchStreetDos[300];
char	sSoloArchivoStreetUnx[100];

char	sArchAddressUnx[100];
char	sArchAddressAux[100];
char	sArchAddressDos[300];
char	sSoloArchivoAddressUnx[100];

char	sArchCuentasUnx[100];
char	sArchCuentasAux[100];
char	sArchCuentasDos[300];
char	sSoloArchivoCuentasUnx[100];

char	sArchContactosUnx[100];
char	sArchContactosAux[100];
char	sArchContactosDos[300];
char	sSoloArchivoContactosUnx[100];

char	sArchCuentasContactosUnx[100];
char	sArchCuentasContactosAux[100];
char	sArchCuentasContactosDos[300];
char	sSoloArchivoCuentasContactosUnx[100];

char	sArchPointDeliveryUnx[100];
char	sArchPointDeliveryAux[100];
char	sArchPointDeliveryDos[300];
char	sSoloArchivoPointDeliveryUnx[100];

char	sArchServiceProductUnx[100];
char	sArchServiceProductAux[100];
char	sArchServiceProductDos[300];
char	sSoloArchivoServiceProductUnx[100];

char	sArchAssetUnx[100];
char	sArchAssetAux[100];
char	sArchAssetDos[300];
char	sSoloArchivoAssetUnx[100];

char	sArchBajasUnx[100];
char	sArchBajasAux[100];
char	sArchBajasDos[300];
char	sSoloArchivoBajasUnx[100];


char	sPathSalida[100];
char	FechaGeneracion[9];	
char	MsgControl[100];
$char	fecha[9];
long	lCorrelativo;

long	cantProcesada;

char	sMensMail[1024];	

/* Variables Globales Host */
$ClsClientes	regCliente;
$long			lFechaLimiteInferior;

$WHENEVER ERROR CALL SqlException;

void main( int argc, char **argv ) 
{
$char 	nombreBase[20];
time_t 	hora;
FILE	*fpIntalacion;
int		iFlagMigra=0;
$ClsNomencla   regNomencla;
char     sCommand[100];
int      iRcv;
$char    sFechaAyer[11];
$long    lNroCliente;
$long    lAltura;
int      iValidaEmail;
long     lCantInvalidos;

	if(! AnalizarParametros(argc, argv)){
		exit(0);
	}

	hora = time(&hora);
	
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));
	
	strcpy(nombreBase, argv[1]);
	
	$DATABASE :nombreBase;	
	
	$SET LOCK MODE TO WAIT;
	$SET ISOLATION TO DIRTY READ;
	
	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
   
   CreaPrepare();

   if(!AbreArchivos()){
      printf("No se pudo abrir los archivos.\nProceso Abortado.");
      exit(2);
   }
   
	cantProcesada=0;


	/*********************************************
				AREA CURSOR PPAL
	**********************************************/

	$OPEN curClientes;

	while(LeoCliente(&regCliente)){
      if(!PadreEnT23(&regCliente)){
         memset(regCliente.papa_t23, '\0', sizeof(regCliente.papa_t23));
      }
		GenerarPlanos(regCliente);
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

	printf("==============================================\n");
	printf("SALES FORCES - extraccion Gral.\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Clientes Procesados :       %ld \n",cantProcesada);
	printf("==============================================\n");
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));						

	hora = time(&hora);
	printf("\nHora de finalizacion del proceso : %s\n", ctime(&hora));

	printf("Fin del proceso OK\n");	

	exit(0);
}	

short AnalizarParametros(argc, argv)
int		argc;
char	* argv[];
{

	if(argc != 4){
		MensajeParametros();
		return 0;
	}
	
   giEstadoCliente=atoi(argv[2]);
   giTipoCorrida=atoi(argv[3]);
   
	return 1;
}


void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("\t<Base>: synergia.\n");
      printf("\t<Estado Cliente>: 0=Activo, 1=No Activo.\n");
      printf("\t<Tipo Corrida>:   0=Normal, 1=Reducida.\n");
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char  sFecha[9];
   
   memset(sTitulos, '\0', sizeof(sTitulos));

	memset(sArchAddressUnx, '\0', sizeof(sArchAddressUnx));
   memset(sArchAddressAux, '\0', sizeof(sArchAddressAux));
   memset(sArchAddressDos, '\0', sizeof(sArchAddressDos));
	memset(sSoloArchivoAddressUnx, '\0', sizeof(sSoloArchivoAddressUnx));
	
	memset(sArchCuentasUnx, '\0', sizeof(sArchCuentasUnx));
   memset(sArchCuentasAux, '\0', sizeof(sArchCuentasAux));
   memset(sArchCuentasDos, '\0', sizeof(sArchCuentasDos));
	memset(sSoloArchivoCuentasUnx, '\0', sizeof(sSoloArchivoCuentasUnx));
	
	memset(sArchContactosUnx, '\0', sizeof(sArchContactosUnx));
   memset(sArchContactosAux, '\0', sizeof(sArchContactosAux));
   memset(sArchContactosDos, '\0', sizeof(sArchContactosDos));
	memset(sSoloArchivoContactosUnx, '\0', sizeof(sSoloArchivoContactosUnx));
	
	memset(sArchPointDeliveryUnx, '\0', sizeof(sArchPointDeliveryUnx));
   memset(sArchPointDeliveryAux, '\0', sizeof(sArchPointDeliveryAux));
   memset(sArchPointDeliveryDos, '\0', sizeof(sArchPointDeliveryDos));
	memset(sSoloArchivoPointDeliveryUnx, '\0', sizeof(sSoloArchivoPointDeliveryUnx));
	
	memset(sArchServiceProductUnx, '\0', sizeof(sArchServiceProductUnx));
   memset(sArchServiceProductAux, '\0', sizeof(sArchServiceProductAux));
   memset(sArchServiceProductDos, '\0', sizeof(sArchServiceProductDos));
	memset(sSoloArchivoServiceProductUnx, '\0', sizeof(sSoloArchivoServiceProductUnx));
	
	memset(sArchAssetUnx, '\0', sizeof(sArchAssetUnx));
   memset(sArchAssetAux, '\0', sizeof(sArchAssetAux));
   memset(sArchAssetDos, '\0', sizeof(sArchAssetDos));
	memset(sSoloArchivoAssetUnx, '\0', sizeof(sSoloArchivoAssetUnx));

	memset(sArchBajasUnx, '\0', sizeof(sArchBajasUnx));
   memset(sArchBajasAux, '\0', sizeof(sArchBajasAux));
   memset(sArchBajasDos, '\0', sizeof(sArchBajasDos));
	memset(sSoloArchivoBajasUnx, '\0', sizeof(sSoloArchivoBajasUnx));

   memset(sFecha, '\0', sizeof(sFecha));

   FechaGeneracionFormateada(sFecha);
   
	memset(sPathSalida,'\0',sizeof(sPathSalida));

	RutaArchivos( sPathSalida, "SALESF" );

	alltrim(sPathSalida,' ');

   /* Armo nombres de archivo */
	strcpy(sSoloArchivoAddressUnx, "T1ADDRESS.unx");
	sprintf(sArchAddressUnx, "%s%s", sPathSalida, sSoloArchivoAddressUnx);
   sprintf(sArchAddressAux, "%sT1ADDRESS.aux", sPathSalida);
   sprintf(sArchAddressDos, "%senel_care_address_t1_%s.csv", sPathSalida, sFecha);

	strcpy(sSoloArchivoCuentasUnx, "T1CUENTAS.unx");
	sprintf(sArchCuentasUnx, "%s%s", sPathSalida, sSoloArchivoCuentasUnx);
   sprintf(sArchCuentasAux, "%sT1CUENTAS.aux", sPathSalida);
   sprintf(sArchCuentasDos, "%senel_care_account_t1_%s.csv", sPathSalida, sFecha);

	strcpy(sSoloArchivoContactosUnx, "T1CONTACTOS.unx");
	sprintf(sArchContactosUnx, "%s%s", sPathSalida, sSoloArchivoContactosUnx);
   sprintf(sArchContactosAux, "%sT1CONTACTOS.aux", sPathSalida);
   sprintf(sArchContactosDos, "%senel_care_contact_t1_%s.csv", sPathSalida, sFecha);

	strcpy(sSoloArchivoPointDeliveryUnx, "T1POINT_DELIVERY.unx");
	sprintf(sArchPointDeliveryUnx, "%s%s", sPathSalida, sSoloArchivoPointDeliveryUnx);
   sprintf(sArchPointDeliveryAux, "%sT1POINT_DELIVERY.aux", sPathSalida);
   sprintf(sArchPointDeliveryDos, "%senel_care_pointofdelivery_t1_%s.csv", sPathSalida, sFecha);

	strcpy(sSoloArchivoServiceProductUnx, "T1SERVICE_PRODUCT.unx");
	sprintf(sArchServiceProductUnx, "%s%s", sPathSalida, sSoloArchivoServiceProductUnx);
   sprintf(sArchServiceProductAux, "%sT1SERVICE_PRODUCT.aux", sPathSalida);
   sprintf(sArchServiceProductDos, "%senel_care_serviceproduct_t1_%s.csv", sPathSalida, sFecha);

	strcpy(sSoloArchivoAssetUnx, "T1ASSET.unx");
	sprintf(sArchAssetUnx, "%s%s", sPathSalida, sSoloArchivoAssetUnx);
   sprintf(sArchAssetAux, "%sT1ASSET.aux", sPathSalida);
   sprintf(sArchAssetDos, "%senel_care_asset_t1_%s.csv", sPathSalida, sFecha);	

   /* Abro Archivos*/
	fpAddressUnx=fopen( sArchAddressUnx, "w" );
	if( !fpAddressUnx ){
		printf("ERROR al abrir archivo 2 %s.\n", sArchAddressUnx );
		return 0;
	}
   
   strcpy(sTitulos, "\"Divisa\";\"Esquina\";\"Número\";\"Referencia\";\"Código Postal\";\"Número\";\"Identificador calle\";\"Departamento\";\"Calle\";\"Tipo de numeración\";\"Dirección concatenada\";\"Sector\";\"Coordenada X\";\"Coordenada Y\";\"Nombre agrupación\";\"Tipo de agrupación\";\"Tipo de interior\";\"Dirección larga\";\"Lote/Manzana\";\"Tipo de sector\";\"CompanyID\";\"Interseccion 1\";\"Interseccion 2\";\"Piso\";\"Departamento\";\"Edificio\";\n");
   fprintf(fpAddressUnx, sTitulos);

	fpCuentasUnx=fopen( sArchCuentasUnx, "w" );
	if( !fpCuentasUnx ){
		printf("ERROR al abrir archivo 3 %s.\n", sArchCuentasUnx );
		return 0;
	}

   strcpy(sTitulos, "\"Identificador cuenta\";\"Nombre de la cuenta\";\"Tipo de identidad\";\"Número de identidad\";\"Email principal\";\"Email secundario\";\"Teléfono principal\";\"Teléfono secundario\";\"Teléfono adicional\";\"Divisa\";\"Tipo de Registro\";\"Fecha de nacimiento\";\"Cuenta principal\";\"Apellido materno\";\"Apellido paterno\";\"Dirección\";\"Ejecutivo\";\"Giro\";\"Clase de Servicio\";\"Id Empresa\";\"Razón social de la empresa\";\"Condicion Impositiva\";\"Email Adicional\";\"Tipo de Cuenta\";\"Cuenta Cliente\";\"Cuenta Padre\";\"Clase de Cuenta\";\"Tipo de Sociedad\";\n");
   fprintf(fpCuentasUnx, sTitulos);

	fpContactosUnx=fopen( sArchContactosUnx, "w" );
	if( !fpContactosUnx ){
		printf("ERROR al abrir archivo 4 %s.\n", sArchContactosUnx );
		return 0;
	}
   
   strcpy(sTitulos, "\"Identificador cuenta\";\"Nombre\";\"Apellido\";\"Saludo\";\"Nombre de la cuenta\";\"Estado Civil\";\"Género\";\"Tipo de identificación\";\"Número de documento\";\"Fase del ciclo de vida del cliente\";\"Estrato\";\"Nivel educacional\";\"Autoriza uso de información personal\";\"No llamar\";\"No recibir correos electrónicos\";\"Profesión\";\"Ocupación\";\"Fecha nacimiento\";\"Canal preferente de contacto\";\"Correo electrónico\";\"Correo electrónico secundario\";\"Teléfono\";\"Teléfono secundario\";\"Teléfono movil\";\"Moneda\";\"Apellido paterno\";\"Apellido materno\";\"Tipo de acreditación\";\"Dirección del contacto\";\"Nombre de usuario de Twitter\";\"Recuento de seguidores de Twitter\";\"Influencia\";\"Tipo de influencia\";\"Biografía de Twitter\";\"Id.de usuario de Twitter\";\"Nombre de usuario de Facebook\";\"Id.de usuario de Facebook\";\"Id.de empresa\";\n");
   fprintf(fpContactosUnx, sTitulos);

	fpPointDeliveryUnx=fopen( sArchPointDeliveryUnx, "w" );
	if( !fpPointDeliveryUnx ){
		printf("ERROR al abrir archivo 5 %s.\n", sArchPointDeliveryUnx );
		return 0;
	}

   strcpy(sTitulos, "\"Identificador PoD\";\"Número PoD\";\"Divisa\";\"DV Número de suministro\";\"Dirección\";\"Estado del suministro\";\"Pais\";\"Comuna\";\"Tipo de segmento\";\"Medida de disciplina\";\"Id empresa\";\"Electrodependiente\";\"Tarifa\";\"Tipo de agrupación\";\"Full electric\";\"Nombre boleta\";\"Ruta\";\"Dirección de reparto\";\"Comuna de reparto\";\"Número de Transformador\";\"Tipo de Transformador\";\"Tipo de Conexión\";\"Estrato socioeconómico\";\"Subestación Eléctrica Conexión\";\"Tipo de medida\";\"Número de alimentador\";\"Tipo de lectura\";\"Bloque\";\"Horario de racionamiento\";\"Estado de conexión\";\"Fecha de corte\";\"Código PRC\";\"SED\";\"SET\";\"Llave\";\"Potencia Instalada\";\"Cliente singular\";\"Clase de servicio\";\"subclase de servicio\";\"Ruta de lectura\";\"Tipo de liquidación\";\"Mercado\";\"Carga aforada\";\"Año de fabricación\";\"Cantidad de Personas\";\"Numero de DCI\";\"Ente Emisor DCI\";\"Potencia Convenida\";\"Fecha Desconexión\";\n");
   fprintf(fpPointDeliveryUnx, sTitulos);   

	fpServiceProductUnx=fopen( sArchServiceProductUnx, "w" );
	if( !fpServiceProductUnx ){
		printf("ERROR al abrir archivo 6 %s.\n", sArchServiceProductUnx );
		return 0;
	}

   strcpy(sTitulos, "\"Activo\";\"Contacto\";\"Cuenta\";\"Pais\";\"Compañia\";\"ExternalID\";\"Contacto Principal\";\"Electrodependiente\";\"Númeor de DCI\";\"Ente Emisor DCI\";\n");
   fprintf(fpServiceProductUnx, sTitulos);

	fpAssetUnx=fopen( sArchAssetUnx, "w" );
	if( !fpAssetUnx ){
		printf("ERROR al abrir archivo 7 %s.\n", sArchAssetUnx );
		return 0;
	}

   strcpy(sTitulos, "\"Identificador activo\";\"Nombre del activo\";\"Cuenta\";\"Contacto\";\"Suministro\";\"Descripción\";\"Producto\";\"Estado\";\"Contacto Principal\";\"Contrato\";\"Estado Contratacion\";\n");
   fprintf(fpAssetUnx, sTitulos);


	return 1;	
}

void CerrarArchivos(void)
{
	fclose(fpAddressUnx);
	fclose(fpCuentasUnx);
	fclose(fpContactosUnx);
	fclose(fpPointDeliveryUnx);
	fclose(fpServiceProductUnx);
	fclose(fpAssetUnx);
}

void FormateaArchivos(void){
char	sCommand[1000];
int		iRcv, i;
$char	sPathCp[100];
	
	memset(sCommand, '\0', sizeof(sCommand));
	memset(sPathCp, '\0', sizeof(sPathCp));

   RutaArchivos( sPathCp, "SALEFC" );
   
                           
	/* ----------- */
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchAddressUnx, sArchAddressAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchAddressAux, sArchAddressDos);
   iRcv=system(sCommand);
      
	sprintf(sCommand, "chmod 777 %s", sArchAddressDos);
	iRcv=system(sCommand);

	sprintf(sCommand, "cp %s %s", sArchAddressDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAddressUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAddressAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAddressDos);
   iRcv=system(sCommand);
   	
	/* ----------- */
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchCuentasUnx, sArchCuentasAux);
	iRcv=system(sCommand);
   
   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchCuentasAux, sArchCuentasDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchCuentasDos);
	iRcv=system(sCommand);

	sprintf(sCommand, "cp %s %s", sArchCuentasDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchCuentasUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchCuentasAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchCuentasDos);
   iRcv=system(sCommand);
   	
	/* ----------- */
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchContactosUnx, sArchContactosAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchContactosAux, sArchContactosDos);
   iRcv=system(sCommand);
   		
	sprintf(sCommand, "chmod 777 %s", sArchContactosDos);
	iRcv=system(sCommand);
	
	sprintf(sCommand, "cp %s %s", sArchContactosDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchContactosUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchContactosAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchContactosDos);
   iRcv=system(sCommand);
   	
	/* ----------- */
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchPointDeliveryUnx, sArchPointDeliveryAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchPointDeliveryAux, sArchPointDeliveryDos);
   iRcv=system(sCommand);
   	
	sprintf(sCommand, "chmod 777 %s", sArchPointDeliveryDos);
	iRcv=system(sCommand);
	
	sprintf(sCommand, "cp %s %s", sArchPointDeliveryDos, sPathCp);
	iRcv=system(sCommand);
   
   sprintf(sCommand, "rm %s", sArchPointDeliveryUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchPointDeliveryAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchPointDeliveryDos);
   iRcv=system(sCommand);
   
	/* ----------- */	
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchServiceProductUnx, sArchServiceProductAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchServiceProductAux, sArchServiceProductDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchServiceProductDos);
	iRcv=system(sCommand);

	sprintf(sCommand, "cp %s %s", sArchServiceProductDos, sPathCp);
	iRcv=system(sCommand);
   
   sprintf(sCommand, "rm %s", sArchServiceProductUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchServiceProductAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchServiceProductDos);
   iRcv=system(sCommand);
   
	/* ----------- */
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchAssetUnx, sArchAssetAux);
	iRcv=system(sCommand);

   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchAssetAux, sArchAssetDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchAssetDos);
	iRcv=system(sCommand);

	sprintf(sCommand, "cp %s %s", sArchAssetDos, sPathCp);
	iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAssetUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAssetAux);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchAssetDos);
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
	strcpy(sql, "SELECT TO_CHAR(TODAY - 1, '%d/%m/%Y') FROM dual ");
	
	$PREPARE selFechaActual FROM $sql;	
   
	/******** Cursor Principal  ****************/	
	strcpy(sql, "SELECT c.numero_cliente, ");
	strcat(sql, "REPLACE(TRIM(c.nombre), '\"', ' '), ");
   strcat(sql, "c.cod_calle, ");
	strcat(sql, "c.nom_calle, ");
	strcat(sql, "TRIM(c.nom_partido), ");
	strcat(sql, "c.provincia, ");
	strcat(sql, "TRIM(c.nom_comuna), ");
	strcat(sql, "c.nro_dir, ");
	strcat(sql, "TRIM(c.obs_dir), ");
	strcat(sql, "c.cod_postal, ");
	strcat(sql, "c.piso_dir, ");
	strcat(sql, "c.depto_dir, ");
   strcat(sql, "c.tip_doc, ");
   strcat(sql, "t3.cod_sf1, ");
	strcat(sql, "c.nro_doc, ");
	strcat(sql, "TRIM(REPLACE(c.telefono, '-', '')), ");
	strcat(sql, "c.tipo_cliente, ");
   
	strcat(sql, "CASE ");
	strcat(sql, "	WHEN LENGTH(c.rut)=11 THEN c.rut[1,2] || '-' || c.rut[3, 10] || '-' || c.rut[11] ");
	strcat(sql, "  ELSE '' ");
	strcat(sql, "END, ");
   
	strcat(sql, "c.tipo_reparto, ");
	strcat(sql, "c.sucursal, ");
	strcat(sql, "c.sector, ");
	strcat(sql, "c.zona, ");
	strcat(sql, "c.tarifa, ");
	strcat(sql, "c.correlativo_ruta, ");
	strcat(sql, "t1.cod_sf1, ");
	strcat(sql, "t1.cod_sf2, ");
	strcat(sql, "c.partido, ");
	strcat(sql, "c.comuna, ");
   strcat(sql, "t.tec_cod_calle, ");
   strcat(sql, "TRIM(c.nom_barrio), ");
   strcat(sql, "c.potencia_inst_fp, ");
   strcat(sql, "TRIM(c.nom_entre), ");
   strcat(sql, "TRIM(c.nom_entre1), ");
   strcat(sql, "t2.cod_sap, ");         /* tipo IVA */
   strcat(sql, "c.minist_repart ");
   
	strcat(sql, "FROM cliente c, OUTER sf_transforma t1, OUTER tecni t ");
   strcat(sql, ", OUTER sap_transforma t2, OUTER sf_transforma t3 ");

if(giTipoCorrida == 1){
   strcat(sql, ", migra_sf ma ");
}
   if(giEstadoCliente == 1){
      strcat(sql, ", sap_inactivos si ");
   	strcat(sql, "WHERE c.numero_cliente = si.numero_cliente ");
   }else{
   	strcat(sql, "WHERE c.estado_cliente = 0 ");
   }
      
   /*
	strcat(sql, "AND c.sector NOT IN (81, 82, 85, 88, 90) ");
   */
   strcat(sql, "AND c.tipo_sum != 5 ");
	strcat(sql, "AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med m ");
	strcat(sql, "	WHERE m.numero_cliente = c.numero_cliente ");
	strcat(sql, "	AND m.fecha_activacion < TODAY  ");
	strcat(sql, "	AND (m.fecha_desactiva IS NULL OR m.fecha_desactiva > TODAY)) ");
	strcat(sql, "AND t1.clave = 'TIPCLI' ");
	strcat(sql, "AND t1.cod_mac = c.tipo_cliente ");
   strcat(sql, "AND t.numero_cliente = c.numero_cliente ");
   strcat(sql, "AND t2.clave = 'TIPIVA' ");
   strcat(sql, "AND t2.cod_mac = c.tipo_iva ");
   strcat(sql, "AND t3.clave = 'TIPDOCU' ");
   strcat(sql, "AND t3.cod_mac = c.tip_doc ");
if(giTipoCorrida == 1){   		
   strcat(sql, "AND ma.numero_cliente = c.numero_cliente ");
}
		
	$PREPARE selClientes FROM $sql;
	
	$DECLARE curClientes CURSOR FOR selClientes;	

	/******** E-Mail *********/
	strcpy(sql, "SELECT TRIM(email_1), TRIM(email_2), TRIM(email_3) ");
	strcat(sql, "FROM clientes_digital ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND fecha_alta <= TODAY ");
	strcat(sql, "AND (fecha_baja IS NULL OR fecha_baja > TODAY) ");
	
	$PREPARE selEmail FROM $sql;

	/******** Telefonos ********/
	strcpy(sql, "SELECT tipo_te, ");
	strcat(sql, "cod_area_te, ");
	strcat(sql, "NVL(prefijo_te, ' '), ");
	strcat(sql, "numero_te, ");
	strcat(sql, "ppal_te ");
	strcat(sql, "FROM telefono ");
	strcat(sql, "WHERE cliente = ? ");
	
	$PREPARE selTelefonos FROM $sql;
	
	$DECLARE curTelefonos CURSOR for selTelefonos;

	/********* Electrodependientes *********/
	strcpy(sql, "SELECT COUNT(*) FROM clientes_vip v, tabla t ");
	strcat(sql, "WHERE v.numero_cliente = ? ");
	strcat(sql, "AND v.fecha_activacion <= TODAY ");
	strcat(sql, "AND (v.fecha_desactivac IS NULL OR v.fecha_desactivac > TODAY) ");
	strcat(sql, "AND t.nomtabla = 'SDCLIV' ");
	strcat(sql, "AND t.codigo = v.motivo ");
	strcat(sql, "AND t.valor_alf[4] = 'S' ");
	strcat(sql, "AND t.sucursal = '0000' ");
	strcat(sql, "AND t.fecha_activacion <= TODAY "); 
	strcat(sql, "AND ( t.fecha_desactivac >= TODAY OR t.fecha_desactivac IS NULL ) ");    
	
	$PREPARE selVip FROM $sql;

	/********* Datos Postales *********/
	strcpy(sql, "SELECT dp_nom_calle, ");
	strcat(sql, "dp_nro_dir, ");
	strcat(sql, "dp_piso_dir, ");
	strcat(sql, "dp_depto_dir, ");
	strcat(sql, "dp_cod_postal, ");
	strcat(sql, "dp_nom_localidad ");
	strcat(sql, "FROM postal ");
	strcat(sql, "WHERE numero_cliente = ? ");
	
	$PREPARE selPostal FROM $sql;

	/********* Datos Medidor *********/
	strcpy(sql, "SELECT m.numero_medidor, m.marca_medidor, m.modelo_medidor, d.med_anio ");
	strcat(sql, "FROM medid m, medidor d ");
	strcat(sql, "WHERE m.numero_cliente = ? ");
	strcat(sql, "AND m.estado = 'I' ");
	strcat(sql, "AND d.med_numero = m.numero_medidor ");
	strcat(sql, "AND d.mar_codigo = m.marca_medidor ");
	strcat(sql, "AND d.mod_codigo = m.modelo_medidor ");
	
	$PREPARE selMedidor FROM $sql;

	/********* Datos Técnicos *********/
	strcpy(sql, "SELECT tec_centro_trans, ");
	strcat(sql, "NVL(tipo_tranformador, ' '), ");
	strcat(sql, "tipo_conexion, ");
	strcat(sql, "tec_subestacion, ");
	strcat(sql, "tec_alimentador, ");
   strcat(sql, "codigo_voltaje, ");
   strcat(sql, "TRIM(tec_nom_calle), ");
   strcat(sql, "TRIM(tec_nro_dir), ");
   strcat(sql, "TRIM(tec_piso_dir), ");
   strcat(sql, "TRIM(tec_depto_dir), ");
   strcat(sql, "tec_cod_local ");
	strcat(sql, "FROM tecni ");
	strcat(sql, "WHERE numero_cliente = ? ");
	
	$PREPARE selTecni FROM $sql;

	/********* Ultimo Corte *********/
	strcpy(sql, "SELECT TO_CHAR(MAX(DATE(fecha_corte)), '%Y-%m-%d') FROM correp ");
	strcat(sql, "WHERE numero_cliente = ? ");
	strcat(sql, "AND tramite_corte[2] = '1' ");

	$PREPARE selCorte FROM $sql;
		

	/************ FechaLimiteInferior **************/
	strcpy(sql, "SELECT TODAY - t.valor FROM dual d, tabla t ");
	strcat(sql, "WHERE t.nomtabla = 'SAPFAC' ");
	strcat(sql, "AND t.sucursal = '0000' ");
	strcat(sql, "AND t.codigo = 'HISTO' ");
	strcat(sql, "AND t.fecha_activacion <= TODAY ");
	strcat(sql, "AND (t.fecha_desactivac IS NULL OR t.fecha_desactivac > TODAY) ");
		
	$PREPARE selFechaLimInf FROM $sql;

	/*********** Correlativos Hacia Atras ***********/		
	strcpy(sql, "SELECT t.valor FROM tabla t ");
	strcat(sql, "WHERE t.nomtabla = 'SAPFAC' ");
	strcat(sql, "AND t.sucursal = '0000' ");
	strcat(sql, "AND t.codigo = 'CORR' ");
	strcat(sql, "AND t.fecha_activacion <= TODAY ");
	strcat(sql, "AND (t.fecha_desactivac IS NULL OR t.fecha_desactivac > TODAY) ");
	
	$PREPARE selCorrelativos FROM $sql;
	
   /********** Valida Nomencla *********/
	strcpy(sql, "SELECT COUNT(*) ");
	strcat(sql, "FROM sae_nomen_calles nc, "); 
	strcat(sql, "SAE_ORG_GEOGRAFICA a1, SAE_TABLAS b1, ");
	strcat(sql, "SAE_ORG_GEOGRAFICA a2, SAE_TABLAS b2 ");
	strcat(sql, "WHERE nc.nom_cod_calle = ? ");
	strcat(sql, "AND nc.nom_altura_desde <= ? ");
	strcat(sql, "AND nc.nom_altura_hasta >= ? ");
	strcat(sql, "AND a1.org_destino = ? ");
	strcat(sql, "AND a2.org_destino = ? ");
	strcat(sql, "AND nc.nom_altura_hasta > nc.nom_altura_desde "); 
	strcat(sql, "AND a1.org_destino = nc.nom_partido "); 
	strcat(sql, "AND a1.org_tipo_relacion = 'SP' "); 
	strcat(sql, "AND a1.org_origen = nc.nom_sucursal ");
	strcat(sql, "AND a1.org_destino = b1.tbl_codigo "); 
	strcat(sql, "AND b1.tbl_tipo_tabla = 8 "); 
	strcat(sql, "AND a2.org_tipo_relacion = 'PL' "); 
	strcat(sql, "AND a2.org_origen = nc.nom_partido "); 
	strcat(sql, "AND a2.org_destino = nc.nom_localidad "); 
	strcat(sql, "AND a2.org_destino = b2.tbl_codigo "); 
	strcat(sql, "AND b2.tbl_tipo_tabla = 9 "); 
   
   $PREPARE selValCalle FROM $sql;
   
   /******** Telefonos Certa ********/
	strcpy(sql, "SELECT telefono_fijo, ");
	strcat(sql, "telefono_movil, ");
	strcat(sql, "telefono_secun, ");
	strcat(sql, "zona_tecnica ");
	strcat(sql, "FROM tele_certa ");
	strcat(sql, "WHERE numero_cleinte = ? ");
   
   $PREPARE selTelCerta FROM $sql;
   
   $DECLARE curTelCerta CURSOR FOR selTelCerta;
   
   /*************** Nomenclador ******************/
	strcpy(sql, "SELECT DISTINCT nc.nom_cod_calle, "); 
	strcat(sql, "TRIM(nc.nom_nombre_calle), "); 
	strcat(sql, "nc.nom_altura_desde, "); 
	strcat(sql, "nc.nom_altura_hasta, ");
	strcat(sql, "a1.org_destino cod_partido, "); 
	strcat(sql, "TRIM(b1.tbl_descripcion) desc_partido, ");
	strcat(sql, "a2.org_destino cod_localidad, "); 
	strcat(sql, "TRIM(b2.tbl_descripcion) desc_localidad, ");
   strcat(sql, "nc.nom_dig_antiguedad ");
	strcat(sql, "FROM sae_nomen_calles nc, "); 
   strcat(sql, "SAE_ORG_GEOGRAFICA a1, SAE_TABLAS b1, ");
	strcat(sql, "SAE_ORG_GEOGRAFICA a2, SAE_TABLAS b2 ");

	strcat(sql, "WHERE nc.nom_cod_calle = ? ");
	strcat(sql, "AND nc.nom_altura_desde <= ? ");
	strcat(sql, "AND nc.nom_altura_hasta >= ? ");
	strcat(sql, "AND a1.org_destino = ? ");
	strcat(sql, "AND a2.org_destino = ? ");
   
   strcat(sql, "AND nc.nom_altura_hasta > nc.nom_altura_desde ");
	strcat(sql, "AND a1.org_destino = nc.nom_partido ");
	strcat(sql, "AND a1.org_tipo_relacion = 'SP' ");
	strcat(sql, "AND a1.org_origen = nc.nom_sucursal ");
	strcat(sql, "AND a1.org_destino = b1.tbl_codigo ");
	strcat(sql, "AND b1.tbl_tipo_tabla = 8 ");
	strcat(sql, "AND a2.org_tipo_relacion = 'PL' ");
	strcat(sql, "AND a2.org_origen = nc.nom_partido ");
   strcat(sql, "AND a2.org_destino = nc.nom_localidad ");
	strcat(sql, "AND a2.org_destino = b2.tbl_codigo ");
	strcat(sql, "AND b2.tbl_tipo_tabla = 9 ");
	strcat(sql, "ORDER BY a1.org_destino, a2.org_destino, nc.nom_dig_antiguedad ASC ");
   
   $PREPARE selNomencla FROM $sql;
   
   $DECLARE curNomencla CURSOR FOR selNomencla;

	/******** Select Path de Archivos ****************/
	strcpy(sql, "SELECT valor_alf ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'PATH' ");
	strcat(sql, "AND codigo = ? ");
	strcat(sql, "AND sucursal = '0000' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL ) ");

	$PREPARE selRutaPlanos FROM $sql;

	/******** Select DCI ****************/
   $PREPARE selDCI FROM "SELECT FIRST 1 organismo, nro_dci
      FROM dci d1
      WHERE d1.numero_cliente = ?
      AND d1.fecha_ingreso = ( SELECT MAX(d2.fecha_ingreso)
      	FROM dci d2
         WHERE d2.numero_cliente = d1.numero_cliente
         AND d2.fecha_ingreso <= TODAY
         AND (d2.fecha_baja is null or d2.fecha_baja > TODAY))";

	/********* Select Corporativo T23 **********/
	strcpy(sql, "SELECT NVL(cod_corporativo, '000'), cod_corpo_padre FROM mg_corpor_t23 ");
	strcat(sql, "WHERE numero_cliente = ? ");
	
	$PREPARE selCorpoT23 FROM $sql;
      
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


short LeoCliente(regCli)
$ClsClientes *regCli;
{
   int iRcv;
   
	InicializaCliente(regCli);

	$FETCH curClientes into
		:regCli->numero_cliente,
		:regCli->nombre,
      :regCli->cod_calle,
		:regCli->nom_calle,
		:regCli->nom_partido,
		:regCli->provincia,
		:regCli->nom_comuna,
		:regCli->nro_dir,
		:regCli->obs_dir,
		:regCli->cod_postal,
		:regCli->piso_dir,
		:regCli->depto_dir,
		:regCli->tip_doc,
      :regCli->tip_doc_SF,
		:regCli->nro_doc,
		:regCli->telefono,
		:regCli->tipo_cliente,
		:regCli->rut,
		:regCli->tipo_reparto,
		:regCli->sucursal,
		:regCli->sector,
		:regCli->zona,
		:regCli->tarifa,
		:regCli->correlativo_ruta,
		:regCli->sClaseServicio,
		:regCli->sSubClaseServ,
		:regCli->partido,
		:regCli->comuna,
      :regCli->tec_cod_calle,
      :regCli->nom_barrio,
      :regCli->potencia_inst_fp,
      :regCli->entre_calle1,
      :regCli->entre_calle2,
      :regCli->tipoIva,
      :regCli->minist_repart;
      
				
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de CLIENTES !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

	alltrim(regCli->nombre, ' ');
	alltrim(regCli->nom_calle, ' ');
	alltrim(regCli->nom_partido, ' ');
	alltrim(regCli->nro_dir, ' ');
	alltrim(regCli->piso_dir, ' ');
	alltrim(regCli->depto_dir, ' ');
	alltrim(regCli->obs_dir, ' ');
	alltrim(regCli->rut, ' ');
	alltrim(regCli->tip_doc, ' ');
   alltrim(regCli->tip_doc_SF, ' ');
	alltrim(regCli->email_1, ' ');
	alltrim(regCli->email_2, ' ');
	alltrim(regCli->sClaseServicio, ' ');
	alltrim(regCli->sSubClaseServ, ' ');
	alltrim(regCli->nom_comuna, ' ');
   
   alltrim(regCli->cod_calle, ' ');
   alltrim(regCli->tec_cod_calle, ' ');
   alltrim(regCli->entre_calle1, ' ');
   alltrim(regCli->entre_calle2, ' ');
   
   if(strcmp(regCli->cod_calle, "")==0 || strcmp(regCli->cod_calle, "-1")==0){
      if(strcmp(regCli->tec_cod_calle, "")!=0 && strcmp(regCli->tec_cod_calle, "-1")!=0){
         strcpy(regCli->cod_calle, regCli->tec_cod_calle);
      }
   }

	if(!CargoEmail(regCli)){
		return 0;	
	}

	if(!CargoTelefonos(regCli)){
		return 0;
	}

	if(!CargoVIP(regCli)){
		return 0;		
	}

   if(!CargaDCI(regCli)){
      return 0;
   }

	if(strcmp(regCli->tipo_reparto, "POSTAL")){
		if(!CargoPostal(regCli)){
			return 0;
		}
	}

   iRcv=DatosMedidor(regCli);
/*   
	if(!DatosMedidor(regCli)){
		return 0;	
	}
*/

	if(!DatosTecnicos(regCli)){
		return 0;
	}

	if(!UltimoCorte(regCli)){
		return 0;	
	}

	if(strcmp(regCli->tipo_cliente, "CP")!=0){
		if(strcmp(regCli->tipo_cliente, "IP")!=0){
			if(strcmp(regCli->tipo_cliente, "LS")!=0){
				if(strcmp(regCli->tipo_cliente, "SL")!=0){
					if(strcmp(regCli->tipo_cliente, "OM")!=0){
						if(strcmp(regCli->tipo_cliente, "ON")!=0){
							if(strcmp(regCli->tipo_cliente, "OP")!=0){
								if(strcmp(regCli->tipo_cliente, "PC")!=0){
									if(strcmp(regCli->tipo_cliente, "PI")!=0){
										strcpy(regCli->es_empresa, "N");
									}else{
										strcpy(regCli->es_empresa, "S");
									}
								}else{
									strcpy(regCli->es_empresa, "S");
								}
							}else{
								strcpy(regCli->es_empresa, "S");
							}
						}else{
							strcpy(regCli->es_empresa, "S");
						}
					}else{
						strcpy(regCli->es_empresa, "S");
					}
				}else{
					strcpy(regCli->es_empresa, "S");
				}
			}else{
				strcpy(regCli->es_empresa, "S");
			}
		}else{
			strcpy(regCli->es_empresa, "S");
		}
	}else{
		strcpy(regCli->es_empresa, "S");
	}


	return 1;	
}

void InicializaCliente(regClie)
$ClsClientes	*regClie;
{
	rsetnull(CLONGTYPE, (char *) &(regClie->numero_cliente));
	memset(regClie->nombre, '\0', sizeof(regClie->nombre));
   memset(regClie->cod_calle, '\0', sizeof(regClie->cod_calle));
	memset(regClie->nom_calle, '\0', sizeof(regClie->nom_calle));
	memset(regClie->nom_partido, '\0', sizeof(regClie->nom_partido));
	memset(regClie->provincia, '\0', sizeof(regClie->provincia));
	memset(regClie->nom_comuna, '\0', sizeof(regClie->nom_comuna));
	memset(regClie->nro_dir, '\0', sizeof(regClie->nro_dir));
	memset(regClie->obs_dir, '\0', sizeof(regClie->obs_dir));	
	rsetnull(CINTTYPE, (char *) &(regClie->cod_postal));
	memset(regClie->piso_dir, '\0', sizeof(regClie->piso_dir));	
	memset(regClie->depto_dir, '\0', sizeof(regClie->depto_dir));	
	memset(regClie->tip_doc, '\0', sizeof(regClie->tip_doc));	
   memset(regClie->tip_doc_SF, '\0', sizeof(regClie->tip_doc_SF));
	rsetnull(CDOUBLETYPE, (char *) &(regClie->nro_doc));
	memset(regClie->telefono, '\0', sizeof(regClie->telefono));
	memset(regClie->tipo_cliente, '\0', sizeof(regClie->tipo_cliente));
	memset(regClie->rut, '\0', sizeof(regClie->rut));
	memset(regClie->tipo_reparto, '\0', sizeof(regClie->tipo_reparto));
	memset(regClie->sucursal, '\0', sizeof(regClie->sucursal));
	rsetnull(CINTTYPE, (char *) &(regClie->sector));
	rsetnull(CINTTYPE, (char *) &(regClie->zona));
	memset(regClie->tarifa, '\0', sizeof(regClie->tarifa));
	rsetnull(CLONGTYPE, (char *) &(regClie->correlativo_ruta));
	
	memset(regClie->email_1, '\0', sizeof(regClie->email_1));
	memset(regClie->email_2, '\0', sizeof(regClie->email_2));
   memset(regClie->email_2, '\0', sizeof(regClie->email_3));
	memset(regClie->electrodependiente, '\0', sizeof(regClie->electrodependiente));
	memset(regClie->dp_nom_calle, '\0', sizeof(regClie->dp_nom_calle));
	memset(regClie->dp_nro_dir, '\0', sizeof(regClie->dp_nro_dir));
	memset(regClie->dp_piso_dir, '\0', sizeof(regClie->dp_piso_dir));
	memset(regClie->dp_depto_dir, '\0', sizeof(regClie->dp_depto_dir));
	rsetnull(CINTTYPE, (char *) &(regClie->dp_cod_postal));
	memset(regClie->dp_nom_localidad, '\0', sizeof(regClie->dp_nom_localidad));
	rsetnull(CLONGTYPE, (char *) &(regClie->medidor_nro));	
	memset(regClie->medidor_marca, '\0', sizeof(regClie->medidor_marca));
	memset(regClie->medidor_modelo, '\0', sizeof(regClie->medidor_modelo));
	rsetnull(CINTTYPE, (char *) &(regClie->medidor_anio));
	memset(regClie->tec_centro_trans, '\0', sizeof(regClie->tec_centro_trans));
	memset(regClie->tipo_tranformador, '\0', sizeof(regClie->tipo_tranformador));
	memset(regClie->tipo_conexion, '\0', sizeof(regClie->tipo_conexion));
	memset(regClie->tec_subestacion, '\0', sizeof(regClie->tec_subestacion));
	memset(regClie->tec_alimentador, '\0', sizeof(regClie->tec_alimentador));
   memset(regClie->tec_alimentador, '\0', sizeof(regClie->cod_voltaje));
	
	memset(regClie->ultimo_corte, '\0', sizeof(regClie->ultimo_corte));
	
	memset(regClie->telefono_celular, '\0', sizeof(regClie->telefono_celular));
	memset(regClie->telefono_secundario, '\0', sizeof(regClie->telefono_secundario));	

	memset(regClie->sClaseServicio, '\0', sizeof(regClie->sClaseServicio));
	memset(regClie->sSubClaseServ, '\0', sizeof(regClie->sSubClaseServ));	

	memset(regClie->partido, '\0', sizeof(regClie->partido));
	memset(regClie->comuna, '\0', sizeof(regClie->comuna));	
   memset(regClie->tec_cod_calle, '\0', sizeof(regClie->tec_cod_calle));
   
   memset(regClie->tec_nom_calle, '\0', sizeof(regClie->tec_nom_calle));
   memset(regClie->tec_nro_dir, '\0', sizeof(regClie->tec_nro_dir));
   memset(regClie->tec_piso_dir, '\0', sizeof(regClie->tec_piso_dir));
   memset(regClie->tec_depto_dir, '\0', sizeof(regClie->tec_depto_dir));
   memset(regClie->tec_cod_local, '\0', sizeof(regClie->tec_cod_local));
   
   memset(regClie->nom_barrio, '\0', sizeof(regClie->nom_barrio));
   rsetnull(CDOUBLETYPE, (char *) &(regClie->potencia_inst_fp));
   
   memset(regClie->entre_calle1, '\0', sizeof(regClie->entre_calle1));
   memset(regClie->entre_calle2, '\0', sizeof(regClie->entre_calle2));
   
   memset(regClie->email_contacto, '\0', sizeof(regClie->email_contacto));
   memset(regClie->tipoIva, '\0', sizeof(regClie->tipoIva));
   
   rsetnull(CDOUBLETYPE, (char *) &(regClie->nro_dci));
   memset(regClie->orga_dci, '\0', sizeof(regClie->orga_dci));

   rsetnull(CLONGTYPE, (char *) &(regClie->minist_repart));
   memset(regClie->papa_t23, '\0', sizeof(regClie->papa_t23));
   
}



short GenerarPlanos(regCliente)
$ClsClientes		regCliente;
{

/* 
   if(strcmp(regCliente.cod_calle, "")==0){
      GeneraStreet(fpStreetUnx, regCliente);
   }
*/
	GeneraAddress(fpAddressUnx, regCliente, "S");
    if(strcmp(regCliente.tipo_reparto, "POSTAL")==0){
        GeneraAddress(fpAddressUnx, regCliente, "P");
    }

	GeneraCuentas(fpCuentasUnx, regCliente);

	GeneraContactos(fpContactosUnx, regCliente);
/*
	GeneraCuentasContacto(fpCuentasContactosUnx, regCliente);
*/
	GeneraPointDelivery(fpPointDeliveryUnx, regCliente);

	GeneraServiceProduct(fpServiceProductUnx, regCliente);

	GeneraAsset(fpAssetUnx, regCliente);

	return 1;
}

void GeneraNomencla(fp, regNom)
FILE           *fp;
ClsNomencla    regNom;
{
	char	sLinea[1000];	
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ID */
   sprintf(sLinea, "\"%s%s\";", regNom.cod_calle, regNom.cod_localidad);
	
	/* NOMBRE_CALLE */
	sprintf(sLinea, "%s\"%s\";", sLinea, regNom.nombre_calle);
	
	/* TIPO CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CIUDAD */
	sprintf(sLinea, "%s\"%s\";", sLinea, regNom.desc_localidad);
	
	/* DEPARTAMENTO - PROVINCIA*/
   if(strcmp(regNom.cod_partido, "000")==0){
      strcat(sLinea, "\"C\";");
   }else{
      strcat(sLinea, "\"B\";");
   }
	
	/* PAIS */
	strcat(sLinea, "\"AR\";");
	
	/* COMUNA (CLIENTE.comuna) */
	sprintf(sLinea, "%s\"%s\";", sLinea, regNom.cod_localidad);
   
	/* REGION (CLIENTE.partido) */
	sprintf(sLinea, "%s\"%s\";", sLinea, regNom.cod_partido);
   
	/* CALLE (VACIO) */
	/*strcat(sLinea, "\"\";");*/
   /*sprintf(sLinea, "%s\"%s%s\";", sLinea, regNom.cod_calle, regNom.cod_localidad);*/
   sprintf(sLinea, "%s\"%s\";", sLinea, regNom.cod_calle);
   
	/* LOCALIDAD (VACIO) */
	strcat(sLinea, "\"\";");
	/* BARRIO (VACIO) */
	/*strcat(sLinea, ";");*/

	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	

}

void GeneraNoNomencla(fp)
FILE           *fp;
{
	char	sLinea[1000];	
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ID */
   strcpy(sLinea, "\"A0000A\";");
	
	/* NOMBRE_CALLE */
   strcat(sLinea, "\"DUMMY\";");
	
	/* TIPO CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CIUDAD */
   strcat(sLinea, "\"DUMMY\";");
	
	/* DEPARTAMENTO - PROVINCIA*/
   strcat(sLinea, "\"D\";");
	
	/* PAIS */
	strcat(sLinea, "\"AR\";");
	
	/* COMUNA (CLIENTE.comuna) */
   strcat(sLinea, "\"999\";");
   
	/* REGION (CLIENTE.partido) */
   strcat(sLinea, "\"999\";");
   
	/* CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	/* LOCALIDAD (VACIO) */
	strcat(sLinea, "\"\";");
	/* BARRIO (VACIO) */
	/*strcat(sLinea, ";");*/
	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	

}


void GeneraStreet(fp, regCli)
FILE 			*fp;
ClsClientes		regCli;
{
	char	sLinea[1000];	
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ID */
	sprintf(sLinea, "\"%ld-2\";", regCli.numero_cliente);
	
	/* NOMBRE_CALLE */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nom_calle);
	
	/* TIPO CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CIUDAD */
	/*sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nom_partido);*/
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nom_comuna);
	
	/* DEPARTAMENTO */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.provincia);
	
	/* PAIS */
	strcat(sLinea, "\"AR\";");
	
	/* COMUNA (CLIENTE.comuna) */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.comuna);
	/* REGION (CLIENTE.partido) */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.partido);
	/* CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	/* LOCALIDAD (VACIO) */
	strcat(sLinea, "\"\";");
	/* BARRIO (VACIO) */
	/*strcat(sLinea, ";");*/

	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
	
}

void GeneraAddress(fp, regCli, sTipoReparto)
FILE 			*fp;
ClsClientes 	regCli;
char            sTipoReparto[2];
{
	char	sLinea[1000];	
	char	sAux[100];
   char  sAuxL[200];
   char  sObs[200];
	
	memset(sLinea, '\0', sizeof(sLinea));
	memset(sAux, '\0', sizeof(sAux));
   memset(sAuxL, '\0', sizeof(sAuxL));
   memset(sObs, '\0', sizeof(sObs));

   if(sTipoReparto[0]=='S'){
       
        sprintf(sAux, "%s %s ", regCli.nom_calle, regCli.nro_dir);
        
        if(strcmp(regCli.piso_dir, "")!=0){
            sprintf(sAux, "%spiso %s ", sAux, regCli.piso_dir);	
        }
        if(strcmp(regCli.depto_dir, "")!=0){
            sprintf(sAux, "%sDpto. %s", sAux, regCli.depto_dir);	
        }	

        strcpy(sAuxL, sAux);
        
        if(strcmp(regCli.comuna, " ")!=0){
            sprintf(sAuxL, "%s Loc. %s", sAuxL, regCli.nom_comuna );
        }
        
        if(strcmp(regCli.partido, " ")!=0){
            sprintf(sAuxL, "%s Part. %s", sAuxL, regCli.nom_partido );
        }
            
        if(strcmp(regCli.obs_dir, "")!=0){
            strcpy(sObs, regCli.obs_dir);
        }
        if(strcmp(regCli.entre_calle1, "")!=0 && strcmp(regCli.entre_calle2, "")!=0){
            if(strcmp(sObs, "")!=0){
                sprintf(sObs, "% (Entre calle: %s y calle: %s)", sObs, regCli.entre_calle1, regCli.entre_calle2);
            }else{
                sprintf(sObs, "(Entre calle: %s y calle: %s)", regCli.entre_calle1, regCli.entre_calle2);
            }
        }
   }else{
        sprintf(sAux, "%s %s ", regCli.dp_nom_calle, regCli.dp_nro_dir);
        
        if(strcmp(regCli.dp_piso_dir, "")!=0){
            sprintf(sAux, "%spiso %s ", sAux, regCli.dp_piso_dir);	
        }
        if(strcmp(regCli.dp_depto_dir, "")!=0){
            sprintf(sAux, "%sDpto. %s", sAux, regCli.dp_depto_dir);	
        }	

        strcpy(sAuxL, sAux);
        
        if(strcmp(regCli.dp_nom_localidad, " ")!=0){
            sprintf(sAuxL, "%s Loc. %s", sAuxL, regCli.dp_nom_localidad );
        }
   }
	/* MONEDA */
	strcpy(sLinea, "\"ARS\";");
		
	/* ESQUINA (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* ALTURA */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nro_dir);

	/* OBSERVACIONES */
	if(strcmp(sObs, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, sObs);
	}else{
		strcat(sLinea, "\"\";");	
	}

	/* CP  */
    if(sTipoReparto[0]=='S'){
        if(!risnull(CINTTYPE, (char *) &regCli.cod_postal)){
            sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.cod_postal);
        }else{
            strcat(sLinea, "\"\";");
        }
    }else{
        if(!risnull(CINTTYPE, (char *) &regCli.dp_cod_postal)){
            sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.dp_cod_postal);
        }else{
            strcat(sLinea, "\"\";");
        }
    }
    
	/* ID */
   alltrim(regCli.tipo_reparto, ' ');
   if(sTipoReparto[0]== 'P'){
      sprintf(sLinea, "%s\"%ld-1ARG\";", sLinea, regCli.numero_cliente);
   }else{
      sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, regCli.numero_cliente);
   }
	
	
	/* ID-CALLE */
   if(sTipoReparto[0]== 'P'){
        strcat(sLinea, "\"A0000AARG\";");
   }else{
            
        if(strcmp(regCli.cod_calle, "")==0 || strcmp(regCli.cod_calle, "-1")==0){
            /*sprintf(sLinea, "%s\"%ld-2\";", sLinea, regCli.numero_cliente);*/
            strcat(sLinea, "\"A0000AARG\";");
        }else{
            if(ValidaCalle(regCli)){
                sprintf(sLinea, "%s\"%s%sARG\";", sLinea, regCli.cod_calle, regCli.comuna);
            }else{
                strcat(sLinea, "\"A0000AARG\";");
            }
        }
   }
   
	/* DEPARTAMENTO  */
   alltrim(regCli.nom_barrio, ' ');
   alltrim(regCli.nom_comuna, ' ');
   if(regCli.provincia[0]=='C'){
      sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nom_barrio);
   }else{
      sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nom_comuna);
   }
   
	/* CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO NUMERACION (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* DIRECCION */
	sprintf(sLinea, "%s\"%s\";", sLinea, sAux);

	/* SECTOR (VACIO) */
	strcat(sLinea, "\"\";");
	/* X (VACIO) */
	strcat(sLinea, "\"\";");
	/* Y (VACIO) */
	strcat(sLinea, "\"\";");
	/* NOMBRE AGRUPACION (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO AGRUPACION (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO INTERIOR (VACIO) */
	strcat(sLinea, "\"\";");
	/* DIRECCION LARGA */
	sprintf(sLinea, "%s\"%s\";", sLinea, sAuxL);

	/* LOTE (VACIO) */
	strcat(sLinea, "\"\";");

	/* TIPO SECTOR (VACIO) */
	strcat(sLinea, "\"\";");

	/* COMPANY ID */
	strcat(sLinea, "\"9\";");
   
   /* INTERSECCION1 */
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.entre_calle1);
   /* INTERSECCION2 */
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.entre_calle2);

   /* PISO */
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.piso_dir);
   
   /* DEPARTAMENTO */
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.depto_dir);
   
   /* EDIFICIO */
   strcat(sLinea, "\"\";");
   
	strcat(sLinea, "\n");

	fprintf(fp, sLinea);

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
		sprintf(sMensMail,"%sF.Desde:%s;F.Hasta:%s<br>",sMensMail, argv[4], argv[5]);
	}else{
		sprintf( sMensMail, "%sGeneracion<br>", sMensMail );
	}		
	
}
*/


char *strReplace(sCadena, cFind, cRemp)
char sCadena[1000];
char cFind[2];
char cRemp[2];
{
	char sNvaCadena[1000];
	int lLargo;
	int lPos;
	int dPos=0;
	
	lLargo=strlen(sCadena);

	for(lPos=0; lPos<lLargo; lPos++){

		if(sCadena[lPos]!= cFind[0]){
			sNvaCadena[dPos]=sCadena[lPos];
			dPos++;
		}else{
			if(strcmp(cRemp, "")!=0){
				sNvaCadena[dPos]=cRemp[0];	
				dPos++;
			}
		}
	}
	
	sNvaCadena[dPos]='\0';

	return sNvaCadena;
}

short CargoEmail(regCli)
$ClsClientes	*regCli;
{
	$EXECUTE selEmail into
		:regCli->email_1,
		:regCli->email_2,
      :regCli->email_3
		using
		:regCli->numero_cliente;
	
	if(SQLCODE != 0){
		if(SQLCODE == 100){
			strcpy(regCli->email_1, "NO TIENE");
			strcpy(regCli->email_2, "NO TIENE");
         strcpy(regCli->email_3, "NO TIENE");
			return 1;
		}else{
			return 0;	
		}	
	}
   
   alltrim(regCli->email_1, ' ');
   alltrim(regCli->email_2, ' ');
   alltrim(regCli->email_3, ' ');
   
   if(strcmp(regCli->email_1, "")==0){
      strcpy(regCli->email_1, "NO TIENE");   
   }

   if(strcmp(regCli->email_2, "")==0){
      strcpy(regCli->email_2, "NO TIENE");   
   }

   if(strcmp(regCli->email_3, "")==0){
      strcpy(regCli->email_3, "NO TIENE");   
   }
	
	return 1;
}

short CargoTelefonos(regCli)
$ClsClientes    *regCli;
{
	$ClsTelefonos	regTel;
	int            s=0;
	$ClsTeleCerta  regCerta;
   char           sTelefono[15];
	double         lTelefono;
   
	$OPEN curTelefonos using :regCli->numero_cliente;
   
	while(LeoTelefonos(&regTel)){
      memset(sTelefono, '\0', sizeof(sTelefono));
      
      sprintf(sTelefono, "%ld", regTel.numero_te);
      alltrim(sTelefono, ' ');

      if(strlen(sTelefono)>=7){
         alltrim(regTel.cod_area_te,' ');
         alltrim(regTel.prefijo_te, ' ');
   		if(strcmp(regTel.tipo_te, "CE")==0){
   		   sprintf(regCli->telefono_celular, "%s%s%ld", regTel.cod_area_te, regTel.prefijo_te, regTel.numero_te);
   		}else if(regTel.ppal_te[0]=='P'){
   			sprintf(regCli->telefono, "%s%ld", regTel.cod_area_te, regTel.numero_te);	
   		}else{
   			sprintf(regCli->telefono_secundario, "%s%ld", regTel.cod_area_te, regTel.numero_te);	
   		}
      }
	}	
		
	$CLOSE curTelefonos;

   if(LeoTelCerta(regCli->numero_cliente, &regCerta)){
      if(strcmp(regCerta.telefono_fijo, "")!=0){
         strcpy(regCli->telefono, regCerta.telefono_fijo);
      }
      if(strcmp(regCerta.telefono_movil, "")!=0){
         strcpy(regCli->telefono_celular, regCerta.telefono_movil);
      }
      if(strcmp(regCerta.telefono_secun, "")!=0){
         strcpy(regCli->telefono_secundario, regCerta.telefono_secun);
      }
   }

	alltrim(regCli->telefono, ' ');
	alltrim(regCli->telefono_secundario, ' ');
	alltrim(regCli->telefono_celular, ' ');
   
   
   lTelefono=atof(regCli->telefono);
   strcpy(sTelefono, regCli->telefono);
   alltrim(sTelefono, ' ');
   if(lTelefono<1000000 || strlen(sTelefono)<7 ){
      memset(regCli->telefono, '\0', sizeof(regCli->telefono));
   }
   lTelefono=atof(regCli->telefono_secundario);

   strcpy(sTelefono, regCli->telefono_secundario);
   alltrim(sTelefono, ' ');
   if(lTelefono<1000000 || strlen(sTelefono)<7 ){
      memset(regCli->telefono_secundario, '\0', sizeof(regCli->telefono_secundario));
   }
   lTelefono=atof(regCli->telefono_celular);

   strcpy(sTelefono, regCli->telefono_celular);
   alltrim(sTelefono, ' ');
   if(lTelefono<1000000 || strlen(sTelefono)<7 ){
      memset(regCli->telefono_celular, '\0', sizeof(regCli->telefono_celular));
   }

	alltrim(regCli->telefono, ' ');
	alltrim(regCli->telefono_secundario, ' ');
	alltrim(regCli->telefono_celular, ' ');

	
	return 1;
}

void InicializoTelefonos(regTel)
$ClsTelefonos	*regTel;
{

	memset(regTel->tipo_te, '\0', sizeof(regTel->tipo_te));
	memset(regTel->cod_area_te, '\0', sizeof(regTel->cod_area_te));	
	memset(regTel->prefijo_te, '\0', sizeof(regTel->prefijo_te));
	rsetnull(CLONGTYPE, (char *) &(regTel->numero_te));
	memset(regTel->ppal_te, '\0', sizeof(regTel->ppal_te));
		
}

short LeoTelefonos(regT)
$ClsTelefonos	*regT;
{

	InicializoTelefonos(regT);
	
	$FETCH curTelefonos into
		:regT->tipo_te,
		:regT->cod_area_te,
		:regT->prefijo_te,
		:regT->numero_te,
		:regT->ppal_te;	
	
	if(SQLCODE != 0){
		return 0;	
	}
   
	return 1;	
}

short LeoTelCerta(nroCliente, regCer)
$long          nroCliente;
$ClsTeleCerta  *regCer;
{

   memset(regCer->telefono_fijo, '\0', sizeof(regCer->telefono_fijo));
   memset(regCer->telefono_movil, '\0', sizeof(regCer->telefono_movil));
   memset(regCer->telefono_secun, '\0', sizeof(regCer->telefono_secun));
   memset(regCer->zona_tecnica, '\0', sizeof(regCer->zona_tecnica));

   $OPEN curTelCerta USING :nroCliente; 
   
   $FETCH curTelCerta INTO
      :regCer->telefono_fijo,
      :regCer->telefono_movil,
      :regCer->telefono_secun,
      :regCer->zona_tecnica;
   
   if(SQLCODE != 0){
      $CLOSE curTelCerta;
      return 0;
   }
   
   $CLOSE curTelCerta;
   
   alltrim(regCer->telefono_fijo, ' ');
   alltrim(regCer->telefono_movil, ' ');
   alltrim(regCer->telefono_secun, ' ');
   alltrim(regCer->zona_tecnica, ' ');
   
   return 1;
}

short CargoVIP(regCli)
$ClsClientes *regCli;
{
	$int iCant;
	
	$EXECUTE selVip into :iCant using :regCli->numero_cliente;
	
	if(SQLCODE != 0){
		return 0;	
	}
	
	if(iCant > 0){
		strcpy(regCli->electrodependiente, "1");	
	}else{
		strcpy(regCli->electrodependiente, "0");
	}
	
	return 1;
}

short CargoPostal(regCli)
$ClsClientes *regCli;
{
	
	$EXECUTE selPostal into
		:regCli->dp_nom_calle,
		:regCli->dp_nro_dir,
		:regCli->dp_piso_dir,
		:regCli->dp_depto_dir,
		:regCli->dp_cod_postal,
		:regCli->dp_nom_localidad
	using
		:regCli->numero_cliente;
			
	if(SQLCODE != 0){
		if(SQLCODE == 100){
			return 1;
		}
		printf("Error al cargar datos postales de cliente %ld\n", regCli->numero_cliente);
		return 0;
	}
		
	return 1;
}

short DatosMedidor(regCli)
$ClsClientes *regCli;
{
	$EXECUTE selMedidor into
		:regCli->medidor_nro,
		:regCli->medidor_marca,
		:regCli->medidor_modelo,
		:regCli->medidor_anio
	using :regCli->numero_cliente;
		
	if(SQLCODE != 0){
      if(SQLCODE != SQLNOTFOUND){
   		printf("Error al cargar datos del medidor de cliente %ld\n", regCli->numero_cliente);
   		return 0;
      }
	}
	
	return 1;
}

short DatosTecnicos(regCli)
$ClsClientes *regCli;
{
	$EXECUTE selTecni into
		:regCli->tec_centro_trans,
		:regCli->tipo_tranformador,
		:regCli->tipo_conexion,
		:regCli->tec_subestacion,
		:regCli->tec_alimentador,
      :regCli->cod_voltaje,
      :regCli->tec_nom_calle,
      :regCli->tec_nro_dir,
      :regCli->tec_piso_dir,
      :regCli->tec_depto_dir,
      :regCli->tec_cod_local
	using
		:regCli->numero_cliente;
			
	if(SQLCODE != 0){
		if(SQLCODE != 100){
			printf("Error al cargar datos tecnicos de cliente %ld\n", regCli->numero_cliente);
			return 0;
		}else{
			return 1;	
		}
	}
	
	alltrim(regCli->tec_centro_trans, ' ');
	alltrim(regCli->tipo_tranformador, ' ');
	alltrim(regCli->tipo_conexion, ' ');
	alltrim(regCli->tec_subestacion, ' ');
	alltrim(regCli->tec_alimentador, ' ');
   alltrim(regCli->cod_voltaje, ' ');

	alltrim(regCli->tec_nom_calle, ' ');
	alltrim(regCli->tec_nro_dir, ' ');
	alltrim(regCli->tec_piso_dir, ' ');
	alltrim(regCli->tec_depto_dir, ' ');
   alltrim(regCli->tec_cod_local, ' ');
	
	return 1;
}

short UltimoCorte(regCli)
$ClsClientes  *regCli;
{
	$EXECUTE selCorte into
		:regCli->ultimo_corte
	using
		:regCli->numero_cliente;
			
	if(SQLCODE!=0){
		if(SQLCODE!=100){
			printf("Error al buscar ultimo corte de cliente %ld\n", regCli->numero_cliente);
			return 0;				
		}else{
			return 1;	
		}
	}
	
	return 1;
}

void InicializaNomencla(regNom)
ClsNomencla *regNom;
{

   memset(regNom->cod_calle, '\0', sizeof(regNom->cod_calle)); 
   memset(regNom->nombre_calle, '\0', sizeof(regNom->nombre_calle)); 
   rsetnull(CLONGTYPE, (char *) &(regNom->altura_desde)); 
   rsetnull(CLONGTYPE, (char *) &(regNom->altura_hasta));
   memset(regNom->cod_partido, '\0', sizeof(regNom->cod_partido));
   memset(regNom->desc_partido, '\0', sizeof(regNom->desc_partido));
   memset(regNom->cod_localidad, '\0', sizeof(regNom->cod_localidad)); 
   memset(regNom->desc_localidad, '\0', sizeof(regNom->desc_localidad));

}

short LeoNomencla(regNom)
$ClsNomencla *regNom;
{
   InicializaNomencla(regNom);
   
   $FETCH curNomencla INTO
     :regNom->cod_calle, 
     :regNom->nombre_calle, 
     :regNom->altura_desde, 
     :regNom->altura_hasta,
     :regNom->cod_partido,
     :regNom->desc_partido,
     :regNom->cod_localidad, 
     :regNom->desc_localidad;
   
   if(SQLCODE != 0){
      return 0;      
   }

   alltrim(regNom->nombre_calle, ' ');
   alltrim(regNom->desc_partido, ' ');
   alltrim(regNom->desc_localidad, ' ');
   
   return 1;      
}

void GeneraCuentas(fp, regCli)
FILE 		*fp;
ClsClientes	regCli;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));
	

	/* ID */
	sprintf(sLinea, "\"%ldARG\";", regCli.numero_cliente);
	
	/* NOMBRE */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nombre);
	
	/* Tipo y Nro.de Documento */
	if(regCli.es_empresa[0]=='S'){
		if(strcmp(regCli.rut, "")!=0){
			/* TIPO DOCUMENTO */
			strcat(sLinea, "\"CE\";");
			/* NRO DOCUMENTO */
			sprintf(sLinea, "%s\"%s\";", sLinea, regCli.rut);
		}else{
            if(strcmp(regCli.tip_doc, "DEF")!=0){
                if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc) && regCli.nro_doc > 0 && regCli.nro_doc != 11111111){

                    if(strcmp(regCli.tip_doc, "")!=0){
                        /* TIPO DOCUMENTO */
                        sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tip_doc_SF);
                    }else{
                        /* TIPO DOCUMENTO */
                        strcat(sLinea, ";");
                    }
                    if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc)){
                        /* NRO DOCUMENTO */
                        sprintf(sLinea, "%s\"%.0f\";", sLinea, regCli.nro_doc);
                    }else{
                        /* NRO DOCUMENTO */
                        strcat(sLinea, "\"\";");
                    }
                }else{
                    /* TIPO DOCUMENTO */
                    strcat(sLinea, "\"\";");
                    /* NRO DOCUMENTO */
                    strcat(sLinea, "\"\";");
                }
            }else{
                /* TIPO DOCUMENTO */
                strcat(sLinea, "\"\";");
                /* NRO DOCUMENTO */
                strcat(sLinea, "\"\";");
            }
                    
		}
	}else{
        if(strcmp(regCli.tip_doc, "DEF")!=0){
            if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc) && regCli.nro_doc > 0 && regCli.nro_doc != 11111111){
        
                if(strcmp(regCli.tip_doc, "")!=0){
                    /* TIPO DOCUMENTO */
                    sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tip_doc_SF);
                }else{
                    /* TIPO DOCUMENTO */
                    strcat(sLinea, "\"\";");
                }
                if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc)){
                    /* NRO DOCUMENTO */
                    sprintf(sLinea, "%s\"%.0f\";", sLinea, regCli.nro_doc);
                }else{
                    /* NRO DOCUMENTO */
                    strcat(sLinea, "\"\";");
                }
            }else{
                /* TIPO DOCUMENTO */
                strcat(sLinea, "\"\";");
                /* NRO DOCUMENTO */
                strcat(sLinea, "\"\";");
            }
        }else{
            /* TIPO DOCUMENTO */
            strcat(sLinea, "\"\";");
            /* NRO DOCUMENTO */
            strcat(sLinea, "\"\";");
        }
            
            
	}
	
	/* EMAIL 1 */
	if(strcmp(regCli.email_1, "NO TIENE")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.email_1);
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* EMAIL 2 */
	if(strcmp(regCli.email_2, "NO TIENE")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.email_2);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* TELEFONO PPAL */
	if(strcmp(regCli.telefono, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono);
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* CELULAR */
	if(strcmp(regCli.telefono_celular, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono_celular);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* TELEFONO SEC */
	if(strcmp(regCli.telefono_secundario, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono_secundario);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* MONEDA */
	strcat(sLinea, "\"ARS\";");
	
	/* TIPO REGISTRO */
   /*
	if(regCli.es_empresa[0]=='S'){
		strcat(sLinea, "\"B2B\";");
	}else{
		strcat(sLinea, "\"B2C\";");
	}
   */
   strcat(sLinea, "\"B2C\";");
	
	/* FECHA NACIMIENTO (VACIO) */
	strcat(sLinea, "\"\";");
	/* CTA.PPAL (VACIO) */
	strcat(sLinea, "\"\";");
	/* APELLIDO MATERNO (VACIO) */
	strcat(sLinea, "\"\";");
	/* APELLIDO PATERNO  */
	strcat(sLinea, "\".\";");
	
	/* DIRECCION */
	sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, regCli.numero_cliente);
	
	/* EJECUTIVO (VACIO) */
	strcat(sLinea, "\"\";");
	/* GIRO (VACIO) */
	strcat(sLinea, "\"\";");
	/* CLASE SERVICIO (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* ID EMPRESA */
	strcat(sLinea, "\"9\";");
	
	/* NOMBRE DE LA EMPRESA */
	if(regCli.es_empresa[0]=='S'){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nombre);
	}else{
		strcat(sLinea, "\"\";");
	}

   /* Tipo IVA */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tipoIva);

   /* Email Adicional */
  	if(strcmp(regCli.email_3, "NO TIENE")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.email_3);
	}else{
		strcat(sLinea, "\"\";");
	}
   
   /* Tipo de Cuenta */
   if(regCli.es_empresa[0]=='S'){
      strcat(sLinea, "\"Persona Juridica\";");
   }else{
      strcat(sLinea, "\"Persona Fisica\";");
   }
  
   /* CuentaCliente  */
   sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.numero_cliente);
      
   /* Cuenta Padre */
   if(strcmp(regCli.papa_t23, "")!=0){
      sprintf(sLinea, "%s\"%sARG\";", sLinea, regCli.papa_t23);
   }else if(regCli.minist_repart > 0){
      sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.minist_repart);
   }else{
      strcat(sLinea, "\"\";");
   }
         
   /* Clase de Cuenta */
   sprintf(sLinea, "%s\"%s\";", sLinea, regCli.sClaseServicio);
   
   /* Tipo de Sociedad */
   strcat(sLinea, "\"\";");
            
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
}

void GeneraContactos(fp, regCli)
FILE 		*fp;
ClsClientes	regCli;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));
	
	/* ID */
	sprintf(sLinea, "\"%ldARG\";", regCli.numero_cliente);
	
	/* NOMBRE */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nombre);
	
	/* APELLIDO (VACIO) */
	strcat(sLinea, "\".\";");
	/* SALUDO (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* NOMBRE CUENTA */
	sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.numero_cliente);
	
	/* ESTADO CIVIL (VACIO) */
	strcat(sLinea, "\"\";");
	/* GENERO (VACIO) */
	strcat(sLinea, "\"\";");

    if(strcmp(regCli.tip_doc, "DEF")!=0){
        if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc) && regCli.nro_doc > 0 && regCli.nro_doc != 11111111){
            
            if(strcmp(regCli.tip_doc, "")!=0){
                /* TIPO DOCUMENTO */
                sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tip_doc);
            }else{
                /* TIPO DOCUMENTO */
                strcat(sLinea, "\"\";");
            }
            if(!risnull(CDOUBLETYPE, (char *) &regCli.nro_doc)){
                /* NRO DOCUMENTO */
                sprintf(sLinea, "%s\"%.0f\";", sLinea, regCli.nro_doc);
            }else{
                /* NRO DOCUMENTO */
                strcat(sLinea, "\"\";");
            }
        }else{
            /* TIPO DOCUMENTO */
            strcat(sLinea, "\"\";");
            /* NRO DOCUMENTO */
            strcat(sLinea, "\"\";");
        }
    }else{
        /* TIPO DOCUMENTO */
        strcat(sLinea, "\"\";");
        /* NRO DOCUMENTO */
        strcat(sLinea, "\"\";");
    }
	/* ETAPA */
	strcat(sLinea, "\"Active Customer\";");
	
	/* ESTRATO (VACIO) */
	strcat(sLinea, "\"\";");
	/* NIVEL EDUCATIVO (VACIO) */
	strcat(sLinea, "\"\";");
	/* AUTORIZACION DATOS (VACIO) */
	strcat(sLinea, "\"\";");
	/* NO LLAMAR (VACIO) */
	strcat(sLinea, "\"\";");
	/* NO CORREO (VACIO) */
	strcat(sLinea, "\"\";");
	/* PROFESION (VACIO) */
	strcat(sLinea, "\"\";");
	/* OCUPACION (VACIO) */
	strcat(sLinea, "\"\";");
	/* Fecha Nacimiento (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CANAL CONTACTO */
/*	
	if(strcmp(regCli.email_1, "NO TIENE")!=0){
		sprintf(sLinea, "%s%s;", sLinea, regCli.email_1);
	}else if(strcmp(regCli.telefono, "")!= 0){
		sprintf(sLinea, "%s%s;", sLinea, regCli.telefono);
	}else if(strcmp(regCli.telefono_secundario, "")!= 0){
		sprintf(sLinea, "%s%s;", sLinea, regCli.telefono_secundario);
	}else if(strcmp(regCli.telefono_celular, "")!= 0){
		sprintf(sLinea, "%s%s;", sLinea, regCli.telefono_celular);
	}else{
		strcat(sLinea, ";");	
	}
*/
   if(strcmp(regCli.email_1, "NO TIENE")==0){
	  strcat(sLinea, "\"CAN006\";");
   }else{
     strcat(sLinea, "\"CAN003\";");
   }
		
	/* EMAIL 1 */
	if(strcmp(regCli.email_1, "NO TIENE")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.email_1);
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* EMAIL 2 */
	if(strcmp(regCli.email_2, "NO TIENE")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.email_2);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* TELEFONO PPAL */
	if(strcmp(regCli.telefono, "")!= 0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono);
	}else{
		strcat(sLinea, "\"\";");
	}	
			
	/* TELEFONO SEC */
	if(strcmp(regCli.telefono_secundario, "")!= 0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono_secundario);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* CELULAR */
	if(strcmp(regCli.telefono_celular, "")!= 0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.telefono_celular);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* MONEDA */
	strcat(sLinea, "\"ARS\";");
	
	/* APELLIDO PATERNO (.) */
	strcat(sLinea, "\".\";");
	
	/* APELLIDO MATERNO (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO ACREDITACION (VACIO) */
	strcat(sLinea, "\"\";");
	/* DIRECC.DEL CONTACTO  */
   sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, regCli.numero_cliente);
	
	/* USR TWITTER (VACIO) */
	strcat(sLinea, "\"\";");
	/* SEGUIDORES TWITTER (VACIO) */
	strcat(sLinea, "\"\";");
	/* INFLUENCIA (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO INFLUENCIA (VACIO) */
	strcat(sLinea, "\"\";");
	/* BIO TWITTER (VACIO) */
	strcat(sLinea, "\"\";");
	/* ID USR TWITTER (VACIO) */
	strcat(sLinea, "\"\";");
	/* USR FACEBOOK (VACIO) */
	strcat(sLinea, "\"\";");
	/* ID USR FACBOOK (VACIO) */
	strcat(sLinea, "\"\";");
	/* ID EMPRESA */
	strcat(sLinea, "\"9\";");
	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
}

void GeneraCuentasContacto(fp, regCli)
FILE 		*fp;
ClsClientes	regCli;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));	
	
	/* ACTIVO */
	strcpy(sLinea, "\"X\";");
	
	/* CONTACTO */
	sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.numero_cliente);
	
	/* CUENTA */
	sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.numero_cliente);
	
	/* DIRECTO */
	strcat(sLinea, "\"X\";");
	
	/* FECHA FIN (VACIO) */
	strcat(sLinea, "\"\";");
	/* FECHA INICIO (VACIO) */
	strcat(sLinea, "\"\";");
	/* FUNCIONES (VACIO) */
	/*strcat(sLinea, ";");*/
	
	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
}

void GeneraPointDelivery(fp, regCli)
FILE 		*fp;
ClsClientes	regCli;
{
	char	sLinea[1000];
	char	sAux[100];
	
	memset(sLinea, '\0', sizeof(sLinea));
	memset(sAux, '\0', sizeof(sAux));

   /* Identificador POD */
   sprintf(sLinea, "\"%ldAR\";", regCli.numero_cliente);
   
	/* NUMERO POD */
	sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.numero_cliente);
	
	/* MONEDA */
	strcat(sLinea, "\"ARS\";");
	
	/* DV (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* DIRECCION */
   sprintf(sLinea, "%s\"%ld-2ARG\";", sLinea, regCli.numero_cliente);
	
	/* ESTADO POD */
	strcat(sLinea, "\"0\";");
	
	/* PAIS */
	strcat(sLinea, "\"ARGENTINA\";");
	
	/* COMUNA (VACIO) */
	strcat(sLinea, "\"\";");
	/* TIPO SEGMENTO */
	strcat(sLinea, "\"BT\";");
    
	/* MED.DICIPLINA (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* ID EMPRESA */
	strcat(sLinea, "\"9\";");
	
	/* ELECTRODEPENDIENTE */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.electrodependiente);
	
	/* TARIFA */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tarifa);
	
	/* TIPO AGRUPA (VACIO) */
	strcat(sLinea, "\"T1\";");
	/* FULL ELECTRIC (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* NOMBRE BOLETA */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nombre);
	
	/* RUTA (VACIO) */
	strcat(sLinea, "\"\";");

	
   /* DIRECCION DE REPARTO */
   sprintf(sAux, "%s %s ", regCli.tec_nom_calle, regCli.tec_nro_dir);
	if(strcmp(regCli.tec_piso_dir, "")!=0){
		sprintf(sAux, "%spiso %s ", sAux, regCli.tec_piso_dir);	
	}
	if(strcmp(regCli.tec_depto_dir, "")!=0){
		sprintf(sAux, "%sDpto. %s", sAux, regCli.tec_depto_dir);	
	}
   if(strcmp(sAux, "")!=0){		
      sprintf(sLinea, "%s\"%s\";", sLinea, sAux);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* COMUNA DE REPARTO */
   if(strcmp(regCli.tec_cod_local, "")!=0){
      sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tec_cod_local);
   }else{
      strcat(sLinea, "\"\";");
   }
	
	/* NRO.TRANSFORMADOR */
	if(strcmp(regCli.tec_centro_trans, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tec_centro_trans);
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* TIPO TRANSFORMADOR */
	if(strcmp(regCli.tipo_tranformador, "")!=0){
		/*sprintf(sLinea, "%s%s;", sLinea, regCli.tipo_tranformador);*/
      strcat(sLinea, "\"\";");
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* TIPO CONEXION */

   if(strcmp(regCli.cod_voltaje, "")!=0){
      if(atoi(regCli.cod_voltaje)==1){
         strcat(sLinea, "\"MF\";");
      }else{
         strcat(sLinea, "\"TF\";");
      }
		
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* ESTRATO (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* SUBESTACION */
	if(strcmp(regCli.tec_subestacion, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tec_subestacion);
	}else{
		strcat(sLinea, "\"\";");
	}
		
	/* COND.INSTALACION (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* NRO ALIMENTADOR */
	if(strcmp(regCli.tec_alimentador, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tec_alimentador);
	}else{
		strcat(sLinea, "\"\";");
	}	
	
	/* TIPO LECTURA */
	strcat(sLinea, "\"8\";");
	
	/* BLOQUE (VACIO) */
   sprintf(sLinea, "%s\"%s\";",sLinea, regCli.sucursal );
	
	/* HORAIO RACIONAMIENTO(VACIO) */
	strcat(sLinea, "\"\";");
	
	/* ESTADO CONEXION */
	strcat(sLinea, "\"0\";");
	
	/* FECHA ULTIMO CORTE */
	if(strcmp(regCli.ultimo_corte, "")!= 0){
		sprintf(sLinea, "%s\"%sT00:00:00.000Z\";", sLinea, regCli.ultimo_corte);
	}else{
		strcat(sLinea, "\"\";");	
	}
	
	/* COD.PRC (VACIO) */
	strcat(sLinea, "\"\";");
	/* SED (VACIO) */
	strcat(sLinea, "\"\";");
	/* SET (VACIO) */
	strcat(sLinea, "\"\";");
	/* LLAVE (VACIO) */
	strcat(sLinea, "\"\";");
	/* POTENCIA */
   if(regCli.potencia_inst_fp >0.00){
      sprintf(sLinea, "%s\"%.02f\";", sLinea, regCli.potencia_inst_fp);
   }else{
	  strcat(sLinea, "\"\";");
   }
	/* CLIENTE SINGULAR (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CLASE SERVICIO */
	/*
	sprintf(sLinea, "%s%s;", sLinea, regCli.sClaseServicio);
	*/
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.tipo_cliente);
	
	/* SUB CLASE SERVICIO */
	/*sprintf(sLinea, "%s\"%s\";", sLinea, regCli.sSubClaseServ);*/
   strcat(sLinea, "\"\";");
	
	/* RUTA LECTURA */
	sprintf(sLinea, "%s\"%s%ld%ld%ld\";", sLinea, regCli.sucursal, regCli.sector, regCli.zona, regCli.correlativo_ruta);
	
	/* TIPO LIQUIDACION (VACIO) */
	strcat(sLinea, "\"\";");
	/* MERCADO (VACIO) */
	strcat(sLinea, "\"\";");
	/* CARGA AFORADA (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* ANO FABRICACION */
	sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.medidor_anio);
   
	/* CANT.PERSONAS EN PUNTO DE SUMINISTRO */
	strcat(sLinea, "\"\";");
   
   /* Nro.DCI */
   if(regCli.nro_dci > 0){
      sprintf(sLinea, "%s\"%.0lf\";", sLinea, regCli.nro_dci);
   }else{
      strcat(sLinea, "\"\";");
   }
   
   /* Organismo */
	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.orga_dci);
   
   /* Potencia Convenida */
   strcat(sLinea, "\"\";");

   /* Fecha Desconexion */
   strcat(sLinea, "\"\";");
   
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
}

void GeneraServiceProduct(fp, regCli)
FILE 		*fp;
ClsClientes	regCli;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ACTIVO */	
	sprintf(sLinea, "\"%ldARG\";", regCli.numero_cliente);
	
	/* CONTACTO */
	sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.numero_cliente);
	
	/* CUENTA */
	sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.numero_cliente);
	
	/* PAIS */
	strcat(sLinea, "\"ARGENTINA\";");
	
	/* COMPANIA */
	strcat(sLinea, "\"9\";");

   /* EXTERNAL ID */
   sprintf(sLinea, "%s\"%ldSPRARG\";", sLinea, regCli.numero_cliente);

	/* CONTACTO PRINCIPAL */
	strcat(sLinea, "\"TRUE\";");
   
   /* ElectroDependiente*/
   if(regCli.electrodependiente[0]=='1'){
      /* Electro */
      /*strcat(sLinea, "\"TRUE\";");*/
      strcat(sLinea, "\"FALSE\";");
      /* Nro.DCI */
      if(regCli.nro_dci > 0){
         sprintf(sLinea, "%s\"%.0lf\";", sLinea, regCli.nro_dci);
      }else{
         strcat(sLinea, "\"\";");
      }
      
      /* Organismo */
   	sprintf(sLinea, "%s\"%s\";", sLinea, regCli.orga_dci);
      
   }else{
      /* Electro */
      strcat(sLinea, "\"FALSE\";");
      /* DCI */
      strcat(sLinea, "\"\";");
      /* Organismo */
      strcat(sLinea, "\"\";");
   }
   
   
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);
}

void GeneraAsset(fp, regCli)
FILE 		*fp;
ClsClientes regCli;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));
	
	/* ID */
	sprintf(sLinea, "\"%ldARG\";", regCli.numero_cliente);
	
	/* NOMBRE */
	/*sprintf(sLinea, "%s\"%s\";", sLinea, regCli.nombre);*/
	sprintf(sLinea, "%s\"Tarifa T1-%ld\";", sLinea, regCli.numero_cliente);
   
	/* CUENTA */
	sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.numero_cliente);
	
	/* CONTACTO */
	sprintf(sLinea, "%s\"%ldARG\";", sLinea, regCli.numero_cliente);
	
	/* SUMINISTRO */
	sprintf(sLinea, "%s\"%ldAR\";", sLinea, regCli.numero_cliente);
	
	/* DESCRIPCION */
	sprintf(sLinea, "%s\"%ld\";", sLinea, regCli.nombre);
	
	/* PRODUCTO */
	sprintf(sLinea, "%s\"%ldSPRARG\";", sLinea, regCli.numero_cliente);
	
	/* ESTADO */
   if(giEstadoCliente==0){
      strcat(sLinea, "\"Installed\";");
   }else{
      strcat(sLinea, "\"Unsuscribed\";");
   }
   
   /* Contacto Principal */
	strcat(sLinea, "\"TRUE\";");
	
   /* Contrato */
   sprintf(sLinea, "%s\"%ldCTOARG\";", sLinea, regCli.numero_cliente);
   
   /* Estado Contratacion */
   if(giEstadoCliente==0){
      strcat(sLinea, "\"Active\";");
   }else{
      strcat(sLinea, "\"Inactive\";");
   }
   
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	
}

short ValidaCalle(reg)
$ClsClientes   reg; 
{
   $int iCant;
   $long  lAltura;
   
   lAltura = atol(reg.nro_dir);
   
   if(lAltura <= 0){
      return 0;  
   }
               
   if(strcmp(reg.cod_calle, "")==0){
      return 0;
   }

   if(strcmp(reg.partido, "")==0){
      return 0;
   }
               
   if(strcmp(reg.comuna, "")==0){
      return 0;
   }

   iCant=0;
   
   $EXECUTE selValCalle
      INTO :iCant
      USING :reg.cod_calle,
            :lAltura,
            :lAltura,
            :reg.partido,
            :reg.comuna;
            
   if(SQLCODE != 0){
      printf("Error al validar calle nomenclada %s Partido %s Comuna %s", reg.cod_calle, reg.partido, reg.comuna);
      return 0;
   }            
   
   if(iCant <= 0){
      return 0;
   }
   
   return 1;
}

short ValidaFecha(stringFecha)
char  *stringFecha;
{
int  error = 0;
long fecha = 0;

   error = rdefmtdate(&fecha, "dd/mm/yyyy", stringFecha);

   switch (error){
      case 0:
         break;	/* OK */
      case -1204:
         printf("Anio Invalido en fecha %s\n", stringFecha);
         return 0;
      case -1205:
         printf("Mes Invalido en fecha %s\n", stringFecha);
         return 0;
      case -1206:
         printf("Dia Invalido en fecha %s\n", stringFecha);
         return 0;
      case -1209:
         printf("A la fecha %s le faltan los delimitadores\n", stringFecha);
         return 0;
      default:
         printf("Fecha %s es inválida\n", stringFecha);
         return 0;
   }

   return 1;
}

void CargaPeriodoAnalisis(argc, argv, sFechaAyer)
int		argc;
char	* argv[];
char  *sFechaAyer;
{
char  sDia[3];
char  sMes[3];
char  sAnio[5];
char  sFechaParam[11];

   memset(sDia, '\0', sizeof(sDia));
   memset(sMes, '\0', sizeof(sMes));
   memset(sAnio, '\0', sizeof(sAnio));
   memset(sFechaParam, '\0', sizeof(sFechaParam));
   
   memset(gsFechaDesdeLarga, '\0', sizeof(gsFechaDesdeLarga));
   memset(gsFechaHastaLarga, '\0', sizeof(gsFechaHastaLarga));
   memset(gsFechaFile, '\0', sizeof(gsFechaFile));

   if(argc >= 3){
      strcpy(sFechaParam, argv[2]);
      sprintf(sDia, "%c%c", sFechaParam[0], sFechaParam[1]);
      sprintf(sMes, "%c%c", sFechaParam[3], sFechaParam[4]);
      sprintf(sAnio, "%c%c%c%c", sFechaParam[6], sFechaParam[7],sFechaParam[8], sFechaParam[9]);
      rdefmtdate(&glFechaDesde, "dd-mm-yyyy", sFechaParam);
   }else{
      sprintf(sDia, "%c%c", sFechaAyer[0], sFechaAyer[1]);
      sprintf(sMes, "%c%c", sFechaAyer[3], sFechaAyer[4]);
      sprintf(sAnio, "%c%c%c%c", sFechaAyer[6], sFechaAyer[7],sFechaAyer[8], sFechaAyer[9]);
      rdefmtdate(&glFechaDesde, "dd/mm/yyyy", sFechaAyer);
   }
   sprintf(gsFechaDesdeLarga, "%s-%s-%s 00:00", sAnio, sMes, sDia);
   sprintf(gsFechaFile, "%s%s%s", sAnio, sMes, sDia);

   memset(sFechaParam, '\0', sizeof(sFechaParam));
   if(argc == 4){
      strcpy(sFechaParam, argv[3]);
      sprintf(sDia, "%c%c", sFechaParam[0], sFechaParam[1]);
      sprintf(sMes, "%c%c", sFechaParam[3], sFechaParam[4]);
      sprintf(sAnio, "%c%c%c%c", sFechaParam[6], sFechaParam[7],sFechaParam[8], sFechaParam[9]);
      sprintf(gsFechaHastaLarga, "%s-%s-%s 23:59", sAnio, sMes, sDia);
      rdefmtdate(&glFechaHasta, "dd/mm/yyyy", sFechaParam);

   }else{
      sprintf(gsFechaHastaLarga, "%s-%s-%s 23:59", sAnio, sMes, sDia);
      glFechaHasta=glFechaDesde;
   }
   
}

short CargaContingente(){
$char sDesde[20];
$char sHasta[20];

   memset(sDesde, '\0', sizeof(sDesde));
   memset(sDesde, '\0', sizeof(sDesde));
   
   sprintf(sDesde, "%s:00", gsFechaDesdeLarga);
   sprintf(sHasta, "%s:59", gsFechaHastaLarga);
   
   /* Limpio Contingente */
   $EXECUTE delActuClie;
   
   if(SQLCODE != 0){
      printf("Falló limpieza tabla contingente.\n");
      return 0;
   }

   /* Altas Puras de clientes */
   $EXECUTE insAltas USING :glFechaDesde, :glFechaHasta;
   
   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga de altas Puras.\n");
         return 0;
      }
   }
   
   /* Bajas Puras Clientes */
   
   $EXECUTE insBajas USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga de bajas Puras.\n");
         return 0;
      }
   }
   
   /* Altas por Cambio Titularidad */
   $EXECUTE insAltasCT USING :sDesde, :sHasta;
   
   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga de altas por CT.\n");
         return 0;
      }
   }

  
   /* Bajas por Cambio Titularidad */
   $EXECUTE insBajasCT USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga de bajas por CT.\n");
         return 0;
      }
   }
   
   /* Cambio Tarifas */
   $EXECUTE insTarifas USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Tarifas.\n");
         return 0;
      }
   }
   
   /* Cambio Potencia */
   $EXECUTE insPotencia USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Potencia.\n");
         return 0;
      }
   }

   /* Cambio Nombre */
   $EXECUTE insNombre USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Nombre.\n");
         return 0;
      }
   }

   /* Cambio Sucursal */
   $EXECUTE insSucursal USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Sucursal.\n");
         return 0;
      }
   }

   /* Cambio Dirección Suministro */
   $EXECUTE insDirSum USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Direccion Suministro.\n");
         return 0;
      }
   }

   /* Cambio Dirección Postal */
   $EXECUTE insDirPost USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Direccion Postal.\n");
         return 0;
      }
   }

   /* Cambios Varios */
   $EXECUTE insVarios USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Varios.\n");
         return 0;
      }
   }

   /*  Cambio Datos Medidor */
   $EXECUTE insCamMed USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Cambio Data Medidor.\n");
         return 0;
      }
   }
   
   /* Inversion de Medidor */
   $EXECUTE insInvMed USING :gsFechaDesdeLarga, :gsFechaHastaLarga;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Inv. Medidor.\n");
         return 0;
      }
   }
   
   /* Alta de Medidor */
   $EXECUTE insAltaMed USING :glFechaDesde, :glFechaHasta;

   if(SQLCODE != 0){
      if(SQLCODE != 100){
         printf("Falló Carga Inv. Medidor.\n");
         return 0;
      }
   }
   
   /* Baja de Medidor */
   
   
   return 1;
}

short LeoBajas(lNroCliente)
$long *lNroCliente;
{
   $long lNumeroCliente;
   
   $FETCH curBajas INTO :lNumeroCliente;
   
   if(SQLCODE != 0){
      return 0;
   }
   
   *lNroCliente = lNumeroCliente;

   return 1;
}

void GeneraBaja(lNroCliente)
long  lNroCliente;
{
	char	sLinea[1000];
	
	memset(sLinea, '\0', sizeof(sLinea));
	

	/* ID */
	sprintf(sLinea, "\"%ldAR\";", lNroCliente);
   
   /* Estado del Suministro */
   strcat(sLinea, "\"1\"");
   
	strcat(sLinea, "\n");
	
	fprintf(fpBajasUnx, sLinea);	

}

short RegistraCorrida(iCant)
$long iCant;
{

   $EXECUTE insLog USING
      :glFechaDesde,
      :glFechaHasta,
      :iCant;
      
   if(SQLCODE != 0)
      return 0;

   return 1;
}

short CargoContactos(void){
$char sDesde[20];
$char sHasta[20];

   memset(sDesde, '\0', sizeof(sDesde));
   memset(sDesde, '\0', sizeof(sDesde));
   
   sprintf(sDesde, "%s:00", gsFechaDesdeLarga);
   sprintf(sHasta, "%s:59", gsFechaHastaLarga);
   
   /* Limpio Contingente */
   $EXECUTE delActuClie;
   
   if(SQLCODE != 0){
      printf("Falló limpieza tabla contingente etapa CONTACTOS.\n");
      return 0;
   }

   /* Cargo Contactos */
   $EXECUTE insContactos USING :sDesde, :sHasta;

   if(SQLCODE != 0){
      printf("Falló carga tabla contingente etapa CONTACTOS.\n");
      return 0;
   }

   return 1;
}

short LeoContactos(regCli, iEmail)
$ClsClientes *regCli;
int          *iEmail;
{
   int iRcv;
   
	InicializaCliente(regCli);

	$FETCH curContactos INTO
		:regCli->numero_cliente,
      :regCli->email_contacto,
		:regCli->nombre,
      :regCli->cod_calle,
		:regCli->nom_calle,
		:regCli->nom_partido,
		:regCli->provincia,
		:regCli->nom_comuna,
		:regCli->nro_dir,
		:regCli->obs_dir,
		:regCli->cod_postal,
		:regCli->piso_dir,
		:regCli->depto_dir,
		:regCli->tip_doc,
		:regCli->nro_doc,
		:regCli->telefono,
		:regCli->tipo_cliente,
		:regCli->rut,
		:regCli->tipo_reparto,
		:regCli->sucursal,
		:regCli->sector,
		:regCli->zona,
		:regCli->tarifa,
		:regCli->correlativo_ruta,
		:regCli->sClaseServicio,
		:regCli->sSubClaseServ,
		:regCli->partido,
		:regCli->comuna,
      :regCli->tec_cod_calle,
      :regCli->nom_barrio,
      :regCli->potencia_inst_fp,
      :regCli->entre_calle1,
      :regCli->entre_calle2;
      
				
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de CLIENTES !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

   alltrim(regCli->email_contacto, ' ');
	alltrim(regCli->nombre, ' ');
	alltrim(regCli->nom_calle, ' ');
	alltrim(regCli->nom_partido, ' ');
	alltrim(regCli->nro_dir, ' ');
	alltrim(regCli->piso_dir, ' ');
	alltrim(regCli->depto_dir, ' ');
	alltrim(regCli->obs_dir, ' ');
	alltrim(regCli->rut, ' ');
	alltrim(regCli->tip_doc, ' ');
	alltrim(regCli->email_1, ' ');
	alltrim(regCli->email_2, ' ');
	alltrim(regCli->sClaseServicio, ' ');
	alltrim(regCli->sSubClaseServ, ' ');
	alltrim(regCli->nom_comuna, ' ');
   
   alltrim(regCli->cod_calle, ' ');
   alltrim(regCli->tec_cod_calle, ' ');
   alltrim(regCli->entre_calle1, ' ');
   alltrim(regCli->entre_calle2, ' ');
   
   if(strcmp(regCli->cod_calle, "")==0 || strcmp(regCli->cod_calle, "-1")==0){
      if(strcmp(regCli->tec_cod_calle, "")!=0 && strcmp(regCli->tec_cod_calle, "-1")!=0){
         strcpy(regCli->cod_calle, regCli->tec_cod_calle);
      }
   }

	if(!CargoEmail(regCli)){
		return 0;	
	}

   if(strcmp(regCli->email_1, "NO TIENE")==0 && strcmp(regCli->email_2, "NO TIENE")==0){
      if(ValidaEmail(regCli->email_contacto)){
         strcpy(regCli->email_1, regCli->email_contacto);
         *iEmail = 1;
      }else{
         return 1;
      }   
   }else if(strcmp(regCli->email_1, "NO TIENE")!=0 && strcmp(regCli->email_2, "NO TIENE")==0){
      if(ValidaEmail(regCli->email_contacto)){
         if(strcmp(regCli->email_1, regCli->email_contacto)!=0){
            strcpy(regCli->email_2, regCli->email_contacto);
            *iEmail = 1;
         }
      }else{
         return 1;
      }
      
   }else{
      return 1;
   }

	alltrim(regCli->email_1, ' ');
	alltrim(regCli->email_2, ' ');


	if(!CargoTelefonos(regCli)){
		return 0;
	}

	if(!CargoVIP(regCli)){
		return 0;		
	}
   
	if(strcmp(regCli->tipo_reparto, "POSTAL")){
		if(!CargoPostal(regCli)){
			return 0;
		}
	}

   iRcv=DatosMedidor(regCli);
/*   
	if(!DatosMedidor(regCli)){
		return 0;	
	}
*/

	if(!DatosTecnicos(regCli)){
		return 0;
	}

	if(!UltimoCorte(regCli)){
		return 0;	
	}

	if(strcmp(regCli->tipo_cliente, "CP")!=0){
		if(strcmp(regCli->tipo_cliente, "IP")!=0){
			if(strcmp(regCli->tipo_cliente, "LS")!=0){
				if(strcmp(regCli->tipo_cliente, "SL")!=0){
					if(strcmp(regCli->tipo_cliente, "OM")!=0){
						if(strcmp(regCli->tipo_cliente, "ON")!=0){
							if(strcmp(regCli->tipo_cliente, "OP")!=0){
								if(strcmp(regCli->tipo_cliente, "PC")!=0){
									if(strcmp(regCli->tipo_cliente, "PI")!=0){
										strcpy(regCli->es_empresa, "N");
									}else{
										strcpy(regCli->es_empresa, "S");
									}
								}else{
									strcpy(regCli->es_empresa, "S");
								}
							}else{
								strcpy(regCli->es_empresa, "S");
							}
						}else{
							strcpy(regCli->es_empresa, "S");
						}
					}else{
						strcpy(regCli->es_empresa, "S");
					}
				}else{
					strcpy(regCli->es_empresa, "S");
				}
			}else{
				strcpy(regCli->es_empresa, "S");
			}
		}else{
			strcpy(regCli->es_empresa, "S");
		}
	}else{
		strcpy(regCli->es_empresa, "S");
	}


	return 1;	
}

short CargaDCI(reg)
$ClsClientes *reg;
{

   $EXECUTE selDCI INTO 
      :reg->orga_dci,
      :reg->nro_dci
   USING :reg->numero_cliente;
   
   if(SQLCODE != 0){
      if(SQLCODE != SQLNOTFOUND){
         printf("Error al buscar DCI para cliente %ld\n", reg->numero_cliente);
         return 0;
      }
   }

   return 1;
}

short ValidaEmail(eMail)
char    *eMail;
{
    int     i, j, s;
    int     largo=0;
    int     valor=0;
    char    *sResu;
    int     iPos;
    int     iAsc;

    largo=strlen(eMail);
    iPos=0;
    if(largo<=0){
        return 0;
    }

    /* Que no tenga caracteres inválidos */
    valor=0;
    i=0;
    s=0;

    while(i<largo && s==0){
        iAsc=eMail[i];

        if(iAsc >= 1 && iAsc < 45){
            s=1;
        }

        if(iAsc==47)
            s=1;

        if(iAsc >= 58 && iAsc <= 63){
            s=1;
        }

        if(iAsc >= 91 && iAsc <= 96 && iAsc != 95){
            s=1;
        }

        if(iAsc >= 126 && iAsc <= 255){
            s=1;
        }

        i++;

    }

    if(s==1){
        return 0;
   }

    /* Que no termine en punto */
    if(eMail[largo-1]=='.'){
        return 0;
    }


    /* Que solo tenga una @ */
    valor=instr(eMail, "@");
    if(valor != 1){
        return 0;
    }

    /* Que tenga al menos un punto */
    valor=instr(eMail, ".");
    if(valor < 1){
        return 0;
    }

    /* Que no tenga '..' */
    if(strstr(eMail, "..") != NULL){
        return 0;
    }

    /* Que no tenga '.@' */
    if(strstr(eMail, ".@") != NULL){
        return 0;
    }

    /* Que no tenga '@.' */
    if(strstr(eMail, "@.") != NULL){
        return 0;
    }

    return 1;
}


short PadreEnT23(reg)
$ClsClientes *reg;
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

int instr(cadena, patron)
char  *cadena;
char  *patron;
{
   int valor=0;
   int i;
   int largo;
   
   largo = strlen(cadena);
   
   for(i=0; i<largo; i++){
      if(cadena[i]==patron[0])
         valor++;
   }
   return valor;
}

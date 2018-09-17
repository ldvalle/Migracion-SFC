/********************************************************************************
    Proyecto: Migracion al sistema SALES FORCE
    Aplicacion: sfc_street
    
	Fecha : 10/01/2018

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Extractor que genera el archivo plano para las estructura STREET
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>
		<Estado Cliente> : 0=Activos; 1= No Activos; 2= Todos;		
		<Tipo Generacion>: G = Generacion; R = Regeneracion
		
		<Nro.Cliente>: Opcional

*******************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_street.h";

/* Variables Globales */
$long	glNroCliente;
$int	giEstadoCliente;
$char	gsTipoGenera[2];

FILE	*fpStreetUnx;

char	sArchStreetUnx[100];
char	sArchStreetAux[100];
char	sArchStreetDos[100];
char	sSoloArchivoStreetUnx[100];

char	sPathSalida[100];
char	FechaGeneracion[9];	
char	MsgControl[100];
$char	fecha[9];
long	lCorrelativo;

long	cantProcesada;

char	sMensMail[1024];	

/* Variables Globales Host */
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

/*
   strcpy(sCommand, "export LANG=es_ES.UTF-8");
   iRcv=system(sCommand);
*/   
   /*setlocale(LC_ALL, "es_ES.UTF-8");*/
   /*setlocale(LC_ALL, "en_US.ISO8859-1");*/

	if(! AnalizarParametros(argc, argv)){
		exit(0);
	}

   /*strcpy(sCommand, setlocale(LC_ALL, "es_ES.UTF8"));*/
	
	hora = time(&hora);
	
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));
	
	strcpy(nombreBase, argv[1]);
	
	$DATABASE :nombreBase;	
	
	$SET LOCK MODE TO WAIT 600;
	$SET ISOLATION TO DIRTY READ;
	
	/*$BEGIN WORK;*/

	CreaPrepare();

		
	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
	if(!AbreArchivos()){
		exit(1);	
	}

	cantProcesada=0;

	/*********************************************
				GENERO CALLES NOMENCLADAS
	**********************************************/
   $OPEN curNomencla;
      
   while(LeoNomencla(&regNomencla)){
      GeneraNomencla(fpStreetUnx, regNomencla);
   }
   
   $CLOSE curNomencla;
   GeneraNoNomencla(fpStreetUnx);

	CerrarArchivos();

	FormateaArchivos();
	
	/*$COMMIT WORK;*/

	$CLOSE DATABASE;

	$DISCONNECT CURRENT;

	/* ********************************************
				FIN AREA DE PROCESO
	********************************************* */

	printf("==============================================\n");
	printf("EMERGENCIAS\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
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

	if(argc != 2){
		MensajeParametros();
		return 0;
	}
	
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   
   memset(sTitulos, '\0', sizeof(sTitulos));
   
	memset(sArchStreetUnx, '\0', sizeof(sArchStreetUnx));
   memset(sArchStreetAux, '\0', sizeof(sArchStreetAux));
   memset(sArchStreetDos, '\0', sizeof(sArchStreetDos));
	memset(sSoloArchivoStreetUnx, '\0', sizeof(sSoloArchivoStreetUnx));
	memset(sFecha, '\0', sizeof(sFecha));

	memset(sPathSalida,'\0',sizeof(sPathSalida));

   FechaGeneracionFormateada(sFecha);
	RutaArchivos( sPathSalida, "SALESF" );
	
	alltrim(sPathSalida,' ');

   /* Armo nombres de archivo */
	strcpy(sSoloArchivoStreetUnx, "T1STREET.unx");
	sprintf(sArchStreetUnx, "%s%s", sPathSalida, sSoloArchivoStreetUnx);
   sprintf(sArchStreetAux, "%sT1STREET.aux", sPathSalida);
   sprintf(sArchStreetDos, "%senel_care_street_t1_%s.csv", sPathSalida, sFecha);
	
	
   /* Abro Archivos*/
	fpStreetUnx=fopen( sArchStreetUnx, "w" );
	if( !fpStreetUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchStreetUnx );
		return 0;
	}
   
   strcpy(sTitulos,"\"Identificador único\";\"Nombre de la calle\";\"Tipo de Calle\";\"Ciudad\";\"Departamento\";\"Pais\";\"Comuna\";\"Region\";\"Calle\";\"Localidad\";\"Barrio\";\"Compañia\"\n");
   fprintf(fpStreetUnx, sTitulos);
							
	return 1;	
}

void CerrarArchivos(void)
{
	fclose(fpStreetUnx);
}

void FormateaArchivos(void){
char	sCommand[1000];
int	iRcv, i;
$char	sPathCp[100];
$char sClave[7];
	
	memset(sCommand, '\0', sizeof(sCommand));
	memset(sPathCp, '\0', sizeof(sPathCp));
   strcpy(sClave, "SALEFC");
   
	$EXECUTE selRutaFinal INTO :sPathCp using :sClave;

    if ( SQLCODE != 0 ){
        printf("ERROR.\nSe produjo un error al tratar de recuperar el path destino del archivo.\n");
        exit(1);
    }
   /* ----------- */
   
   sprintf(sCommand, "unix2dos %s | tr -d '\32' > %s", sArchStreetUnx, sArchStreetAux);
	iRcv=system(sCommand);
      
   sprintf(sCommand, "iconv -f WINDOWS-1252 -t UTF-8 %s > %s ", sArchStreetAux, sArchStreetDos);
   iRcv=system(sCommand);
   
	sprintf(sCommand, "chmod 777 %s", sArchStreetDos);
	iRcv=system(sCommand);
   
	
	sprintf(sCommand, "cp %s %s", sArchStreetDos, sPathCp);
	iRcv=system(sCommand);
  
   sprintf(sCommand, "rm %s", sArchStreetUnx);
   iRcv=system(sCommand);

   sprintf(sCommand, "rm %s", sArchStreetAux);
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
   strcat(sql, "WHERE nc.nom_altura_hasta > nc.nom_altura_desde ");
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

	/******** Select Path Destino Final ****************/
	strcpy(sql, "SELECT valor_alf ");
	strcat(sql, "FROM tabla ");
	strcat(sql, "WHERE nomtabla = 'PATH' ");
	strcat(sql, "AND codigo = ? ");
	strcat(sql, "AND sucursal = '0000' ");
	strcat(sql, "AND fecha_activacion <= TODAY ");
	strcat(sql, "AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL ) ");

	$PREPARE selRutaFinal FROM $sql;

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


void GeneraNomencla(fp, regNom)
FILE           *fp;
ClsNomencla    regNom;
{
	char	sLinea[1000];	
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ID */
   sprintf(sLinea, "\"%s%sARG\";", regNom.cod_calle, regNom.cod_localidad);
	
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
	strcat(sLinea, "\"ARGENTINA\";");
	
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
	strcat(sLinea, "\"\";");
   
   /* COMPAÑIA */
   strcat(sLinea, "\"9\"");
	
	strcat(sLinea, "\n");
	
	fprintf(fp, sLinea);	

}

void GeneraNoNomencla(fp)
FILE           *fp;
{
	char	sLinea[1000];	
	
	memset(sLinea, '\0', sizeof(sLinea));

	/* ID */
   strcpy(sLinea, "\"A0000AARG\";");
	
	/* NOMBRE_CALLE */
   strcat(sLinea, "\"DUMMY\";");
	
	/* TIPO CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	
	/* CIUDAD */
   strcat(sLinea, "\"DUMMY\";");
	
	/* DEPARTAMENTO - PROVINCIA*/
   strcat(sLinea, "\"D\";");
	
	/* PAIS */
	strcat(sLinea, "\"ARGENTINA\";");
	
	/* COMUNA (CLIENTE.comuna) */
   strcat(sLinea, "\"999\";");
   
	/* REGION (CLIENTE.partido) */
   strcat(sLinea, "\"999\";");
   
	/* CALLE (VACIO) */
	strcat(sLinea, "\"\";");
	/* LOCALIDAD (VACIO) */
	strcat(sLinea, "\"\";");
	/* BARRIO (VACIO) */
	strcat(sLinea, "\"\";");
   /* COMPAÑIA */
   strcat(sLinea, "\"9\"");
	
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






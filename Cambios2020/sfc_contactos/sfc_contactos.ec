/*********************************************************************************
    Proyecto: Migracion al sistema SALES-FORCES
		
********************************************************************************/
#include <locale.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
/*#include <synmail.h>*/

$include "sfc_contactos.h";

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

char  gsDesdeFmt[9];
char  gsHastaFmt[9];

/* Variables Globales Host */
$ClsContactos	regCto;
$char  			gsDesdeDT[20];
$char  			gsHastaDT[20];
$long    		glFechaDesde;
$long    		glFechaHasta;
char				sMensMail[1024];	

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
	
   fp=pFileUnx;
	/*********************************************
				AREA CURSOR PPAL
	**********************************************/

   if(giTipoCorrida == 3){
      /* Los pendientes */
      printf("Periodo Analisis: [%s] al [%s]\n", gsDesdeDT, gsHastaDT);
      
      $OPEN curCtosAbiertos USING :gsDesdeDT, :gsHastaDT;
      
      while(LeoAbiertos(&regCto)){
			if (!GenerarPlano(fp, regCto)){
				printf("Fallo GenearPlano\n");
				exit(1);	
			}
			cantProcesada++;
		}
      $CLOSE curCtosAbiertos;
      
      /* Los cerrados */
      $OPEN curCtosCerrados USING :gsDesdeDT, :gsHastaDT;
      
      while(LeoCerrados(&regCto)){
			if (!GenerarPlano(fp, regCto)){
				printf("Fallo GenearPlano\n");
				exit(1);	
			}
			cantProcesada++;
		}      
      
      $CLOSE curCtosCerrados;
      
   }else{
      /* Los pendientes */
      $OPEN curCtosAbiertos;
      
      while(LeoAbiertos(&regCto)){
			if (!GenerarPlano(fp, regCto)){
				printf("Fallo GenearPlano\n");
				exit(1);	
			}
			cantProcesada++;
		}      
		
		$CLOSE curCtosAbiertos;
   }

   
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
	printf("Contactos\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Contactos Procesados :       %ld \n",cantProcesada);
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
   
	if(argc < 3 || argc > 5){
		MensajeParametros();
		return 0;
	}
	
   memset(sFechaDesde, '\0', sizeof(sFechaDesde));
   memset(sFechaHasta, '\0', sizeof(sFechaHasta));

   memset(gsDesdeFmt, '\0', sizeof(gsDesdeFmt));
   memset(gsHastaFmt, '\0', sizeof(gsHastaFmt));

   memset(gsDesdeDT, '\0', sizeof(gsDesdeDT));
   memset(gsHastaDT, '\0', sizeof(gsHastaDT));
   
   giTipoCorrida=atoi(argv[2]);
   
   if(argc==5){
      giTipoCorrida=3;/* Modo Delta */
      strcpy(sFechaDesde, argv[3]); 
      strcpy(sFechaHasta, argv[4]);
      rdefmtdate(&glFechaDesde, "dd/mm/yyyy", sFechaDesde); 
      rdefmtdate(&glFechaHasta, "dd/mm/yyyy", sFechaHasta);
      
      sprintf(gsDesdeFmt, "%c%c%c%c%c%c%c%c", sFechaDesde[6], sFechaDesde[7],sFechaDesde[8],sFechaDesde[9],
                  sFechaDesde[3],sFechaDesde[4], sFechaDesde[0],sFechaDesde[1]);      

      sprintf(gsHastaFmt, "%c%c%c%c%c%c%c%c", sFechaHasta[6], sFechaHasta[7],sFechaHasta[8],sFechaHasta[9],
                  sFechaHasta[3],sFechaHasta[4], sFechaHasta[0],sFechaHasta[1]);      

      sprintf(gsDesdeDT, "%c%c%c%c-%c%c-%c%c 00:00:00", sFechaDesde[6], sFechaDesde[7],sFechaDesde[8],sFechaDesde[9],
                  sFechaDesde[3],sFechaDesde[4], sFechaDesde[0],sFechaDesde[1]);      

      sprintf(gsHastaDT, "%c%c%c%c-%c%c-%c%c 23:59:59", sFechaHasta[6], sFechaHasta[7],sFechaHasta[8],sFechaHasta[9],
                  sFechaHasta[3],sFechaHasta[4], sFechaHasta[0],sFechaHasta[1]);      
       
   }else{
      glFechaDesde=-1;
      glFechaHasta=-1;
   }
   
	return 1;
}

void MensajeParametros(void){
		printf("Error en Parametros.\n");
		printf("	<Base> = synergia.\n");
      printf("	<Tipo Corrida> 0=Inicial, 3=Delta.\n");
      printf("	<Fecha Desde (Opcional)> dd/mm/aaaa.\n");
      printf("	<Fecha Hasta (Opcional)> dd/mm/aaaa.\n");
}

short AbreArchivos()
{
   char  sTitulos[10000];
   $char sFecha[9];
   
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

	sprintf( sArchUnx  , "%sT1CONTACTOS.unx", sPathSalida );
   sprintf( sArchAux  , "%sT1CONTACTOS.aux", sPathSalida );
   sprintf( sArchDos  , "%senel_care_contact_t1_%s_%s.csv", sPathSalida, gsDesdeFmt, gsHastaFmt);

	strcpy( sSoloArchivo, "T1CONTACTO.unx");

	pFileUnx=fopen( sArchUnx, "w" );
	if( !pFileUnx ){
		printf("ERROR al abrir archivo %s.\n", sArchUnx );
		return 0;
	}

   strcpy(sTitulos,"\"ID Externo\";");
   strcat(sTitulos, "\"Motivo\";");
   strcat(sTitulos, "\"Submotivo\";");
   strcat(sTitulos, "\"Estado\";");
   strcat(sTitulos, "\"Tipo\";");
   strcat(sTitulos, "\"Favorabiliad\";");
   strcat(sTitulos, "\"Cliente\";");
   strcat(sTitulos, "\"Observaciones\";");
   strcat(sTitulos, "\"Prioridad\";");
   strcat(sTitulos, "\"Suministro\";");
   strcat(sTitulos, "\"Origen\";");

   strcat(sTitulos, "\n");
      
   fprintf(pFileUnx, sTitulos);
      
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

	/******** Contactos Abiertos  ****************/	
	strcpy(sql, "SELECT co_numero_cliente, ");
	strcat(sql, "co_numero, ");
	strcat(sql, "co_suc_contacto, ");
	strcat(sql, "mo_cod_motivo, ");
	strcat(sql, "mo_cod_mot_empresa, ");
	strcat(sql, "t1.cod_sf1, ");           /* Medio de Contacto*/
	strcat(sql, "t2.cod_sf1, ");				/* Tipo de Contacto */
	strcat(sql, "co_fecha_inicio, ");
	strcat(sql, "co_rol_inicio, ");
	strcat(sql, "co_fecha_cerrado, ");
	strcat(sql, "co_rol_cierre, ");
	strcat(sql, "co_oficina ");
	strcat(sql, "su_desc_suctrof ");
	strcat(sql, "FROM contacto:ct_contacto, contacto:ct_tab_medio, contacto:ct_tab_suctrof, ");
	strcat(sql, "contacto:ct_motivo, OUTER sf_transforma t1, OUTER sf_transforma t2 ");
	if(giTipoCorrida == 3) {
		strcat(sql, "WHERE co_fecha_inicio BETWEEN ? AND ? ");
		strcat(sql, "AND co_cod_medio != '25' ");
	}else{
		strcat(sql, "WHERE co_cod_medio != '25' ");
	}
	strcat(sql, "AND tm_cod_medio = co_cod_medio ");
	strcat(sql, "AND su_cod_suctrof = co_oficina ");
	strcat(sql, "AND su_cate_suctrof = 'O' ");
	strcat(sql, "AND mo_co_numero = co_numero ");
	strcat(sql, "AND mo_suc_contacto = co_suc_contacto ");
	strcat(sql, "AND t1.clave = 'MEDIOCTO' ");
	strcat(sql, "AND t1.cod_mac = co_cod_medio ");
	strcat(sql, "AND t2.clave = 'TIPOCTO' ");
	strcat(sql, "AND t2.cod_mac = mo_tipo_contacto ");
	

	$PREPARE selCtosAbiertos FROM $sql;
	
	$DECLARE curCtosAbiertos CURSOR WITH HOLD FOR selCtosAbiertos;
	
	/******** Contactos Cerrados  ****************/	
	strcpy(sql, "SELECT cf_numero_cliente, ");
	strcat(sql, "cf_numero, ");
	strcat(sql, "cf_suc_contacto, ");
	strcat(sql, "mf_cod_motivo, ");
	strcat(sql, "mf_cod_mot_empresa, ");
	strcat(sql, "t1.cod_sf1, ");           /* Medio de Contacto*/
	strcat(sql, "t2.cod_sf1, ");				/* Tipo de Contacto */
	strcat(sql, "cf_fecha_inicio, ");
	strcat(sql, "cf_rol_inicio, ");
	strcat(sql, "cf_fecha_cerrado, ");
	strcat(sql, "cf_rol_cierre, ");
	strcat(sql, "cf_oficina ");
	strcat(sql, "su_desc_suctrof, "); 
	strcat(sql, "CASE ");
	strcat(sql, "	WHEN r.rm_cod_resp = '022' THEN 'RES001' ");
	strcat(sql, "	WHEN r.rm_cod_resp = '023' THEN 'RES002' ");
	strcat(sql, "	ELSE NULL ");
	strcat(sql, "END ");
	strcat(sql, "FROM contacto:ct_contacto_final, contacto:ct_tab_medio, contacto:ct_tab_suctrof, ");
	strcat(sql, "contacto:ct_motivo_final, OUTER sf_transforma t1, OUTER sf_transforma t2, ");
	strcat(sql, "OUTER contacto:ct_rta_motivos r ");
	if(giTipoCorrida == 3) {
		strcat(sql, "WHERE cf_fecha_cerrado BETWEEN ? AND ? ");
		strcat(sql, "AND CF_cod_medio != '25' ");
	}else{
		strcat(sql, "WHERE CF_cod_medio != '25' ");
	}
	strcat(sql, "AND tm_cod_medio = cf_cod_medio ");
	strcat(sql, "AND su_cod_suctrof = cf_oficina ");
	strcat(sql, "AND su_cate_suctrof = 'O' ");
	strcat(sql, "AND mf_co_numero = cf_numero ");
	strcat(sql, "AND mf_suc_contacto = cf_suc_contacto ");
	strcat(sql, "AND t1.clave = 'MEDIOCTO' ");
	strcat(sql, "AND t1.cod_mac = cf_cod_medio ");
	strcat(sql, "AND t2.clave = 'TIPOCTO' ");
	strcat(sql, "AND t2.cod_mac = mf_tipo_contacto ");
	strcat(sql, "AND r.rm_co_numero = cf_numero ");
	strcat(sql, "AND r.rm_suc_contacto = cf_suc_contacto ");
	
	$PREPARE selCtosCerrados FROM $sql;
	
	$DECLARE curCtosCerrados CURSOR WITH HOLD FOR selCtosCerrados;	

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


short LeoAbiertos(reg)
$ClsContactos *reg;
{

	InicializaContactos(reg);

	$FETCH curCtosAbiertos INTO
      :reg->numero_cliente,
      :reg->numero_contacto,
      :reg->suc_contacto,
      :reg->cod_motivo_cliente,
      :reg->cod_mot_empresa,
      :reg->cod_medio,
      :reg->tipo_contacto,
      :reg->fecha_inicio,
      :reg->rol_inicio,
      :reg->fecha_cerrado,
      :reg->rol_cierre,
      :reg->oficina,
      :reg->desc_suctrof;
   	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Contactos Abiertos !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

	strcpy(reg->sEstado, "ESTA003");

	alltrim(reg->cod_medio, ' ');
	alltrim(reg->tipo_contacto, ' ');
    alltrim(reg->cod_motivo_cliente, ' ');
    alltrim(reg->cod_mot_empresa, ' ');
    alltrim(reg->rol_inicio, ' ');
    alltrim(reg->rol_cierre, ' ');
	   
	return 1;	
}


short LeoCerrados(reg)
$ClsContactos *reg;
{

	InicializaContactos(reg);

	$FETCH curCtosCerrados INTO
      :reg->numero_cliente,
      :reg->numero_contacto,
      :reg->suc_contacto,
      :reg->cod_motivo_cliente,
      :reg->cod_mot_empresa,
      :reg->cod_medio,
      :reg->tipo_contacto,
      :reg->fecha_inicio,
      :reg->rol_inicio,
      :reg->fecha_cerrado,
      :reg->rol_cierre,
      :reg->oficina,
      :reg->desc_suctrof
      :reg->resultado;
   	
    if ( SQLCODE != 0 ){
    	if(SQLCODE == 100){
			return 0;
		}else{
			printf("Error al leer Cursor de Contactos Abiertos !!!\nProceso Abortado.\n");
			exit(1);	
		}
    }			

	strcpy(reg->sEstado, "ESTA007");

	alltrim(reg->cod_medio, ' ');
	alltrim(reg->tipo_contacto, ' ');
    alltrim(reg->cod_motivo_cliente, ' ');
    alltrim(reg->cod_mot_empresa, ' ');
    alltrim(reg->rol_inicio, ' ');
    alltrim(reg->rol_cierre, ' ');
	alltrim(reg->resultado, ' ');
	   
	return 1;	
}

void InicializaContactos(reg)
$ClsContactos	*reg;
{
	
	rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
	rsetnull(CLONGTYPE, (char *) &(reg->numero_contacto));
	memset(reg->suc_contacto, '\0', sizeof(reg->suc_contacto));
	memset(reg->cod_motivo_cliente, '\0', sizeof(reg->cod_motivo_cliente));
	memset(reg->cod_mot_empresa, '\0', sizeof(reg->cod_mot_empresa));
	memset(reg->cod_medio, '\0', sizeof(reg->cod_medio));
	memset(reg->tipo_contacto, '\0', sizeof(reg->tipo_contacto));
	memset(reg->fecha_inicio, '\0', sizeof(reg->fecha_inicio));
	memset(reg->rol_inicio, '\0', sizeof(reg->rol_inicio));
	memset(reg->fecha_cerrado, '\0', sizeof(reg->fecha_cerrado));
	memset(reg->rol_cierre, '\0', sizeof(reg->rol_cierre));
	memset(reg->oficina, '\0', sizeof(reg->oficina));
	memset(reg->desc_suctrof, '\0', sizeof(reg->desc_suctrof));
	memset(reg->resultado, '\0', sizeof(reg->resultado));
	memset(reg->sEstado, '\0', sizeof(reg->sEstado));
   
}


short GenerarPlano(fp, reg)
FILE 				*fp;
$ClsContactos		reg;
{
	char	sLinea[3000];
   int   iRcv;	

	memset(sLinea, '\0', sizeof(sLinea));


	/* ID Externo */
	sprintf(sLinea, "%s\"%s%ldAR\";", sLinea,reg.suc_contacto, reg.numero_contacto);
	
	/* Motivo */
	sprintf(sLinea, "%s\"%s\";", sLinea, reg.cod_motivo_cliente);
	
	/* Submotivo */
	sprintf(sLinea, "%s\"%s\";", sLinea, reg.cod_mot_empresa);
	
	/* Estado */
	sprintf(sLinea, "%s\"%s\";", sLinea, reg.sEstado);
	
	/* Tipo */
	sprintf(sLinea, "%s\"%s\";", sLinea, reg.tipo_contacto);
	
	/* Favorabiliad */
	if(strcmp(reg.resultado, "")!=0){
		sprintf(sLinea, "%s\"%s\";", sLinea, reg.resultado);
	}else{
		strcat(sLinea, "\"\";");
	}
	
	/* Cliente */
	sprintf(sLinea, "%s\"%ld\";", sLinea, reg.numero_cliente);
	
	/* Observaciones */
	sprintf(sLinea, "%s\"Fecha Inicio: %s Rol Inicio: %s Fecha Cierre: %s Rol Cierre: %s\";", sLinea, reg.fecha_inicio, reg.rol_inicio, reg.fecha_cerrado, reg.rol_cierre);
	
	/* Prioridad */
	strcat(sLinea, "\"0\";");
	
	/* Suministro */
	sprintf(sLinea, "%s\"%ldAR\";", sLinea, reg.numero_cliente);
	
	/* Origen */
	sprintf(sLinea, "%s\"%s\";", sLinea, reg.cod_medio);



	strcat(sLinea, "\n");
		
	iRcv=fprintf(fp, sLinea);
   if(iRcv<0){
      printf("Error al grabar en archivo MarketDicipline.\n");
      exit(1);
   }
	
	return 1;
}


/*****************************
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



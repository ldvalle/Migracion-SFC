/********************************************************************************
    Proyecto: Migracion al sistema SAP IS-U
    Aplicacion: sfc_contactos
    
	Fecha : 16/11/2017

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Genera los contactos MAC a requerimiento de Sales Forces
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>

*******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_contactos.h";

/* Variables Globales */
FILE	*pFileLog;
char	sArchLog[100];
char	sSoloArchLog[100];
char	sPathSalida[100];
char	sMensMail[1024];	

/* Variables Globales HOST */
$long  lFechaHoy;
$char  sFechaHoy[11];

$WHENEVER ERROR CALL SqlException;

void main( int argc, char **argv ) 
{
$char 	           nombreBase[20];
time_t 	          hora;
long              cantContactos;
$ClsInterfaceData regData;

	if(! AnalizarParametros(argc, argv)){
		exit(0);
	}
	
	hora = time(&hora);
	
	printf("\nHora antes de comenzar proceso : %s\n", ctime(&hora));
	
	strcpy(nombreBase, argv[1]);
	
	$DATABASE :nombreBase;	
	
	$SET LOCK MODE TO WAIT;
	$SET ISOLATION TO DIRTY READ;
   $SET ISOLATION TO CURSOR STABILITY;
   
	CreaPrepare1();

   memset(sFechaHoy, '\0', sizeof(sFechaHoy));
   
   $EXECUTE selFechaActual INTO :lFechaHoy, :sFechaHoy;
   
	if(!AbreArchivos()){
		exit(1);	
	}
		
	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
   cantContactos=0;

   if(!CreaTemporal()){
      exit(1);
   }			

   CreaPrepare2();
   
   $OPEN curPpal;
   
   while(LeoPpal(&regData)){
      $BEGIN WORK;   
      
      if(!ProcesaSolicitud(regData)){
         $ROLLBACK WORK;
      }else{
         $COMMIT WORK;
      }
      
      cantContactos++;
   }
   
   $CLOSE curPpal;
   

	$CLOSE DATABASE;

	$DISCONNECT CURRENT;

	/* ********************************************
				FIN AREA DE PROCESO
	********************************************* */
	CerrarArchivos();


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
	printf("SFC_CONTACTOS.\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Contactos creados : %ld \n",cantContactos);
	printf("Archivo Log :  %s \n", sArchLog);   
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
	
	memset(sArchLog,'\0',sizeof(sArchLog));
	memset(sSoloArchLog,'\0',sizeof(sSoloArchLog));
	memset(sPathSalida,'\0',sizeof(sPathSalida));
   
   strcpy(sPathSalida, "/tmp/");

	sprintf( sArchLog  , "%sSFC_Contactos.log", sPathSalida );
	strcpy( sSoloArchLog, "SFC_Contactos.log");
	
	pFileLog=fopen( sArchLog, "w" );
	if( !pFileLog ){
		printf("ERROR al abrir archivo %s.\n", sArchLog );
		return 0;
	}

	return 1;	
}

void CerrarArchivos(void)
{
    
	fclose(pFileLog);
}


void CreaPrepare1(void){
$char sql[10000];
$char sAux[1000];

	memset(sql, '\0', sizeof(sql));
	memset(sAux, '\0', sizeof(sAux));
	
	/******** Fecha Actual Formateada ****************/
	strcpy(sql, "SELECT TO_CHAR(TODAY, '%Y%m%d') FROM dual ");
	
	$PREPARE selFechaActualFmt FROM $sql;

	/******** Fecha Actual  ****************/
	strcpy(sql, "SELECT TODAY, TO_CHAR(TODAY, '%d/%m/%Y') FROM dual ");
	
	$PREPARE selFechaActual FROM $sql;	

   /******** Fecha Actual  ****************/
   strcpy(sql, "SELECT caso, ");
   strcat(sql, "nro_orden, ");
   strcat(sql, "numero_cliente, ");
   strcat(sql, "sucursal, ");
   strcat(sql, "tarifa, ");
   strcat(sql, "motivo, ");
   strcat(sql, "sub_motivo, ");
   strcat(sql, "trabajo ");
   strcat(sql, "FROM sfc_inter_ctc ");
   strcat(sql, "WHERE tarifa = 'T1' ");
   strcat(sql, "AND estado = 0 ");
   strcat(sql, "INTO TEMP tempo1 WITH NO LOG ");
   
   $PREPARE selCreaTempo FROM $sql;


}

void CreaPrepare2(void){
$char sql[10000];
$char sAux[1000];

	memset(sql, '\0', sizeof(sql));
	memset(sAux, '\0', sizeof(sAux));


   /********* Cursor Ppal ************/
   strcpy(sql, "SELECT caso, ");
   strcat(sql, "nro_orden, ");
   strcat(sql, "numero_cliente, ");
   strcat(sql, "sucursal, ");
   strcat(sql, "tarifa, ");
   strcat(sql, "motivo, ");
   strcat(sql, "sub_motivo, ");
   strcat(sql, "trabajo ");
   strcat(sql, "FROM tempo1 ");
   
   $PREPARE selTempo FROM $sql;
   $DECLARE curPpal CURSOR WITH HOLD FOR selTempo;
   
   /********** Plazo Comercial **********/
   strcpy(sql, "SELECT te_plazo_com, NVL(te_tipo_contacto, '0') ");
   strcat(sql, "FROM contacto:ct_tab_mot_empresa ");
   strcat(sql, "WHERE te_cod_motivo = ? ");
   strcat(sql, "AND te_cod_mot_empresa = ? ");
   
   $PREPARE selPlazo FROM $sql;

   /********** Cliente **********/
   strcpy(sql, "SELECT numero_cliente, ");
   strcat(sql, "nombre, ");
   strcat(sql, "tip_doc, ");
   strcat(sql, "nro_doc, ");
   strcat(sql, "origen_doc, ");
   strcat(sql, "provincia, ");
   strcat(sql, "nom_provincia, ");
   strcat(sql, "sucursal, ");
   strcat(sql, "sector, ");
   strcat(sql, "partido, ");
   strcat(sql, "nom_partido, ");
   strcat(sql, "comuna, ");
   strcat(sql, "nom_comuna, ");
   strcat(sql, "cod_calle, ");
   strcat(sql, "nom_calle, ");
   strcat(sql, "nro_dir, ");
   strcat(sql, "piso_dir, ");
   strcat(sql, "depto_dir, ");
   strcat(sql, "cod_postal, ");
   strcat(sql, "telefono, ");
   strcat(sql, "tarifa, ");
   strcat(sql, "tipo_iva, ");
   strcat(sql, "tipo_cliente, ");
   strcat(sql, "rut ");
   strcat(sql, "FROM cliente ");
   strcat(sql, "WHERE numero_cliente = ? ");
 
   $PREPARE selCliente FROM $sql;  

   /********** sucur Padre **********/
   strcpy(sql, "SELECT su_cod_superior ");
   strcat(sql, "FROM contacto:ct_tab_suctrof ");
   strcat(sql, "WHERE su_cod_suctrof = ? ");
   strcat(sql, "AND su_cate_suctrof = 'C' ");

   $PREPARE selSucurPadre FROM $sql;

   /********** insNroCto **********/
   strcpy(sql, "INSERT INTO contacto:ct_numero_suc0100 ( ");
   strcat(sql, "nu_sucursal_contac, nu_usuario, nu_fecha_proceso ");
   strcat(sql, ")VALUES('0100', 'SALESFORCE', CURRENT) ");

   $PREPARE insNroContacto FROM $sql;
   
   /********** selNroCto **********/
   strcpy(sql, "SELECT MAX(nu_co_numero) FROM contacto:ct_numero_suc0100 ");
   strcat(sql, "WHERE nu_sucursal_contac = '0100' ");
   strcat(sql, "AND nu_usuario = 'SALESFORCE' ");
   
   $PREPARE selNroContacto FROM $sql;

   /********** Insert Contacto **********/
   strcpy(sql, "INSERT INTO contacto:ct_contacto ( ");
   strcat(sql, "sfc_caso, ");
   strcat(sql, "sfc_nro_orden, ");
   strcat(sql, "co_numero, ");
   strcat(sql, "co_numero_cliente, ");
   strcat(sql, "co_tipo_doc, ");
   strcat(sql, "co_nro_doc, ");
   strcat(sql, "co_es_cliente, ");
   strcat(sql, "co_tarifa, ");
   strcat(sql, "co_suc_cli, ");
   strcat(sql, "co_cen_cli, ");
   strcat(sql, "co_plan, ");
   strcat(sql, "co_nombre, ");
   strcat(sql, "co_telefono, ");
   strcat(sql, "co_backoffice, ");
   strcat(sql, "co_fecha_vto, ");
   strcat(sql, "co_direccion, ");
   strcat(sql, "co_partido, ");
   strcat(sql, "co_codpos, ");
   strcat(sql, "co_nro_cuit, ");
   strcat(sql, "co_rol_inicio, ");
   strcat(sql, "co_rol_resp, ");
   strcat(sql, "co_cod_medio, ");
   strcat(sql, "co_fecha_inicio, ");
   strcat(sql, "co_suc_ag_contacto, ");
   strcat(sql, "co_suc_contacto, ");
   strcat(sql, "co_oficina, ");
   strcat(sql, "co_fecha_proceso, ");
   strcat(sql, "co_fecha_estado, ");
   strcat(sql, "co_multi ");
   strcat(sql, ")VALUES( ");
   strcat(sql, "?,?,?,?,?, ");
   strcat(sql, "?,?,?,?,?, ");
   strcat(sql, "?,?,?,?,?, ");
   strcat(sql, "?,?,?,?,?, ");
   strcat(sql, "?, ");
   strcat(sql, "'25', ");
   strcat(sql, "CURRENT, ");
   strcat(sql, "'0100', ");
   strcat(sql, "'0100', ");
   strcat(sql, "'0100', ");
   strcat(sql, "CURRENT, ");
   strcat(sql, "CURRENT, ");
   strcat(sql, "'0') ");
   
   $PREPARE insContacto FROM $sql;

   /********** Insert Motivo **********/
   strcpy(sql, "INSERT INTO contacto:ct_motivo ( ");
   strcat(sql, "mo_co_numero, ");
   strcat(sql, "mo_cod_motivo, ");
   strcat(sql, "mo_cod_mot_empresa, ");
   strcat(sql, "mo_fecha_vto, ");
   strcat(sql, "mo_vto_real_com, ");
   strcat(sql, "mo_suc_ag_contacto, ");
   strcat(sql, "mo_suc_contacto, ");
   strcat(sql, "mo_oficina, ");
   strcat(sql, "mo_fecha_inicio, ");
   strcat(sql, "mo_rol_inicio, ");
   strcat(sql, "mo_tipo_contacto, ");
   strcat(sql, "mo_fecha_proceso, ");
   strcat(sql, "mo_principal, ");
   strcat(sql, "mo_estado, ");
   strcat(sql, "mo_fecha_estado ");
   strcat(sql, ")VALUES( ");   
   strcat(sql, "?,?,?,?,?, ");
   strcat(sql, "'0100', ");
   strcat(sql, "'0100', ");
   strcat(sql, "'0100', ");
   strcat(sql, "CURRENT, ");
   strcat(sql, "'SFC_CONTACTOS', ");
   strcat(sql, "'0', ");
   strcat(sql, "CURRENT, ");
   strcat(sql, "'1', ");
   strcat(sql, "'C', ");
   strcat(sql, "CURRENT) ");
   
   $PREPARE insMotivo FROM $sql;

   /********** Sel Observa **********/
   strcpy(sql, "SELECT observacion, pag ");
   strcat(sql, "FROM sfc_interctc_obs ");
   strcat(sql, "WHERE caso = ? ");
   strcat(sql, "AND nro_orden = ? ");
   strcat(sql, "ORDER BY pag ASC ");
   
   $PREPARE selObserva FROM $sql;
   $DECLARE curObserva CURSOR FOR selObserva;
   
   /********** Ins Observa **********/
   strcpy(sql, "INSERT INTO contacto:ct_observ( ");
   strcat(sql, "ob_co_numero, ");
   strcat(sql, "ob_suc_contacto, ");
   strcat(sql, "ob_descrip, ");
   strcat(sql, "ob_pagina ");
   strcat(sql, ")VALUES( ");
   strcat(sql, "?, '0100', ?, ?) ");
   
   $PREPARE insObserva FROM $sql;

   /********** Actual Interface **********/
   strcpy(sql, "UPDATE sfc_inter_ctc SET ");
   strcat(sql, "estado = 1 ");
   strcat(sql, "WHERE caso = ? ");
   strcat(sql, "AND nro_orden = ? ");

   $PREPARE updInterface FROM $sql;
         
}   
   


short CreaTemporal(void){

   $EXECUTE selCreaTempo;
   
   if(SQLCODE != 0 ){
      printf("No se pudo crear la tabla temporal para el cursor ppal.\n");
      return 0;
   }

   return 1;
}

short LeoPpal(reg)
$ClsInterfaceData *reg;
{

   InicializaInterface(reg);
   
   $FETCH curPpal INTO
            :reg->caso,
            :reg->nro_orden,
            :reg->numero_cliente,
            :reg->sucursal,
            :reg->tarifa,
            :reg->motivo,
            :reg->sub_motivo,
            :reg->trabajo;

   if(SQLCODE != 0){
      return 0;
   }

   return 1;
}

void InicializaInterface(reg)
$ClsInterfaceData *reg;
{

	rsetnull(CLONGTYPE, (char *) &(reg->caso));
   rsetnull(CLONGTYPE, (char *) &(reg->nro_orden));
   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
	
   memset(reg->sucursal, '\0', sizeof(reg->sucursal));
	memset(reg->tarifa, '\0', sizeof(reg->tarifa));
   memset(reg->motivo, '\0', sizeof(reg->motivo));
   memset(reg->sub_motivo, '\0', sizeof(reg->sub_motivo));
   memset(reg->trabajo, '\0', sizeof(reg->trabajo));

}

short ProcesaSolicitud(reg)
$ClsInterfaceData reg;
{
$ClsParametros regPar;
$ClsCliente    regClie;
$ClsContacto   regCon;
$ClsMotivo     regMot;
$long          lNroContacto;

   /* obtener plazo comercial */
   if(! GetPlazoComercial(reg, &regPar)){
      return 0;
   }
      
   /* Calcular Fecha Vencimiento */
   if(! getVencimiento(&regPar)){
      return 0;
   }
   
   InicializaContacto(&regCon);
   
   /* Cargar Datos del Cliente */
   if(reg.numero_cliente > 0){
      if(!LeoCliente(reg, &regClie)){
         return 0;
      }
   }
   
   /* Obtener Nro.de Contacto */
   if(!getNroContacto(reg, &lNroContacto)){
      return 0;
   }
   
   CargaContacto(lNroContacto, reg, regClie, regPar, &regCon);
   
   CargaMotivo(lNroContacto, reg, regPar, &regMot);
   
   /* Grabar Contacto */
   if(! GrabaContacto(regCon)){
      return 0;
   }
   
   /* Grabar Motivo */
   if(! GrabaMotivo(reg, regMot)){
      return 0;
   }
   
   /* Procesa Observaciones */
   if(! ProcesaObs(lNroContacto, reg)){
      return 0;
   }
   
   /* Actualizar Solicitud de Contacto */
  if(! ActualSolic(reg)){
      return 0;
  }
   return 1;
}

short GetPlazoComercial(reg, regPar)
$ClsInterfaceData reg;
$ClsParametros    *regPar;
{
   char sLinea[1000];
   
   
   rsetnull(CLONGTYPE, (char *) &(regPar->iPlazo));
   memset(regPar->sTipoContacto, '\0', sizeof(regPar->sTipoContacto));
   memset(regPar->sFechaVto, '\0', sizeof(regPar->sFechaVto));
   memset(sLinea, '\0', sizeof(sLinea));
   
   $EXECUTE selPlazo 
            INTO :regPar->iPlazo, :regPar->sTipoContacto
            USING :reg.motivo, :reg.sub_motivo;
            
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. GetPlazoComercial. No se encontro fila para mot.cliente %s mot.cliente-empresa %s\n",
            reg.caso, reg.nro_orden, reg.motivo, reg.sub_motivo);
      fprintf(pFileLog, sLinea);
      return 0;
   }
   
   return 1;
}

short getVencimiento(regPar)
$ClsParametros    *regPar;
{
long  lFechaDesdeAux;
long  lFechaVcto;
char  sFechaVcto[11];

   memset(sFechaVcto, '\0', sizeof(sFechaVcto));
   
   lFechaDesdeAux = lFechaHoy-30;
   
   lFechaVcto = SumarDiasHabiles ( lFechaHoy, regPar->iPlazo, lFechaDesdeAux);

   rfmtdate(lFechaVcto, "yyyy-mm-dd", sFechaVcto);
   
   sprintf(regPar->sFechaVto, "%s 23:59:59", sFechaVcto);
   
   return 1;
}

void InicializaContacto(reg)
$ClsContacto   *reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->sfc_caso));
   rsetnull(CLONGTYPE, (char *) &(reg->sfc_nro_orden));
   rsetnull(CLONGTYPE, (char *) &(reg->co_numero));
   rsetnull(CLONGTYPE, (char *) &(reg->co_numero_cliente));
   memset(reg->co_tipo_doc, '\0', sizeof(reg->co_tipo_doc));   
   memset(reg->co_nro_doc, '\0', sizeof(reg->co_nro_doc));
   memset(reg->co_es_cliente, '\0', sizeof(reg->co_es_cliente));   
   memset(reg->co_cod_medio, '\0', sizeof(reg->co_cod_medio));
   memset(reg->co_tarifa, '\0', sizeof(reg->co_tarifa));
   memset(reg->co_suc_cli, '\0', sizeof(reg->co_suc_cli));
   memset(reg->co_cen_cli, '\0', sizeof(reg->co_cen_cli));
   rsetnull(CINTTYPE, (char *) &(reg->co_plan));
   memset(reg->co_nombre, '\0', sizeof(reg->co_nombre));
   memset(reg->co_telefono, '\0', sizeof(reg->co_telefono));
   memset(reg->co_backoffice, '\0', sizeof(reg->co_backoffice));   
   memset(reg->co_fecha_inicio, '\0', sizeof(reg->co_fecha_inicio));
   memset(reg->co_fecha_vto, '\0', sizeof(reg->co_fecha_vto));
   memset(reg->co_suc_ag_contacto, '\0', sizeof(reg->co_suc_ag_contacto));
   memset(reg->co_suc_contacto, '\0', sizeof(reg->co_suc_contacto));
   memset(reg->co_oficina, '\0', sizeof(reg->co_oficina));
   memset(reg->co_fecha_proceso, '\0', sizeof(reg->co_fecha_proceso));
   memset(reg->co_fecha_estado, '\0', sizeof(reg->co_fecha_estado));
   memset(reg->co_rol_inicio, '\0', sizeof(reg->co_rol_inicio));
   memset(reg->co_multi, '\0', sizeof(reg->co_multi));
   memset(reg->co_direccion, '\0', sizeof(reg->co_direccion));
   memset(reg->co_partido, '\0', sizeof(reg->co_partido));
   rsetnull(CINTTYPE, (char *) &(reg->co_codpos));
   memset(reg->co_nro_cuit, '\0', sizeof(reg->co_nro_cuit));

}


short LeoCliente(regData, reg)
$ClsInterfaceData regData;
$ClsCliente    *reg;
{
char  sLinea[1000];

   memset(sLinea, '\0', sizeof(sLinea));
   
   InicializaCliente(reg);

   $EXECUTE selCliente INTO
         :reg->numero_cliente,
         :reg->nombre,
         :reg->tip_doc,
         :reg->nro_doc,
         :reg->origen_doc,
         :reg->provincia,
         :reg->nom_provincia,
         :reg->sucursal,
         :reg->sector,
         :reg->partido,
         :reg->nom_partido,
         :reg->comuna,
         :reg->nom_comuna,
         :reg->cod_calle,
         :reg->nom_calle,
         :reg->nro_dir,
         :reg->piso_dir,
         :reg->depto_dir,
         :reg->cod_postal,
         :reg->telefono,
         :reg->tarifa,
         :reg->tipo_iva,
         :reg->tipo_cliente,
         :reg->rut
      USING :regData.numero_cliente;
   
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. LeoCliente. No se encontro Cliente %ld.\n",
            regData.caso, regData.nro_orden, regData.numero_cliente);
      fprintf(pFileLog, sLinea);
      return 0;
   }   
   
   alltrim(reg->nombre, ' ');
   alltrim(reg->tip_doc, ' ');
   alltrim(reg->nom_provincia, ' ');
   alltrim(reg->nom_partido, ' ');
   alltrim(reg->nom_comuna, ' ');
   alltrim(reg->nom_calle, ' ');
   alltrim(reg->nro_dir, ' ');                  
   alltrim(reg->piso_dir, ' ');
   alltrim(reg->depto_dir, ' ');
   alltrim(reg->telefono, ' ');                  
   
   return 1;
}

void InicializaCliente(reg)
$ClsCliente    *reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->numero_cliente));
   memset(reg->nombre, '\0', sizeof(reg->nombre));
   memset(reg->tip_doc, '\0', sizeof(reg->tip_doc));
   rsetnull(CDOUBLETYPE, (char *) &(reg->nro_doc));
   memset(reg->origen_doc, '\0', sizeof(reg->origen_doc));   
   memset(reg->provincia, '\0', sizeof(reg->provincia));
   memset(reg->nom_provincia, '\0', sizeof(reg->nom_provincia));
   memset(reg->sucursal, '\0', sizeof(reg->sucursal));
   rsetnull(CINTTYPE, (char *) &(reg->sector));
   memset(reg->partido, '\0', sizeof(reg->partido));
   memset(reg->nom_partido, '\0', sizeof(reg->nom_partido));
   memset(reg->comuna, '\0', sizeof(reg->comuna));
   memset(reg->nom_comuna, '\0', sizeof(reg->nom_comuna));
   memset(reg->cod_calle, '\0', sizeof(reg->cod_calle));
   memset(reg->nom_calle, '\0', sizeof(reg->nom_calle));
   memset(reg->nro_dir, '\0', sizeof(reg->nro_dir));
   memset(reg->piso_dir, '\0', sizeof(reg->piso_dir));
   memset(reg->depto_dir, '\0', sizeof(reg->depto_dir));
   rsetnull(CINTTYPE, (char *) &(reg->cod_postal));
   memset(reg->telefono, '\0', sizeof(reg->telefono));
   memset(reg->tarifa, '\0', sizeof(reg->tarifa));
   memset(reg->tipo_iva, '\0', sizeof(reg->tipo_iva));
   memset(reg->tipo_cliente, '\0', sizeof(reg->tipo_cliente));
   memset(reg->rut, '\0', sizeof(reg->rut));

}

short getNroContacto(reg, lNro)
ClsInterfaceData  reg;
$long *lNro;
{
   $long lNroAux;
   char  sLinea[1000];
   
   memset(sLinea, '\0', sizeof(sLinea));
   
   $EXECUTE insNroContacto;

   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. getNroContacto. No se inserto el Nro.de Contacto.\n",
            reg.caso, reg.nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
    }
    
    $EXECUTE selNroContacto INTO :lNroAux;
    
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. getNroContacto. No se leyo el Nro.de Contacto.\n",
            reg.caso, reg.nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
    }
    
   *lNro = lNroAux;
   
   return 1;
}

void CargaContacto(lNroContacto, regData, regClie, regPar, regCon)
long              lNroContacto;
ClsInterfaceData  regData;
$ClsCliente       regClie;
ClsParametros     regPar;
ClsContacto       *regCon;
{
char      sAuxDire[41];
$char     sSucurPadre[5];

   memset(sAuxDire, '\0', sizeof(sAuxDire));
   memset(sSucurPadre, '\0', sizeof(sSucurPadre));

   regCon->sfc_caso = regData.caso;
   regCon->sfc_nro_orden = regData.nro_orden;
   regCon->co_numero = lNroContacto;
   regCon->co_numero_cliente = regData.numero_cliente;

   if(regData.numero_cliente > 0){

      $EXECUTE selSucurPadre INTO :sSucurPadre USING :regClie.sucursal;
      
      if(SQLCODE != 0){
         printf("No se encontró sucursal padre para centro operativo %s\n", regClie.sucursal);
      }

      strcpy(regCon->co_tipo_doc, regClie.tip_doc);
      sprintf(regCon->co_nro_doc, "%.0lf", regClie.nro_doc);
      strcpy(regCon->co_es_cliente, "0");
      strcpy(regCon->co_tarifa, regClie.tarifa);
      
      strcpy(regCon->co_suc_cli, sSucurPadre);
      strcpy(regCon->co_cen_cli, regClie.sucursal);
      regCon->co_plan = regClie.sector;
      strcpy(regCon->co_nombre, regClie.nombre);
      strcpy(regCon->co_telefono, regClie.telefono);
      
      sprintf(sAuxDire, "%s %s Piso %s Dto.%s", regClie.nom_calle, regClie.nro_dir, regClie.piso_dir, regClie.depto_dir);
      strcpy(regCon->co_direccion, sAuxDire);
   
      strcpy(regCon->co_partido, regClie.nom_partido);
      regCon->co_codpos = regClie.cod_postal;
      strcpy(regCon->co_nro_cuit, regClie.rut);
      
      sprintf(regCon->co_rol_inicio, "SF%s", regClie.sucursal);
      
   }else{
      strcpy(regCon->co_es_cliente, "1");
   }
    
   strcpy(regCon->co_backoffice, "B");
   strcpy(regCon->co_fecha_vto, regPar.sFechaVto);
   
   alltrim(regCon->co_direccion, ' ');
   alltrim(regCon->co_rol_inicio, ' '); 

}


void CargaMotivo(lNroContacto, regData, regPar, regMot)
long        lNroContacto;
ClsInterfaceData  regData;
ClsParametros     regPar;
$ClsMotivo        *regMot;
{

   regMot->mo_co_numero = lNroContacto;
   strcpy(regMot->mo_cod_motivo, regData.motivo);
   strcpy(regMot->mo_cod_mot_empresa, regData.sub_motivo);
   strcpy(regMot->mo_fecha_vto, regPar.sFechaVto);
   strcpy(regMot->mo_vto_real_com, regPar.sFechaVto);

}

short GrabaContacto(reg)
$ClsContacto reg;
{
char  sLinea[1000];

   memset(sLinea, '\0', sizeof(sLinea));

   $EXECUTE insContacto USING
      :reg.sfc_caso,
      :reg.sfc_nro_orden,
      :reg.co_numero,
      :reg.co_numero_cliente,
      :reg.co_tipo_doc,
      :reg.co_nro_doc,
      :reg.co_es_cliente,
      :reg.co_tarifa,
      :reg.co_suc_cli,
      :reg.co_cen_cli,
      :reg.co_plan,
      :reg.co_nombre,
      :reg.co_telefono,
      :reg.co_backoffice,
      :reg.co_fecha_vto,
      :reg.co_direccion,
      :reg.co_partido,
      :reg.co_codpos,
      :reg.co_nro_cuit,
      :reg.co_rol_inicio,
      :reg.co_rol_inicio;
   
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. GrabaContacto. No se pudo grabar en CT_CONTACTO.\n",
            reg.sfc_caso, reg.sfc_nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
   }   

   return 1;
}

short GrabaMotivo(regData, reg)
ClsInterfaceData   regData;
$ClsMotivo  reg;
{
char  sLinea[1000];

   memset(sLinea, '\0', sizeof(sLinea));

   $EXECUTE insMotivo USING
      :reg.mo_co_numero,
      :reg.mo_cod_motivo,
      :reg.mo_cod_mot_empresa,
      :reg.mo_fecha_vto,
      :reg.mo_vto_real_com;

   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. GrabaMotivo. No se pudo grabar en CT_MOTIVO.\n",
            regData.caso, regData.nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
   }   

   return 1;
}

short ProcesaObs(lNroContacto, reg)
$long       lNroContacto;
$ClsInterfaceData    reg;
{

   $ClsInterfaceTxt regOb;
   
   $OPEN curObserva using :reg.caso, :reg.nro_orden;
   
   while(LeoObserva(&regOb)){
      if(!GrabaObs(lNroContacto, reg, regOb)){
         return 0;
      }
   }
   
   $CLOSE curObserva;

   return 1;
}

short LeoObserva(reg)
$ClsInterfaceTxt  *reg;
{
   
   InicializaObserva(reg);

   $FETCH curObserva INTO :reg->observacion, :reg->pag;
   
   if(SQLCODE != 0){
      return 0;
   }
   
   return 1;
}


void InicializaObserva(reg)
$ClsInterfaceTxt  *reg;
{
   memset(reg->observacion, '\0', sizeof(reg->observacion));   
   rsetnull(CINTTYPE, (char *) &(reg->pag));
}

short GrabaObs(lNroConta, regData, regOb)
$long             lNroConta;
ClsInterfaceData  regData;
$ClsInterfaceTxt  regOb;  
{
char  sLinea[1000];

   memset(sLinea, '\0', sizeof(sLinea));

   $EXECUTE insObserva USING :lNroConta, :regOb.observacion, :regOb.pag;
   
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. GrabaObs. No se pudo grabar en CT_OBSERV.\n",
            regData.caso, regData.nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
   }   

   return 1;
}

short ActualSolic(reg)
$ClsInterfaceData reg;
{
char  sLinea[1000];

   memset(sLinea, '\0', sizeof(sLinea));

   $EXECUTE updInterface USING :reg.caso, :reg.nro_orden;
   
   if(SQLCODE != 0){
      sprintf(sLinea, "Caso %ld Orden %ld. ActualSolic. No se pudo actualizar interface.\n",
            reg.caso, reg.nro_orden);
      fprintf(pFileLog, sLinea);
      return 0;
   }   
   
   return 1;
}

void FechaGeneracionFormateada( Fecha )
char *Fecha;
{
	$char fmtFecha[9];
	
	memset(fmtFecha,'\0',sizeof(fmtFecha));
	
	$EXECUTE selFechaActualFmt INTO :fmtFecha;
	
	strcpy(Fecha, fmtFecha);
	
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


/********************************************************************************
    Proyecto: Migracion del MAC
    Aplicacion: sfc_segen
    
	Fecha : 23/11/2017

	Autor : Lucas Daniel Valle(LDV)

	Funcion del programa : 
		Informa el estado de los segenes para que sea tomado por Sales Forces
		
	Descripcion de parametros :
		<Base de Datos> : Base de Datos <synergia>

*******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <synmail.h>

$include "sfc_segen.h";

/* Variables Globales */

/* Variables Globales HOST */

$WHENEVER ERROR CALL SqlException;

void main( int argc, char **argv ) 
{
$char 	         nombreBase[20];
time_t 	         hora;
long              cantContactos;
$ClsSegen         regSeg;

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
   
		
	/* ********************************************
				INICIO AREA DE PROCESO
	********************************************* */
   cantContactos=0;

   $OPEN curSegen;
   
   while(LeoSegen(&regSeg)){
      $BEGIN WORK;
      if(! InformaSts(regSeg)){
         $ROLLBACK WORK;
         printf("Error al informar segen %ld\n", regSeg.se_mensaje);
      }
      $COMMIT WORK;
      cantContactos++;
   }
   
   $CLOSE curSegen;
   

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
	printf("SFC_SEGEN.\n");
	printf("==============================================\n");
	printf("Proceso Concluido.\n");
	printf("==============================================\n");
	printf("Segenes leidos : %ld \n",cantContactos);
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



void CreaPrepare(void){
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

   /******** Contacto - Segen ************/
	strcpy(sql, "SELECT c.sfc_caso, "); 
   strcat(sql, "c.sfc_nro_orden, "); 
   strcat(sql, "c.co_numero, "); 
   strcat(sql, "c.co_suc_contacto, "); 
   strcat(sql, "s.se_mensaje, ");
   strcat(sql, "m.rol_actual, ");
   strcat(sql, "m.fecha_modif, ");
   strcat(sql, "m.etapa, ");
   strcat(sql, "m.estado ");
   strcat(sql, "FROM contacto:ct_contacto c, "); 
   strcat(sql, "contacto:ct_segen s, xnear2:mensaje m ");
   strcat(sql, "WHERE c.sfc_caso IS NOT NULL ");
   strcat(sql, "AND s.se_co_numero = c.co_numero ");
   strcat(sql, "AND s.se_suc_contacto = c.co_suc_contacto ");
   strcat(sql, "AND m.servidor = 1 ");
   strcat(sql, "AND m.mensaje = s.se_mensaje ");

   $PREPARE selSegen FROM $sql;
   $DECLARE curSegen CURSOR WITH HOLD FOR selSegen;

   /******** Existe Informe ************/
	strcpy(sql, "SELECT COUNT(*) FROM sfc_segen ");
   strcat(sql, "WHERE mensaje_xnear = ? ");
   
   $PREPARE selCountInfo FROM $sql;
   
   /******** Inserta Informe ************/
	strcpy(sql, "INSERT INTO sfc_segen ( ");   
   strcat(sql, "   caso, ");
   strcat(sql, "   nro_orden, ");
   strcat(sql, "   mensaje_xnear, ");
   strcat(sql, "   rol_actual, ");
   strcat(sql, "   fecha_estado, ");
   strcat(sql, "   etapa, ");
   strcat(sql, "   estado ");
   strcat(sql, ")VALUES( ");   
   strcat(sql, "?, ?, ?, ?, ?, ?, ? ");
   
   $PREPARE insInforme FROM $sql;
   
   /******** Actualiza Informe ************/
	strcpy(sql, "UPDATE sfc_segen SET ");
   strcat(sql, "rol_actual = ?, ");
   strcat(sql, "fecha_estado = ?, ");
   strcat(sql, "etapa = ?, ");
   strcat(sql, "estado = ? ");
   strcat(sql, "WHERE mensaje_xnear = ? ");

   $PREPARE updInforme FROM $sql;

}




void InicializaSegen(reg)
$ClsSegen   *reg;
{

   rsetnull(CLONGTYPE, (char *) &(reg->sfc_caso));
   rsetnull(CLONGTYPE, (char *) &(reg->sfc_nro_orden));
   rsetnull(CLONGTYPE, (char *) &(reg->co_numero));
   memset(reg->co_suc_contacto, '\0', sizeof(reg->co_suc_contacto));
   rsetnull(CLONGTYPE, (char *) &(reg->se_mensaje));
   memset(reg->rol_actual, '\0', sizeof(reg->rol_actual));
   memset(reg->sFechaModif, '\0', sizeof(reg->sFechaModif));
   memset(reg->etapa, '\0', sizeof(reg->etapa));
   memset(reg->estado, '\0', sizeof(reg->estado));

}

short LeoSegen(reg)
$ClsSegen   *reg;
{

   InicializaSegen(reg);
   
   $FETCH curSegen INTO
      :reg->sfc_caso,
      :reg->sfc_nro_orden,
      :reg->co_numero,
      :reg->co_suc_contacto,
      :reg->se_mensaje,
      :reg->rol_actual,
      :reg->sFechaModif,
      :reg->etapa,
      :reg->estado;
   
   if(SQLCODE != 0){
      return 0;
   }

   return 1;
}

short InformaSts(reg)
$ClsSegen   reg;
{
   $int  iExiste;
   
   $EXECUTE selCountInfo INTO :iExiste USING :reg.se_mensaje;
   
   if(SQLCODE != 0){
      return 0;
   }
   
   if(iExiste <= 0){
      $EXECUTE insInforme USING
            :reg.sfc_caso,
            :reg.sfc_nro_orden,
            :reg.se_mensaje,
            :reg.rol_actual,
            :reg.sFechaModif,
            :reg.etapa,
            :reg.estado;
   
   }else{
   
      $EXECUTE updInforme USING
            :reg.rol_actual,
            :reg.sFechaModif,
            :reg.etapa,
            :reg.estado,
            :reg.se_mensaje;
      
   }

   if(SQLCODE != 0){
      return 0;
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


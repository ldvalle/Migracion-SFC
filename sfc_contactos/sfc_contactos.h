$ifndef SFCCONTACTOS_H;
$define SFCCONTACTOS_H;

#include "ustring.h"
#include "macmath.h"

$include sqltypes.h;
$include sqlerror.h;
$include datetime.h;
$include mfecha.h;

#define BORRAR(x)       memset(&x, 0, sizeof x)
#define BORRA_STR(str)  memset(str, 0, sizeof str)

#define SYN_CLAVE "DD_NOVOUT"

/* Estructuras **/
$typedef struct{
   long  caso;
   long  nro_orden;
   long  numero_cliente;
   char  sucursal[5];
   char  tarifa[3];
   char  motivo[5];
   char  sub_motivo[5];
   char  trabajo[5];
   int   estado;
}ClsInterfaceData;

$typedef struct{
   long  caso;
   long  nro_orden;
   char  observacion[251];
   int   pag;
}ClsInterfaceTxt;

$typedef struct{
   long  numero_cliente;
   char  nombre[41];   
   char  tip_doc[7];
   double   nro_doc;
   char  origen_doc[7];
   char  provincia[4];
   char  nom_provincia[26];
   char  sucursal[5];
   int   sector;
   char  partido[4];
   char  nom_partido[26];
   char  comuna[4];
   char  nom_comuna[26];
   char  cod_calle[7];
   char  nom_calle[26];
   char  nro_dir[6];
   char  piso_dir[7];
   char  depto_dir[7];
   int   cod_postal;
   char  telefono[10];
   char  tarifa[6];
   char  tipo_iva[4];
   char  tipo_cliente[3];
   char  rut[12]; 
}ClsCliente;

$typedef struct{
   long  sfc_caso;
   long  sfc_nro_orden;
   long  co_numero;
   long  co_numero_cliente;
   char  co_tipo_doc[9];
   char  co_nro_doc[17];
   char  co_es_cliente[2];
   char  co_tarifa[4];
   char  co_suc_cli[5];
   char  co_cen_cli[5];
   int   co_plan;
   char  co_nombre[41];
   char  co_telefono[21];
   char  co_backoffice[2];    /* B o C */
   char  co_fecha_vto[20];
   char  co_direccion[41];
   char  co_partido[26];
   int   co_codpos;
   char  co_nro_cuit[21];
   char  co_rol_inicio[21];
   
   char  co_cod_medio[3];
   char  co_fecha_inicio[20];   
   char  co_suc_ag_contacto[5];
   char  co_suc_contacto[5];
   char  co_oficina[5];
   char  co_fecha_proceso[20];
   char  co_fecha_estado[20];
   char  co_multi[2];         /* 0 cero */   
   
}ClsContacto;

$typedef struct{
   long  mo_co_numero;
   char  mo_cod_motivo[5];
   char  mo_cod_mot_empresa[5];
   char  mo_fecha_vto[20];
   char  mo_vto_real_com[20];
   
   char  mo_suc_ag_contacto[5];
   char  mo_suc_contacto[5];
   char  mo_oficina[5];
   char  mo_fecha_inicio[20];
   char  mo_rol_inicio[21];
   char  mo_tipo_contacto[2];   /* 0 (cero) */
   char  mo_fecha_proceso[20];
   char  mo_principal[2];        /* 1 */
   char  mo_estado[2];           /* C o P */
   char  mo_fecha_estado[20];
}ClsMotivo;

$typedef struct{
   int   iPlazo;
   char  sTipoContacto[2];
   char  sFechaVto[20];
}ClsParametros;

$typedef struct{
   long  ob_co_numero;
   char  ob_suc_contacto[5];
   char  ob_descrip[251];
   int   ob_pagina;
}ClsObservaciones;

/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare1(void);
void  CreaPrepare2(void);
short CreaTemporal(void);
short LeoPpal(ClsInterfaceData *);
void  InicializaInterface(ClsInterfaceData *);
short ProcesaSolicitud(ClsInterfaceData );
short GetPlazoComercial(ClsInterfaceData, ClsParametros *);
short getVencimiento(ClsParametros *);
void  InicializaContacto(ClsContacto *);
short LeoCliente(ClsInterfaceData, ClsCliente *);
void  InicializaCliente(ClsCliente *);
short getNroContacto(ClsInterfaceData, long *);
void  CargaContacto(long, ClsInterfaceData, ClsCliente, ClsParametros, ClsContacto *);
void  CargaMotivo(long, ClsInterfaceData, ClsParametros, ClsMotivo *);
short GrabaContacto(ClsContacto);
short GrabaMotivo(ClsInterfaceData, ClsMotivo);
short ProcesaObs(long, ClsInterfaceData);
short LeoObserva(ClsInterfaceTxt *);
void  InicializaObserva(ClsInterfaceTxt *);
short GrabaObs(long, ClsInterfaceData, ClsInterfaceTxt);
short ActualSolic(ClsInterfaceData);
void  FechaGeneracionFormateada(char*);

char 	*strReplace(char *, char *, char *);
void	CerrarArchivos(void);

/*
short	EnviarMail( char *, char *);
void  	ArmaMensajeMail(char **);
short	CargaEmail(ClsCliente, ClsEmail*, int *);
void    InicializaEmail(ClsEmail*);
*/

$endif;

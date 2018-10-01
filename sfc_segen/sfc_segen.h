$ifndef SFCSEGEN_H;
$define SFCSEGEN_H;

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
   long  sfc_caso;
   long  sfc_nro_orden;
   long  co_numero;
   char  co_suc_contacto[5];
   long  se_mensaje;
   char  rol_actual[21];
   char  sFechaModif[20];
   char  etapa[21];
   char  estado[2];
}ClsSegen;

/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
void  CreaPrepare(void);
short LeoSegen(ClsSegen *);
void  InicializaSegen(ClsSegen *);
short InformaSts(ClsSegen);



char 	*strReplace(char *, char *, char *);
/*
short	EnviarMail( char *, char *);
void  	ArmaMensajeMail(char **);
short	CargaEmail(ClsCliente, ClsEmail*, int *);
void    InicializaEmail(ClsEmail*);
*/

$endif;

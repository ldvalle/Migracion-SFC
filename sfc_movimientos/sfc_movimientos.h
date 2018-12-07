$ifndef SFCMOVIMIENTOS_H;
$define SFCMOVIMIENTOS_H;

#include "ustring.h"
#include "macmath.h"

$include sqltypes.h;
$include sqlerror.h;
$include datetime.h;

#define BORRAR(x)       memset(&x, 0, sizeof x)
#define BORRA_STR(str)  memset(str, 0, sizeof str)

#define SYN_CLAVE "DD_NOVOUT"

/* Estructuras ---*/

$typedef struct{
   long  numero_cliente;
   int   corr_pagos;
   long  llave;
   char  fecha_pago[25];
   char  fecha_actualiza[25];
   char  tipo_pago[3];
   char  descripcion[31];
   char  cajero[5]; 
   char  oficina[5];
   char  sucursal[5];
   double   valor_pago;
   char  centro_emisor[3];
   char  tipo_docto[3];
   long  nro_docto_asociado;
   char  tipo_mov[2];
   char  nombre_cajero[31];
   char  lugarPago[60];
}ClsPago;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(int);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( long *, long *);
short LeoPagos(ClsPago *);
void  InicializaPago(ClsPago *);

short	GenerarPlano(FILE *, ClsPago);

char 	*strReplace(char *, char *, char *);
void	CerrarArchivos(void);
void	FormateaArchivos(void);
void  MoverArchivos(void);

/*
short	EnviarMail( char *, char *);
void  	ArmaMensajeMail(char **);
short	CargaEmail(ClsCliente, ClsEmail*, int *);
void    InicializaEmail(ClsEmail*);
*/

$endif;

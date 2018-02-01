$ifndef SFCINVOICE_H;
$define SFCINVOICE_H;

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
   int   corr_facturacion;
   long  lFecha_facturacion;
   char  fecha_facturacion[11];
   char  fecha_vencimiento1[11];
   char  fecha_vencimiento2[11];
   double   suma_intereses;
   double   suma_cargos_man;
   double   saldo_anterior;
   double   suma_impuestos;
   char     id_factura[50];
   long     numero_factura;
   double   total_a_pagar;
   double   coseno_phi;
   double   suma_recargo;
   double   suma_convenio;
   char     tarifa[4];
   char     indica_refact[2];
   
   double   cargo_fijo;
   double   cargo_variable;
   double   cargo_tap;
   char     factu_digital[2];
   double   recargoAnterior;
   double   cargo_kit;
   
}ClsFactura;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( long *);
short LeoFacturas(ClsFactura *);
void  InicializaFactura(ClsFactura *);
short LeoDetalle(ClsFactura *, int);

short	GenerarPlano(FILE *, ClsFactura);

char 	*strReplace(char *, char *, char *);
void	CerrarArchivos(void);
void	FormateaArchivos(void);

/*
short	EnviarMail( char *, char *);
void  	ArmaMensajeMail(char **);
short	CargaEmail(ClsCliente, ClsEmail*, int *);
void    InicializaEmail(ClsEmail*);
*/

$endif;

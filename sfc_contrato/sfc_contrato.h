$ifndef SFCCONTRATO_H;
$define SFCCONTRATO_H;

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
   char  nombre[41];
   char  tipo_fpago[2];
   char  tipo_reparto[7];
   long  nro_beneficiario;
   char  sFechaAlta[11];      
   char  factu_digital[2];
   char  sFechaAltaFactuDigital[11];
   char  sNombreBanco[41];
   char  codTarjetaCredito[11];
   char  nroTarjeta[21];
   char  cbu[23];
   char  codBanco[7];
   char  codActividadEconomica[100];
   char  tipo_titularidad[51];
   long  minist_repart;
   char  papa_t23[11];
   char  sTasaAP[10];
   char  sPatidaMuni[14];
   char  sMarcaTarjeta[2];
    char    dgFechaEmision[11];
    long    dgGarante;
   
}ClsCliente;

$typedef struct{
   char  fp_banco[7];
   char  fp_nrocuenta[21];
   char  fp_cbu[23];
   char  tipo[2];
   char  nombre[31];
}ClsFormaPago;


$typedef struct{
    long    nroDg;
    char    sFechaEmision[11];
    long    lGarante;
    char    motivo[10];
}ClsGarantia;

/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( ClsCliente *);
void  InicializaCliente(ClsCliente *);
void  CargaAlta1(ClsCliente *);
short CargaAlta2(ClsCliente *);
void  CargaTasa(ClsCliente *);
void  CargaFormaPago(ClsCliente *);
short PadreEnT23(ClsCliente *);

void GeneraContrato(ClsCliente);
void GeneraLinea(ClsCliente);
void GeneraBilling(ClsCliente);

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

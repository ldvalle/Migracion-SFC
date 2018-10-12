$ifndef SFCCONVENIOS_H;
$define SFCCONVENIOS_H;

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
   int   corr_convenio;
   char  opcion_convenio[5];
   char  estado[2];
   char  fecha_creacion[11];
   char  fecha_termino[11];
   double   deuda_origen;
   double   valor_cuota_ini;
   double   deuda_convenida;
   double   valor_cuota;
   int   numero_tot_cuotas;
   int   numero_ult_cuota;
   float intereses;
   char  usuario_creacion[11]; 
   char  usuario_termino[11];
}ClsConve;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( long *);
short LeoConve(ClsConve *);
void  InicializaConve(ClsConve *);

short	GenerarPlano(FILE *, ClsConve);

char 	*strReplace(char *, char *, char *);
char	*getEmplazaSAP(char*);
char	*getEmplazaT23(char*);
void	CerrarArchivos(void);
void	FormateaArchivos(void);

/*
short	EnviarMail( char *, char *);
void  	ArmaMensajeMail(char **);
short	CargaEmail(ClsCliente, ClsEmail*, int *);
void    InicializaEmail(ClsEmail*);
*/

$endif;

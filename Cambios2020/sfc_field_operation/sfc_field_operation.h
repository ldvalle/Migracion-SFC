$ifndef SFCFIELDOPERATION_H;
$define SFCFIELDOPERATION_H;

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
   char  fecha_corte[25];
   char  fecha_reposicion[25];
   double   saldo_exigible;
   char  motivo_corte[3];
   char  desc_motivo_corte[51];
   char  motivo_repo[3];
   char  accion_corte[3];
   char  accion_rehab[3];
   char  funcionario_corte[10];
   char  funcionario_repo[10];
   char  fecha_ini_evento[25];
   char  fecha_sol_repo[25];
   char  sit_encon[3];
   char  sit_rehab[3];
   int   corr_corte;
   int   corr_repo;
}ClsCorte;

$typedef struct{
   long  numero_cliente;
   char  fecha_solicitud[25];
   char  cod_motivo[3];
   char  motivo[51];
   char  rol[21];
   char  estado[11];
   int   dias;
   int   corr_rehab;
   char	sFechaSol[9];
}ClsExtent;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( long *);
short LeoCortes(ClsCorte *);
short LeoRepo(ClsCorte *);
void  InicializaCorte(ClsCorte *);

short LeoExtent(ClsExtent *);
void  InicializaExtent(ClsExtent *);

short	GenerarPlano(FILE *, ClsCorte, ClsExtent, char *, int);

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

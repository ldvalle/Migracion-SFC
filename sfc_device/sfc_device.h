$ifndef SFCDEVICE_H;
$define SFCDEVICE_H;

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
   long	numero;
	char	marca[4];
	char	modelo[3];
   char  estado[4];	
	char	med_ubic[4]; 
	char	med_codubic[11];
	long	numero_cliente;
   char	tipo_medidor[2];
   char  estado_sfc[2];
}ClsMedidor;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short  LeoMedidores(ClsMedidor *);
void   InicializaMedidor(ClsMedidor *);
short CargaEstadoSFC(ClsMedidor *);
short	GenerarPlano(FILE *, ClsMedidor);

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

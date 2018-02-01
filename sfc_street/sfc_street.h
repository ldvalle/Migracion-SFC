$ifndef SFCSTREET_H;
$define SFCSTREET_H;

#include "ustring.h"
#include "macmath.h"

$include sqltypes.h;
$include sqlerror.h;
$include datetime.h;

#define BORRAR(x)       memset(&x, 0, sizeof x)
#define BORRA_STR(str)  memset(str, 0, sizeof str)

#define SYN_CLAVE "DD_NOVOUT"

#define SEPARADOR ";"

/* Estructuras **/

$typedef struct{
   char  cod_calle[7]; 
   char  nombre_calle[26]; 
   int   altura_desde; 
   int   altura_hasta;
   char  cod_partido[4];
   char  desc_partido[26];
   char  cod_localidad[4]; 
   char  desc_localidad[26];
}ClsNomencla;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  	CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

void  InicializaNomencla(ClsNomencla *);
short LeoNomencla(ClsNomencla *);
void  GeneraNomencla(FILE *, ClsNomencla);
void  GeneraNoNomencla(FILE *);

char 	*strReplace(char *, char *, char *);
void	CerrarArchivos(void);
void	FormateaArchivos(void);
$endif;

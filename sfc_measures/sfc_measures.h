$ifndef SFCMEASURES_H;
$define SFCMEASURES_H;

#include "ustring.h"
#include "macmath.h"

$include sqltypes.h;
$include sqlerror.h;
$include datetime.h;

#define BORRAR(x)       memset(&x, 0, sizeof x)
#define BORRA_STR(str)  memset(str, 0, sizeof str)

#define SYN_CLAVE "DD_NOVOUT"

/* --- Estructuras ---*/

$typedef struct{
   long     numero_cliente;
   int      corr_facturacion; 
   int      tipo_lectura;
   char     fecha_lectura[11];
   double   constante;
   long     consumo;  
   double   lectura_facturac;
   double   lectura_terreno;
   char     id_factura[50];
   char     indica_refact[2];
   char     fecha_facturacion[11];
   long     numero_medidor;
   char     marca_medidor[4];
   char     modelo_medidor[3];
   char     tipo_medidor[2];
   double   coseno_phi;
   char     proxLectura[11];
   char     estado_medidor[2];
   
   char     clave_lectura[60];
   double   lectura_bim;
   double   lectura_bim_activa;
   double   lectura_bim_reactiva;
   char     fecha_lectura_bim[11];
   int		tipo_lectura_bim;
   double   consumoRectificado;
}ClsLectura;


$typedef struct{
	int		tipo_lectura;
	char		fecha_cierre[11];
	double   lectura_activa_cierre;
	double   consumo_activa;
	double   lectura_reactiva_cierre;
	double   consumo_reactiva;
}ClsLecturaBim;

/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoCliente( long *, int *);
short LeoLecturas(ClsLectura *);
void  InicializaLectura(ClsLectura *);
short LeoReactiva(ClsLectura *);
void  InicializaLectuReac(ClsLectura *);

short LeoAjustes(ClsLectura *);
short LeoBimestral(ClsLectura, ClsLecturaBim *);
void  InicializaBimestral(ClsLecturaBim *);
short	GenerarPlano(FILE *, ClsLectura, char *);
short	GenerarPlanoConsumo(FILE *, ClsLectura, char *);

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

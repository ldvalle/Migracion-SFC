$ifndef SFCCONTACTOS_H;
$define SFCCONTACTOS_H;

#include "ustring.h"
/*#include "macmath.h"*/

$include sqltypes.h;
$include sqlerror.h;
$include datetime.h;

#define BORRAR(x)       memset(&x, 0, sizeof x)
#define BORRA_STR(str)  memset(str, 0, sizeof str)

#define SYN_CLAVE "DD_NOVOUT"

/* --- Estructuras ---*/

$typedef struct{
	
	long		numero_cliente;
	long		numero_contacto;
	char		suc_contacto[5];
	char		cod_motivo_cliente[10];
	char		cod_mot_empresa[10];
	char		cod_medio[7];
	char		tipo_contacto[7];
	char		fecha_inicio[20];
	char		rol_inicio[20];
	char		fecha_cerrado[20];
	char		rol_cierre[20];
	char		oficina[4];
	char		desc_suctrof[31];
	char     resultado[7];
	char     sEstado[8];
}ClsContactos;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
short	AbreArchivos(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short LeoAbiertos(ClsContactos *);
short LeoCerrados(ClsContactos *);
void  InicializaContactos(ClsContactos *);

short	GenerarPlano(FILE *, ClsContactos);

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

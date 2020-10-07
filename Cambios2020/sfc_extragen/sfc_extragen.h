$ifndef SFCEXTRAGEN_H;
$define SFCEXTRAGEN_H;

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
	long	numero_cliente;
	char	nombre[41];
   char  cod_calle[7];
	char	nom_calle[26];
	char	nom_partido[26];
	char	provincia[4];
	char	nom_comuna[26];
	char	nro_dir[6];
	char	obs_dir[61];
	int	cod_postal;
	char	piso_dir[7];
	char	depto_dir[7];
	char	tip_doc[11];
   char  tip_doc_SF[11];
	double	nro_doc;
	char	telefono[20];
	char	tipo_cliente[3];
	char	rut[14];
	char	tipo_reparto[7];
	char	sucursal[5];
	int	sector;
	int	zona;
	char	tarifa[4];
	long	correlativo_ruta;
	char	sClaseServicio[11];
	char	sSubClaseServ[11];
	char	partido[4];
	char	comuna[4];
	char  tec_cod_calle[7];
   char  nom_barrio[26];
   double   potencia_inst_fp;
   
   char  sClienteDigital[2];
	char	email_1[51];
	char	email_2[51];
   char	email_3[51];
	char	electrodependiente[2];
	char	dp_nom_calle[36];
	char	dp_nro_dir[6];
	char	dp_piso_dir[7];
	char	dp_depto_dir[7];
	int	dp_cod_postal;
	char	dp_nom_localidad[26];
	long	medidor_nro;
	char	medidor_marca[4];
	char	medidor_modelo[3];
	int	medidor_anio;
	
	char	tec_centro_trans[21];
	char	tipo_tranformador[3];
	char	tipo_conexion[6];
	char	tec_subestacion[4];
	char	tec_alimentador[12];
   char  cod_voltaje[3];

   char  tec_nom_calle[26];
   char  tec_nro_dir[6];
   char  tec_piso_dir[7];
   char  tec_depto_dir[7];
   char  tec_cod_local[4];
   
	char	ultimo_corte[11];
	char	telefono_celular[20];
	char	telefono_secundario[20];
	char	es_empresa[2];
   char  entre_calle1[26];
   char  entre_calle2[26];
   char  email_contacto[101];
   char  tipoIva[3];
   
   double  nro_dci;
   char  orga_dci[3];
   long  minist_repart;
   char  papa_t23[11];
   
   char  sCodPropiedad[60];
   char	sTipoInstalacion[60];
   char	sTipoConexion[60];
   char	sTension[60];
}ClsClientes;

$typedef struct{
	char	tipo_te[3];
	char	cod_area_te[6];
	char	prefijo_te[3];
	long	numero_te;
	char	ppal_te[2];
}ClsTelefonos;

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

$typedef struct{
   char     telefono_fijo[21];
   char     telefono_movil[21];
   char     telefono_secun[21];
   char     zona_tecnica[31];
}ClsTeleCerta;


/* Prototipos de Funciones */
short	AnalizarParametros(int, char **);
void	MensajeParametros(void);
void  CargaPeriodoAnalisis(int, char **, char *);
short ValidaFecha(char *);
short CargaContingente(void);


short	AbreArchivos(void);
void  CreaPrepareIni(void);
void  CreaPrepare(void);
void 	FechaGeneracionFormateada( char *);
void 	RutaArchivos( char*, char * );

short   LeoCliente(ClsClientes *);
void    InicializaCliente(ClsClientes *);
short   PadreEnT23(ClsClientes *);

void  InicializaNomencla(ClsNomencla *);
short LeoNomencla(ClsNomencla *);
void  GeneraNomencla(FILE *, ClsNomencla);
void  GeneraNoNomencla(FILE *);

short CargoEmail(ClsClientes *);
short	CargoTelefonos(ClsClientes *);
void  InicializoTelefonos(ClsTelefonos *);
short	LeoTelefonos(ClsTelefonos *);
short LeoTelCerta(long, ClsTeleCerta *);
short	CargoVIP(ClsClientes *);
short CargaDCI(ClsClientes *);
short	CargoPostal(ClsClientes *);
short	DatosMedidor(ClsClientes *);
short	DatosTecnicos(ClsClientes *);
short UltimoCorte(ClsClientes *);

short CargoContactos(void);
short LeoContactos(ClsClientes *, int *);

short	GenerarPlanos(ClsClientes);
void	GeneraStreet(FILE *, ClsClientes);
void	GeneraAddress(FILE *, ClsClientes, char *);
void	GeneraCuentas(FILE *, ClsClientes);
void	GeneraContactos(FILE *, ClsClientes);
void	GeneraEFactura(FILE *, ClsClientes, char *, int);
void  GeneraEBilling(FILE *, ClsClientes, char *, int);

void	GeneraCuentasContacto(FILE *, ClsClientes);
void	GeneraPointDelivery(FILE *, ClsClientes);
void	GeneraServiceProduct(FILE *, ClsClientes);
void	GeneraAsset(FILE *, ClsClientes);
void  GeneraNoNomencla(FILE *);

short ValidaCalle(ClsClientes);
short ValidaEmail(char*);

short LeoBajas(long *);
void  GeneraBaja(long);
short RegistraCorrida(long);

char 	*strReplace(char *, char *, char *);
void	CerrarArchivos(void);
void	FormateaArchivos(void);
int   instr(char *, char *);

$endif;

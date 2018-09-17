package entidades;

import dao.ExtragenDAO;
import servicios.ExtragenSRV;

public class ExtragenDTO {
	// Datos ppales a Informar
	public	long	numero_cliente;
	public	String	nombre;
	public	String	cod_calle;
	public	String	nom_calle;
	public	String	nom_partido;
	public	String	provincia;
	public	String	nom_comuna;
	public	String	nro_dir;
	public	String	obs_dir;
	public	int		cod_postal;
	public	String	piso_dir;
	public	String	depto_dir;
	public	String	tip_doc;
	public	String	tip_doc_SF;
	public	Double	nro_doc;
	public	String	telefono;
	public	String	tipo_cliente;
	public	String	rut;
	public	String	tipo_reparto;
	public	String	sucursal;
	public	int		sector;
	public	int		zona;
	public	String	tarifa;
	public	long	correlativo_ruta;
	public	String	sClaseServicio;
	public	String	sSubClaseServ;
	public	String	partido;
	public	String	comuna;
	public	String	tec_cod_calle;
	public	String	nom_barrio;
	public	Double  potencia_inst_fp;
	public	String	email_1;
	public	String	email_2;
	public	String	email_3;
	public	String	electrodependiente;
	public	String	dp_nom_calle;
	public	String	dp_nro_dir;
	public	String	dp_piso_dir;
	public	String	dp_depto_dir;
	public	int		dp_cod_postal;
	public	String	dp_nom_localidad;
	public	long	medidor_nro;
	public	String	medidor_marca;
	public	String	medidor_modelo;
	public	int		medidor_anio;
	public	String	tec_centro_trans;
	public	String	tipo_tranformador;
	public	String	tipo_conexion;
	public	String	tec_subestacion;
	public	String	tec_alimentador;
	public	String	cod_voltaje;
	public	String	tec_nom_calle;
	public	String	tec_nro_dir;
	public	String	tec_piso_dir;
	public	String	tec_depto_dir;
	public	String	tec_cod_local;
	public	String	ultimo_corte;
	public	String	telefono_celular;
	public	String	telefono_secundario;
	public	String	es_empresa;
	public	String	entre_calle1;
	public	String	entre_calle2;
	public	String	email_contacto;
	public	String	tipoIva;
	public	Double  nro_dci;
	public	String	orga_dci;
	public	long  	minist_repart;
	public	String	papa_t23;
	
	// Telefonos
	public	String	tel_tipo_te;
	public	String	tel_cod_area_te;
	public	String	tel_prefijo_te;
	public	long	tel_numero_te;
	public	String	tel_ppal_te;

	// Telefonos CERTA
	public	String	telCer_telefono_fijo;
	public	String	telCer_telefono_movil;
	public	String	telCer_telefono_secun;
	public	String	telCer_zona_tecnica;

	
	public ExtragenDTO() {
		
	}
	
}

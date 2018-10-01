package dao;

import entidades.ExtragenDTO;
/*import servicios.CnrSRV;*/
import servicios.ExtragenSRV;

/*import java.lang.*;*/
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
/*
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;
*/
import org.apache.commons.lang3.StringUtils;


import conectBD.UConnection;

public class ExtragenDAO {
	Connection con = null;
	PreparedStatement pstm0 = null;
	ResultSet rs0 = null;
	
	PreparedStatement stCliente = null;
	PreparedStatement stEmail = null;
	PreparedStatement stTele = null;
	PreparedStatement stTeleCerta = null;
	PreparedStatement stVip = null;
	PreparedStatement stValCalle = null;
	
	private long lNroCli;
	
	public ExtragenDAO () throws SQLException {
		con = UConnection.getConnection();
		
		stCliente = con.prepareStatement(SEL_CLIENTE);
		stEmail = con.prepareStatement(SEL_EMAIL);
		stTele = con.prepareStatement(SEL_TELEFONOS);
		stTeleCerta = con.prepareStatement(SEL_TELE_CERTA);
		stVip = con.prepareStatement(SEL_VIP);
		stValCalle = con.prepareStatement(SEL_VAL_CALLE);
	}
	
	public String getRuta(String sCodigo) {
		String sRuta="";
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SQL_SEL_RUTA_FILES);
			st.setString(1, sCodigo);
			rs=st.executeQuery();
			if(rs.next()) {
				sRuta = rs.getString(1);
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return sRuta;
	}

	public Boolean ProcesoPpal(int iTipoCorrida, int iEstadoCliente) {
		long lCantClientes=0;
		
		/*
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		*/
		ExtragenSRV miSrv = new ExtragenSRV();
		/*ExtragenDTO miClie = new ExtragenDTO();*/
		
		String sql = getCursorClientes(iTipoCorrida, iEstadoCliente);

		try {
			/*
			con = UConnection.getConnection();
			*/
			
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
			
			pstm0 = con.prepareStatement(sql, ResultSet.TYPE_SCROLL_INSENSITIVE , ResultSet.CONCUR_READ_ONLY, ResultSet.HOLD_CURSORS_OVER_COMMIT);
			pstm0.setQueryTimeout(120);
			pstm0.setFetchSize(1);
			rs0 = pstm0.executeQuery();

			while (rs0.next()) {
				ExtragenDTO miClie = new ExtragenDTO(rs0.getLong(1));
				/*miClie.numero_cliente = rs0.getLong(1);*/
				lNroCli = miClie.numero_cliente;
				
				//Cargo Datos Generales
				getClienteGral(miClie);

				//Cargo Email
				getEmail(miClie);

				//Cargo Telefonos
				getTelefonos(miClie);
				
				//Cargo VIP
				getVip(miClie);

				lCantClientes++;

				//Informamos 
				if(!miSrv.InformaExtragen(miClie)) {
					System.out.println("Fallo informar Extragen para Cliente " + miClie.numero_cliente);
					return false;
				}
				
			}
			System.out.println("Clientes Procesados " + lCantClientes);
			rs0.close();
			pstm0.close();
		}catch(Exception ex){
			System.out.println("revento en la vuelta " + lCantClientes + " Ultimo Cliente " + lNroCli);
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
	
		return true;
	}
	
	
	public void getClienteGral(ExtragenDTO reg) {
		/*Connection con = null;*/
		/*PreparedStatement stCliente = null;*/
		ResultSet rs = null;

		try {
			/*con = UConnection.getConnection();*/
			/*st = con.prepareStatement(SEL_CLIENTE);*/
			stCliente.setLong(1, reg.numero_cliente);

			rs=stCliente.executeQuery();
			if(rs.next()) 
				//Copia datos de cliente
				CopiaDatos(reg, rs);

			rs.close();
			/*stCliente.close();*/
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
	}
	
	private void CopiaDatos(ExtragenDTO reg, ResultSet rs) throws SQLException
	{
		reg.numero_cliente = rs.getLong(1);
		reg.nombre = rs.getString(2).trim();
		reg.cod_calle = StringUtils.trim(rs.getString(3));
		reg.nom_calle =rs.getString(4).trim();
		reg.nom_partido = rs.getString(5).trim();
		reg.provincia = rs.getString(6);
		reg.nom_comuna = rs.getString(7).trim();
		reg.nro_dir = rs.getString(8).trim();
		reg.obs_dir = StringUtils.trim(rs.getString(9));
		reg.cod_postal = rs.getInt(10);
		reg.piso_dir = rs.getString(11);
		reg.depto_dir = rs.getString(12);
		reg.tip_doc = rs.getString(13).trim();
		reg.tip_doc_SF = rs.getString(14).trim();
		reg.nro_doc = rs.getDouble(15);
		reg.telefono = StringUtils.trim(rs.getString(16));
		reg.tipo_cliente = rs.getString(17);
		reg.rut = rs.getString(18);
		reg.tipo_reparto = rs.getString(19);
		reg.sucursal = rs.getString(20).trim();
		reg.sector = rs.getInt(21);
		reg.zona = rs.getInt(22);
		reg.tarifa = rs.getString(23);
		reg.correlativo_ruta = rs.getLong(24);
		reg.sClaseServicio = rs.getString(25).trim();
		reg.sSubClaseServ = rs.getString(26);
		reg.partido = rs.getString(27);
		reg.comuna = rs.getString(28);
		reg.tec_cod_calle = StringUtils.trim(rs.getString(29));
		reg.nom_barrio = StringUtils.trim(rs.getString(30));
		reg.potencia_inst_fp = rs.getDouble(31);
		reg.entre_calle1 = StringUtils.trim(rs.getString(32));
		reg.entre_calle2 = StringUtils.trim(rs.getString(33));
		reg.tipoIva = rs.getString(34).trim();
		reg.minist_repart = rs.getLong(35);
		reg.estado_cliente = rs.getString(36).trim();
		
		if(reg.cod_calle == null || reg.cod_calle.equals("-1")) {
			if(reg.tec_cod_calle != null && !reg.tec_cod_calle.equals("-1")) {
				reg.cod_calle = reg.tec_cod_calle;
			}
			
		}
	}
	
	/*public ExtragenDTO getEmail(long lNroCliente) {*/
	public void getEmail(ExtragenDTO reg) {
		/*Connection con = null;
		PreparedStatement stEmail = null;*/
		ResultSet rs = null;
		/*ExtragenDTO reg = new ExtragenDTO();*/
		
		try {
			/*con = UConnection.getConnection();
			stEmail = con.prepareStatement(SEL_EMAIL);*/
			stEmail.setLong(1, reg.numero_cliente);

			rs=stEmail.executeQuery();
			if(rs.next()) {
				reg.email_1 = rs.getString(1);
				reg.email_2 = rs.getString(2);
				reg.email_3 = rs.getString(3);
			}
			
			if(rs.wasNull()) {
				reg.email_1 = "NO TIENE";
				reg.email_2 = "NO TIENE";
				reg.email_3 = "NO TIENE";
			}else {
				if(reg.email_1 == null || reg.email_1.equals("")) {
					reg.email_1 = "NO TIENE";
				}
				if(reg.email_2 == null || reg.email_2.equals("")) {
					reg.email_2 = "NO TIENE";
				}
				if(reg.email_3 == null || reg.email_3.equals("")) {
					reg.email_3 = "NO TIENE";
				}
				
			}
			
			rs.close();
			/*stEmail.close();*/
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		/*return reg;*/
	}

	/*public ExtragenDTO getTelefonos(long lNroCliente) {*/
	public void getTelefonos(ExtragenDTO reg) {
		/*Connection con = null;
		PreparedStatement stTele = null;*/
		ResultSet rs = null;
		/*ExtragenDTO reg = new ExtragenDTO();*/
		
		try {
			/*con = UConnection.getConnection();
			stTele = con.prepareStatement(SEL_TELEFONOS);*/
			
			stTele.setLong(1, reg.numero_cliente);

			rs=stTele.executeQuery();
			while(rs.next()) {
				reg.tel_tipo_te = rs.getString(1);
				reg.tel_cod_area_te = rs.getString(2);
				reg.tel_prefijo_te = rs.getString(3);
				reg.tel_numero_te = rs.getLong(4); 
				reg.tel_ppal_te = rs.getString(5);
				
				if (Long.toString(reg.tel_numero_te).length() >= 7 ) {
					if (reg.tel_tipo_te.equals("CE")) 
						reg.telefono_celular = reg.tel_cod_area_te + reg.tel_prefijo_te + Long.toString(reg.tel_numero_te);   
					else if (reg.tel_ppal_te.equals("P")) 
						reg.telefono = reg.tel_cod_area_te + Long.toString(reg.tel_numero_te);
					else
						reg.telefono_secundario = reg.tel_cod_area_te + Long.toString(reg.tel_numero_te);
				}
			}

			rs.close();
			/*stTele.close();*/
			
			// Telefonos de CERTA
			/*stTeleCerta = con.prepareStatement(SEL_TELE_CERTA);*/
			/*st.setLong(1, lNroCliente);*/
			stTeleCerta.setLong(1, reg.numero_cliente);

			rs=stTeleCerta.executeQuery();
			if(rs.next() && !rs.wasNull()) {
				if(rs.getString(1) != null && !rs.getString(1).equals("")) 
					reg.telefono = rs.getString(1);
				if(rs.getString(2) != null && !rs.getString(2).equals("")) 
					reg.telefono_celular = rs.getString(2);
				if(rs.getString(3) != null && !rs.getString(3).equals("")) 
					reg.telefono_secundario = rs.getString(3);
			}
			
			if (StringUtils.length(reg.telefono) < 7 || Long.parseLong(reg.telefono) < 1000000)
				reg.telefono="";
			if (StringUtils.length(reg.telefono_secundario) < 7 || Long.parseLong(reg.telefono_secundario) < 1000000)
				reg.telefono_secundario="";
			if (StringUtils.length(reg.telefono_celular) < 7 || Long.parseLong(reg.telefono_celular) < 1000000)
				reg.telefono_celular="";
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		/*return reg;*/
	}
	
	public void getVip(ExtragenDTO reg) {
		/*Connection con = null;
		PreparedStatement st = null;*/
		ResultSet rs = null;
		
		try {
			/*con = UConnection.getConnection();
			stVip = con.prepareStatement(SEL_VIP);*/
			stVip.setLong(1, reg.numero_cliente);

			rs=stVip.executeQuery();
			if(rs.next()) 
				reg.electrodependiente = Integer.parseInt(rs.getString(1)) > 0 ? "1" : "0";

			rs.close();
			/*stVip.close();*/
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
	}
	
	public Boolean getValCalle(String cod_calle, Long lAltura, String partido, String comuna) {
		ResultSet rs = null;
		int iCant = 0;
		
		try {
			stValCalle.setString(1, cod_calle);
			stValCalle.setLong  (2, lAltura);
			stValCalle.setLong  (3, lAltura);
			stValCalle.setString(4, partido);
			stValCalle.setString(5, comuna);

			rs=stValCalle.executeQuery();
			if(rs.next()) 
				iCant = Integer.parseInt(rs.getString(1));
				
			rs.close();
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return iCant <= 0 ? false : true;
	}
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getCursorClientes(int iTipoCorrida, int iEstadoCliente) {
		String sql = "SELECT c.numero_cliente FROM cliente c ";
		
		if(iTipoCorrida == 1)
			sql += ", migra_sf ma ";
		if(iEstadoCliente == 1)
			sql += ", sap_inactivos si ";
		if(iEstadoCliente == 0) {
			sql += "WHERE c.estado_cliente = 0 ";
		}else {
			sql += "WHERE c.estado_cliente != 0 ";
		}

		sql +=  "AND c.tipo_sum != 5 " + 
				"AND c.tipo_sum NOT IN (5, 6) " + 
				"AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm " + 
				"WHERE cm.numero_cliente = c.numero_cliente " + 
				"AND cm.fecha_activacion < TODAY " + 
				"AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY))";

		if(iTipoCorrida == 1)
			sql += " AND ma.numero_cliente = c.numero_cliente ";
		if(iEstadoCliente == 1)
			sql += "AND si.numero_cliente = c.numero_cliente ";
		
		return sql;
	}
	
	private static final String SEL_CLIENTE = "SELECT c.numero_cliente, " + 
			"REPLACE(TRIM(c.nombre), '\"', ' '), " + 
			"c.cod_calle, " + 
			"c.nom_calle, " + 
			"TRIM(c.nom_partido), " + 
			"c.provincia, " + 
			"TRIM(c.nom_comuna), " + 
			"c.nro_dir, " + 
			"TRIM(c.obs_dir), " + 
			"c.cod_postal, " + 
			"c.piso_dir, " + 
			"c.depto_dir, " + 
			"c.tip_doc, " + 
			"t3.cod_sf1 tipDoc, " + 
			"c.nro_doc, " + 
			"TRIM(REPLACE(c.telefono, '-', '')), " +  
			"c.tipo_cliente, " + 
			"c.rut, " + 
			"c.tipo_reparto, " + 
			"c.sucursal, " + 
			"c.sector, " + 
			"c.zona, " + 
			"c.tarifa, " + 
			"c.correlativo_ruta, " + 
			"t1.cod_sf1 tipCli, " + 
			"t1.cod_sf2 tipClaCli, " + 
			"c.partido, " + 
			"c.comuna, " + 
			"t.tec_cod_calle, " + 
			"TRIM(c.nom_barrio), " + 
			"c.potencia_inst_fp, " + 
			"TRIM(c.nom_entre), " + 
			"TRIM(c.nom_entre1), " + 
			"t2.cod_sap tipoIva, " + 
			"c.minist_repart, " + 
			"c.estado_cliente " +
			"FROM cliente c, OUTER sf_transforma t1, OUTER tecni t " + 
			", OUTER sap_transforma t2, OUTER sf_transforma t3 " + 
			"WHERE c.numero_cliente = ? " + 
			"AND c.tipo_sum != 5 " + 
			"AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med m " + 
			"	WHERE m.numero_cliente = c.numero_cliente " + 
			"	AND m.fecha_activacion < TODAY  " + 
			"	AND (m.fecha_desactiva IS NULL OR m.fecha_desactiva > TODAY)) " + 
			"AND t1.clave = 'TIPCLI' " + 
			"AND t1.cod_mac = c.tipo_cliente " + 
			"AND t.numero_cliente = c.numero_cliente " + 
			"AND t2.clave = 'TIPIVA' " + 
			"AND t2.cod_mac = c.tipo_iva " + 
			"AND t3.clave = 'TIPDOCU' " + 
			"AND t3.cod_mac = c.tip_doc";
	
	private static final String SEL_EMAIL = "SELECT TRIM(email_1), TRIM(email_2), TRIM(email_3) " + 
			"FROM clientes_digital " + 
			"WHERE numero_cliente = ? " + 
			"AND fecha_alta <= TODAY " + 
			"AND (fecha_baja IS NULL OR fecha_baja > TODAY) "; 

	
	private static final String SEL_TELEFONOS = "SELECT TRIM(tipo_te), " + 
			"TRIM(NVL(cod_area_te, '')), " + 
			"TRIM(NVL(prefijo_te, '')), " + 
			"numero_te, " + 
			"TRIM(ppal_te) " + 
			"FROM telefono " + 
			"WHERE cliente = ? "; 

	private static final String SEL_TELE_CERTA = "SELECT TRIM(telefono_fijo), " + 
			"TRIM(telefono_movil), " + 
			"TRIM(telefono_secun), " + 
			"TRIM(zona_tecnica) " + 
			"FROM tele_certa " + 
			"WHERE numero_cleinte = ? "; 

	private static final String SEL_VIP = "SELECT COUNT(*) " + 
			"FROM clientes_vip v, tabla t " + 
			"WHERE numero_cliente = ? " +
			"AND v.fecha_activacion <= TODAY " + 
			"AND (v.fecha_desactivac IS NULL OR v.fecha_desactivac > TODAY) " +
			"AND t.nomtabla = 'SDCLIV' " +
			"AND t.codigo = v.motivo " +
			"AND t.valor_alf[4] = 'S' " +
			"AND t.sucursal = '0000' " +
			"AND t.fecha_activacion <= TODAY "+ 
			"AND ( t.fecha_desactivac >= TODAY OR t.fecha_desactivac IS NULL )";    

	private static final String SEL_VAL_CALLE = "SELECT COUNT(*) " + 
			"FROM sae_nomen_calles nc, " + 
			"SAE_ORG_GEOGRAFICA a1, SAE_TABLAS b1, " +
			"SAE_ORG_GEOGRAFICA a2, SAE_TABLAS b2 " +
			"WHERE nc.nom_cod_calle = ? " +
			"AND nc.nom_altura_desde <= ? " +
			"AND nc.nom_altura_hasta >= ? " +
			"AND a1.org_destino = ? " +
			"AND a2.org_destino = ? " +
			"AND nc.nom_altura_hasta > nc.nom_altura_desde " + 
			"AND a1.org_destino = nc.nom_partido " + 
			"AND a1.org_tipo_relacion = 'SP' " + 
			"AND a1.org_origen = nc.nom_sucursal " +
			"AND a1.org_destino = b1.tbl_codigo " + 
			"AND b1.tbl_tipo_tabla = 8 " + 
			"AND a2.org_tipo_relacion = 'PL' " + 
			"AND a2.org_origen = nc.nom_partido " + 
			"AND a2.org_destino = nc.nom_localidad " + 
			"AND a2.org_destino = b2.tbl_codigo " + 
			"AND b2.tbl_tipo_tabla = 9 "; 
}

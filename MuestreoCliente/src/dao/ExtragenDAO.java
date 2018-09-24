package dao;

import conectBD.UConnection;
import entidades.ExtragenDTO;
import servicios.ExtragenSRV;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class ExtragenDAO {

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
		long lNroCliente=0;
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		ExtragenSRV miSrv = new ExtragenSRV();
		
		String sql = getCursorClientes(iTipoCorrida, iEstadoCliente);

		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
			pstm0 = con.prepareStatement(sql, ResultSet.TYPE_SCROLL_INSENSITIVE , ResultSet.CONCUR_READ_ONLY, ResultSet.HOLD_CURSORS_OVER_COMMIT);
			pstm0.setQueryTimeout(120);
			pstm0.setFetchSize(1);
			rs0 = pstm0.executeQuery();

			while(rs0.next() ){
				lNroCliente = rs0.getLong(1);

				if(! miSrv.ProcesaCliente(lNroCliente)) {
					System.out.println("No se proceso cliente " + lNroCliente);
				}

				lCantClientes++;
			}
			System.out.println("Clientes Procesados " + lCantClientes);
			rs0.close();
			pstm0.close();
		}catch(Exception ex){
			System.out.println("revento en la vuelta " + lCantClientes + " Ultimo Cliente " + lNroCliente);
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
	
		return true;
	}
	
	
	public ExtragenDTO getClienteGral(long lNroCliente) {
		ExtragenDTO reg = new ExtragenDTO();
		
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_CLIENTE);
			st.setLong(1, lNroCliente);

			rs=st.executeQuery();
			if(rs.next()) {
				ExtragenDTO regMail = null;
				
				reg.numero_cliente = rs.getLong(1);
				reg.nombre = rs.getString(2).trim();
				reg.cod_calle = rs.getString(3);
				reg.nom_calle =rs.getString(4).trim();
				reg.nom_partido = rs.getString(5).trim();
				reg.provincia = rs.getString(6);
				reg.nom_comuna = rs.getString(7).trim();
				reg.nro_dir = rs.getString(8).trim();
				reg.obs_dir = rs.getString(9).trim();
				reg.cod_postal = rs.getInt(10);
				reg.piso_dir = rs.getString(11);
				reg.depto_dir = rs.getString(12);
				reg.tip_doc = rs.getString(13).trim();
				reg.tip_doc_SF = rs.getString(14).trim();
				reg.nro_doc = rs.getDouble(15);
				reg.telefono = rs.getString(16).trim();
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
				reg.tec_cod_calle = rs.getString(29);
				reg.nom_barrio = rs.getString(30).trim();
				reg.potencia_inst_fp = rs.getDouble(31);
				reg.entre_calle1 = rs.getString(32).trim();
				reg.entre_calle2 = rs.getString(33).trim();
				reg.tipoIva = rs.getString(34).trim();
				reg.minist_repart = rs.getLong(35);

				if(reg.cod_calle.trim() == null || reg.cod_calle.trim().equals("-1")) {
					if(reg.tec_cod_calle.trim() != null || !reg.tec_cod_calle.trim().equals("-1")) {
						reg.cod_calle = reg.tec_cod_calle;
					}
					
				}
				//Cargo Email
				regMail = getEmail(lNroCliente);
				reg.email_1 = regMail.email_1;
				reg.email_2 = regMail.email_2;
				reg.email_3 = regMail.email_3;

				//Cargo Telefonos
				
				
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return reg;
	}
	
	public ExtragenDTO getEmail(long lNroCliente) {
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;
		ExtragenDTO reg = new ExtragenDTO();
		
		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_EMAIL);
			st.setLong(1, lNroCliente);

			rs=st.executeQuery();
			if(rs.next()) {
				reg.email_1 = rs.getString(1).trim();
				reg.email_2 = rs.getString(2).trim();
				reg.email_3 = rs.getString(3).trim();

			}
			
			if(rs.wasNull()) {
				reg.email_1 = "NO TIENE";
				reg.email_2 = "NO TIENE";
				reg.email_3 = "NO TIENE";
			}else {
				if(reg.email_1.trim().equals("") || reg.email_1 == null) {
					reg.email_1 = "NO TIENE";
				}
				if(reg.email_2.trim().equals("") || reg.email_2 == null) {
					reg.email_2 = "NO TIENE";
				}
				if(reg.email_2.trim().equals("") || reg.email_2 == null) {
					reg.email_2 = "NO TIENE";
				}
				
			}
			
			rs.close();
			st.close();
			
				
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return reg;
	}

	public ExtragenDTO getTelefonos(long lNroCliente) {
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;
		ExtragenDTO reg = new ExtragenDTO();
		
		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_EMAIL);
			st.setLong(1, lNroCliente);

			rs=st.executeQuery();
			while(rs.next()) {
				reg.email_1 = rs.getString(1).trim();
				reg.email_2 = rs.getString(2).trim();
				reg.email_3 = rs.getString(3).trim();

			}
			
			if(rs.wasNull()) {
				reg.email_1 = "NO TIENE";
				reg.email_2 = "NO TIENE";
				reg.email_3 = "NO TIENE";
			}else {
				if(reg.email_1.trim().equals("") || reg.email_1 == null) {
					reg.email_1 = "NO TIENE";
				}
				if(reg.email_2.trim().equals("") || reg.email_2 == null) {
					reg.email_2 = "NO TIENE";
				}
				if(reg.email_2.trim().equals("") || reg.email_2 == null) {
					reg.email_2 = "NO TIENE";
				}
				
			}
			
			rs.close();
			st.close();
			
				
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return reg;
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
			"c.minist_repart " + 
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

	
	private static final String SEL_TELEFONOS = "SELECT tipo_te, " + 
			"cod_area_te, " + 
			"NVL(prefijo_te, ' '), " + 
			"numero_te, " + 
			"ppal_te " + 
			"FROM telefono " + 
			"WHERE cliente = ? "; 

	private static final String SEL_TELE_CERTA = "SELECT telefono_fijo, " + 
			"telefono_movil, " + 
			"telefono_secun, " + 
			"zona_tecnica " + 
			"FROM tele_certa " + 
			"WHERE numero_cleinte = ? "; 

}

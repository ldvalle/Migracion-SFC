package dao;

import conectBD.UConnection;
import entidades.DeviceDTO;
import servicios.DeviceSRV;


import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class DeviceDAO {
	
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
	
	public Boolean ProcesaDevices(int iTipoCorrida) {
		String sql = getCursorDevice(iTipoCorrida);
		DeviceSRV miSrv = new DeviceSRV();
		long iCant=0;
		
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;

		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);

			pstm0 = con.prepareStatement(sql, ResultSet.TYPE_SCROLL_INSENSITIVE , ResultSet.CONCUR_READ_ONLY, ResultSet.HOLD_CURSORS_OVER_COMMIT);
			pstm0.setQueryTimeout(120);
			pstm0.setFetchSize(1);
			rs0 = pstm0.executeQuery();
			while(rs0.next()) {
				DeviceDTO reg = new DeviceDTO();
				
				reg.numero = rs0.getLong(1);
				reg.marca = rs0.getString(2);
				reg.modelo = rs0.getString(3);
				reg.estado = rs0.getString(4);
				reg.med_ubic = rs0.getString(5);
				reg.med_codubic = rs0.getString(6);
				reg.numero_cliente = rs0.getLong(7);
				reg.tipo_medidor = rs0.getString(8);
				reg.fecha_prim_insta = rs0.getString(9);
				reg.fecha_ult_insta = rs0.getString(10);
				reg.constante = rs0.getDouble(11);
				reg.med_anio = rs0.getInt(12);
				
				reg.estado_sfc = miSrv.getEstadoSFC(reg.estado, reg.med_codubic);
				
				if(!miSrv.InformaDevice(reg)) {
					System.out.println(String.format("Fallo al informar medidor para cliente %d", reg.numero_cliente));
					return false;
				}
				
				iCant++;
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		System.out.println("Cant.Medidores informados: " + iCant);
		
		return true;
	}
	
	public Boolean setLstMedidores(String sNro, String sMarca, String sModelo) {
		long lNro = Long.parseLong(sNro);
		Connection con = null;
		PreparedStatement pstm = null;

		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			
			pstm = con.prepareStatement(SET_LST_MEDIDORES);
			pstm.setLong(1, lNro);
			pstm.setString(2, sMarca);
			pstm.setString(3, sModelo);
			pstm.executeUpdate();
			
			con.commit();
			
			pstm.close();
		}catch(Exception ex){
			System.out.println("Fallo grabación Medidor");
			try {
				con.rollback();
			}catch(SQLException exSQL) {
				exSQL.printStackTrace();
			}
			
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}		
		
		return true;
	}
	
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";
	
	private String getCursorDevice(int iTipoCorrida) {
		String	sql = "";
		
		sql = "SELECT me.med_numero, " + 
				"me.mar_codigo, " + 
				"me.mod_codigo, " + 
				"me.med_estado, " + 
				"me.med_ubic, " + 
				"me.med_codubic, " + 
				"me.numero_cliente, " + 
				"NVL(mo.tipo_medidor, 'A'), " + 
				"TO_CHAR(m.fecha_prim_insta, '%Y-%m-%d'), " + 
				"TO_CHAR(m.fecha_ult_insta, '%Y-%m-%d'), " + 
				"m.constante, " + 
				"me.med_anio " + 
				"FROM medid m, medidor me, modelo mo ";
		
		if(iTipoCorrida == 1) {
			sql += ", migra_sf ma ";
		}
		
		sql += "WHERE m.estado = 'I' " + 
				"AND me.med_numero = m.numero_medidor " + 
				"AND me.mar_codigo = m.marca_medidor " + 
				"AND me.mod_codigo = m.modelo_medidor " + 
				"AND me.med_tarifa = 'T1'  " + 
				"AND me.mar_codigo NOT IN ('000', 'AGE')  " + 
				"AND me.med_anio != 2019  " + 
				"AND mo.mar_codigo = me.mar_codigo  " + 
				"AND mo.mod_codigo = me.mod_codigo ";

		if(iTipoCorrida == 1) {
			sql += "AND ma.numero_cliente = m.numero_cliente ";
		}
		
		return sql;
	}
	
	private static final String SET_LST_MEDIDORES = "INSERT INTO sap_lst_medidores (" + 
			"numero_medidor, " +
			"marca_medidor," +
			"modelo_medidor " + 
			")VALUES(?, ?, ?)";
	
}

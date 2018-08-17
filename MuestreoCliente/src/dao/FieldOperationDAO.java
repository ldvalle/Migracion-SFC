package dao;

import conectBD.UConnection;
import entidades.DeviceDTO;
import entidades.FieldOperationDTO;
import servicios.DeviceSRV;
import servicios.FieldOperationSRV;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class FieldOperationDAO {

	public String getRuta(String sCodigo) {
		String sRuta="";
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SQL_SEL_RUTA_FILES);
			st.setString(1, sRuta);
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
	
	public Boolean procesaCorte(int iTipoCorrida) {
		
		String sql = getCurCorte(iTipoCorrida);
		FieldOperationSRV miSrv = new FieldOperationSRV();
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
				FieldOperationDTO reg = new FieldOperationDTO();
				
			    reg.numero_cliente = rs0.getLong(1);
			    reg.fecha_corte = rs0.getString(2);
			    if(rs0.getString(3) != null)
			    	reg.fecha_reposicion = rs0.getString(3);
			    reg.saldo_exigible = rs0.getDouble(4);
			    reg.motivo_corte = rs0.getString(5);
			    if(rs0.getString(6) != null)
			    	reg.motivo_repo = rs0.getString(6);
			    reg.accion_corte = rs0.getString(7);
			    if(rs0.getString(8) != null)
			    	reg.accion_rehab = rs0.getString(8);
			    reg.funcionario_corte= rs0.getString(9);
			    if(rs0.getString(10) != null)
			    	reg.funcionario_repo = rs0.getString(10); 
			    reg.fecha_ini_evento = rs0.getString(11);
			    if(rs0.getString(12) != null)
			    	reg.fecha_sol_repo = rs0.getString(12);
			    reg.sit_encon = rs0.getString(13);
			    if(rs0.getString(14) != null)
			    	reg.sit_rehab = rs0.getString(14);
			    reg.desc_motivo_corte= rs0.getString(15);

				
				if(!miSrv.InformaEvento(reg, "C")) {
					System.out.println(String.format("Fallo al informar CORTE para cliente %d", reg.numero_cliente));
					return false;
				}
				
				if(reg.fecha_reposicion != null) {
					if(!miSrv.InformaEvento(reg, "R")) {
						System.out.println(String.format("Fallo al informar REPOSICION para cliente %d", reg.numero_cliente));
						return false;
					}
				}
				
				iCant++;
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		System.out.println("Cant.Cortes informados: " + iCant);
		
		return true;
	}
	
	
	public Boolean procesaExtend(int iTipoCorrida) {
		String sql = getCurExtend(iTipoCorrida);
		FieldOperationSRV miSrv = new FieldOperationSRV();
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
				FieldOperationDTO reg = new FieldOperationDTO();
				
			    reg.numero_cliente = rs0.getLong(1);
			    reg.ext_fecha_solicitud = rs0.getString(2);
			    reg.ext_cod_motivo = rs0.getString(3);
			    reg.ext_motivo = rs0.getString(4);
			    reg.ext_rol = rs0.getString(5);
			    reg.ext_estado = rs0.getString(6);
			    reg.ext_dias = rs0.getInt(7);
				
				if(!miSrv.InformaEvento(reg, "E")) {
					System.out.println(String.format("Fallo al informar EXTENSIÓN para cliente %d", reg.numero_cliente));
					return false;
				}
				
				iCant++;
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		System.out.println("Cant.Extensiones informados: " + iCant);
		
		return true;
	}
	
	private String getCurCorte(int iTipoCorrida) {
		String sql ="";
		
			sql = "SELECT c.numero_cliente, " + 
					"TO_CHAR(c.fecha_corte, '%Y-%m-%dT%H:%M:00.000Z'), " + 
					"TO_CHAR(c.fecha_reposicion, '%Y-%m-%dT%H:%M:00.000Z'), " + 
					"c.saldo_exigible, " + 
					"c.motivo_corte, " + 
					"c.motivo_repo, " + 
					"c.accion_corte, " + 
					"c.accion_rehab, " + 
					"c.funcionario_corte, " + 
					"c.funcionario_repo, " + 
					"TO_CHAR(c.fecha_ini_evento, '%Y-%m-%dT%H:%M:00.000Z'), " + 
					"TO_CHAR(c.fecha_sol_repo, '%Y-%m-%dT%H:%M:00.000Z'), " + 
					"c.sit_encon, " + 
					"c.sit_rehab, " + 
					"t1.descripcion " + 
					"FROM cliente cl, correp c, tabla t1 ";

			if(iTipoCorrida==1) {
				sql += " , migra_sf ma ";
			}
			
			sql += "WHERE cl.estado_cliente = 0 " + 
					"AND cl.tipo_sum != 5 " + 
					"AND c.numero_cliente = cl.numero_cliente " + 
					"AND c.fecha_corte >= TODAY-365 " + 
					"AND t1.nomtabla = 'CORMOT' " + 
					"AND t1.sucursal = '0000' " + 
					"AND t1.codigo = c.motivo_corte " + 
					"AND t1.fecha_activacion <= TODAY " + 
					"AND (t1.fecha_desactivac IS NULL OR t1.fecha_desactivac > TODAY) ";
					
			if(iTipoCorrida==1) {
				sql += " AND ma.numero_cliente = cl.numero_cliente ";
			}
			
			sql += "ORDER BY 2 ASC";
		
		return sql;
	}
	
	private String getCurExtend(int iTipoCorrida) {
		String sql="";
		
			sql = "SELECT c.numero_cliente, " + 
					"TO_CHAR(c.fecha_solicitud, '%Y-%m-%dT%H:%M:00.000Z'), " + 
					"c.cod_motivo, " + 
					"c.motivo, " + 
					"c.rol, " + 
					"CASE " + 
					"	WHEN c.fecha_anterior + c.dias > TODAY THEN 'Active' " + 
					"  ELSE 'Completed' " + 
					"END estado, " + 
					"c.dias " + 
					"FROM cliente cl, corplazo c ";
					
			if(iTipoCorrida==1) {
				sql += " , migra_sf ma ";
			}
					
			sql += "WHERE cl.estado_cliente = 0 " + 
					"AND cl.tipo_sum != 5 " + 
					"AND c.numero_cliente = cl.numero_cliente " + 
					"AND c.fecha_solicitud >= TODAY-365 ";

			if(iTipoCorrida==1) {
				sql += " AND ma.numero_cliente = cl.numero_cliente ";
			}
			
			sql += "ORDER BY 2 ASC";
					
		return sql;
	}
	
	
	
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";
	
}

package dao;

import conectBD.UConnection;
import entidades.CnrDTO;
import servicios.CnrSRV;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
//import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class cnrDAO {

	
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

	public Boolean procesaCNR(int iTipoCorrida) {
		String sql = getCursorCNR(iTipoCorrida);
		CnrSRV miSrv = new CnrSRV();
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
				CnrDTO reg = new CnrDTO();
				
				reg.sucursal = rs0.getString(1);
				reg.nro_expediente = rs0.getLong(2);
				reg.ano_expediente = rs0.getInt(3);
				reg.fecha_deteccion = rs0.getString(4);
				reg.fecha_inicio = rs0.getString(5);
				reg.fecha_finalizacion = rs0.getString(6);
				reg.numero_cliente = rs0.getLong(7);
				reg.nro_solicitud = rs0.getLong(8);
				reg.cod_estado = rs0.getString(9);
				reg.descripcion = rs0.getString(10).trim();
			   
				//-- Ver si existen calculos
			   PreparedStatement ps = con.prepareStatement(SEL_PERI_CALCU);
			   ps.setString(1, reg.sucursal);
			   ps.setInt(2, reg.ano_expediente);
			   ps.setLong(3, reg.nro_expediente);
			   
			   ResultSet rs = ps.executeQuery();
			   if(rs.next()) {
				   reg.sFechaDesdePeriCalcu = rs.getString(1);
				   reg.sFechaHastaPeriCalcu = rs.getString(2);
			   }
			   ps.close();
			   rs.close();
			  
			   //-- Cargar Datos Medidor
			   if(reg.numero_cliente>0) {
				   ps = con.prepareStatement(SEL_MEDIDOR);
				   ps.setLong(1, reg.numero_cliente);
				   
				   rs = ps.executeQuery();
				   if(rs.next()) {
					   reg.marca_medidor = rs.getString(1);
					   reg.modelo_medidor = rs.getString(2);
					   reg.numero_medidor = rs.getLong(3);
				   }
			   }else {
				   
				   if(reg.nro_solicitud > 0) {
					   ps = con.prepareStatement(SEL_SOLICITUD);
					   ps.setLong(1, reg.nro_solicitud);
					   
					   rs = ps.executeQuery();
					   if(rs.next()) {
						   reg.numero_cliente = rs.getLong(1);
					   }
					   ps.close();
					   rs.close();
					   if(reg.numero_cliente>0) {
						   ps = con.prepareStatement(SEL_MEDIDOR);
						   ps.setLong(1, reg.numero_cliente);
						   
						   rs = ps.executeQuery();
						   if(rs.next()) {
							   reg.marca_medidor = rs.getString(1);
							   reg.modelo_medidor = rs.getString(2);
							   reg.numero_medidor = rs.getLong(3);
						   }
					   }
				   }	   
			   }
			   ps.close();
			   rs.close();
			   iCant++;
			   //Informamos el CNR
			   if(!miSrv.InformaCnr(reg)) {
				   System.out.println("Fallo informar CNR para Cliente " + reg.numero_cliente + " Suc." + reg.sucursal + " año expe." + reg.ano_expediente + " Nro Expe." + reg.nro_expediente);
				   return false;
			   }
			}
			rs0.close();
			pstm0.close();
			
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		System.out.println("Cant.CNR informados: " + iCant);
		return true;
	}
	
	
	
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getCursorCNR(int iTipoCorrida) {
		String sql="";
		
		sql = "SELECT c.sucursal, " + 
				"c.nro_expediente, " + 
				"c.ano_expediente, " + 
				"TO_CHAR(c.fecha_deteccion, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
				"TO_CHAR(c.fecha_inicio, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
				"TO_CHAR(c.fecha_finalizacion, '%Y-%m-%dT%H:%M:%S.000Z'),  " + 
				"c.numero_cliente, " + 
				"c.nro_solicitud, " + 
				"c.cod_estado, " + 
				"t1.descripcion " + 
				"FROM cnr_new c, tabla t1 ";
		
		if(iTipoCorrida == 1) {
			sql += ", migra_sf ma ";
		}
		
		sql += "WHERE c.fecha_inicio >= TODAY - 365 " + 
				"AND c.cod_estado != '99' " + 
				"AND t1.nomtabla = 'CNRRE' " + 
				"AND t1.sucursal = '0000' " + 
				"AND t1.codigo = c.cod_estado " + 
				"AND t1.fecha_activacion <= TODAY " + 
				"AND (t1.fecha_desactivac IS NULL OR t1.fecha_desactivac >TODAY) "; 

		if(iTipoCorrida == 1) {
			sql += "AND ma.numero_cliente = c.numero_cliente ";
		}
	
		return sql;
	}

	private static final String SEL_PERI_CALCU = "SELECT FIRST 1 TO_CHAR(fecha_desde, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
			"TO_CHAR(fecha_hasta, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
			"total_calculo, " + 
			"MAX(fecha_calculo) " + 
			"FROM cnr_calculo  " + 
			"WHERE sucursal = ? " + 
			"AND ano_expediente = ? " + 
			"AND nro_expediente = ? " + 
			"GROUP BY 1,2,3 " + 
			"ORDER BY 1,2,3";

	private static final String SEL_MEDIDOR = "SELECT marca_medidor, " + 
			"modelo_medidor, " + 
			"numero_medidor " + 
			"FROM medid " + 
			"WHERE numero_cliente = ? " + 
			"AND estado = 'I' "; 
			
	private static final String SEL_SOLICITUD = "SELECT numero_cliente FROM solicitud WHERE nro_solicitud = ? ";
	
}



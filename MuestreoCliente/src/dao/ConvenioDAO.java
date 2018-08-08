package dao;

import conectBD.UConnection;
import entidades.ConvenioDTO;
import servicios.ConvenioSRV;

//import servicios.ConvenioSRV;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
//import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class ConvenioDAO {

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

	public Boolean procesaConve(int iTipoCorrida) {
		String sql = getCursorClientes(iTipoCorrida);
		ConvenioSRV miSrv = new ConvenioSRV();
		long iCant=0;
		long	lNroCliente;
		
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
				lNroCliente=rs0.getLong(1);
				
				PreparedStatement ps = con.prepareStatement(SEL_CONVENIOS);
				ps.setLong(1, lNroCliente);
			   
				ResultSet rs = ps.executeQuery();
				while(rs.next()) {
					ConvenioDTO reg = new ConvenioDTO();
					
					reg.numero_cliente=rs.getLong(1);
					reg.corr_convenio=rs.getInt(2);
					reg.opcion_convenio=rs.getString(3);
					reg.estado=rs.getString(4);
					reg.fecha_creacion=rs.getString(5);
					reg.fecha_termino=rs.getString(6);
					reg.deuda_origen=rs.getDouble(7);
					reg.valor_cuota_ini=rs.getDouble(8);
					reg.deuda_convenida=rs.getDouble(9);
					reg.valor_cuota=rs.getDouble(10);
					reg.numero_tot_cuotas=rs.getInt(11);
					reg.numero_ult_cuota=rs.getInt(12);
					reg.intereses=rs.getDouble(13);
					reg.usuario_creacion=rs.getString(14);
					reg.usuario_termino=rs.getString(15);

					if(!miSrv.InformaConve(reg)) {
					   System.out.println("Fallo informar Convenio para Cliente " + reg.numero_cliente + " Corr. Convenio" + reg.corr_convenio);
					   return false;
					}
					
					iCant++;
				}
				ps.close();
				rs.close();
				
				
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		System.out.println("Cant.Convenios informados: " + iCant);
		
		return true;
	}
	
	
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getCursorClientes(int iTipoCorrida) {
		String sql="SELECT c.numero_cliente FROM cliente c ";
		
		if(iTipoCorrida==1) {
			sql += ", migra_sf ma ";
		}
		
		sql += "WHERE c.estado_cliente = 0 " + 
				"AND c.tipo_sum != 5 " + 
				"AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm " + 
				"WHERE cm.numero_cliente = c.numero_cliente " + 
				"AND cm.fecha_activacion < TODAY " + 
				"AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY)) ";
		
		if(iTipoCorrida==1) {
			sql += "AND ma.numero_cliente = c.numero_cliente ";
		}
		
		
		return sql;
	}
	
	private static final String SEL_CONVENIOS = "SELECT numero_cliente, " + 
			"corr_convenio, " + 
			"opcion_convenio, " + 
			"estado, " + 
			"TO_CHAR(fecha_creacion, '%Y-%m-%d'), " + 
			"TO_CHAR(fecha_termino, '%Y-%m-%d'), " + 
			"deuda_origen, " + 
			"valor_cuota_ini, " + 
			"deuda_convenida, " + 
			"valor_cuota, " + 
			"numero_tot_cuotas, " + 
			"numero_ult_cuota, " + 
			"intereses, " + 
			"usuario_creacion,  " + 
			"usuario_termino " + 
			"FROM conve " + 
			"WHERE numero_cliente = ? " + 
			"AND estado = 'V' " + 
			"ORDER BY corr_convenio ASC";
}

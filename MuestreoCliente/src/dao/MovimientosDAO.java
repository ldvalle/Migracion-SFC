package dao;

import conectBD.UConnection;
import entidades.MovimientosDTO;
import servicios.MovimientosSRV;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class MovimientosDAO {

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
	
	public Boolean ProcesoPpal(int iTipoCorrida) {
		long lCantClientes=0;
		long lNroCliente=0;
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		MovimientosSRV miSrv = new MovimientosSRV();
		
		String sql = getCursorClientes(iTipoCorrida);

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
				
				if(!miSrv.ProcesaCliente(lNroCliente)) {
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

	public Collection<MovimientosDTO>getPagos(long lNroCliente){
		Vector<MovimientosDTO>miLista = new Vector<MovimientosDTO>();
		MovimientosDTO miReg = null;
		Connection con = null;
		PreparedStatement st=null;
		ResultSet rs = null;
		int iter=1;
	
		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
			st = con.prepareStatement(SEL_PAGO, ResultSet.TYPE_SCROLL_INSENSITIVE , ResultSet.CONCUR_READ_ONLY, ResultSet.HOLD_CURSORS_OVER_COMMIT);
			st.setQueryTimeout(120);
			st.setFetchSize(1);
			st.setLong(1, lNroCliente);
			rs = st.executeQuery();

			while(rs.next()){
				miReg = new MovimientosDTO();

				miReg.numero_cliente = rs.getLong(1);
				miReg.corr_pagos = rs.getInt(2);
				miReg.llave = rs.getLong(3);
				miReg.fecha_pago = rs.getString(4);
				miReg.fecha_actualiza = rs.getString(5);
				miReg.tipo_pago = rs.getString(6);
				miReg.descripcion = rs.getString(7);
				miReg.cajero = rs.getString(8);
				miReg.oficina = rs.getString(9);
				miReg.sucursal = rs.getString(10);
				miReg.valor_pago = rs.getDouble(11);
				miReg.centro_emisor = rs.getString(12);
				miReg.tipo_docto = rs.getString(13);
				miReg.nro_docto_asociado = rs.getLong(14);
				miReg.tipo_mov = rs.getString(15);
				
				
				//Si tiene Factura Digital
				miReg.nombre_cajero = getNombreCajero(miReg);
				
				
				miLista.add(miReg);
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			System.out.println("Fallo getPagos() para cliente " + lNroCliente );
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return miLista;
	}
	
	private String getNombreCajero(MovimientosDTO reg) {
		String sNombre="";
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;
		
		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_CAJERO);
			st.setString(1, reg.sucursal);
			st.setString(2, reg.cajero);

			rs=st.executeQuery();
			if(rs.next()) {
				sNombre = rs.getString(1);
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return sNombre.trim();
	}
	
	
	private static final String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getCursorClientes(int iTipoCorrida) {
		String sql = "SELECT c.numero_cliente FROM cliente c ";
		
		if(iTipoCorrida == 1)
			sql += ", migra_sf ma ";
		
		sql += "WHERE c.estado_cliente = 0 " + 
				"AND c.tipo_sum != 5 " + 
				"AND c.tipo_sum NOT IN (5, 6) " + 
				"AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm " + 
				"WHERE cm.numero_cliente = c.numero_cliente " + 
				"AND cm.fecha_activacion < TODAY " + 
				"AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY))";

		if(iTipoCorrida == 1)
			sql += " AND ma.numero_cliente = c.numero_cliente ";
		
		return sql;
	}
	
	private static final String SEL_PAGO = "SELECT h.numero_cliente, " + 
			"h.corr_pagos, " + 
			"h.llave, " + 
			"TO_CHAR(h.fecha_pago, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
			"TO_CHAR(h.fecha_actualiza, '%Y-%m-%dT%H:%M:%S.000Z'), " + 
			"h.tipo_pago, " + 
			"c1.descripcion, " + 
			"h.cajero,  " + 
			"h.oficina, " + 
			"h.sucursal, " + 
			"h.valor_pago, " + 
			"h.centro_emisor, " + 
			"h.tipo_docto, " + 
			"h.nro_docto_asociado, " + 
			"c1.tipo_mov " + 
			"FROM hispa h, conce c1 " + 
			"WHERE h.numero_cliente = ?  " + 
			"AND h.fecha_pago >= TODAY - 420 " + 
			"AND c1.codigo_concepto = h.tipo_pago " + 
			"ORDER BY h.corr_pagos ASC ";
	
	private static final String SEL_CAJERO = "SELECT FIRST 1 nombre FROM ccb@pagos_test:cajer " + 
			"WHERE sucursal = ? " + 
			"AND cajero = ? ";
	
}

package dao;

import conectBD.UConnection;
import entidades.InvoiceDTO;
import servicios.InvoiceSRV;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class InvoiceDAO {

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

	public Boolean ProcesoPpal(int iTipoCorrida) {
		long lCantClientes=0;
		long lNroCliente=0;
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		InvoiceSRV miSrv = new InvoiceSRV();
		
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
	
	public Collection<InvoiceDTO>getFacturas(long lNroCliente){
		Vector<InvoiceDTO>miLista = new Vector<InvoiceDTO>();
		InvoiceDTO miReg = null;
		InvoiceDTO miRegRectif=null;
		InvoiceDTO miDeta=null;
		Connection con = null;
		PreparedStatement st=null;
		ResultSet rs = null;
		int iter=1;
		Double dRecargoAnterior= 0.00;
	
		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
			st = con.prepareStatement(SEL_HISFAC, ResultSet.TYPE_SCROLL_INSENSITIVE , ResultSet.CONCUR_READ_ONLY, ResultSet.HOLD_CURSORS_OVER_COMMIT);
			st.setQueryTimeout(120);
			st.setFetchSize(1);
			st.setLong(1, lNroCliente);
			rs = st.executeQuery();

			while(rs.next()){
				miReg = new InvoiceDTO();
				
				miReg.numero_cliente = rs.getLong(1);
				miReg.corr_facturacion = rs.getInt(2);
				miReg.fecha_facturacion = rs.getString(3);
				miReg.fecha_vencimiento1 = rs.getString(4);
				miReg.fecha_vencimiento2 = rs.getString(5);
				miReg.suma_intereses = rs.getDouble(6);
				miReg.suma_cargos_man = rs.getDouble(7);
				miReg.saldo_anterior = rs.getDouble(8);
				miReg.suma_impuestos = rs.getDouble(9);
				miReg.id_factura = rs.getString(10);
				miReg.numero_factura = rs.getLong(11);
				miReg.total_a_pagar = rs.getDouble(12);
				miReg.coseno_phi = rs.getDouble(13);
				miReg.suma_recargo = rs.getDouble(14);
				miReg.suma_convenio = rs.getDouble(15);
				miReg.tarifa = rs.getString(16);
				miReg.indica_refact = rs.getString(17);
				miReg.dFechaFacturacion = rs.getDate(18);
				
				if(miReg.indica_refact.compareTo("S")==0) {
					//Debo buscar la refacturada
					miRegRectif = new InvoiceDTO();
					miRegRectif = getHisfacRectif(miReg);
					if(miRegRectif!=null) {
						miReg.total_a_pagar = miRegRectif.total_a_pagar;
						miReg.suma_impuestos = miRegRectif.suma_impuestos;
						if(miRegRectif.coseno_phi != null)
							miReg.coseno_phi = miRegRectif.coseno_phi;
					}
				}
				//Detalle refacturado
				miDeta = getDetaFactu(miReg);
				
				miReg.cargo_fijo = miDeta.cargo_fijo;
				miReg.cargo_variable = miDeta.cargo_variable;
				miReg.cargo_tap = miDeta.cargo_tap;
				miReg.cargo_kit = miDeta.cargo_kit;
				
				//Si tiene Factura Digital
				miReg.factu_digital = getFactuDigital(miReg);
				
				if(iter==1) {
					miReg.recargoAnterior=0.00;
					dRecargoAnterior=miReg.suma_recargo;
				}else {
					miReg.recargoAnterior=dRecargoAnterior;
					dRecargoAnterior=miReg.suma_recargo;
				}
				
				miLista.add(miReg);
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			System.out.println("Fallo getFacturas() para cliente " + lNroCliente + " Correlativo facturacion " + miReg.corr_facturacion);
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return miLista;
	}
	
	private InvoiceDTO getHisfacRectif(InvoiceDTO reg1) {
		InvoiceDTO reg2 = new InvoiceDTO();
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_HISFAC_RECTIF);
			st.setLong(1, reg1.numero_cliente);
			st.setDate(2, (java.sql.Date) reg1.dFechaFacturacion);
			st.setLong(3, reg1.numero_factura);
			
			rs=st.executeQuery();
			if(rs.next()) {
				reg2.total_a_pagar = rs.getDouble(1);
				reg2.suma_impuestos = rs.getDouble(3);
				reg2.coseno_phi = rs.getDouble(3);
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return reg2;
	}
	
	
	private InvoiceDTO getDetaFactu(InvoiceDTO reg1) {
		InvoiceDTO reg2 = new InvoiceDTO();
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;
		String sql="";
		String sCodCargo="";
		Double dValorCargo=0.00;
		
		reg2.cargo_fijo=0.00;
		reg2.cargo_variable=0.00;
		reg2.cargo_tap=0.00;
		reg2.cargo_kit=0.00;
				
		if(reg1.indica_refact.equals("S")) {
			sql = getCurDetalle(1);
		}else {
			sql = getCurDetalle(0);
		}
		
		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(sql);
			st.setLong(1, reg1.numero_cliente);
			st.setInt(2, reg1.corr_facturacion);
			rs=st.executeQuery();
			while(rs.next()) {
				sCodCargo = rs.getString(1);
				dValorCargo = rs.getDouble(2);
				
				if(sCodCargo.equals("020")) {
					reg2.cargo_fijo = rs.getDouble(1);
				}else if(sCodCargo.equals("030")) {
					reg2.cargo_variable = rs.getDouble(1);
				}else if(sCodCargo.equals("580")) {
					reg2.cargo_tap += rs.getDouble(1);
				}else if(sCodCargo.equals("581")) {
					reg2.cargo_tap += rs.getDouble(1);
				}else if(sCodCargo.equals("886")) {
					reg2.cargo_tap += rs.getDouble(1);
				}else if(sCodCargo.equals("887")) {
					reg2.cargo_tap += rs.getDouble(1);
				}else if(sCodCargo.equals("952")) {
					reg2.cargo_kit = rs.getDouble(1);
				}
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return reg2;
	}
	
	private String getFactuDigital(InvoiceDTO reg) {
		String sDigital="N";
		int	iValor=0;
		String sFechaDesde="";
		String sFechaHasta="";
		SimpleDateFormat fmtDate= new SimpleDateFormat("yyyy-MM-dd");
		Connection con = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		sFechaDesde = fmtDate.format(reg.dFechaFacturacion) + " 00:00:00";
		sFechaHasta = fmtDate.format(reg.dFechaFacturacion) + " 23:59:59";
		
		try {
			con = UConnection.getConnection();
			st = con.prepareStatement(SEL_DIGITAL);
			st.setLong(1, reg.numero_cliente);
			st.setString(2, sFechaDesde);
			st.setString(3, sFechaHasta);

			rs=st.executeQuery();
			if(rs.next()) {
				iValor = rs.getInt(1);
				if(iValor > 0)
					sDigital = "S";
			}
			rs.close();
			st.close();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return sDigital;
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

	private static final String SEL_HISFAC = "SELECT h.numero_cliente, " + 
			"h.corr_facturacion, " + 
			"TO_CHAR(h.fecha_facturacion, '%Y-%m-%d'), " + 
			"TO_CHAR(h.fecha_vencimiento1, '%Y-%m-%d'), " + 
			"TO_CHAR(NVL(h.fecha_vencimiento2, h.fecha_vencimiento1), '%Y-%m-%d'), " + 
			"h.suma_intereses, " + 
			"h.suma_cargos_man, " + 
			"h.saldo_anterior, " + 
			"h.suma_impuestos, " + 
			"h.centro_emisor || h.tipo_docto || h.numero_factura, " + 
			"h.numero_factura, " + 
			"h.total_a_pagar, " + 
			"h.coseno_phi /100, " + 
			"h.suma_recargo, " + 
			"h.suma_convenio, " + 
			"h.tarifa, " + 
			"h.indica_refact, " +
			"h.fecha_facturacion " +
			"FROM hisfac h " + 
			"WHERE h.numero_cliente = ? " + 
			"AND h.fecha_facturacion >= TODAY - 420 " + 
			"ORDER BY h.corr_facturacion ASC";
	
	private static final String SEL_HISFAC_RECTIF ="SELECT r.total_refacturado," + 
			"r.total_impuestos, " + 
			"r.coseno_phi/100 " + 
			"FROM refac r " + 
			"WHERE r.numero_cliente = ? " + 
			"AND r.fecha_fact_afect = ? " + 
			"AND r.nro_docto_afect = ? " + 
			"AND r.corr_refacturacion = (SELECT MAX(r2.corr_refacturacion) FROM refac r2 " + 
			"	WHERE r2.numero_cliente = r.numero_cliente " + 
			"	AND r2.fecha_fact_afect = r.fecha_fact_afect " + 
			"	AND r2.nro_docto_afect = r.nro_docto_afect)";
	
	private String getCurDetalle(int iRectif) {
		String sql ="SELECT codigo_cargo, SUM(valor_cargo) ";
		
		if(iRectif == 0) {
			sql += "FROM carfac ";
		}else {
			sql += "FROM carfac_aux ";
		}
		
		sql += "WHERE numero_cliente = ? " + 
				"AND corr_facturacion = ? " + 
				"AND codigo_cargo IN ('020', '030', '580', '581', '886', '887', '952') " + 
				"GROUP BY 1";
				
		return sql;
	}
	
	private static final String SEL_DIGITAL = "SELECT COUNT(*) " + 
			"FROM clientes_digital " + 
			"WHERE numero_cliente = ? " + 
			"AND fecha_alta < ? " + 
			"AND (fecha_baja IS NULL OR fecha_baja > ? ) ";
	
}

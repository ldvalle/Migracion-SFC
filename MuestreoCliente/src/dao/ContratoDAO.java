package dao;

import conectBD.UConnection;
import entidades.sfcClienteDTO;
import entidades.ContratoDTO;
import entidades.MeasuresDTO;
import servicios.MeasuresSRV;
import servicios.sfcContrato;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
//import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class ContratoDAO {

	public Boolean ProcesaContrato(int iEstadoCliente, int iTipoCorrida, int iTipoArchivo) {
		long lCantClientes=0;
		long lNroCliente=0;
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		sfcContrato miSrv = new sfcContrato();
		
		String sql = getCursorClientes(iEstadoCliente, iTipoCorrida);
		
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

				if(!miSrv.ProcesaCliente(lNroCliente, iTipoArchivo)) {
					System.out.println("No se proceso cliente " + lNroCliente);
				}
		
				lCantClientes++;
			}
			System.out.println("CONTRATO - Proceso Terminado OK.");
			System.out.println("Clientes Procesados " + lCantClientes);
			
		}catch(Exception ex){
			System.out.println("revento en la vuelta " + lCantClientes + " Ultimo Cliente " + lNroCliente);
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				if(rs0 != null) rs0.close();
				if(pstm0 != null) pstm0.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		return true;
	}
	
	public ContratoDTO getCliente(long nroCliente) {
		ContratoDTO miReg =null;
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = getSelCliente(nroCliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				miReg = new ContratoDTO();

				miReg.numero_cliente = rs.getLong(1);
				miReg.corr_facturacion = rs.getInt(2);
				miReg.nombre = rs.getString(3);
				miReg.tipo_fpago = rs.getString(4);
				miReg.tipo_reparto = rs.getString(5);
				miReg.nro_beneficiario = rs.getLong(6);
				miReg.codActividadEconomica = rs.getString(7);
				miReg.tipo_titularidad = rs.getString(8);
				miReg.minist_repart = rs.getLong(9);
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return miReg;
	}

	public String getPartidaMuni(long nroCliente) {
		String sPartida="";
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = selPartidaMuni(nroCliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				sPartida = rs.getString(1);
			}else {
				sPartida = "FALSE";
			}

		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return sPartida;
	}
	
	public String getCorpoT23(long nroCliente) {
		String sCodCorpo="";
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = selCorpoT23(nroCliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				sCodCorpo = rs.getString(1);
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return sCodCorpo;
	}

	public ContratoDTO getFormaPago(long nroCliente) {
		ContratoDTO reg = null;
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";
		String sCBU="";

		sql = selFormaPago(nroCliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			
			if(rs.next()){
				reg = new ContratoDTO();
				reg.fp_banco = rs.getString(1).trim();
				reg.fp_nrocuenta = rs.getString(2).trim();
				if(rs.getString(3) == null) {
					reg.fp_cbu = "";
				}else{
					reg.fp_cbu = rs.getString(3).trim();
				}
				reg.fp_tipo = rs.getString(4).trim();
				
			}
			rs=null;
			st=null;
			reg.codBanco = reg.fp_banco;
			if(reg.fp_cbu.equals("")) {
				//Es Tarjeta
				reg.fp_nroTarjeta = reg.fp_nrocuenta;

				sql = selCodSapTarjeta(reg.fp_banco);
				st = con.createStatement();
				rs=st.executeQuery(sql);
				
				if(rs.next()) {
					reg.codTarjetaCredito = rs.getString(1);
					reg.sNombreBanco = rs.getString(2);
					reg.sMarcaTarjeta = rs.getString(3);
				}
			}else {
				//Es Debito
				reg.fp_nroTarjeta = reg.fp_nrocuenta;
				reg.cbu = reg.fp_cbu;
				reg.codBanco = reg.fp_banco;
				
				sql = selEntiDebito(reg.fp_banco);
				st = con.createStatement();
				rs=st.executeQuery(sql);
				
				if(rs.next()) {
					reg.sNombreBanco = rs.getString(1);
				}
				
			}

		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return reg;
	}
	
	public String getPathFile(String sCodigo) {
		Connection con = null;
		PreparedStatement pstm = null;
		ResultSet rs = null;
		String sRuta="";

		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(SQL_SEL_RUTA_FILES);
			pstm.setString(1, sCodigo);
			
			pstm.setQueryTimeout(120);
			rs = pstm.executeQuery();
			
			if(rs.next()){
				sRuta = rs.getString(1);
			}
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(pstm != null) pstm=null;
				rs.close();
				pstm.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		
		return sRuta;
	}


	public String getFechaAlta(ContratoDTO reg) {
		String sFechaAlta="";
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = selFechaEstoc(reg.numero_cliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				sFechaAlta = rs.getString(1);
			}else {
				rs=null;
				st=null;

				if(reg.nro_beneficiario>0) {
					sql = selRetiroMedidor(reg.nro_beneficiario);

					st = con.createStatement();
					rs=st.executeQuery(sql);
					if(rs.next()){
						sFechaAlta = rs.getString(1);
					}else {
						sFechaAlta = "1995-09-24";
					}
				}else {
					sql = selFechaInstal(reg.numero_cliente);

					st = con.createStatement();
					rs=st.executeQuery(sql);
					if(rs.next()){
						sFechaAlta = rs.getString(1);
					}else {
						sFechaAlta = "1995-09-24";
					}
					
				}
			}
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return sFechaAlta;
	}

	public String getFactuDigital(long lNroCliente) {
		String sFechaAlta="";
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = selFactuDigital(lNroCliente);

		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				sFechaAlta = rs.getString(1);
			}else {
				sFechaAlta="NOTIENE";
			}

		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				//if(rs != null) rs=null;
				//if(st != null) st=null;
				rs.close();
				st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
			
		return sFechaAlta;
	}

	private static String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
			"FROM tabla "+
			"WHERE nomtabla = 'PATH' "+
			"AND codigo = ? "+
			"AND sucursal = '0000' "+
			"AND fecha_activacion <= TODAY "+
			"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getCursorClientes (int estado, int iTipoCorrida) {
		String sql="";
		
		sql = "SELECT c.numero_cliente " + 
  			"FROM cliente c ";
		
		if(iTipoCorrida==1) {
			sql += ", migra_sf ma ";
		}
		
		if(estado==0) {
			sql += "WHERE c.estado_cliente = 0 ";
		}else {
			sql += "WHERE c.estado_cliente != 0 ";
		}
		 
		sql += "AND c.tipo_sum != 5 " + 
				"AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm " + 
				"WHERE cm.numero_cliente = c.numero_cliente " + 
				"AND cm.fecha_activacion < TODAY " + 
				"AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY)) "; 
				
		if(iTipoCorrida==1) {
			sql += "AND ma.numero_cliente = c.numero_cliente ";
		}
		
		return sql;
	}
	
	private  String getSelCliente(long lNroCliente) {
		String sql="";
		
		sql = "SELECT c.numero_cliente, " + 
				"c.corr_facturacion, " + 
				"TRIM(c.nombre), " + 
				"c.tipo_fpago, " + 
				"s1.cod_sf1,, " + 
				"c.nro_beneficiario, " + 
				"TRIM(t1.cod_sap) || '-' || trim(t1.descripcion), " + 
				"t2.descripcion, " + 
				"c.minist_repart " + 
				"FROM cliente c, OUTER sap_transforma t1, OUTER tabla t2, sf_transforma s1 " + 
				"WHERE c.numero_cliente = " + lNroCliente + " " + 
				"AND t1.clave = 'BU_TYPE' " + 
				"AND t1.cod_mac = c.actividad_economic " + 
				"AND t2.nomtabla = 'CNRTU' " + 
				"AND t2.sucursal = '0000' " + 
				"AND t2.codigo = c.cod_propiedad " + 
				"AND t2.fecha_activacion <= TODAY " + 
				"AND (t2.fecha_desactivac IS NULL OR t2.fecha_desactivac > TODAY) " +
				"AND s1.clave = 'TIPREPARTO' " +
				"AND s1.cod_mac = c.tipo_reparto ";
		
		
		return sql;
	}
	
	private String selCorpoT23(long lNroCliente) {
		String sql="SELECT cod_corpo_padre FROM mg_corpor_t23 " + 
				"WHERE numero_cliente = " + lNroCliente + " ";
		
		return sql;
	}

	private String selFormaPago(long lNroCliente) {
		String sql = "SELECT f.fp_banco, f.fp_nrocuenta, f.fp_cbu, e.tipo " + 
				"FROM forma_pago f, entidades_debito e " + 
				"WHERE f.numero_cliente = " + lNroCliente + " " + 
				"AND f.fecha_activacion <= TODAY " + 
				"AND (f.fecha_desactivac IS NULL OR f.fecha_desactivac > TODAY) " + 
				"AND e.oficina = f.fp_banco " + 
				"AND e.fecha_activacion <= TODAY " + 
				"AND (e.fecha_desactivac IS NULL OR e.fecha_desactivac > TODAY) "; 
		
		return sql;
	}
	
	private String selCodSapTarjeta(String codMac) {
		String sql = "SELECT cod_sap, trim(descripcion), trim(acronimo_sap) " + 
				"FROM sap_transforma " + 
				"WHERE clave = 'CARDTYPE' " + 
				"AND cod_mac =  '" + codMac.trim() + "' ";
		
		return sql;
	}
	
	private String selEntiDebito(String codBanco) {
		String sql = "SELECT TRIM(nombre) FROM oficinas " + 
				"WHERE sucursal = '0000' " + 
				"AND oficina = '" + codBanco.trim() + "' "; 

		return sql;
	}
	
	private String selPartidaMuni(long lNroCliente) {
		String sql ="SELECT partida_municipal " + 
				"FROM cliente_tasa " + 
				"WHERE numero_cliente = " + lNroCliente + " " + 
				"AND tasa_exceptuada = 0 " + 
				"AND tasa_anulada = 0 " ; 
		
		return sql;
	}
	
	private String selFechaEstoc(long lNroCliente) {
		String sql = "SELECT TO_CHAR(fecha_terr_puser, '%Y-%m-%d') " + 
				"FROM estoc " + 
				"WHERE numero_cliente = " + lNroCliente ;
				
		return sql;
	}
	
	private String selRetiroMedidor(long lNroCliente) {
		String sql = "SELECT TO_CHAR(MAX(m2.fecha_modif), '%Y-%m-%d') " + 
				"FROM modif m2 " + 
				"WHERE m2.numero_cliente = " + lNroCliente + " " + 
				"AND m2.codigo_modif = 58";
		
		return sql;
	}
	
	private String selFechaInstal(long lNroCliente) {
		String sql = "SELECT NVL(TO_CHAR(MIN(m.fecha_ult_insta), '%Y-%m-%d'), '1995-09-24') " + 
				"FROM medid m " + 
				"WHERE m.numero_cliente = " + lNroCliente;
		
		return sql;
	}
	
	private String selFactuDigital(long lNroCliente) {
		String sql = "SELECT TO_CHAR(fecha_alta, '%Y-%m-%d') " + 
				"FROM clientes_digital " + 
				"WHERE numero_cliente = " + lNroCliente + " " + 
				"AND fecha_alta <= TODAY " + 
				"AND fecha_baja IS NULL OR fecha_baja > TODAY ";
		
		return sql;
	}
}

package dao;

import conectBD.UConnection;
import entidades.sfcClienteDTO;
import entidades.MeasuresDTO;
import servicios.MeasuresSRV;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
//import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;

public class MeasuresDAO {
	
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
				if(rs != null) rs.close();
				if(pstm != null) pstm.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		
		return sRuta;
	}
	
	public Boolean ProcesaMeasures(int iEstadoCliente, int iModoExtraccion) {
		long lCantClientes=0;
		long lNroCliente=0;
		Connection con = null;
		PreparedStatement pstm0 = null;
		ResultSet rs0 = null;
		MeasuresSRV miSrv = new MeasuresSRV();
		
		String sql = getQueryClientes(iEstadoCliente, iModoExtraccion);

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
	
	public Collection<MeasuresDTO>getLecturas(long iNroCliente){
		Vector<MeasuresDTO>miLista = new Vector<MeasuresDTO>();
		MeasuresDTO miReg = null;
		MeasuresDTO miRegRectif=null;
		MeasuresDTO miRegMedid=null;
		Connection con = null;
		Statement st=null;
		ResultSet rs0 = null;
		
		String sql = getQueryLecturas(iNroCliente);

		try {
			con = UConnection.getConnection();
			con.setAutoCommit(false);
			con.setTransactionIsolation(Connection.TRANSACTION_READ_UNCOMMITTED);
			st = con.createStatement();
			st.setFetchSize(1);
			rs0=st.executeQuery(sql);

			while(rs0.next()){
				miReg = new MeasuresDTO();
				miReg.numero_cliente = rs0.getLong(1);
				miReg.corr_facturacion = rs0.getInt(2); 
				miReg.tipo_lectura = rs0.getInt(3);
				miReg.fecha_lectura = rs0.getString(4);
				miReg.constante = rs0.getFloat(5);
				miReg.consumo=rs0.getLong(6);  
				miReg.lectura_facturac=rs0.getDouble(7);
				miReg.lectura_terreno=rs0.getDouble(8);
				miReg.id_factura=rs0.getString(9);
				miReg.indica_refact=rs0.getString(10);
				miReg.fecha_facturacion= rs0.getString(11);
				miReg.numero_medidor=rs0.getLong(12);
				miReg.marca_medidor=rs0.getString(13);
				miReg.coseno_phi = rs0.getFloat(14);
				
				if(miReg.indica_refact.compareTo("S")==0) {
					//Debo buscar la refacturada
					miRegRectif = new MeasuresDTO();
					miRegRectif = getHislecRectif(miReg.numero_cliente, miReg.corr_facturacion, miReg.tipo_lectura);
					if(miRegRectif!=null) {
						miReg.lectura_facturac=miRegRectif.lectura_facturac;
						miReg.consumo=miRegRectif.consumo;
					}
				}
			
				//Datos del medidor
				miRegMedid = new MeasuresDTO();
				miRegMedid = getDataMedid(miReg.marca_medidor, miReg.numero_medidor, miReg.numero_cliente);
				if(miRegMedid != null) {
					miReg.modelo_medidor=miRegMedid.modelo_medidor;
					miReg.tipo_medidor=miRegMedid.tipo_medidor;
				}
				
				miLista.add(miReg);
			}
			
			
		}catch(Exception ex){
			System.out.println("Fallo getLecturas() para cliente " + iNroCliente);
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		
		return miLista;
	}

	private MeasuresDTO getDataMedid(String Marca, long nroMedidor, long nroCliente) {
		MeasuresDTO miReg=null;
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = getQueryMedidor(Marca, nroMedidor, nroCliente);
		
		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				miReg = new MeasuresDTO();
				miReg.modelo_medidor = rs.getString(1);
				miReg.tipo_medidor = rs.getString(2);
			}
			
		}catch(Exception ex){
			System.out.println("Fallo busqueda Medidor para Marca " + Marca + " Medidor " + nroMedidor + " Cliente " + nroCliente +"\nSQL[" + sql +"]");
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				if(rs != null) rs.close();
				if(st != null) st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		return miReg;
	}
	
	private MeasuresDTO getHislecRectif(long nroCliente, int corrFacturacion, int tipoLectu) {
		MeasuresDTO miReg=null;
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = getQueryHislecRectif(nroCliente, corrFacturacion, tipoLectu);
		
		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			
			if(rs.next()){
				miReg = new MeasuresDTO();
				miReg.lectura_facturac=rs.getDouble(1);
				miReg.consumo = rs.getLong(2);
			}
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				if(rs != null) rs.close();
				if(st != null) st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		return miReg;
	}

	
	public MeasuresDTO getHislecReac(long nroCliente, int corrFacturacion, int tipoLectu, String tieneRefacturac) {
		MeasuresDTO miReg=null;
		Connection con = null;
		Statement st = null;
		ResultSet rs = null;
		String sql="";

		sql = getQueryReactiva(nroCliente, corrFacturacion, tipoLectu);
		
		try{
			con = UConnection.getConnection();
			st = con.createStatement();
			rs=st.executeQuery(sql);
			if(rs.next()){
				miReg = new MeasuresDTO();
				
				miReg.lectura_facturac=rs.getDouble(1);
				miReg.lectura_terreno=rs.getDouble(2);
				miReg.consumo = rs.getLong(3);
			}

			rs=null;
			st=null;
			
			if(tieneRefacturac.equals("S")) {
				sql = getQueryReactivaRectif(nroCliente, corrFacturacion, tipoLectu);
				st = con.createStatement();
				rs=st.executeQuery(sql);
				if(rs.next()){
					miReg.lectura_facturac=rs.getDouble(1);
					miReg.consumo = rs.getLong(2);
				}
			}
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				if(rs != null) rs.close();
				if(st != null) st.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}
		
		return miReg;
	}
	
	private String getQueryMedidor(String Marca, long nroMedidor, long nroCliente) {
		String sql = String.format("SELECT me.mod_codigo, NVL(mo.tipo_medidor, 'A') FROM medidor me, modelo mo "+
			"WHERE me.mar_codigo = '%1$s' "+
			"AND me.med_numero = %2$d "+
			"AND me.numero_cliente = %3$d "+
			"AND mo.mar_codigo = me.mar_codigo "+
			"AND mo.mod_codigo = me.mod_codigo ", Marca.trim(), nroMedidor, nroCliente);

		return sql;
	}
	
	private String getQueryClientes(int iEstado, int iModo) {
		String sql="";
		
		sql= "SELECT c.numero_cliente FROM cliente c ";
		if(iModo==1){	
		   sql+= ", migra_sf ma ";
		}   
		if(iEstado==0) {
			sql+= "WHERE c.estado_cliente = 0 ";
		}else {
			sql+= "WHERE c.estado_cliente != 0 ";
		}
		sql+= "AND c.tipo_sum NOT IN (5, 6) ";
		sql+= "AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm ";
		sql+= "WHERE cm.numero_cliente = c.numero_cliente ";
		sql+= "AND cm.fecha_activacion < TODAY ";
		sql+= "AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY)) ";
		if(iModo==1){
			sql+= "AND ma.numero_cliente = c.numero_cliente ";
		}
		
		return sql;
	}
	
	private static String SQL_SEL_RUTA_FILES = "SELECT valor_alf "+
				"FROM tabla "+
				"WHERE nomtabla = 'PATH' "+
				"AND codigo = ? "+
				"AND sucursal = '0000' "+
				"AND fecha_activacion <= TODAY "+
				"AND ( fecha_desactivac >= TODAY OR fecha_desactivac IS NULL )";

	private String getQueryLecturas(long nroCliente) {
		String sql="";
		
		sql = "SELECT h.numero_cliente, "+
		"h.corr_facturacion, "+
		"h.tipo_lectura, "+
		"TO_CHAR(h.fecha_lectura, '%Y-%m-%d'), "+
		"h.constante, "+
		"h.consumo, "+
		"h.lectura_facturac, "+
		"NVL(h.lectura_terreno,0), "+
		"h2.centro_emisor || h2.tipo_docto || h2.numero_factura, "+
		"h2.indica_refact, "+
	    "TO_CHAR(h2.fecha_facturacion, '%Y-%m-%d'), "+
		"h.numero_medidor, "+
		"h.marca_medidor, "+
		"h2.coseno_phi "+
		"FROM hislec h, hisfac h2 "+
		"WHERE h.numero_cliente =  "+ nroCliente + " "+
		"AND h.fecha_lectura >= TODAY - 365 "+
		"AND h.tipo_lectura NOT IN (5, 6, 7) "+
		"AND h2.numero_cliente = h.numero_cliente "+
		"AND h2.corr_facturacion = h.corr_facturacion ";

		return sql;
	}
	
	private String getQueryHislecRectif(long nroCliente, int corrFacturacion, int tipoLectura) {
		String sql = String.format("SELECT h1.lectura_rectif, h1.consumo_rectif "+
		"FROM hislec_refac h1 "+
		"WHERE h1.numero_cliente = %1$d "+
		"AND h1.corr_facturacion = %2$d "+
		"AND h1.tipo_lectura = %3$d "+
		"AND h1.corr_hislec_refac = (SELECT MAX(h2.corr_hislec_refac) "+
		"	FROM hislec_refac h2 "+
		" 	WHERE h2.numero_cliente = h1.numero_cliente "+
		"   AND h2.corr_facturacion = h1.corr_facturacion "+
		"   AND h2.tipo_lectura = h1.tipo_lectura) ", nroCliente, corrFacturacion, tipoLectura);
		
		return sql;
	}
	
	private String getQueryReactiva(long nroCliente, int corrFacturacion, int tipoLectura) {
		String sql = String.format("SELECT NVL(lectu_factu_reac, 0), "+
		"NVL(lectu_terreno_reac, 0), "+
		"NVL(consumo_reac, 0) "+
		"FROM hislec_reac "+
		"WHERE numero_cliente = %1$d "+
		"AND corr_facturacion = %2$d "+
		"AND tipo_lectura = %3$d ", nroCliente, corrFacturacion, tipoLectura); 
		
		return sql;
	}
	
	private String getQueryReactivaRectif(long nroCliente, int corrFacturacion, int tipoLectura) {
		String sql = String.format("SELECT NVL(h1.lectu_rectif_reac, 0), NVL(h1.consu_rectif_reac,0) "+
		"FROM hislec_refac_reac h1 "+
		"WHERE h1.numero_cliente = %1$d "+
		"AND h1.corr_facturacion = %2$d "+
		"AND h1.tipo_lectura = %3$d "+
		"AND h1.corr_hislec_refac = (SELECT MAX(h2.corr_hislec_refac) "+
		"	FROM hislec_refac_reac h2 "+
		" 	WHERE h2.numero_cliente = h1.numero_cliente "+
		"   AND h2.corr_facturacion = h1.corr_facturacion "+
		"   AND h2.tipo_lectura = h1.tipo_lectura )", nroCliente, corrFacturacion, tipoLectura);
		
		return sql;
	}
	
}

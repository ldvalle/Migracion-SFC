package dao;
import conectBD.UConnection;
import entidades.ClienteDTO;
import entidades.MoveInDTO;
import entidades.sfcClienteDTO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
//import java.sql.SQLException;

import java.util.Collection;
import java.util.Vector;

public class ClientesDAO {
		
	public Collection<ClienteDTO> getLstClientes(){
		Connection con = null;
		PreparedStatement pstm = null;
		ResultSet rs = null;

		Vector<ClienteDTO> miLista = new Vector<ClienteDTO>();
		ClienteDTO miReg = null;
		String sql = getQuery1();
		
		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(sql);
			rs = pstm.executeQuery();
			
			while(rs.next()){
				miReg = new ClienteDTO();
				
				miReg.numero_cliente = rs.getLong("numero_cliente");
				miReg.sucursal = rs.getString("sucursal");
				miReg.sector = rs.getLong("sector");
				miReg.tarifa = rs.getString("tarifa");
				miReg.tipo_sum = rs.getInt("tipo_sum");
				miReg.corr_facturacion = rs.getInt("corr_facturacion");
				miReg.provincia = rs.getString("provincia");
				miReg.partido = rs.getString("partido");
				miReg.comuna = rs.getString("comuna");
				miReg.tipo_iva = rs.getString("tipo_iva");
				miReg.tipo_cliente = rs.getString("tipo_cliente");
				miReg.actividad_economic = rs.getString("actividad_economic");
				
				miLista.add(miReg);
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
		
		return miLista;
	}

	public Boolean insClientes(Long nroCliente){
		Connection con = null;
		PreparedStatement pstm = null;

		String sql = getQuery2(nroCliente);
		
		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(sql);
			pstm.executeQuery();
			
		}catch(Exception ex){
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}
		return true;
	}
	
	public ClienteDTO getCliente(Long nroCliente) {
		Connection con = null;
		PreparedStatement pstm = null;
		ResultSet rs = null;
		String sql = getQuery3(nroCliente);
		ClienteDTO miReg = null;
		
		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(sql);
			rs = pstm.executeQuery();
			
			while(rs.next()){
				miReg = new ClienteDTO();
				
				miReg.numero_cliente = rs.getLong("numero_cliente");
				miReg.sucursal = rs.getString("sucursal");
				miReg.sector = rs.getLong("sector");
				miReg.tarifa = rs.getString("tarifa");
				miReg.tipo_sum = rs.getInt("tipo_sum");
				miReg.corr_facturacion = rs.getInt("corr_facturacion");
				miReg.provincia = rs.getString("provincia");
				miReg.partido = rs.getString("partido");
				miReg.comuna = rs.getString("comuna");
				miReg.tipo_iva = rs.getString("tipo_iva");
				miReg.tipo_cliente = rs.getString("tipo_cliente");
				miReg.actividad_economic = rs.getString("actividad_economic");
				
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
		
		return miReg;
	}
	
	public Collection<MoveInDTO>getLstMoveIn(String Sucursal){
		Connection con = null;
		PreparedStatement pstm = null;
		ResultSet rs = null;

		Vector<MoveInDTO> miLista = new Vector<MoveInDTO>();
		MoveInDTO miReg = null;
		String sql = getQuery4(Sucursal);
		
		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(sql);
			rs = pstm.executeQuery();
			
			while(rs.next()){
				miReg = new MoveInDTO();

				miReg.nroCliente = rs.getLong("numero_cliente");
				miReg.Tarifa = rs.getString("tarifa");
				miReg.Categoria = rs.getString("categoria");
				miReg.CDC = rs.getString("cdc");
				miReg.Sucursal = rs.getString("sucursal");
				miReg.Beneficiario = rs.getLong("beneficiario");
				miReg.CorrFacturacion = rs.getInt("corr_fac");
				miReg.Electro = rs.getString("electro");
				
				miLista.add(miReg);
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
		
		return miLista;
		
	}

	public Collection<sfcClienteDTO>getLstSfcCliente(){
		Connection con = null;
		PreparedStatement pstm = null;
		ResultSet rs = null;

		Vector<sfcClienteDTO> miLista = new Vector<sfcClienteDTO>();
		sfcClienteDTO miReg = null;
		String sql = getQuery5();
		
		try{
			con = UConnection.getConnection();
			pstm = con.prepareStatement(sql);
			rs = pstm.executeQuery();
			
			while(rs.next()){
				miReg = new sfcClienteDTO();

				miReg.numero_cliente = rs.getLong("numero_cliente");
				
				miReg.nombre = rs.getString("nombre_cliente");
				miReg.cod_calle = rs.getString("cod_calle");
				miReg.nom_calle = rs.getString("nom_calle");
				miReg.nom_partido = rs.getString("nom_partido");
				miReg.provincia = rs.getString("provincia");
				miReg.nom_comuna = rs.getString("nom_comuna");
				miReg.nro_dir = rs.getString("nro_dir");
				miReg.obs_dir = rs.getString("obseva_dir");
				miReg.cod_postal = rs.getInt("cod_postal");
				miReg.piso_dir = rs.getString("piso_dir");
				miReg.depto_dir = rs.getString("depto_dir");
				miReg.tip_doc = rs.getString("tip_doc");
				miReg.nro_doc = rs.getDouble("nro_doc");
				miReg.telefono = rs.getString("tele_cliente");
				miReg.tipo_cliente = rs.getString("tipo_cliente");
				miReg.rut = rs.getString("rut");
				miReg.tipo_reparto = rs.getString("tipo_reparto");
				miReg.sucursal = rs.getString("sucursal");
				miReg.sector = rs.getInt("sector");
				miReg.zona = rs.getInt("zona");
				miReg.tarifa = rs.getString("tarifa");
				miReg.correlativo_ruta = rs.getLong("correlativo_ruta");;
				miReg.sClaseServicio = rs.getString("cod_sf1");
				miReg.sSubClaseServ = rs.getString("cod_sf2");
				miReg.partido = rs.getString("partido");
				miReg.comuna = rs.getString("comuna");
				miReg.tec_cod_calle = rs.getString("tec_cod_calle");
				miReg.nom_barrio = rs.getString("barrio_clie");
				miReg.potencia_inst_fp = rs.getDouble("potencia_inst_fp");
				miReg.entre_calle1 = rs.getString("entre1");
				miReg.entre_calle2 = rs.getString("entre2");
				
				
				miLista.add(miReg);
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
		
		return miLista;
		
		
	}
	
	
	private String getQuery1(){
		String sql="";
		
		sql = "SELECT numero_cliente, ";
		sql += "sucursal, "; 
		sql += "sector, ";
		sql += "tarifa, ";
		sql += "tipo_sum, ";
		sql += "corr_facturacion, ";
		sql += "provincia, ";
		sql += "partido, ";
		sql += "comuna, ";
		sql += "tipo_iva, ";
		sql += "tipo_cliente, ";
		sql += "actividad_economic ";
		sql += "FROM cliente ";
		sql += "WHERE estado_cliente = 0 ";
		sql += "AND tipo_sum != 5 ";
		
		return sql;
		
	}

	private String getQuery2(Long nroCliente){
		String sql;
		
		sql = "INSERT INTO migra_activos (numero_cliente)VALUES(" + nroCliente + ")";
		
		return sql;
	}
	
	private String getQuery3(Long nroCliente){
		String sql="";
		
		sql = "SELECT numero_cliente, ";
		sql += "sucursal, "; 
		sql += "sector, ";
		sql += "tarifa, ";
		sql += "tipo_sum, ";
		sql += "corr_facturacion, ";
		sql += "provincia, ";
		sql += "partido, ";
		sql += "comuna, ";
		sql += "tipo_iva, ";
		sql += "tipo_cliente, ";
		sql += "actividad_economic ";
		sql += "FROM cliente ";
		sql += "WHERE numero_cliente = " + nroCliente;
		
		return sql;
		
	}

	private String getQuery4(String sucursal){
		String sql="";
		
		sql = "SELECT c.numero_cliente, ";
		sql += "NVL(t1.cod_sap, c.tarifa) tarifa, ";
		sql += "t2.cod_sap categoria,";
		sql += "t2.acronimo_sap cdc, ";
		sql += "t3.cod_sap sucursal, ";
		sql += "NVL(c.nro_beneficiario, 0) beneficiario, ";
		sql += "NVL(c.corr_facturacion, 0) corr_fac, ";
		sql += "CASE ";
		sql += "	WHEN cv.numero_cliente IS NOT NULL THEN 'SI' ";
		sql += "	ELSE 'NO' ";
		sql += "END electro ";
		sql += "FROM cliente c, migra_activos ma, OUTER sap_transforma t1, OUTER sap_transforma t2, OUTER clientes_vip cv ";
		sql += ", OUTER sap_transforma t3 ";
		sql += "WHERE c.numero_cliente = ma.numero_cliente ";
		sql += "AND c.sucursal = '%s' ";
		sql += "AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med cm ";
		sql += "WHERE cm.numero_cliente = c.numero_cliente ";
		sql += "AND cm.fecha_activacion < TODAY ";
		sql += "AND (cm.fecha_desactiva IS NULL OR cm.fecha_desactiva > TODAY)) ";
		sql += "AND t1.clave = 'TARIFTYP' ";
		sql += "AND t1.cod_mac = c.tarifa ";
		sql += "AND t2.clave = 'TIPCLI' ";
		sql += "AND t2.cod_mac = c.tipo_cliente ";
		sql += "AND cv.numero_cliente = c.numero_cliente ";
		sql += "AND cv.fecha_activacion <= TODAY ";
		sql += "AND (cv.fecha_desactivac IS NULL OR cv.fecha_desactivac > TODAY) ";
		sql += "AND t3.clave = 'CENTROOP' ";
		sql += "AND t3.cod_mac = c.sucursal ";
		
		return String.format(sql, sucursal.trim());
		
	}

	private String getQuery5(){
		String sql="";

		sql =  "SELECT first 10 c.numero_cliente, ";
		sql += "REPLACE(TRIM(c.nombre), '\"', ' ') nombre_cliente, ";
		sql += "c.cod_calle, ";
		sql += "c.nom_calle, ";
		sql += "c.nom_partido, ";
		sql += "c.provincia, ";
		sql += "c.nom_comuna, ";
		sql += "c.nro_dir, ";
		sql += "TRIM(c.obs_dir) obseva_dir, ";
		sql += "c.cod_postal, ";
		sql += "c.piso_dir, ";
		sql += "c.depto_dir, ";
		sql += "c.tip_doc, ";
		sql += "c.nro_doc, ";
		sql += "TRIM(REPLACE(c.telefono, '-', '')) tele_cliente, ";
		sql += "c.tipo_cliente, ";
		sql += "c.rut, ";
		sql += "c.tipo_reparto, ";
		sql += "c.sucursal, ";
		sql += "c.sector, ";
		sql += "c.zona, ";
		sql += "c.tarifa, ";
		sql += "c.correlativo_ruta, ";
		sql += "t1.cod_sf1, ";
		sql += "t1.cod_sf2, ";
		sql += "c.partido, ";
		sql += "c.comuna, ";
		sql += "t.tec_cod_calle, ";
		sql += "TRIM(c.nom_barrio) barrio_clie, ";
		sql += "c.potencia_inst_fp, ";
		sql += "TRIM(c.nom_entre) entre1, ";
		sql += "TRIM(c.nom_entre1) entre2 ";
		sql += "FROM cliente c, OUTER sf_transforma t1, OUTER tecni t ";
		sql += "WHERE c.estado_cliente = 0 ";
		sql += "AND c.sector NOT IN (81, 82, 85, 88, 90) ";
		sql += "AND NOT EXISTS (SELECT 1 FROM clientes_ctrol_med m ";
		sql += "	WHERE m.numero_cliente = c.numero_cliente ";
		sql += "	AND m.fecha_activacion < TODAY  ";
		sql += "	AND (m.fecha_desactiva IS NULL OR m.fecha_desactiva > TODAY)) ";
		sql += "AND t1.clave = 'TIPCLI' ";
		sql += "AND t1.cod_mac = c.tipo_cliente ";
		sql += "AND t.numero_cliente = c.numero_cliente ";

		
		return sql;
	}
	
	
}

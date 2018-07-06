package dao;

import conectBD.UConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
//import java.sql.SQLException;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Vector;


public class universoDAO {

	public Boolean CargaUniverso() {
		Connection con = null;
		PreparedStatement pstm = null;
		String sql;

		try{
			con = UConnection.getConnection();
			con.setAutoCommit(false);

			//tarifa social
			System.out.println("Cargando Tarifa Social");
			sql = query1();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//electro dependientes
			System.out.println("Cargando Electro Dependientes");			
			sql = query2();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//residenciales
			System.out.println("Cargando Residenciales");			
			sql = query3();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;
			
			//oficiales
			System.out.println("Cargando Oficiales");			
			sql = query4();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//pim
			System.out.println("Cargando PIM");			
			sql = query5();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;
			
			//APM con medidor
			System.out.println("Cargando APM con medidor");			
			sql = query6();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//APM sin medidor
			System.out.println("Cargando APM sin medidor");			
			sql = query7();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;
			
			//con padres en T2T3
			System.out.println("Cargando hijos de T23");
			sql = query8();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//EBP
			System.out.println("Cargando EBP");
			sql = query9();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;

			//Reactiva
			System.out.println("Cargando Reactiva");
			sql = query10();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;
			
			//no activos con deuda
			/*
			System.out.println("Cargando No activos con deuda");
			sql = query11();
			pstm = con.prepareStatement(sql);
			pstm.executeUpdate();
			pstm=null;
			*/

			con.commit();
		}catch(Exception ex){
			System.out.println("universoDAO() exploto");
			try {
				con.rollback();
			}catch(SQLException exSQL) {
				exSQL.printStackTrace();
			}
			
			ex.printStackTrace();
			throw new RuntimeException(ex);
		}finally{
			try{
				if(pstm != null) pstm.close();
			}catch(Exception ex){
				ex.printStackTrace();
				throw new RuntimeException(ex);
			}
		}		
			
		
		return true;
	}
	
	private String query1() {
		String sql;
		//tarifa social
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c, tarifa_social ts ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and ts.numero_cliente = c.numero_cliente ";
		sql += "and ts.fecha_inicio <= '2017-12-20' ";
		sql += "and (ts.fecha_desactivac is null or ts.fecha_desactivac > today) ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}

	private String query2() {
		String sql;
		//electrodependientes
		
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c, clientes_vip ts ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and ts.numero_cliente = c.numero_cliente ";
		sql += "and ts.motivo in (3,4,5,8) ";
		sql += "and ts.fecha_activacion <= '2017-12-20' ";
		sql += "and (ts.fecha_desactivac is null or ts.fecha_desactivac > today) ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}
	
	private String query3() {
		String sql;
		//residenciales
		sql ="insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and c.tarifa = '1RM' ";
		sql += "and c.tipo_cliente not in ('OM', 'OP', 'ON') ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}
	
	private String query4() {
		String sql;
		//oficiales
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and c.tipo_sum != 5 ";
		sql += "and c.tipo_cliente in ('OM', 'OP', 'ON') ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}
	
	private String query5() {
		String sql;
		//pim
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and c.tarifa[1] = 'P' ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}

	private String query6() {
		String sql;
		//APM Con Medidor
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c, medid m ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and c.tarifa in ('1AP', 'APM') ";
		sql += "and m.numero_cliente = c.numero_cliente ";
		sql += "and m.estado = 'I' ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}	

	private String query7() {
		String sql;
		//APM Sin Medidor
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and c.tarifa in ('1AP', 'APM') ";
		sql += "and not exists (select 1 from medid m where m.numero_cliente = c.numero_cliente ";
		sql += " and m.estado = 'I') ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}		

	private String query8() {
		String sql;
		//con padres en T2T3
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 m.numero_cliente ";
		sql += "from mg_corpor_t23 m, cliente c ";
		sql += "where c.numero_cliente = m.numero_cliente ";
		sql += "and c.estado_cliente = 0 ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}
	
	private String query9() {
		String sql;
		//EBP
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c, entid_bien_publico e ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and e.numero_cliente = c.numero_cliente ";
		sql += "and e.fecha_inicio <= '2017-05-01' ";
		sql += "and (e.fecha_desactivac is null or e.fecha_desactivac > today) ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}

	private String query10() {
		String sql;
		//Reactiva
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c, medid m ";
		sql += "where c.estado_cliente = 0 ";
		sql += "and m.numero_cliente = c.numero_cliente ";
		sql += "and m.estado = 'I' ";
		sql += "and m.tipo_medidor = 'R' ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}

	private String query11() {
		String sql;
		//no activos con deuda
		sql = "insert into sap_universo(numero_cliente) ";
		sql += "select first 500 c.numero_cliente ";
		sql += "from cliente c ";
		sql += "where c.estado_cliente != 0 ";
		sql += "and c.saldo_actual != 0 ";
		sql += "and not exists (select 1 from sap_universo s where s.numero_cliente = c.numero_cliente) ";
		
		return sql;
	}
	
}

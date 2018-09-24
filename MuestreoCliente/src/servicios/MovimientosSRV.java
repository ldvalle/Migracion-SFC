package servicios;

import java.util.*;
import entidades.*;
import dao.*;

import java.util.Collection;
import java.util.Vector;
import java.util.Date;
import java.text.SimpleDateFormat;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class MovimientosSRV {
	private static Writer outFile=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchivoSalida;
	private static int iTipoCorrida;

	public Boolean ProcesaMovimientos(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		MovimientosDAO miDao = new MovimientosDAO();
		
		//proceso ppal
		if(!miDao.ProcesoPpal(iTipo)) {
			System.out.println("Fallo el DAO para Movimientos");
			return false;
		}
		
		
		//Cierra Archivos
		CierraArchivos();
	
		//Copiar Archivos
		if(!MoverArchivo()) {
			System.out.println("No se pudo mover los archivos.");
		}

		return true;
	}

	public Boolean ProcesaCliente(long lNroCliente) {
		MovimientosDAO miDao = new MovimientosDAO();
		Collection<MovimientosDTO>lstPagos=null;
		
		lstPagos=miDao.getPagos(lNroCliente);
		
		for(MovimientosDTO reg : lstPagos) {
			if(! InformaEvento(reg)) {
				System.out.println("Error al informar Pago para Cliente " + lNroCliente );
				return false;
			}
		}
		
		return true;
	}
	
	private Boolean InformaEvento(MovimientosDTO reg) {
		String sLinea ="";
		
		if(reg.centro_emisor == null) {
			reg.centro_emisor="";
		}
		if(reg.tipo_docto == null) {
			reg.tipo_docto="";
		}

	   /* Cuenta */
		sLinea = String.format("\"%dARG\";", reg.numero_cliente);
	      
	   /* Suministro */
		sLinea += String.format("\"%dAR\";", reg.numero_cliente);
	   
	   /* Tipo de movimiento */
		sLinea += String.format("\"%s\";", reg.tipo_mov);
	   
	   /* Número documento */
		sLinea += String.format("\"%d\";", reg.llave);
	   
	   /* Fecha de movimiento */
		sLinea += String.format("\"%s\";", reg.fecha_pago);
	   
	   /* Fecha de vencimiento */
		sLinea += "\"\";";
	   
	   /* Monto de evento */
		sLinea += String.format("\"%.02f\";", reg.valor_pago);
	   
	   /* Deuda */
		sLinea += "\"\";";
	   
	   /* Tipo de documento */
		sLinea += String.format("\"%s\";", reg.tipo_pago);
	   
	   /* Numero interno documento */
		sLinea += String.format("\"%d\";", reg.llave);
	   
	   /* Sentido */
		sLinea += "\"C\";";
	   
	   /* External Id */
		sLinea += String.format("\"%d%d%dMOVARG\";", reg.llave, reg.numero_cliente, reg.corr_pagos);
	   
	   /* Factura */
		sLinea += String.format("\"%d%s%s%dINVARG\";",reg.numero_cliente, reg.centro_emisor, reg.tipo_docto, reg.nro_docto_asociado);
	   
	   /* Monto energía */
		sLinea += "\"\";";
	   /* Monto convenio energía */
	   sLinea += "\"\";";
	   /* Monto productos y servicios */
	   sLinea += "\"\";";
	   /* Saldo actual */
	   sLinea += "\"\";";
	   
	   /* Fecha ingreso de pago */
	   sLinea += String.format("\"%s\";", reg.fecha_pago);
	   
	   /* Fecha ingreso sistema */
	   sLinea += String.format("\"%s\";", reg.fecha_actualiza);
	   
	   /* Fecha amortización de pago */
	   sLinea += String.format("\"%s\";", reg.fecha_actualiza);
	   
	   /* Monto */
	   sLinea += String.format("\"%.02f\";", reg.valor_pago);
	   
	   /* Medio de pago */
	   sLinea += "\"\";";
	   /* Lugar de pago */
	   sLinea += String.format("\"%s\";", reg.lugarPago);
	   
	   /* Cajero */
	   sLinea += String.format("\"%s\";", reg.nombre_cajero);
	   
	   /* Oficina */
	   sLinea += String.format("\"%s\";", reg.oficina);

	   /* Intereses */
	   sLinea += "\"\";";
	   /* Moneda */
	   sLinea += "\"ARS\";";
	   /* Compañía */
	   sLinea += "\"9\";";
	   /* Impuestos */
	   sLinea += "\"\";";
	   /* Cuota Convenio */
	   sLinea += "\"\";";
		

		sLinea += "\r\n";
		
		try {
			outFile.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
			return false;
		}
		
		return true;
	}
	
	
	private Boolean AbreArchivos( String sOS) {
		String sLinea="";
		MovimientosDAO miDao = new MovimientosDAO();
		String sClave = "";
		String sArchivoMovimiento="";
		String sFilePathMovimiento="";
		
		Date dFechaHoy = new Date();
		
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyyMMdd");
		String sFechaFMT=fechaF.format(dFechaHoy);

		
		sClave = "SALESF";
		sPathGenera=miDao.getRuta(sClave);
		sClave = "SALEFC";
		sPathCopia=miDao.getRuta(sClave);
		
		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
		}
		
		sArchivoMovimiento= String.format("enel_care_payment_t1_%s.csv", sFechaFMT);
		sFilePathMovimiento=sPathGenera.trim() + sArchivoMovimiento.trim();
		
		sArchivoSalida=sArchivoMovimiento;

		try {
			outFile = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathMovimiento), "UTF-8"));
			sLinea = getTitulos();
			try {
				outFile.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		return true;
	}

	void CierraArchivos() {
		try {
			outFile.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}

	Boolean MoverArchivo() {
		String sOriDevice = sPathGenera.trim() + sArchivoSalida.trim();
		String sDestiDevice = sPathCopia.trim() + sArchivoSalida.trim();
		
        Path pOriDevice = FileSystems.getDefault().getPath(sOriDevice);
        Path pDestiDevice = FileSystems.getDefault().getPath(sDestiDevice);
        
		try {
			Files.move(pOriDevice, pDestiDevice, StandardCopyOption.REPLACE_EXISTING);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}

	String getTitulos() {
		String sLinea="";
		
		sLinea = "\"Cuenta\";" + 
				"\"Suministro\";" + 
				"\"Tipo de Movimiento\";" + 
				"\"Número de Documento\";" + 
				"\"Fecha de Movimiento\";" + 
				"\"Fecha de Vencimiento\";" +
				"\"Monto Evento\";" + 
				"\"Deuda\";" + 
				"\"Tipo de Documento\";" +
				"\"Número Interno Documento\";" + 
				"\"Sentido\";" + 
				"\"External ID\";" + 
				"\"Factura\";" + 
				"\"Monto Energía\";" + 
				"\"Monto productos y servicios\"" +
				"\"Saldo actual\";" +
				"\"Fecha ingreso de pago\";" +
				"\"Fecha ingreso sistema\";" +
				"\"Fecha amortización de pago\";" +
				"\"Monto\";" +
				"\"Medio de Pago\";" +
				"\"Lugar de Pago\";" +
				"\"Cajero\";" +
				"\"Oficina\";" +
				"\"Intereses\";" +
				"\"Moneda\";" +
				"\"Compañia\";" +
				"\"Impuestos\";" +
				"\"Cuota Convenio\";" +
				
				"\r\n";
		
		return sLinea;
	}
	
}

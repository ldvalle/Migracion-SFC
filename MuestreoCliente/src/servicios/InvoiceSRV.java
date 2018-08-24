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

public class InvoiceSRV {
	private static Writer outFile=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchivoSalida;
	private static int iTipoCorrida;

	public Boolean ProcesaInvoice(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		InvoiceDAO miDao = new InvoiceDAO();

		
		//proceso ppal
		if(!miDao.ProcesoPpal(iTipo)) {
			System.out.println("Fallo el DAO para Invoices");
			return false;
		}
		
		
		//Cierra Archivos
		CierraArchivos();
	
		//Copiar Archivos
/*		
		if(!MoverArchivo()) {
			System.out.println("No se pudo mover los archivos.");
		}
*/
		return true;
	}
	
	public Boolean ProcesaCliente(long lNroCliente) {
		InvoiceDAO miDao = new InvoiceDAO();
		Collection<InvoiceDTO>lstFacturas=null;
		
		lstFacturas=miDao.getFacturas(lNroCliente);
		
		for(InvoiceDTO reg : lstFacturas) {
			if(! InformaEvento(reg)) {
				System.out.println("Error al informar INVOICE para Cliente " + lNroCliente + " Corr.Factu " + reg.corr_facturacion);
				return false;
			}
		}
		
		return true;
	}
	
	private Boolean AbreArchivos( String sOS) {
		String sLinea="";
		InvoiceDAO miDao = new InvoiceDAO();
		String sClave = "";
		String sArchivoInvoice="";
		String sFilePathInvoice="";
		
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
		
		sArchivoInvoice= String.format("enel_care_invoice_t1_%s.csv", sFechaFMT);
		sFilePathInvoice=sPathGenera.trim() + sArchivoInvoice.trim();
		
		sArchivoSalida=sArchivoInvoice;

		try {
			outFile = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathInvoice), "UTF-8"));
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
		
		sLinea = "\"Fecha de Emisión\";" + 
				"\"Fecha de Vencimiento\";" + 
				"\"Fecha de Segundo Vencimiento\";" + 
				"\"Intereses\";" + 
				"\"Acceso a la Factura\";" + 
				"\"Dirección Factura\";" + 
				"\"Tituloar\";" + 
				"\"Otros Cargos\";" + 
				"\"Suministro\";" + 
				"\"Saldo Anterior\";" + 
				"\"Cantidad de Productos y Servicios\";" + 
				"\"Impuestos\";" + 
				"\"External ID\";" + 
				"\"Numero Factura\";" + 
				"\"Dirección Facturación (histórico)\"" +
				"\"Pago\";" +
				"\"Total\";" +
				"\"Cargos Fijos\";" +
				"\"Cargos Variables\";" +
				"\"Factor Potencia\";" +
				"\"Tasa Alumbrado Público\";" +
				"\"Recargo\";" +
				"\"Recargo Anterior\";" +
				"\"Cuota Convenio\";" +
				"\"C.N.R.\";" +
				"\"Refacturación\";" +
				"\"Ahorro %\";" +
				"\"Factura Digital\";" +
				"\"Moneda\";" +
				
				"\r\n";
		
		return sLinea;
	}

	private Boolean InformaEvento(InvoiceDTO reg) {
		String sLinea ="";

	   // Fecha de emisión
		sLinea = String.format("\"%sT00:00:00.000Z\";", reg.fecha_facturacion);
	   
	   // Fecha de vencimiento
		sLinea += String.format("\"%sT00:00:00.000Z\";", reg.fecha_vencimiento1);
	   
	   // Fecha de segundo vencimiento
		sLinea += String.format("\"%sT00:00:00.000Z\";", reg.fecha_vencimiento2);
	   
	   // Intereses
		sLinea += String.format("\"%.02f\";", reg.suma_intereses);
	   
	   // Acceso a la factura
		sLinea +="\"http://www.edesur.com.ar\";";
	   
	   // Dirección factura
		sLinea += String.format("\"%dAR\";", reg.numero_cliente);
	   
	   // Titular
		sLinea += String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // Otros cargos
		sLinea += String.format("\"%.02f\";", reg.suma_cargos_man);
	   
	   // Suministro
		sLinea += String.format("\"%dAR\";", reg.numero_cliente);
	   
	   // Saldo anterior
		sLinea += String.format("\"%.02f\";", reg.saldo_anterior);
	   
	   // Saldos de productos y servicios (cuota kit) 
	   if(reg.cargo_kit > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.cargo_kit);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Impuestos
	   sLinea += String.format("\"%.02f\";", reg.suma_impuestos);
	   
	   // External ID
	   sLinea += String.format("\"%sAR\";", reg.id_factura);
	   
	   // Numero Factura
	   sLinea += String.format("\"%sAR\";", reg.id_factura);
	   
	   // Direccion Facturación (Historico)
	   sLinea += String.format("\"%d\";", reg.numero_cliente);
	   
	   // Pago (vacio)
	   sLinea += "\"\";";
	   
	   // Total
	   sLinea += String.format("\"%.02f\";", reg.total_a_pagar);
	   
	   // Cargos Fijos
	   if(reg.cargo_fijo > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.cargo_fijo);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Cargos Variables
	   if(reg.cargo_variable > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.cargo_variable);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Factor Potencia
	   sLinea += String.format("\"%.02f\";", reg.coseno_phi);
	   
	   // Tasa Alumbrado Público
	   if(reg.cargo_tap > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.cargo_tap);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Recargo
	   if(reg.suma_recargo > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.suma_recargo);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Recargo Anterior
	   if(reg.recargoAnterior > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.recargoAnterior);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // Cuota convenio
	   if(reg.suma_convenio > 0.01){
		   sLinea += String.format("\"%.02f\";", reg.suma_convenio);
	   }else{
		   sLinea += "\"\";";
	   }
	   
	   // CNR (Vacio)
	   sLinea += "\"\";";
	   
	   // Refacturación
	   if(reg.indica_refact.charAt(0) == 'S'){
		   sLinea += "\"YES\";";
	   }else {
		   sLinea += "\"NO\";";
	   }
	   
	   // Ahorro % (vacio)
	   sLinea += "\"\";";
	   
	   // Factura Digital
	   if(reg.factu_digital.charAt(0)=='S') {
		   sLinea += "\"True\";";
	   }else {
		   sLinea += "\"False\";";
	   }
	
	   // Moneda
	   sLinea += "\"ARS\";";
	
		
	   sLinea += "\r\n";
		
		try {
			outFile.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
			return false;
		}
		
		return true;
	}
}

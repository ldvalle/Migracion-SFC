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



public class sfcContrato {
	private static String Plataforma;
	private static Writer outContrato=null;
	private static Writer outLinea=null;
	private static Writer outBilling=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchContrato;
	private static String sArchLinea;
	private static String sArchBilling;
	private static int iTipoFiles;

	public Boolean ProcesaContrato(int iEstadoCliente, int iModoExtraccion, int iTipoArchivos, String sOS) {
		iTipoFiles=iTipoArchivos;
		
		//Abre Archivos
		if(!AbreArchivos(iTipoArchivos, sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		long lNroCliente=0;
		ContratoDAO miDao = new ContratoDAO();
		
		Plataforma=sOS;

		//proceso ppal ----
		if(!miDao.ProcesaContrato(iEstadoCliente, iModoExtraccion, iTipoArchivos)) {
			System.out.println("Fallo el DAO");
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

	public Boolean ProcesaCliente(long nroCliente, int iTipoArchivo) {
		ContratoDAO miDAO = new ContratoDAO();
		ContratoDTO miContra=null;
		ContratoDTO miFPago=null;
		
		miContra = miDAO.getCliente(nroCliente);
		
		//Cargar Alta
		miContra.sFechaAlta = miDAO.getFechaAlta(miContra);
		
		//Cargar Factura Digital
		miContra.sFechaAltaFactuDigital = miDAO.getFactuDigital(nroCliente);
		if(miContra.sFechaAltaFactuDigital.trim().equals("NOTIENE")) {
			miContra.factu_digital="N";
			miContra.sFechaAltaFactuDigital="";
		}else {
			miContra.factu_digital="S";
		}
		
		//Cargar padre T23 si tiene
		miContra.papa_t23 = miDAO.getCorpoT23(nroCliente);
		
		//Carga Forma de Pago
		if(miContra.tipo_fpago.equals("D")) {
			miFPago = miDAO.getFormaPago(nroCliente);
			
			if(miFPago.fp_banco.trim().equals("")) {
				miContra.tipo_fpago="N";
			}else {
				miContra.fp_banco = miFPago.fp_banco.trim();
				miContra.fp_nroTarjeta = miFPago.fp_nroTarjeta.trim();
				if(miFPago.codTarjetaCredito != null) {
					miContra.codTarjetaCredito = miFPago.codTarjetaCredito.trim();
				}else {
					miContra.codTarjetaCredito = "";
				}
				
				miContra.sNombreBanco = miFPago.sNombreBanco.trim();
				if(miFPago.cbu != null) {
					miContra.cbu = miFPago.cbu.trim();
				}else {
					miContra.cbu="";
				}
				
				miContra.codBanco = miFPago.codBanco.trim();
			}
		}
		
		//Cargar Tasa
		String sTasa = miDAO.getPartidaMuni(nroCliente);
		if(sTasa.trim().equals("FALSE")) {
			miContra.sTasaAP="FALSE";
		}else {
			miContra.sTasaAP="TRUE";
			miContra.sPatidaMuni = sTasa.trim();
		}
	
		//Carga DG
		if( miDAO.getDepGar(miContra)) {
			miContra.garantia=true;
		}else {
			miContra.garantia=false;
		}
		
		//Generar Archivos
		
		switch(iTipoArchivo) {
			case 0: //Todos
				GenerarPlanoContrato(miContra);
				GenerarPlanoLinea(miContra);
				GenerarPlanoBilling(miContra);
				break;
			case 1: //Contrato
				GenerarPlanoContrato(miContra);
				break;
			case 2: //Linea contrato
				GenerarPlanoLinea(miContra);
				break;
				
			case 3: //Billing Profile
				GenerarPlanoBilling(miContra);
				break;
		}
		
		return true;
	}
	
	private Boolean AbreArchivos(int iTipoArchivos, String sOS) {
		String sLinea="";
		ContratoDAO miDao = new ContratoDAO();
		String sClave = "";
		String sArchivoContrato="";
		String sFilePathContrato="";
		String sArchivoLinea="";
		String sFilePathLinea="";
		String sArchivoBilling="";
		String sFilePathBilling="";
		
		Date dFechaHoy = new Date();
		
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyyMMdd");
		String sFechaFMT=fechaF.format(dFechaHoy);

		
		sClave = "SALESF";
		sPathGenera=miDao.getPathFile(sClave);
		sClave = "SALEFC";
		sPathCopia=miDao.getPathFile(sClave);
		
		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
		}
		
		sArchivoContrato= String.format("enel_care_contract_t1_%s.csv", sFechaFMT);
		sFilePathContrato=sPathGenera.trim() + sArchivoContrato.trim();
		
		sArchivoLinea= String.format("enel_care_contract_line_t1_%s.csv", sFechaFMT);
		sFilePathLinea=sPathGenera.trim() + sArchivoLinea.trim();

		sArchivoBilling= String.format("enel_care_billingprofile_t1_%s.csv", sFechaFMT);
		sFilePathBilling=sPathGenera.trim() + sArchivoBilling.trim();
		
		sArchContrato=sArchivoContrato;
		sArchLinea=sArchivoLinea;
		sArchBilling=sArchivoBilling;
		
		try {
			switch(iTipoArchivos) {
			case 0:	//Contrato - Linea - Billing
				outContrato = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathContrato), "UTF-8"));
				sLinea=getTitulos("CONTRATO");
				try {
					outContrato.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				outLinea = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathLinea), "UTF-8"));
				sLinea=getTitulos("LINEA");
				try {
					outLinea.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}

				outBilling = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathBilling), "UTF-8"));
				sLinea=getTitulos("BILLING");
				try {
					outBilling.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			case 1://Contrato
				outContrato = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathContrato), "UTF-8"));
				sLinea=getTitulos("CONTRATO");
				try {
					outContrato.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			case 2://Linea
				outLinea = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathLinea), "UTF-8"));
				sLinea=getTitulos("LINEA");
				try {
					outLinea.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			case 3://Billing
				outBilling = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathBilling), "UTF-8"));
				sLinea=getTitulos("BILLING");
				try {
					outBilling.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			}

		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	String getTitulos(String sTipo) {
		String sTitulo="";

		if(sTipo.equals("CONTRATO")) {
			sTitulo="\"Divisa del contrato\";\"Duración del contrato (meses)\";\"Estado\";\"Fecha de activación\";\"Fecha de inicio del contrato\";\"Fecha final del contrato\";\"Nombre de la cuenta\";\"Nombre del contrato\";\"Tipo de contrato\";\"Compañía\";\"External Id\";\"Contacto\";\"Suministro\";";
			sTitulo+="\"Actividad Económica\";\"Garantía\";\"Garante\";\"Fin de Garantía\";\"Comienzo de Garantía\";\"Conexión Transitoria\";\"Tipo de Titular\";\"Motivo de Garantía\";\"Tipo de Garantía\";\"Amount To Pay\";\"Connection Charge\";\"Construction Product\";\"Deactivation Date\";\"Payment Terms\";\"Cuenta Contrato\";";
			sTitulo+="\"Tasa AP\";\"Número de Partida\";\"Cliente Peaje\";\r\n";
			
		}else if(sTipo.equals("LINEA")) {
			sTitulo= "\"Divisa\";\"Activo\";\"Perfil de Facturación\";\"Contrato\";\"Cantidad\";\"Estado\";\"External ID\";\"CuentaContrato\";\"Perfil de Facturacion agrupador\";\r\n";
		}else { // BILLING
			sTitulo="\"Cuenta\";\"Tipo\";\"Acepta Términos y Condiciones\";\"Nombre de la factura\";\"Dirección de reparto\";\"Tipo de Documento\";\"Adhesión a Factura Electrónica\";\"External ID\";\"External ID Suministro\";\"Clase de Tarjeta\";\"Numero Tarjeta Crédito\";\"CBU\";\"Entidad Bancaria\";\"CuentaContrato\";\"Número de Cuenta\";\"Dirección Postal\";\"Tipo de Reparto\";\"Fecha Factura Digital\";\r\n";
		}
		
		return sTitulo;
	}

	void CierraArchivos() {
		try {
			outContrato.close();
			outLinea.close();
			outBilling.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}

	Boolean MoverArchivo() {
		String sOriContrato = sPathGenera.trim() + sArchContrato.trim();
		String sDestiContrato = sPathCopia.trim() + sArchContrato.trim();
		
        Path pOriContrato = FileSystems.getDefault().getPath(sOriContrato);
        Path pDestiContrato = FileSystems.getDefault().getPath(sDestiContrato);
        
		String sOriLinea = sPathGenera.trim() + sArchLinea.trim();
		String sDestiLinea = sPathCopia.trim() + sArchLinea.trim();
		
        Path pOriLinea = FileSystems.getDefault().getPath(sOriLinea);
        Path pDestiLinea = FileSystems.getDefault().getPath(sDestiLinea);
        
		String sOriBilling = sPathGenera.trim() + sArchBilling.trim();
		String sDestiBilling = sPathCopia.trim() + sArchBilling.trim();
		
        Path pOriBilling = FileSystems.getDefault().getPath(sOriBilling);
        Path pDestiBilling = FileSystems.getDefault().getPath(sDestiBilling);
        
		try {
			switch(iTipoFiles) {
			case 0:
				Files.move(pOriContrato, pDestiContrato, StandardCopyOption.REPLACE_EXISTING);
				Files.move(pOriLinea, pDestiLinea, StandardCopyOption.REPLACE_EXISTING);
				Files.move(pOriBilling, pDestiBilling, StandardCopyOption.REPLACE_EXISTING);
				break;
			case 1:
				Files.move(pOriContrato, pDestiContrato, StandardCopyOption.REPLACE_EXISTING);
				break;
			case 2:
				Files.move(pOriLinea, pDestiLinea, StandardCopyOption.REPLACE_EXISTING);
				break;
			case 3:
				Files.move(pOriBilling, pDestiBilling, StandardCopyOption.REPLACE_EXISTING);
				break;
			}
			
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	void GenerarPlanoContrato(ContratoDTO reg) {
		String sLinea="";

	   // Divisa del contrato
		sLinea="\"ARS\";";
	   
	   // Duración del contrato (meses) (vacio)
		sLinea += "\"\";";
	   
	   // Estado
		sLinea += "\"Activated\";";
	   
	   // Fecha de activación
		sLinea += String.format("\"%sT00:00:00.000Z\";", reg.sFechaAlta);

	   
	   // Fecha de inicio del contrato
		sLinea += String.format("\"%s\";", reg.sFechaAlta);

	   
	   // Fecha final del contrato (vacio)
		sLinea += "\"\";";
	   
	   // Nombre de la cuenta
		sLinea += String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // Nombre del contrato
		sLinea += String.format("\"%s\";", reg.nombre.trim());
	   
	   // Tipo de contrato
		sLinea += "\"Direct Contract\";";
	   
	   // Compañía
		sLinea += "\"9\";";

		// External Id
		sLinea += String.format("\"%dCTOARG\";", reg.numero_cliente);
	   
	   // Contacto
		sLinea += String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // id suministro
		sLinea += String.format("\"%dAR\";", reg.numero_cliente);

	   // Actividad Económica
		if(reg.codActividadEconomica != null) {
			sLinea += String.format("\"%s\";", reg.codActividadEconomica.trim());
		}else {
			sLinea += "\"\";";
		}
		
	   
	   // Garantía
		if(reg.garantia) {
			sLinea += "\"TRUE\";";
		}else {
			sLinea += "\"FALSE\";";
		}
		
	   // Garante
		if(reg.dg_garante != null) {
			sLinea += String.format("\"%d\";", reg.dg_garante);
		}else {
			sLinea += "\"\";";
		}
		
	   // Fin de Garantía
		sLinea += "\"\";";
	   // Comienzo de Garantía
		if(reg.dg_fechaEmision != null) {
			sLinea += String.format("\"%s\";", reg.dg_fechaEmision);
		}else {
			sLinea += "\"\";";
		}
		
	   // Conexión Transitoria
		sLinea += "\"\";";
	   // Tipo de Titular
		sLinea += String.format("\"%s\";", reg.tipo_titularidad.trim());

	   // Motivo de Garantía
		sLinea += "\"\";";
	   // Tipo de Garantía
		sLinea += "\"\";";
	   // Amount To Pay
		sLinea += "\"\";";
	   // Connection Charge
		sLinea += "\"\";";
	   // Construction Product / Budget 
		sLinea += "\"\";";
	   // Deactivation Date
		sLinea += "\"\";";
	   // Payment Terms
		sLinea += "\"\";";
	   // Cuenta Contrato
		sLinea += String.format("\"%d\";", reg.numero_cliente);
		
	   // Tasa AP
		if(!reg.sTasaAP.trim().equals("")) {
			sLinea += String.format("\"%s\";", reg.sTasaAP.trim());
		}else {
			sLinea += "\"\";";
		}
		
	   // Numero Partida
		if(reg.sPatidaMuni != null) {
			sLinea += String.format("\"%s\";", reg.sPatidaMuni.trim());
		}else {
			sLinea += "\"\";";
		}

	   // Cliente Peaje
		sLinea += "\"FALSE\";";
		
		
		sLinea += "\r\n";
			
		try {
			outContrato.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	void GenerarPlanoLinea(ContratoDTO reg) {
		String sLinea="";
		
	   // Divisa
		sLinea = "\"ARS\";";

	      
	   // Activo
		sLinea += String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // Perfil de Facturación
		sLinea += String.format("\"%dBPARG\";", reg.numero_cliente);
	   
	   // Contrato
		sLinea += String.format("\"%dCTOARG\";", reg.numero_cliente);
	   
	   // Cantidad
		sLinea += "\"1\";";
	   
	   // Estado
		sLinea += "\"Active\";";
	   
	   // External ID
		sLinea += String.format("\"%dLCOARG\";", reg.numero_cliente); 
	   
	   // Cuenta contrato
		sLinea += String.format("\"%d\";", reg.numero_cliente);
	   
	   //Perfil de Facturación agrupador
		if(!reg.papa_t23.trim().equals("")) {
			sLinea += String.format("\"%sBPARG\";", reg.papa_t23.trim());
		}else if(reg.minist_repart>0) {
			sLinea += String.format("\"%dAR\";", reg.minist_repart);
		}else {
			sLinea += "\"\";";
		}

		
		sLinea += "\r\n";
		
		try {
			outLinea.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
	}
	
	void GenerarPlanoBilling(ContratoDTO reg) {
		String sLinea = "";

	   // Cuenta
		sLinea = String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // Tipo
		if(reg.tipo_fpago.trim().contentEquals("D")) {
			if(reg.cbu.trim().equals("")) {
				sLinea += String.format("\"%s\";", reg.sMarcaTarjeta);
			}else {
				sLinea += "\"D\";";
			}
			
		}else {
			sLinea += "\"\";";
		}
		
	   // Acepta Términos y Condiciones
		if(reg.factu_digital.trim().equals("S")) {
			sLinea += "\"TRUE\";";
		}else {
			sLinea += "\"FALSE\";";
		}
		
	   // Nombre de la factura
		sLinea += String.format("\"%dARG\";", reg.numero_cliente);
	   
	   // Dirección de reparto
		if(reg.tipo_reparto.trim().equals("P")) {
			sLinea += String.format("\"%d-1ARG\";", reg.numero_cliente);
		}else {
			sLinea += String.format("\"%d-2ARG\";", reg.numero_cliente);
		}
		
	   
	   // Tipo de Documento
		sLinea += "\"\";";
	   
	   // Adhesión a Factura Electrónica
		if(reg.tipo_fpago.trim().contentEquals("D")) {
			sLinea += "\"TRUE\";";
	   }else{
		   sLinea += "\"FALSE\";";

	   }
	   
	   // External ID
		sLinea += String.format("\"%dBPARG\";", reg.numero_cliente);
	   
	   // External ID Suministro
		sLinea += String.format("\"%dAR\";", reg.numero_cliente);
	   
	   // Clase de Tarjeta
		if(reg.codTarjetaCredito != null) {
			sLinea += String.format("\"%s\";", reg.codTarjetaCredito.trim());
		}else {
			sLinea += "\"\";";
		}
		
	   // Numero Tarjeta Crédito
		if(reg.nroTarjeta != null) {
			sLinea += String.format("\"%s\";", reg.nroTarjeta.trim());
		}else {
			sLinea += "\"\";";
		}
	   
	   // CBU
		if(reg.cbu != null) {
			sLinea += String.format("\"%s\";", reg.cbu.trim());
		}else {
			sLinea += "\"\";";
		}
	   
	   // Entidad Bancaria
		if(reg.codBanco != null) {
			sLinea += String.format("\"%s\";", reg.codBanco.trim());
		}else {
			sLinea += "\"\";";
		}
		
	   // CuentaContrato
		sLinea += String.format("\"%d\";", reg.numero_cliente);
	   
	   // Número de Cuenta
		/*
		if(reg.nroTarjeta != null) {
			sLinea += String.format("\"%s\";", reg.nroTarjeta.trim());
		}else {
			sLinea += "\"\";";
		}
		*/
		sLinea += "\"\";";
	   
	   // Dirección Postal
		if(reg.tipo_reparto.trim().equals("P")) {
			sLinea += String.format("\"%d-1ARG\";", reg.numero_cliente);
		}else {
			sLinea += String.format("\"%d-2ARG\";", reg.numero_cliente);
		}

	   
	   // Tipo de Reparto  
		sLinea += String.format("\"%s\";", reg.tipo_reparto.trim());
	
	   // Fecha Factura Digital
		if(!reg.sFechaAltaFactuDigital.trim().equals("")) {
			sLinea += String.format("\"%s\";", reg.sFechaAltaFactuDigital);
		}else {
			sLinea += "\"\";";
		}
		

		sLinea += "\r\n";
		
		try {
			outBilling.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
	}
}

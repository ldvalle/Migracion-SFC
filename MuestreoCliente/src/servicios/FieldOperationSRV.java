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

public class FieldOperationSRV {

	private static Writer outFile=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchivoSalida;
	private static int iTipoCorrida;

	public Boolean ProcesaCortes(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		FieldOperationDAO miDao = new FieldOperationDAO();

		
		//proceso Cortes
		if(!miDao.procesaCorte(iTipo)) {
			System.out.println("Fallo el DAO para Cortes/Repo");
			return false;
		}
		
		//proceso Extensiones
		if(!miDao.procesaExtend(iTipo)) {
			System.out.println("Fallo el Extensiones");
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
	
	public Boolean InformaEvento(FieldOperationDTO reg, String sEvento) {
		String sLinea="";
		
		switch(sEvento.charAt(0)) {
		case 'C':
			// Tipo de registro
			sLinea = "\"CUTOFF\";";
			// Fecha actual
			sLinea += String.format("\"%s\";", reg.fecha_corte);
			// Monto */
			sLinea += String.format("\"%.02f\";", reg.saldo_exigible);
			// Description
			sLinea += String.format("\"%s\";", reg.desc_motivo_corte.trim());
			// Acción realizada
			sLinea += String.format("\"%s\";", reg.accion_corte);
			// Rol ejecutor
			sLinea += String.format("\"%s\";", reg.funcionario_corte.trim());
			// Evento
			sLinea += "\"\";";
			// Fecha evento
			sLinea += String.format("\"%s\";", reg.fecha_ini_evento);
			// External Id
			sLinea += String.format("\"%d%sAR\";", reg.numero_cliente, reg.fecha_ini_evento);
			// Situación encontrada
			sLinea += String.format("\"%s\";", reg.sit_encon);
			// Suministro
			sLinea += String.format("\"%dAR\";", reg.numero_cliente);
			// Observaciones
			sLinea += "\"\";";
			// Motivo
			sLinea += String.format("\"%s\";", reg.motivo_corte);
			// Estado
			sLinea += "\"Completed\";";
			// Dias (Vacio)
			sLinea += "\"\";";

			break;
		case 'R':
			// Tipo de registro
			sLinea = "\"REINSTATEMEN\";";
			// Fecha actual
			sLinea += String.format("\"%s\";", reg.fecha_reposicion);
			// Monto */
			sLinea += String.format("\"%.02f\";", reg.saldo_exigible);
			// Description
			sLinea += String.format("\"%s\";", reg.motivo_repo);
			// Acción realizada
			sLinea += String.format("\"%s\";", reg.accion_rehab);
			// Rol ejecutor
			sLinea += String.format("\"%s\";", reg.funcionario_repo);
			// Evento
			sLinea += "\"\";";
			// Fecha evento
			sLinea += String.format("\"%s\";", reg.fecha_sol_repo);
			// External Id
			sLinea += String.format("\"%d%sAR\";", reg.numero_cliente, reg.fecha_sol_repo);
			// Situación encontrada
			sLinea += String.format("\"%s\";", reg.sit_rehab);
			// Suministro
			sLinea += String.format("\"%dAR\";", reg.numero_cliente);
			// Observaciones
			sLinea += "\"\";";
			// Motivo
			sLinea += String.format("\"%s\";", reg.motivo_repo);
			// Estado
			sLinea += "\"Completed\";";
			// Dias (vacio)
			sLinea += "\"\";";			
			break;
		case 'E':
			//Tipo de registro
			sLinea = "\"EXTENSION\";";
			// Fecha actual
			sLinea += String.format("\"%s\";", reg.ext_fecha_solicitud);
			// Monto (vacio)
			sLinea += "\"\";";
			// Description
			sLinea += String.format("\"%s\";", reg.ext_motivo);
			// Acción realizada (vacio)
			sLinea += "\"\";";
			// Rol ejecutor
			sLinea += String.format("\"%s\";", reg.ext_rol);
			// Evento
			sLinea += "\"\";";
			// Fecha evento
			sLinea += "\"\";";
			// External Id
			sLinea += String.format("\"%d%sAR\";", reg.numero_cliente, reg.ext_fecha_solicitud);
			// Situación encontrada
			sLinea += "\"\";";
			// Suministro
			sLinea += String.format("\"%dAR\";", reg.numero_cliente);
			// Observaciones
			sLinea += "\"\";";
			// Motivo
			sLinea += String.format("\"%s\";", reg.ext_cod_motivo);
			// Estado
			sLinea += String.format("\"%s\";", reg.ext_estado);
			// Dias
			sLinea += String.format("\"%d\";", reg.ext_dias);
			
			break;
		}
		
		sLinea += "\r\n";
		
		try {
			outFile.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	private Boolean AbreArchivos( String sOS) {
		String sLinea="";
		DeviceDAO miDao = new DeviceDAO();
		String sClave = "";
		String sArchivoDevice="";
		String sFilePathDevice="";
		
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
		
		sArchivoDevice= String.format("enel_care_fieldoperation_t1_%s.csv", sFechaFMT);
		sFilePathDevice=sPathGenera.trim() + sArchivoDevice.trim();
		
		sArchivoSalida=sArchivoDevice;

		try {
			outFile = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathDevice), "UTF-8"));
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
		
		sLinea = "\"Tipo de registro\";" + 
				"\"Fecha actual\";" + 
				"\"Monto\";" + 
				"\"Description\";" + 
				"\"Acción realizada\";" + 
				"\"Rol ejecutor\";" + 
				"\"Evento\";" + 
				"\"Fecha evento\";" + 
				"\"External Id\";" + 
				"\"Situación encontrada\";" + 
				"\"Suministro\";" + 
				"\"Observaciones\";" + 
				"\"Motivo\";" + 
				"\"Estado\";" + 
				"\"Dias\"" + 
				"\r\n";
		
		return sLinea;
	}
	
	
}

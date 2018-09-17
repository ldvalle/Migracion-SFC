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

public class DeviceSRV {
	private static Writer outFile=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchivoSalida;
	private static int iTipoCorrida;

	public Boolean ProcesaDevice(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		DeviceDAO miDao = new DeviceDAO();

		
		//proceso ppal ----
		if(!miDao.ProcesaDevices(iTipo)) {
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
		
		sArchivoDevice= String.format("enel_care_device_t1_%s.csv", sFechaFMT);
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
		
		sLinea = "\"Marca Medidor\";"+
			"\"Modelo Medidor\";"+
			"\"Nro.Medidor\";"+
			"\"Propiedad Medidor\";"+
			"\"Tipo Medidor\";"+
			"\"Punto de Suministro\";"+
			"\"External ID\";"+
			"\"Estado Medidor\";"+
			"\"Fecha Ult.Instalación\";"+
			"\"Constante\";"+
			"\"Fecha Fabricación\";"+
			"\"Fecha Instalación\";"+
			"\r\n";
		
		return sLinea;
	}

	public String getEstadoSFC(String stsMAC, String medUbic) {
		String stsSFC="";
		
		switch (stsMAC.charAt(0)) {
			case 'Z':
			case 'U':
				//No Disponible
				stsSFC="R";
				break;
			default:
				switch(medUbic.charAt(1)) {
				case 'C': //En Cliente
					stsSFC="I";
					break;
				case 'D':	//Bodega
				case 'L':	//Laboratorio
				case 'F':	//En Fabrica
					stsSFC="R";
					break;
				case 'O':	//Contratista
				case 'S':	//Sucursal
					stsSFC = "D";
					break;
				}
				break;
		}
		return stsSFC;
	}
	
	public Boolean InformaDevice(DeviceDTO reg) {
		String sLinea="";
		
	   /* Marca Medidor */
		sLinea = String.format("\"%s\";", reg.marca.trim());
	   
	   /* Modelo Medidor */
		sLinea += String.format("\"%s\";", reg.modelo.trim());
	   
	   /* Nro.Medidor */
		sLinea += String.format("\"%d\";", reg.numero);
	   
	   /* Propiedad */
		sLinea +=  "\"C\";";
	   
	   /* Tipo Medidor */
		if(reg.tipo_medidor.trim().equals("R")) {
			sLinea +=  "\"REAC\";";
		}else {
			sLinea +=  "\"ACTI\";";
		}
	   
	   /* Punto Suministro */
		if(reg.med_ubic.trim().equals("C")) {
			if(reg.numero_cliente > 0) {
				sLinea += String.format("\"%dAR\";", reg.numero_cliente);
			}else {
				sLinea +=  "\"\";";
			}
		}else {
			sLinea +=  "\"\";";
		}
		
	   /* External ID */
		sLinea+= String.format("\"%d%d%s%sDEVARG\";", reg.numero_cliente, reg.numero, reg.marca, reg.modelo);
	   
	   /* Estado Medidor */
		sLinea += String.format("\"%s\";", reg.estado_sfc.trim());

	   /* Fecha Ult.Instalacion */
		sLinea += String.format("\"%s\";", reg.fecha_ult_insta);

	   /* Constante */
		sLinea += String.format("\"%.02f\";", reg.constante);

	   /* Fecha Fabricación */
		sLinea += String.format("\"%d\";", reg.med_anio);

	   /* Fecha Retiro */
/*		
		if(reg.fecha_prim_insta != null) {
			sLinea += String.format("\"%s\";", reg.fecha_prim_insta);
		}else {
			sLinea +=  "\"\";";
		}
*/
		sLinea +=  "\"\";";
		
		sLinea += "\r\n";
		
		try {
			outFile.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
}
